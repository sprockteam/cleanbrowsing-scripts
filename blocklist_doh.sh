#!/usr/bin/env bash

# shellcheck source=config.sh
source config.sh

log_file="logs/blocklist_doh.log"
doh_repo="https://raw.githubusercontent.com/wiki/curl/curl/DNS-over-HTTPS.md"

if [ -z "$CLEANBROWSING_API_KEY" ]; then
    echo 'ERROR: Check config, the API key is not defined.'
    exit
fi

if [ "${#CLEANBROWSING_PROFILES[@]}" -eq 0 ]; then
    CLEANBROWSING_PROFILES=( "default" )
fi

# Extract the list of DoH providers from the repo.
raw_doh_list=$(curl -s "$doh_repo" | sed -n '/^\| Who runs it/,/^\s*$/p' | grep "https:")

# Cut out just the URL column from the list.
raw_doh_list=$(echo "$raw_doh_list" | cut -d '|' -f 3)

# Don't keep the colon or slash or anything after the domain in the URL.
raw_doh_list=$(echo "$raw_doh_list" | grep -oE 'https:\/\/[^(\/|:)]*')

# Trim the leading 'https://' and also 'example.' to get just the domains to block.
raw_doh_list=$(echo "$raw_doh_list" | sed 's|https:\/\/||g;s|example\.||g')

# Exclude certain domains from the list.
raw_doh_list=$(echo "$raw_doh_list" | grep -vE 'cleanbrowsing\.org|my\.nextdns\.io|blog\.cloudflare\.com')

# Finally sort and process the list for each profile.
for profile in "${CLEANBROWSING_PROFILES[@]}"; do
    run_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "===== START $profile at $run_time =====" >> $log_file
    while IFS=$'\n' read -r provider; do
        url="$CLEANBROWSING_API_URL?apikey=$CLEANBROWSING_API_KEY&action=blocklist/add&profile_name=$profile&domain_name=$provider"
        echo "Adding $provider to blocklist for profile $profile" >> $log_file
        curl -s "$url" >> $log_file
        echo "curl exit status: $?" >> $log_file
    done < <(echo "$raw_doh_list" | sort -u)
    echo "===== END $profile =====" >> $log_file
done
