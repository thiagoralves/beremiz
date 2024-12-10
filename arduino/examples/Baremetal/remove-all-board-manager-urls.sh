#!/bin/sh
# remove-all-board-manager-urls.sh
# Removes all configured board manager URLs
. "`dirname \"$0\"`/find-arduino-cli.sh"
urls="`\"$ARDUINO_CLI\" --json config dump | jq -r '.config.board_manager.additional_urls[]'`"
echo "$urls" | while read -r url; do
    echo "Removing URL: $url"
    "$ARDUINO_CLI" config remove board_manager.additional_urls "$url"
done
