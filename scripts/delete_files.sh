#!/usr/bin/env bash

# Script to find and delete files matching a pattern in a target directory.

# Usage: ./delete_files.sh <pattern> <target_directory>

set -euo pipefail

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <pattern> <target_directory>"
    exit 1
fi

# Assign arguments to variables
pattern="$1"
target_directory="$2"

# Check if the target directory exists
if [ ! -d "$target_directory" ]; then
    echo "Error: Target directory '$target_directory' does not exist."
    exit 1
fi

# Path sanitization: ensure target_directory doesn't start with a dash
# to prevent find from interpreting it as an option.
if [[ "$target_directory" == -* ]]; then
  target_directory="./$target_directory"
fi

# Find and delete files matching the pattern
# Defensive coding: quote variables
if find "$target_directory" -type f -name "*$pattern*" -print -delete | grep -q .; then
    echo "Files matching pattern '$pattern' deleted in $target_directory."
else
    echo "No files found matching pattern '$pattern' in '$target_directory'."
fi

echo "Script completed for pattern $pattern in $target_directory"

exit 0
