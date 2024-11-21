# JSON Tools

This toolset provides enhanced JSON file comparison and cleaning capabilities.

## Features

### Git Integration Tool (`json-format.sh`)
- Sorts JSON object keys for consistent comparison
- Preserves array order (important for semantic meaning)
- Handles nested objects
- Falls back gracefully for invalid JSON files
- Ignores whitespace and formatting variations

### Command Line Compare Tool (`json-compare.sh`)
- Direct comparison of two JSON files
- Uses colored output if available (`colordiff`)
- Provides clear status output
- Returns standard diff exit codes
- Auto-cleanup of temporary files

### HALs Cleaner Tool (`clean-hals-json.sh`)
- Resets specific HALs JSON fields to default values, use it before commits
- Creates automatic backups before modification
- Preserves original file on error
- Provides clear error messages and installation help
- Handles failure scenarios gracefully

## Requirements

The tools require `jq` (JSON processor) to be installed on your system:

- Gentoo Linux:
  ```bash
  emerge dev-libs/jq
  ```
- Other Linux distributions:
  - Debian/Ubuntu: `apt install jq`
  - RHEL/Fedora: `dnf install jq`
  - Arch Linux: `pacman -S jq`
- Windows: Install via [Chocolatey](https://chocolatey.org/): `choco install jq`

Optional for enhanced visual comparison:
- `colordiff` for colored output in command line comparison
  ```bash
  emerge sys-apps/colordiff  # Gentoo
  ```

## Installation

### 1. Make scripts executable:
```bash
chmod +x ./arduino/examples/Baremetal/json-format.sh
chmod +x ./arduino/examples/Baremetal/json-compare.sh
chmod +x ./arduino/examples/Baremetal/clean-hals-json.sh
```

### 2. For git integration:

Add to either your global git config (`~/.gitconfig`) or the repository's local config (`.git/config`):

```ini
[diff "json"]
    textconv = ./arduino/examples/Baremetal/json-format.sh
```

Tell git which files should use this diff tool. Add to either your global git attributes (`~/.config/git/attributes`) or the repository's `.gitattributes`:

```
*.json diff=json
```

### 3. Quick Setup Using Git Commands

#### Global Setup
```bash
# Configure git for JSON comparison globally
git config --global diff.json.textconv './arduino/examples/Baremetal/json-format.sh'
git config --global core.attributesFile '~/.config/git/attributes'

# Create global attributes directory if it doesn't exist
mkdir -p ~/.config/git

echo "*.json diff=json" >> ~/.config/git/attributes
```

#### Repository-specific Setup
```bash
# Configure git for JSON comparison in current repository
git config diff.json.textconv './arduino/examples/Baremetal/json-format.sh'
echo "*.json diff=json" >> .gitattributes
```

Choose either global or repository-specific setup depending on your needs. Global setup affects all repositories, while repository-specific setup only affects the current repository.

## Usage

### Git Integration
After installation, git will automatically use the formatting tool when showing differences for JSON files:

```bash
git diff file.json           # Compare with unstaged changes
git diff --cached file.json  # Compare staged changes
git log -p file.json        # Show changes in history
```

### Command Line Comparison
Use the compare script to directly compare two JSON files:
```bash
./arduino/examples/Baremetal/json-compare.sh file1.json file2.json
```

The script will:
- Use colored output if `colordiff` is available
- Show differences in a human-readable format
- Return 0 if files are identical, 1 if different
- Handle errors gracefully with meaningful messages

### HALs Cleaner
Use the cleaner script to reset HALs JSON fields:
```bash
./arduino/examples/Baremetal/clean-hals-json.sh
```

The script will:
- Create a backup as `hals.json.bak`
- Reset `last_update` to 0
- Reset `version` to "0"
- Remove backup on successful update
- Preserve backup on failure

## Example

Given two JSON files with different formatting:

```json
// Version 1
{
  "b": 2,
  "a": 1
}

// Version 2
{
    "a":    1,
    "b": 2
}
```

Both git diff and the compare script will show no differences, as the files are semantically identical.

## Troubleshooting

- If the scripts aren't working, verify that:
  1. The scripts have execute permissions
  2. The path in your git config is correct (for git integration)
  3. `jq` is installed and available in your PATH
  4. Your `.gitattributes` file is properly configured (for git integration)
  5. `colordiff` is installed (optional, for colored command line output)

For git integration, you can verify the configuration with:
```bash
git check-attr -a example.json
```

## Technical Details

The tools use `jq`'s `walk` function to traverse the JSON structure, applying key sorting only to objects while preserving array order. This ensures that semantically significant ordering in arrays is maintained while still providing normalized comparison for objects.

### Fields Modified by HALs Cleaner
The cleaner modifies these fields in all entries:
- `last_update`: Set to 0
- `version`: Set to "0"

### Exit Codes
- 0: Operation successful
- 1: Error (file not found, invalid JSON, jq not installed)
