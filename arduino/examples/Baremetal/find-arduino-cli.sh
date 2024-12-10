#!/bin/sh
# find-arduino-cli.sh
# Configuration file for Arduino CLI Tools
# Provides OS detection and common settings for all scripts

# Determine program directory using readlink
PROGDIR="`readlink -f "$0"`"
PROGDIR="`dirname "$PROGDIR"`"

# Function to detect operating system
detect_os() {
    os_name="`uname -s`"
    case "$os_name" in
        Linux*)
            echo "Linux"
            ;;
        Darwin*)
            echo "MacOS"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "Windows"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Function to check required tools
check_requirements() {
    # Check if jq is available
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: 'jq' is not installed" >&2
        exit 1
    fi
    
    # Check if Arduino CLI exists
    if [ ! -f "$ARDUINO_CLI" ]; then
        echo "Error: Arduino CLI not found at: $ARDUINO_CLI" >&2
        exit 1
    fi
    
    # Check if Arduino CLI is executable
    if [ ! -x "$ARDUINO_CLI" ]; then
        echo "Error: Arduino CLI is not executable: $ARDUINO_CLI" >&2
        exit 1
    fi
}

# Set correct Arduino CLI path based on operating system
OS="`detect_os`"
case "$OS" in
    Linux)
        ARDUINO_CLI="`readlink -f \"$PROGDIR/../../bin/arduino-cli-l64\"`"
        ;;
    MacOS)
        # MacOS workaround for readlink
        if command -v greadlink >/dev/null 2>&1; then
            ARDUINO_CLI="`greadlink -f \"$PROGDIR/../../bin/arduino-cli-mac\"`"
        else
            ARDUINO_CLI="$PROGDIR/../../bin/arduino-cli-mac"
        fi
        ;;
    Windows)
        ARDUINO_CLI="`readlink -f \"$PROGDIR/../../bin/arduino-cli-w64.exe\"`"
        ;;
    *)
        echo "Unsupported operating system" >&2
        exit 1
        ;;
esac

# Export variables for use in other scripts
export ARDUINO_CLI
export PROGDIR

# Perform requirements check
check_requirements
