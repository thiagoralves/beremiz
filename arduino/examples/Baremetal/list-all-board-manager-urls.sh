#!/bin/sh
# list-all-board-manager-urls.sh
# Lists all configured board manager URLs
. "`dirname \"$0\"`/find-arduino-cli.sh"
"$ARDUINO_CLI" --json config dump | jq -r '.config.board_manager.additional_urls[]'
