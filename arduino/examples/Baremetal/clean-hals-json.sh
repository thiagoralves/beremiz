#!/bin/bash

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    echo "Please install jq using your package manager:"
    echo "  For Gentoo: emerge -av app-misc/jq"
    echo "  For Debian/Ubuntu: apt-get install jq"
    echo "  For Fedora: dnf install jq"
    exit 1
fi

# Create backup of original file
cp hals.json hals.json.bak

# Apply jq filter and write to temporary file
jq '
  to_entries | map(
    .value.last_update = 0 |
    .value.version = "0"
  ) | from_entries
' hals.json > hals.json.tmp

# On success, replace original file with updated version and clean up
if [ $? -eq 0 ]; then
    mv hals.json.tmp hals.json
    rm hals.json.bak
    echo "JSON file successfully updated"
else
    rm hals.json.tmp
    echo "Error updating JSON file"
    echo "Backup preserved as hals.json.bak"
    exit 1
fi
