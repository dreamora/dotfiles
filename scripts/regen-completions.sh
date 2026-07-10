#!/usr/bin/env bash
# Regenerate static zsh completions for tools whose completion output would
# otherwise cost a subshell on every startup. Run after upgrading these tools.

set -euo pipefail

COMPDIR="$HOME/.zsh/completions"
mkdir -p "$COMPDIR"

regen() {
	local name="$1"
	shift
	if command -v "$1" >/dev/null 2>&1; then
		"$@" >"$COMPDIR/_$name"
		echo "OK: _$name"
	else
		echo "skip: $1 not installed"
	fi
}

regen jj jj util completion zsh
regen kubectl kubectl completion zsh

# Force compinit to rebuild its dump on next shell start
rm -f "$HOME/.zcompdump"

echo "Done. Restart your shell (or run 'exec zsh')."
