#!/usr/bin/env bash

# A utility script to add DoH providers to your CleanBrowsing blocklist.
# Part of the cleanbrowsing-scripts project.
# https://github.com/sprockteam/cleanbrowsing-scripts/
# MIT License
# Copyright (c) 2020 SprockTech, LLC and contributors

# shellcheck source=config.sh
source config.sh

if [ -z "$CLEANBROWSING_API_KEY" ]; then
    echo 'ERROR: Check config, the API key is not defined.'
    exit
fi

if [ "${#CLEANBROWSING_PROFILES[@]}" -eq 0 ]; then
    CLEANBROWSING_PROFILES=( "default" )
fi

# Make the logs directory if needed.
if [ ! -d "logs" ]; then
    mkdir logs
fi

log_file="logs/blocklist_doh.log"
doh_repo="https://raw.githubusercontent.com/wiki/curl/curl/DNS-over-HTTPS.md"
base_api="$CLEANBROWSING_API_URL?apikey=$CLEANBROWSING_API_KEY"

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
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "===== START $profile at $timestamp =====" >> $log_file
    url="$base_api&action=blocklist/list&profile_name=$profile"
    current_blocklist=$(curl -s "$url")
    while IFS=$'\n' read -r provider; do
        # Trim any leading or trailing whitespace in the provider name.
        provider=$(echo "$provider" | xargs)
        timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        if [ "$(echo "$current_blocklist" | grep -c "$provider")" -gt 0 ]; then
            echo "$timestamp - Skipping $provider already in blocklist for profile $profile" >> $log_file
        else
            echo "$timestamp - Adding $provider to blocklist for profile $profile" >> $log_file
            url="$base_api&action=blocklist/add&profile_name=$profile&domain_name=$provider"
            # shellcheck disable=SC2129
            curl -s "$url" >> $log_file
            echo "curl exit status: $?" >> $log_file
            # Wait a second to not send too many requests.
            sleep 1
        fi
    done < <(echo "$raw_doh_list" | sort -u)
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "===== END $profile at $timestamp =====" >> $log_file
done

unset -v CLEANBROWSING_API_KEY
