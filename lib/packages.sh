#!/usr/bin/env bash

###
# Package installer: parses YAML manifest and installs packages
# via brew (formula/cask), mas, npm, gem on macOS; apt/pacman on Linux.
# @author Sisyphus
###

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/utils.sh"

# ============================================================================
# INTERNAL STATE
# ============================================================================

_PKG_INSTALLED=0
_PKG_SKIPPED=0
_PKG_FAILED=0

# Default packages.yaml location (overridable via second arg to install_packages)
_PACKAGES_YAML="${DOTFILES_DIR}/packages.yaml"

_ADDED_TAPS=""

# Caches for slow list commands (mas/npm/gem); populated lazily on first check.
# Brew formula/cask checks use individual brew list calls (fast, no pipe issues).
_MAS_CACHE=""
_NPM_CACHE=""
_GEM_CACHE=""
_MAS_CACHE_LOADED=0
_NPM_CACHE_LOADED=0
_GEM_CACHE_LOADED=0

# ============================================================================
# INSTALLED-PACKAGE CHECKERS
# ============================================================================

# Check if a MAS app is installed (caches mas list across calls)
_mas_installed() {
  local pkg_id="$1"
  if [[ "$_MAS_CACHE_LOADED" -eq 0 ]]; then
    _MAS_CACHE=$(mas list)
    _MAS_CACHE_LOADED=1
  fi
  # Inline bash match avoids pipe/SIGPIPE issues with set -o pipefail
  [[ $'\n'"${_MAS_CACHE}"$'\n' == *$'\n'"${pkg_id} "* ]]
}

# Check if a global npm package is installed (caches npm list across calls)
_npm_installed() {
  local name="$1"
  if [[ "$_NPM_CACHE_LOADED" -eq 0 ]]; then
    _NPM_CACHE=$(npm list -g --depth 0)
    _NPM_CACHE_LOADED=1
  fi
  [[ "${_NPM_CACHE}" == *"${name}@"* ]]
}

# Check if a gem is installed (caches gem list across calls)
_gem_installed() {
  local name="$1"
  if [[ "$_GEM_CACHE_LOADED" -eq 0 ]]; then
    _GEM_CACHE=$(gem list --local)
    _GEM_CACHE_LOADED=1
  fi
  [[ $'\n'"${_GEM_CACHE}"$'\n' == *$'\n'"${name} "* ]]
}

# Reset all caches (call after a successful install so next check is fresh)
_invalidate_caches() {
  _MAS_CACHE=""
  _NPM_CACHE=""
  _GEM_CACHE=""
  _MAS_CACHE_LOADED=0
  _NPM_CACHE_LOADED=0
  _GEM_CACHE_LOADED=0
}

# ============================================================================
# TAP MANAGEMENT
# ============================================================================

# Ensure a Homebrew tap is added (idempotent, deduped across the run)
_ensure_tap() {
  local tap="$1"

  [[ -z "$tap" ]] && return 0

  [[ $'\n'"${_ADDED_TAPS}"$'\n' == *$'\n'"${tap}"$'\n'* ]] && return 0
  _ADDED_TAPS="${_ADDED_TAPS}"$'\n'"${tap}"

  if ! command -v brew >/dev/null 2>&1; then
    log_warn "  brew not found; cannot add tap: $tap"
    return 0
  fi

  if brew tap | grep -qF "$tap"; then
    log_info "  [skip] tap: $tap (already added)"
    return 0
  fi

  if is_dry_run; then
    log_info "  [DRY-RUN] brew tap $tap"
    return 0
  fi

  log_info "  [tap] brew tap $tap"
  if brew tap "$tap"; then
    log_success "  Tap added: $tap"
  else
    log_warn "  Failed to add tap: $tap"
  fi
}

# ============================================================================
# PLATFORM INSTALL HELPERS
# ============================================================================

_install_via_brew() {
  local name="$1"
  local options="${2:-}"

  if brew list --formula "$name" >/dev/null 2>&1; then
    log_info "  [skip] brew: $name"
    _PKG_SKIPPED=$(( _PKG_SKIPPED + 1 ))
    return 0
  fi

  if is_dry_run; then
    log_info "  [DRY-RUN] brew install $name"
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
    return 0
  fi

  log_info "  [install] brew install $name"
  if brew install "$name"; then
    if [[ "$options" == *"link: false"* ]]; then
      brew unlink "$name" >/dev/null 2>&1 || true
    fi
    if [[ "$options" == *"restart_service: :changed"* ]]; then
      brew services restart "$name" || log_warn "  Failed to restart service: $name"
    fi
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
  else
    log_error "  [fail] brew install $name"
    _PKG_FAILED=$(( _PKG_FAILED + 1 ))
  fi
}

_install_via_cask() {
  local name="$1"

  if brew list --cask "$name" >/dev/null 2>&1; then
    log_info "  [skip] cask: $name"
    _PKG_SKIPPED=$(( _PKG_SKIPPED + 1 ))
    return 0
  fi

  if is_dry_run; then
    log_info "  [DRY-RUN] brew install --cask $name"
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
    return 0
  fi

  log_info "  [install] brew install --cask $name"
  if brew install --cask "$name"; then
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
  else
    log_error "  [fail] brew install --cask $name"
    _PKG_FAILED=$(( _PKG_FAILED + 1 ))
  fi
}

_install_via_mas() {
  local name="$1"
  local pkg_id="$2"

  if [[ -z "$pkg_id" ]]; then
    log_error "  [fail] mas: $name — missing id field"
    _PKG_FAILED=$(( _PKG_FAILED + 1 ))
    return 0
  fi

  if _mas_installed "$pkg_id"; then
    log_info "  [skip] mas: $name ($pkg_id)"
    _PKG_SKIPPED=$(( _PKG_SKIPPED + 1 ))
    return 0
  fi

  if is_dry_run; then
    log_info "  [DRY-RUN] mas install $pkg_id  # $name"
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
    return 0
  fi

  log_info "  [install] mas install $pkg_id  # $name"
  if mas install "$pkg_id"; then
    _invalidate_caches
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
  else
    log_error "  [fail] mas install $pkg_id ($name)"
    _PKG_FAILED=$(( _PKG_FAILED + 1 ))
  fi
}

_install_via_npm() {
  local name="$1"

  if _npm_installed "$name"; then
    log_info "  [skip] npm: $name"
    _PKG_SKIPPED=$(( _PKG_SKIPPED + 1 ))
    return 0
  fi

  if is_dry_run; then
    log_info "  [DRY-RUN] npm install -g $name"
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
    return 0
  fi

  log_info "  [install] npm install -g $name"
  if npm install -g "$name"; then
    _invalidate_caches
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
  else
    log_error "  [fail] npm install -g $name"
    _PKG_FAILED=$(( _PKG_FAILED + 1 ))
  fi
}

_install_via_gem() {
  local name="$1"

  if _gem_installed "$name"; then
    log_info "  [skip] gem: $name"
    _PKG_SKIPPED=$(( _PKG_SKIPPED + 1 ))
    return 0
  fi

  if is_dry_run; then
    log_info "  [DRY-RUN] gem install $name"
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
    return 0
  fi

  log_info "  [install] gem install $name"
  if gem install "$name"; then
    _invalidate_caches
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
  else
    log_error "  [fail] gem install $name"
    _PKG_FAILED=$(( _PKG_FAILED + 1 ))
  fi
}

_install_via_apt() {
  local name="$1"

  if dpkg -s "$name" >/dev/null 2>&1; then
    log_info "  [skip] apt: $name"
    _PKG_SKIPPED=$(( _PKG_SKIPPED + 1 ))
    return 0
  fi

  if is_dry_run; then
    log_info "  [DRY-RUN] sudo apt-get install -y $name"
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
    return 0
  fi

  log_info "  [install] sudo apt-get install -y $name"
  if sudo apt-get install -y "$name"; then
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
  else
    log_error "  [fail] apt-get install -y $name"
    _PKG_FAILED=$(( _PKG_FAILED + 1 ))
  fi
}

_install_via_pacman() {
  local name="$1"

  if pacman -Q "$name" >/dev/null 2>&1; then
    log_info "  [skip] pacman: $name"
    _PKG_SKIPPED=$(( _PKG_SKIPPED + 1 ))
    return 0
  fi

  if is_dry_run; then
    log_info "  [DRY-RUN] sudo pacman -S --noconfirm $name"
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
    return 0
  fi

  log_info "  [install] sudo pacman -S --noconfirm $name"
  if sudo pacman -S --noconfirm "$name"; then
    _PKG_INSTALLED=$(( _PKG_INSTALLED + 1 ))
  else
    log_error "  [fail] pacman -S --noconfirm $name"
    _PKG_FAILED=$(( _PKG_FAILED + 1 ))
  fi
}

# ============================================================================
# PACKAGE DISPATCHER
# ============================================================================

# Route a package to the correct install helper based on method
_dispatch_install() {
  local name="$1"
  local method="$2"
  local options="${3:-}"
  local pkg_id="${4:-}"

  case "$method" in
    brew)    _install_via_brew   "$name" "$options" ;;
    cask)    _install_via_cask   "$name"            ;;
    mas)     _install_via_mas    "$name" "$pkg_id"  ;;
    npm)     _install_via_npm    "$name"            ;;
    gem)     _install_via_gem    "$name"            ;;
    apt)     _install_via_apt    "$name"            ;;
    pacman)  _install_via_pacman "$name"            ;;
    *)
      log_warn "  Unknown method '$method' for package '$name' — skipping"
      _PKG_SKIPPED=$(( _PKG_SKIPPED + 1 ))
      ;;
  esac
}

# ============================================================================
# CATEGORY DEFAULTS
# ============================================================================

# Return default install method for a given category
_default_method_for_category() {
  local category="$1"
  case "$category" in
    cli)    echo "brew" ;;
    gui)    echo "cask" ;;
    fonts)  echo "cask" ;;
    mas)    echo "mas"  ;;
    npm)    echo "npm"  ;;
    gem)    echo "gem"  ;;
    *)      echo "brew" ;;
  esac
}

# ============================================================================
# ROLE PROCESSING — PHASE 1: TAPS
# ============================================================================

# Scan a single category for tap fields and ensure they are added
_process_category_taps() {
  local role="$1"
  local category="$2"
  local packages_yaml="$3"

  local count
  count=$(yq e ".roles.${role}.${category} | length" "$packages_yaml")
  [[ "$count" =~ ^[0-9]+$ && "$count" -gt 0 ]] || return 0

  local tap
  while IFS= read -r tap; do
    [[ -z "$tap" || "$tap" == "null" ]] && continue
    _ensure_tap "$tap"
  done < <(yq e ".roles.${role}.${category}[] | select(.tap != null) | .tap" "$packages_yaml")
}

# Scan all categories in a role for taps and ensure they are added
_process_role_taps() {
  local role="$1"
  local packages_yaml="$2"
  local categories=("cli" "gui" "fonts" "mas" "npm" "gem")

  for category in "${categories[@]}"; do
    _process_category_taps "$role" "$category" "$packages_yaml"
  done
}

# ============================================================================
# ROLE PROCESSING — PHASE 2: PACKAGES
# ============================================================================

# Install all packages in a single role category.
# Batches all package field reads into one yq call per category.
# Output format per line: name|method|os|options|id|tap (pipe-delimited)
_process_category_packages() {
  local role="$1"
  local category="$2"
  local packages_yaml="$3"
  local default_method="$4"

  local count
  count=$(yq e ".roles.${role}.${category} | length" "$packages_yaml")
  [[ "$count" =~ ^[0-9]+$ && "$count" -gt 0 ]] || return 0

  log_info "  Category: $category"

  local name method os_filter options pkg_id tap
  while IFS='|' read -r name method os_filter options pkg_id tap; do
    [[ -z "$name" || "$name" == "null" ]] && continue

    [[ "$method"    == "null" ]] && method=""
    [[ "$os_filter" == "null" ]] && os_filter=""
    [[ "$options"   == "null" ]] && options=""
    [[ "$pkg_id"    == "null" ]] && pkg_id=""
    [[ "$tap"       == "null" ]] && tap=""

    [[ -z "$method" ]] && method="$default_method"

    if [[ -n "$os_filter" && "$os_filter" != "$DOTFILES_OS" ]]; then
      continue
    fi

    _dispatch_install "$name" "$method" "$options" "$pkg_id"
  done < <(yq e ".roles.${role}.${category}[] | [.name // \"\", .method // \"\", .os // \"\", .options // \"\", ((.id // \"\") | tostring), .tap // \"\"] | join(\"|\")" "$packages_yaml")
}

# Install all packages in a role across all categories
_process_role_packages() {
  local role="$1"
  local packages_yaml="$2"
  local categories=("cli" "gui" "fonts" "mas" "npm" "gem")

  log_step "Role: $role"

  for category in "${categories[@]}"; do
    local default_method
    default_method=$(_default_method_for_category "$category")
    _process_category_packages "$role" "$category" "$packages_yaml" "$default_method"
  done
}

# ============================================================================
# SUMMARY
# ============================================================================

_print_packages_summary() {
  echo ""
  log_step "Package installation summary"
  log_success "  Installed : $_PKG_INSTALLED"
  log_info    "  Skipped   : $_PKG_SKIPPED"
  if [[ "$_PKG_FAILED" -gt 0 ]]; then
    log_error "  Failed    : $_PKG_FAILED"
  else
    log_success "  Failed    : 0"
  fi
}

# ============================================================================
# PUBLIC API
# ============================================================================

# Install packages for a machine profile.
#
# Usage:
#   install_packages <profile_yaml_path> [packages_yaml_path]
#
# Environment:
#   DOTFILES_DRY_RUN=1  — log actions, install nothing
#   DOTFILES_ROLES=...  — space-separated role override (skips profile parse)
#
install_packages() {
  local profile_yaml="${1:-}"
  local packages_yaml="${2:-${_PACKAGES_YAML}}"

  if [[ -z "$profile_yaml" ]]; then
    die "install_packages: profile YAML path is required"
  fi
  if [[ ! -f "$profile_yaml" ]]; then
    die "install_packages: profile not found: $profile_yaml"
  fi
  if [[ ! -f "$packages_yaml" ]]; then
    die "install_packages: packages.yaml not found: $packages_yaml"
  fi

  require_command yq "brew install yq"

  if [[ -z "${DOTFILES_OS:-}" ]]; then
    detect_os
  fi

  local roles_str
  if [[ -n "${DOTFILES_ROLES:-}" ]]; then
    roles_str="${DOTFILES_ROLES// /$'\n'}"
    log_info "Using roles from DOTFILES_ROLES: $DOTFILES_ROLES"
  else
    roles_str=$(yq e '.roles[]' "$profile_yaml")
  fi

  if [[ -z "$roles_str" ]]; then
    die "install_packages: no roles found in $profile_yaml"
  fi

  _PKG_INSTALLED=0
  _PKG_SKIPPED=0
  _PKG_FAILED=0
  _ADDED_TAPS=""
  _invalidate_caches

  log_step "Installing packages (OS: ${DOTFILES_OS})"

  log_step "Registering Homebrew taps..."
  while IFS= read -r role; do
    [[ -z "$role" ]] && continue
    _process_role_taps "$role" "$packages_yaml"
  done <<< "$roles_str"

  while IFS= read -r role; do
    [[ -z "$role" ]] && continue
    _process_role_packages "$role" "$packages_yaml"
  done <<< "$roles_str"

  _print_packages_summary

  if [[ "$_PKG_FAILED" -gt 0 ]]; then
    return 1
  fi

  return 0
}

# ============================================================================
# GUARD: Do not execute any code when sourced
# ============================================================================
# This file only defines functions. No code executes on source.
