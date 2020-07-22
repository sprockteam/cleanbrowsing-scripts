# CleanBrowsing Scripts
Scripts related to managing the CleanBrowsing service via their API.

### How to begin
- Clone the project to your computer and copy the sample config.
```console
get clone https://github.com/sprockteam/cleanbrowsing-scripts.git
cd cleanbrowsing-scripts
cp sample-config.sh config.sh
```
- Edit `config.sh` to set your API key and profiles.
```
vi config.sh
```

### blocklist_doh.sh
This will block all DoH providers listed [here](https://raw.githubusercontent.com/wiki/curl/curl/DNS-over-HTTPS.md) if they are not already blocked.
```
bash blocklist_doh.sh
```