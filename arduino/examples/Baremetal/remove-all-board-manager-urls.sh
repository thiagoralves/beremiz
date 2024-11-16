#!/bin/bash

PROGDIR=$(dirname "$(readlink -f "$0")")
ARDUINO_CLI=$(readlink -f "$PROGDIR/../../bin/arduino-cli-l64")

# read the list of URLs
URLS=$($ARDUINO_CLI --json config dump | jq -r '.config.board_manager.additional_urls[]')

# remove URLs one by one
for url in $URLS; do
    echo "Removing URL: $url"
    $ARDUINO_CLI config remove board_manager.additional_urls "$url"
done
