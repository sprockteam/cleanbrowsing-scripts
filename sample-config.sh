#!/usr/bin/env bash

# Enable command tracing if needed for debugging.
#set -o xtrace

# Set your real API key here.
export CLEANBROWSING_API_KEY="your-api-key-here"

# Define the profiles you want to manage in this array.
export CLEANBROWSING_PROFILES=( "default" )

# Don't change this.
export CLEANBROWSING_API_URL="https://my.cleanbrowsing.org/api"
