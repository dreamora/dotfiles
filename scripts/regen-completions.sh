#!/usr/bin/env bash
# Regenerate static zsh completions for tools whose completion output would
# otherwise cost a subshell on every startup. Run after upgrading these tools.

set -euo pipefail

COMPDIR="$HOME/.zsh/completions"
mkdir -p "$COMPDIR"

regen() {
  local name="$1"
  local command_name target tmp status

  shift
  command_name="$1"
  target="$COMPDIR/_$name"

  if command -v "$command_name" >/dev/null 2>&1; then
    tmp="$(mktemp "$target.tmp.XXXXXX")"
    if "$@" >"$tmp"; then
      mv "$tmp" "$target"
      echo "OK: _$name"
    else
      status=$?
      rm -f "$tmp"
      echo "ERROR: failed to regenerate _$name" >&2
      return "$status"
    fi
  else
    echo "skip: $command_name not installed"
  fi
}

regen jj jj util completion zsh
regen kubectl kubectl completion zsh

# Force compinit to rebuild its dump on next shell start
rm -f "${ZDOTDIR:-$HOME}/.zcompdump"

echo "Done. Restart your shell (or run 'exec zsh')."
