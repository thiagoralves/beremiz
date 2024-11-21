# Arduino CLI Management Tools

A collection of POSIX-compliant shell scripts for managing Arduino CLI components, including board manager URLs, cores, and libraries.

## Prerequisites

- POSIX-compliant shell (`/bin/sh`)
- Arduino CLI binaries:
  - Linux: `arduino-cli-l64`
  - MacOS: `arduino-cli-mac`
  - Windows: `arduino-cli-w64.exe`
- `jq` (JSON processor)
- `readlink` (GNU readlink or compatible)
  - For MacOS: GNU readlink (`greadlink`) is recommended but not required

## Script Overview

### Configuration

#### `find-arduino-cli.sh`
Central configuration script that:
- Detects the operating system
- Sets up the correct Arduino CLI binary path
- Performs requirement checks
- Provides common functions and variables
- Handles paths with spaces correctly

### Board Manager URL Management

#### `list-all-board-manager-urls.sh`
Lists all configured board manager URLs.

**Operation:**
- Uses Arduino CLI in JSON mode
- Extracts all configured URLs from Arduino CLI configuration
- Outputs URLs line by line

#### `remove-all-board-manager-urls.sh`
Removes all configured board manager URLs.

**Operation:**
- Reads all configured URLs
- Removes each URL individually from the configuration
- Provides feedback for each removed URL

### Core Management

#### `list-all-cores.sh`
Shows all installed Arduino cores.

**Operation:**
- Retrieves the list of all installed cores
- Outputs core IDs line by line

#### `remove-all-cores.sh`
Uninstalls all installed Arduino cores.

**Operation:**
- Determines all installed cores
- Uninstalls each core individually
- Provides feedback for each removed core

### Library Management

#### `list-all-libraries.sh`
Shows all installed Arduino libraries.

**Operation:**
- Retrieves the list of all installed libraries
- Outputs library names line by line

## Installation

1. Ensure Arduino CLI binaries are present in the correct path relative to the script directory
2. Install `jq` on your system
3. Ensure `readlink` is available (or `greadlink` for MacOS)
4. Make the scripts executable:
   ```sh
   chmod +x *.sh
   ```

## Usage

All scripts can be executed directly from the command line:

```sh
./list-all-board-manager-urls.sh
./list-all-cores.sh
./list-all-libraries.sh
./remove-all-board-manager-urls.sh
./remove-all-cores.sh
```

## Platform-Specific Notes

### Linux
- Requires GNU readlink (typically pre-installed)
- Uses `arduino-cli-l64` binary

### MacOS
- Can use either GNU readlink (`greadlink`) or work without it
- Uses `arduino-cli-mac` binary
- To install GNU readlink: `brew install coreutils`

### Windows (MSYS2/Git Bash)
- Requires GNU readlink
- Uses `arduino-cli-w64.exe` binary

## Important Notes

- Scripts use relative paths to Arduino CLI binaries
- All removal operations are permanent and cannot be undone
- It's recommended to create a backup of your configuration before running removal scripts
- Scripts are POSIX-compliant and should work with any POSIX-compatible shell
- Path handling is robust and supports spaces in directory names

## Troubleshooting

If the scripts fail to run:
1. Check script execution permissions
2. Verify Arduino CLI binary paths
3. Ensure `jq` is installed
4. Check `readlink` availability
   - Linux: Should be pre-installed
   - MacOS: Install GNU coreutils for `greadlink`
   - Windows: Ensure running in MSYS2/Git Bash environment
5. If using paths with spaces, ensure they are properly quoted in any customizations

## Contributing

When contributing to these scripts, please ensure:
- POSIX compliance
- Platform independence
- Proper error handling
- English comments and documentation
- Proper quoting of paths and variables
