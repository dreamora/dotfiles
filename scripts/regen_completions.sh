#!/usr/bin/env bash
# Regenerate static zsh completions for tools whose completion output would
# otherwise cost a subshell on every startup. Run after upgrading these tools.

set -euo pipefail

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/../lib_sh/echos.sh"

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
      ok "Regenerated _$name"
    else
      status=$?
      rm -f "$tmp"
      error "Failed to regenerate _$name" >&2
      return "$status"
    fi
  else
    warn "$command_name not installed; skipping _$name"
  fi
}

regen jj jj util completion zsh
regen kubectl kubectl completion zsh

# Force compinit to rebuild its dump on next shell start
rm -f "${ZDOTDIR:-$HOME}/.zcompdump"

bot "Completions regenerated. Restart your shell (or run 'exec zsh')."
