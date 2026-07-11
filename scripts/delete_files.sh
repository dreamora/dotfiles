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

# Sanitize before validating the directory so both the check and find use the same safe path.
# If it starts with a dash, prefix it with ./
[[ "$target_directory" == -* ]] && target_directory="./$target_directory"

# Check if the target directory exists
if [ ! -d "$target_directory" ]; then
    echo "Error: Target directory '$target_directory' does not exist."
    exit 1
fi

# Find and delete files matching the pattern
# We don't need a loop here unless we expect files to be recreated immediately,
# but even then, it's better to let a scheduler handle it or use a more controlled loop.
# The previous loop was infinite because 'find' returns 0 (success) even if it finds nothing.

if find "$target_directory" -type f -name "*$pattern*" -print -delete | grep -q .; then
    echo "Files matching pattern '$pattern' deleted in $target_directory."
else
    echo "No files found matching pattern '$pattern' in '$target_directory'."
fi

echo "Script completed for pattern $pattern in $target_directory"

exit 0
