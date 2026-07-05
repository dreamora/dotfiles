#!/usr/bin/env bash

# Script to find and delete files matching a pattern in a target directory.

# Usage: ./delete_files.sh <pattern> <target_directory>

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <pattern> <target_directory>"
  exit 1
fi

pattern="$1"
target_directory="$2"

if [[ ! -d "$target_directory" ]]; then
  echo "Error: Target directory '$target_directory' does not exist."
  exit 1
fi

# Prefix dash-leading relative paths so find cannot parse them as options.
[[ "$target_directory" == -* ]] && target_directory="./$target_directory"

# Find and delete files matching the pattern
if find "$target_directory" -type f -name "*$pattern*" -print -delete | grep -q .; then
  echo "Files matching pattern '$pattern' deleted in $target_directory."
else
  echo "No files found matching pattern '$pattern' in '$target_directory'."
fi

echo "Script completed for pattern $pattern in $target_directory"

exit 0
