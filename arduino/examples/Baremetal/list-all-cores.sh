#!/bin/bash

PROGDIR=$(dirname "$(readlink -f "$0")")
ARDUINO_CLI=$(readlink -f "$PROGDIR/../../bin/arduino-cli-l64")

# read the list of cores
$ARDUINO_CLI --json core list | jq -r '.platforms[] | "\(.id)"'
