#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

errors=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  errors=$((errors + 1))
}

ok() {
  printf 'OK: %s\n' "$1"
}

require_dir() {
  local dir="$1"

  if [[ -d "$ROOT_DIR/$dir" ]]; then
    ok "$dir/ exists"
  else
    fail "$dir/ is missing"
  fi
}

require_install_contract() {
  local description="$1"
  local pattern="$2"

  if grep -Eq "$pattern" "$ROOT_DIR/install.sh"; then
    ok "$description"
  else
    fail "$description"
  fi
}

require_file_contains() {
  local description="$1"
  local file="$2"
  local pattern="$3"

  if grep -Eq "$pattern" "$ROOT_DIR/$file"; then
    ok "$description"
  else
    fail "$description"
  fi
}

validate_command_script() {
  local script="$1"
  local first_line

  if [[ ! -x "$script" ]]; then
    fail "${script#$ROOT_DIR/} is not executable"
    return
  fi

  IFS= read -r first_line < "$script" || first_line=""
  if [[ ! "$first_line" =~ ^#! ]]; then
    fail "${script#$ROOT_DIR/} is missing a shebang"
  else
    ok "${script#$ROOT_DIR/} has executable metadata"
  fi
}

require_dir "homedir"
require_dir "config"
require_dir "scripts"

require_install_contract "install.sh stows homedir/ into HOME" \
  'stow[[:space:]].*-d[[:space:]]+"\$DOTFILES_DIR"[[:space:]].*-t[[:space:]]+"\$HOME"[[:space:]]+homedir'
require_install_contract "install.sh creates HOME/.config before config stow" \
  'mkdir[[:space:]]+-p[[:space:]]+"\$HOME/\.config"'
require_install_contract "install.sh stows config/ into HOME/.config" \
  'stow[[:space:]].*-d[[:space:]]+"\$DOTFILES_DIR"[[:space:]].*-t[[:space:]]+"\$HOME/\.config"[[:space:]]+config'

require_install_contract "install.sh creates HOME/.local/bin before scripts stow" \
  'mkdir[[:space:]]+-p[[:space:]]+"\$HOME/\.local/bin"'
require_install_contract "install.sh targets HOME/.local/bin for scripts stow" \
  'stow[[:space:]].*-d[[:space:]]+"\$DOTFILES_DIR"[[:space:]].*-t[[:space:]]+"\$HOME/\.local/bin"'
require_install_contract "install.sh stows scripts/ package" \
  'scripts[[:space:]]*\|\|[[:space:]]*exit[[:space:]]+1'
require_file_contains "homedir/.shellpaths exposes HOME/.local/bin on PATH" \
  "homedir/.shellpaths" '\$HOME/\.local/bin'

while IFS= read -r script; do
  validate_command_script "$script"
done < <(find "$ROOT_DIR/scripts" -maxdepth 1 -type f -perm -111 | sort)

if [[ $errors -gt 0 ]]; then
  printf '\n%d folder contract check(s) failed.\n' "$errors" >&2
  exit 1
fi

printf '\nFolder contracts verified.\n'
