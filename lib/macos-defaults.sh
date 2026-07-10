#!/usr/bin/env bash

###
# Orchestrator module for applying macOS system preferences
# Sources modular defaults files from macos/*.sh and applies them
# @author Sisyphus
###

set -euo pipefail

# Source utilities (this script is at lib/macos-defaults.sh)
# shellcheck source=./utils.sh
# shellcheck disable=SC1091
source "${BASH_SOURCE[0]%/*}/utils.sh"

# ============================================================================
# APPLY MACOS DEFAULTS
# ============================================================================

# Apply all macOS system preferences from modular defaults files
# - Guards on OS (darwin only)
# - Supports dry-run mode
# - Loads modules from macos/*.sh in alphabetical order
# - Gracefully handles missing modules (nullglob)
# - Continues on module failure (partial application is better than none)
apply_macos_defaults() {
  # OS guard: skip on non-macOS systems
  if [[ "${DOTFILES_OS:-}" != "darwin" ]]; then
    log_info "[skip] macOS defaults: not macOS (OS is ${DOTFILES_OS:-unknown})"
    return 0
  fi

  # Dry-run support: log what would run without executing
  if is_dry_run; then
    log_step "macOS defaults (dry-run mode)"
    log_info "Would apply macOS defaults from: $DOTFILES_DIR/macos/"
    return 0
  fi

  log_step "Applying macOS defaults"

  # Enable nullglob to handle empty directory gracefully
  shopt -s nullglob

  local modules_dir="$DOTFILES_DIR/macos"
  local module_files=("$modules_dir"/*.sh)
  local total_modules=${#module_files[@]}
  local applied=0
  local failed=0

  # If no modules exist, log and return
  if [[ $total_modules -eq 0 ]]; then
    log_info "No macOS defaults modules found in $modules_dir"
    shopt -u nullglob
    return 0
  fi

  # Process each module file in alphabetical order (glob naturally sorts)
  for module in "${module_files[@]}"; do
    local module_name
    module_name="$(basename "$module")"

    log_step "Applying macOS defaults: $module_name"

    # Source module in subshell to isolate failures
    # shellcheck disable=SC1090
    if ( source "$module" ); then
      applied=$(( applied + 1 ))
    else
      log_warn "macOS defaults module failed: $module_name (continuing)"
      failed=$(( failed + 1 ))
    fi
  done

  # Disable nullglob
  shopt -u nullglob

  # Summary
  log_success "macOS defaults: $applied/$total_modules modules applied, $failed failed"

  # Return 0 even if some modules failed (partial application is acceptable)
  return 0
}

# ============================================================================
# GUARD: Do not execute any code when sourced
# ============================================================================
# This file only defines functions. No code executes on source.
