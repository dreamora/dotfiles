# Collected shell helper scripts

Files in this directory that are executable are intended to be available as
global shell commands through the dotfiles setup. The installer stows command
scripts into `$HOME/.local/bin`.

## convert-android-keystore.sh

Converts an Android keystore through a PKCS#12 intermediate into a new JKS
keystore.

## delete_files.sh

**alias:** delete-files

Deletes all files that meet a certain structure

## ide

Starts tmux when needed and creates the pane layout used for an IDE-style
terminal workspace. Prints a clear error when tmux is not installed.

## line_extract.sh

**alias:** line-extract

Extracts all lines of a given file (for example logcat) based on regex criteria

`line-extract PATTERN FILE`

## miyooogameslist.py

Not installed as a global command. This is a local helper script for generating
a Miyoo game list from a fixed ROM directory.

## verify_folder_contracts.sh

Verifies that the repository folder contracts are intact: `homedir-common/` stows
into `$HOME`, `configs/` stows under `~/.config`, and executable files in
`scripts/` are available as utilities in the `scripts/` directory.
