#!/usr/bin/env bash

###
# Antidote ZSH plugin manager wrapper
# Handles plugin bundle generation and updates for the dotfiles restructure
# @author Sisyphus
###

set -euo pipefail

# Source utilities
source "${BASH_SOURCE[0]%/*}/utils.sh"

# ============================================================================
# ANTIDOTE SETUP
# ============================================================================

# Setup antidote: verify installation and generate static plugin bundle
setup_antidote() {
  local antidote_path
  local plugins_txt
  local plugins_zsh

  # Determine antidote installation path based on OS
  if [[ "$DOTFILES_OS" == "darwin" ]]; then
    antidote_path="/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
  else
    antidote_path="$HOME/.antidote/antidote.zsh"
  fi

  # Verify antidote is installed
  if [[ ! -f "$antidote_path" ]]; then
    require_command antidote "brew install antidote (macOS) or see https://getantidote.github.io"
  fi

  # Set plugin list and output paths
  plugins_txt="${DOTFILES_DIR}/homedir-common/.zsh_plugins.txt"
  plugins_zsh="${HOME}/.zsh_plugins.zsh"

  # Verify plugin list exists
  if [[ ! -f "$plugins_txt" ]]; then
    die "Plugin list not found: $plugins_txt"
  fi

  # Generate static bundle
  if is_dry_run; then
    log_info "[DRY RUN] Would generate antidote bundle from $plugins_txt → $plugins_zsh"
  else
    log_info "Generating antidote plugin bundle from $plugins_txt"
    antidote bundle < "$plugins_txt" > "$plugins_zsh"
    log_success "Plugin bundle generated: $plugins_zsh"
  fi
}

# ============================================================================
# ANTIDOTE UPDATE
# ============================================================================

# Update all antidote plugins
update_antidote() {
  if is_dry_run; then
    log_info "[DRY RUN] Would run: antidote update"
  else
    log_info "Updating antidote plugins..."
    antidote update
    log_success "Antidote plugins updated"
  fi
}

# ============================================================================
# GUARD: Do not execute any code when sourced
# ============================================================================
# This file only defines functions. No code executes on source.
