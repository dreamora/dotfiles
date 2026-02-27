#!/usr/bin/env bash

set -euo pipefail
source "$(cd "$(dirname "$0")" && pwd)/helpers.sh"

if ! require_cmd tuckr; then
  exit 2
fi

ROOT="$(repo_root)"
FAILED=0

TUCKR_GROUPS=(zsh git vim neovim tmux screen ruby node asdf crontab)
for group in "${TUCKR_GROUPS[@]}"; do
  out="$(cd "$ROOT" && tuckr status "$group" 2>&1 || true)"
  if echo "$out" | grep -q "Symlinked:"; then
    pass "tuckr status reports symlinked group: $group"
  else
    fail "tuckr group not symlinked: $group" || true
    info "$out"
    FAILED=1
  fi
done

declare -A EXPECTED_TARGETS
EXPECTED_TARGETS["$HOME/.zshrc"]="$ROOT/Configs/zsh/.zshrc"
EXPECTED_TARGETS["$HOME/.gitconfig"]="$ROOT/Configs/git/.gitconfig"
EXPECTED_TARGETS["$HOME/.vimrc"]="$ROOT/Configs/vim/.vimrc"
EXPECTED_TARGETS["$HOME/.tmux.conf"]="$ROOT/Configs/tmux/.tmux.conf"
EXPECTED_TARGETS["$HOME/.screenrc"]="$ROOT/Configs/screen/.screenrc"
EXPECTED_TARGETS["$HOME/.gemrc"]="$ROOT/Configs/ruby/.gemrc"
EXPECTED_TARGETS["$HOME/.nvmrc"]="$ROOT/Configs/node/.nvmrc"
EXPECTED_TARGETS["$HOME/.asdfrc"]="$ROOT/Configs/asdf/.asdfrc"
EXPECTED_TARGETS["$HOME/.crontab"]="$ROOT/Configs/crontab/.crontab"
EXPECTED_TARGETS["$HOME/.config/nvim"]="$ROOT/Configs/neovim/.config/nvim"

for link in "${!EXPECTED_TARGETS[@]}"; do
  expected="${EXPECTED_TARGETS[$link]}"
  if [[ ! -L "$link" ]]; then
    fail "expected symlink missing: $link" || true
    FAILED=1
    continue
  fi

  actual="$(readlink "$link")"
  if [[ "$actual" == "$expected" ]]; then
    pass "symlink target ok: $link"
  else
    fail "symlink target mismatch for $link (got: $actual, expected: $expected)" || true
    FAILED=1
  fi
done

if command -v zsh >/dev/null 2>&1; then
  if zsh -lc 'source ~/.zshrc' >/dev/null 2>&1; then
    pass "zsh source smoke test passed"
  else
    fail "zsh source smoke test failed" || true
    FAILED=1
  fi
fi

if command -v nvim >/dev/null 2>&1; then
  if nvim --headless '+q' >/dev/null 2>&1; then
    pass "nvim headless smoke test passed"
  else
    fail "nvim headless smoke test failed" || true
    FAILED=1
  fi
fi

exit $FAILED
