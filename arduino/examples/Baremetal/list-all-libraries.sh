#!/bin/bash

PROGDIR="$(dirname "$(readlink -f "$0")")"
ARDUINO_CLI="$(readlink -f "$PROGDIR/../../bin/arduino-cli-l64")"

# read the list of libraries
"$ARDUINO_CLI" --json lib list | jq -r '.installed_libraries[] | .library.name'
