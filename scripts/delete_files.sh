#!/usr/bin/env bash

set -euo pipefail

# Script to find and delete files matching a pattern in a target directory.

# Usage: ./delete_files.sh <pattern> <target_directory>

# Check if the correct number of arguments is provided
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <pattern> <target_directory>"
  exit 1
fi

# Assign arguments to variables
pattern="$1"
target_directory="$2"
display_target_directory="$target_directory"

case "$target_directory" in
  -*) target_directory="./$target_directory" ;;
esac

# Check if the target directory exists
if [[ ! -d "$target_directory" ]]; then
  echo "Error: Target directory '$display_target_directory' does not exist."
  exit 1
fi

# Find and delete files matching the pattern
# We don't need a loop here unless we expect files to be recreated immediately,
# but even then, it's better to let a scheduler handle it or use a more controlled loop.
# The previous loop was infinite because 'find' returns 0 (success) even if it finds nothing.

deleted_files="$(mktemp "${TMPDIR:-/tmp}/delete-files.XXXXXX")"
trap 'rm -f -- "$deleted_files"' EXIT

if ! find "$target_directory" -type f -name "*$pattern*" -print -delete > "$deleted_files"; then
  echo "Error: Failed to delete files matching pattern '$pattern' in '$display_target_directory'." >&2
  exit 1
fi

if [[ -s $deleted_files ]]; then
  echo "Files matching pattern '$pattern' deleted in $display_target_directory."
else
  echo "No files found matching pattern '$pattern' in '$display_target_directory'."
fi

echo "Script completed for pattern $pattern in $display_target_directory"

exit 0
