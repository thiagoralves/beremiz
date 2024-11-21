#!/bin/sh
# list-all-cores.sh
# Lists all installed Arduino cores
. "`dirname \"$0\"`/find-arduino-cli.sh"
"$ARDUINO_CLI" --json core list | jq -r '.platforms[] | "\(.id)"'
