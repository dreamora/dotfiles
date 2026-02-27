#!/usr/bin/env bash
# scripts/detect_role.sh — Detect machine role
# Priority: DOTFILES_ROLE env > ~/.dotfiles_role file > hostname heuristic > default
ROLE_FILE="${HOME}/.dotfiles_role"
if [ -n "${DOTFILES_ROLE:-}" ]; then
  echo "$DOTFILES_ROLE"
elif [ -f "$ROLE_FILE" ]; then
  cat "$ROLE_FILE"
else
  hostname=$(hostname -s 2>/dev/null || hostname)
  case "$hostname" in
    *-work|*work*|corp-*|mbp-*) echo "work" ;;
    *shared*|*lab*|server*) echo "shared" ;;
    *) echo "personal" ;;
  esac
fi
