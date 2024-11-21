#!/bin/bash

PROGDIR="$(dirname "$(readlink -f "$0")")"
ARDUINO_CLI="$(readlink -f "$PROGDIR/../../bin/arduino-cli-l64")"

# read the list of cores
CORES=$("$ARDUINO_CLI" --json core list | jq -r '.platforms[] | "\(.id)"')

# remove URLs one by one
for c in $CORES; do
    echo "Removing core: $c"
    "$ARDUINO_CLI" core uninstall $c
done
