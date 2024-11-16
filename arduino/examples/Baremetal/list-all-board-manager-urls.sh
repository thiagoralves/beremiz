#!/bin/bash

PROGDIR=$(dirname "$(readlink -f "$0")")
ARDUINO_CLI=$(readlink -f "$PROGDIR/../../bin/arduino-cli-l64")

# read the list of URLs
$ARDUINO_CLI --json config dump | jq -r '.config.board_manager.additional_urls[]'
