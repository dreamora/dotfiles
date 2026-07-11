#!/usr/bin/env bash

# Usage: ./line_extract.sh PATTERN FILE
# Example: ./line_extract.sh '^ERROR' /var/log/system.log

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 PATTERN FILE"
  exit 1
fi

PATTERN="$1"
FILE="$2"

if [[ ! -f "$FILE" ]]; then
  echo "Error: File '$FILE' does not exist."
  exit 2
fi

# Extract lines matching the regex pattern.
# Use -e and -- to prevent option injection from PATTERN or FILE.
grep -E -e "$PATTERN" -- "$FILE"
