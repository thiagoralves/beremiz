#!/bin/sh
# list-all-libraries.sh
# Lists all installed Arduino libraries
. "`dirname \"$0\"`/find-arduino-cli.sh"
"$ARDUINO_CLI" --json lib list | jq -r '.installed_libraries[] | .library.name'
