#!/bin/sh
# remove-all-cores.sh
# Removes all installed Arduino cores
. "`dirname \"$0\"`/find-arduino-cli.sh"
cores="`\"$ARDUINO_CLI\" --json core list | jq -r '.platforms[] | \"\(.id)\"'`"
echo "$cores" | while read -r core; do
    echo "Removing core: $core"
    "$ARDUINO_CLI" core uninstall "$core"
done
