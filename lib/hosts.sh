#!/usr/bin/env bash

###
# Hosts file management: refresh StevenBlack ad-blocking list and apply to /etc/hosts
# @author Sisyphus
###

set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/utils.sh"

# ============================================================================
# CONSTANTS
# ============================================================================

_HOSTS_SOURCE="${DOTFILES_DIR}/configs/hosts"
_HOSTS_DEST="/etc/hosts"
_HOSTS_BACKUP="${_HOSTS_DEST}.backup"
_HOSTS_UPSTREAM="https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"

# ============================================================================
# INTERNAL: _apply_hosts
# ============================================================================

# Backup /etc/hosts then copy configs/hosts → /etc/hosts
_apply_hosts() {
  if [[ ! -f "$_HOSTS_SOURCE" ]]; then
    die "Hosts source file not found: $_HOSTS_SOURCE"
  fi

  if is_dry_run; then
    log_info "[dry-run] Would backup ${_HOSTS_DEST} → ${_HOSTS_BACKUP}"
    log_info "[dry-run] Would copy ${_HOSTS_SOURCE} → ${_HOSTS_DEST}"
    return 0
  fi

  sudo cp "$_HOSTS_DEST" "$_HOSTS_BACKUP"
  sudo cp "$_HOSTS_SOURCE" "$_HOSTS_DEST"

  local domain_count
  domain_count="$(grep -c '^0\.0\.0\.0' "$_HOSTS_DEST")"
  log_success "Hosts file applied (${domain_count} blocked domains). Backup at ${_HOSTS_BACKUP}"
}

# ============================================================================
# refresh_hosts_file
# ============================================================================

# Download latest StevenBlack hosts list to configs/hosts
refresh_hosts_file() {
  require_command curl "brew install curl"

  if is_dry_run; then
    log_info "[dry-run] Would download ${_HOSTS_UPSTREAM} → ${_HOSTS_SOURCE}"
    return 0
  fi

  sudo curl -fsSL "$_HOSTS_UPSTREAM" -o "$_HOSTS_SOURCE" || die "curl failed to download hosts file from ${_HOSTS_UPSTREAM}"
}

# ============================================================================
# update_hosts
# ============================================================================

# Interactive entry point: prompts before each destructive step
update_hosts() {
  log_step "Hosts file management"

  if is_dry_run; then
    log_info "[dry-run] Would prompt to refresh ${_HOSTS_SOURCE} from upstream"
    log_info "[dry-run] Would prompt to apply ${_HOSTS_SOURCE} → ${_HOSTS_DEST}"
    return 0
  fi

  local response

  read -r -p "  Refresh hosts file from StevenBlack upstream? [y|N] " response
  if [[ "$response" =~ ^(yes|y|Y)$ ]]; then
    refresh_hosts_file
  fi

  read -r -p "  Apply ${_HOSTS_SOURCE} to ${_HOSTS_DEST}? [y|N] " response
  if [[ "$response" =~ ^(yes|y|Y)$ ]]; then
    _apply_hosts
  else
    log_info "[skip] Hosts file not applied"
  fi
}
