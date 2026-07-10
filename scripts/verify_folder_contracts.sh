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

require_dir "homedir-common"
require_dir "homedir-darwin"
require_dir "homedir-linux"
require_dir "configs"
require_dir "configs-darwin"
require_dir "configs-linux"
require_dir "scripts"

require_file_contains "lib/stow.sh stows common homedir files into HOME" \
  "lib/stow.sh" 'stow_jobs\+=\("homedir-common\|\$\{HOME\}"\)'
require_file_contains "lib/stow.sh stows Darwin homedir files into HOME" \
  "lib/stow.sh" 'stow_jobs\+=\("homedir-darwin\|\$\{HOME\}"\)'
require_file_contains "lib/stow.sh stows Linux homedir files into HOME" \
  "lib/stow.sh" 'stow_jobs\+=\("homedir-linux\|\$\{HOME\}"\)'
require_file_contains "lib/stow.sh creates HOME/.config before config stow" \
  "lib/stow.sh" 'mkdir[[:space:]]+-p[[:space:]]+"\$\{HOME\}/\.config"'
require_file_contains "lib/stow.sh stows common config files into HOME/.config" \
  "lib/stow.sh" 'stow_jobs\+=\("configs\|\$\{HOME\}/\.config"\)'
require_file_contains "lib/stow.sh stows Darwin config files into HOME/.config" \
  "lib/stow.sh" 'stow_jobs\+=\("configs-darwin\|\$\{HOME\}/\.config"\)'
require_file_contains "lib/stow.sh stows Linux config files into HOME/.config" \
  "lib/stow.sh" 'stow_jobs\+=\("configs-linux\|\$\{HOME\}/\.config"\)'
require_file_contains "lib/stow.sh creates HOME/.local/bin before scripts stow" \
  "lib/stow.sh" 'mkdir[[:space:]]+-p[[:space:]]+"\$\{HOME\}/\.local/bin"'
require_file_contains "lib/stow.sh stows scripts into HOME/.local/bin" \
  "lib/stow.sh" 'stow_jobs\+=\("scripts\|\$\{HOME\}/\.local/bin"\)'
require_file_contains "install.sh delegates stow operations to lib/stow.sh" \
  "install.sh" 'apply_stow'
require_file_contains "homedir-common/.shellpaths exposes HOME/.local/bin on PATH" \
  "homedir-common/.shellpaths" '\$HOME/\.local/bin'

while IFS= read -r script; do
  validate_command_script "$script"
done < <(find "$ROOT_DIR/scripts" -maxdepth 1 -type f -perm -111 | sort)

if [[ $errors -gt 0 ]]; then
  printf '\n%d folder contract check(s) failed.\n' "$errors" >&2
  exit 1
fi

printf '\nFolder contracts verified.\n'
