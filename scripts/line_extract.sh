#!/usr/bin/env bash

# Usage: ./extract-matching-lines.sh PATTERN FILE
# Example: ./extract-matching-lines.sh '^ERROR' /var/log/system.log

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 PATTERN FILE"
  exit 1
fi

pattern="$1"
file="$2"

if [[ ! -f "$file" ]]; then
  echo "Error: File '$file' does not exist."
  exit 2
fi

# Extract lines matching the regex pattern
grep -E -e "$pattern" -- "$file"
