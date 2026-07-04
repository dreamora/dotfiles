#!/usr/bin/env bash

# Usage: ./extract-matching-lines.sh PATTERN FILE
# Example: ./extract-matching-lines.sh '^ERROR' /var/log/system.log

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

# Extract lines matching the regex pattern
# Defensive coding: use -- to prevent option injection
grep -E -- "$PATTERN" "$FILE"
