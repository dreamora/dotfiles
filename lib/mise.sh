#!/usr/bin/env bash

###
# mise runtime provisioner: runs `mise install` to provision runtimes from .tool-versions.
# Runtimes: node v24.15.0, bun 1.3, java openjdk-17.0.2 (from homedir/.tool-versions)
# Source: https://github.com/jdx/mise
###

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/utils.sh"

# ============================================================================
# setup_mise_tools — Provision runtimes via mise install
# ============================================================================

setup_mise_tools() {
  log_step "Setting up mise runtimes (.tool-versions)"

  if is_dry_run; then
    log_info "[dry-run] Would run: mise install"
    log_info "[dry-run] Would run: mise exec node@22 -- npm config set save-exact true"
    return 0
  fi

  require_command mise "brew install mise"

  log_info "Running mise install..."
  if ! mise install; then
    die "mise install failed"
  fi

  log_info "Activating mise in current shell..."
  if ! eval "$(mise activate bash)"; then
    die "mise activate failed"
  fi

  log_info "Pinning npm save-exact=true..."
  mise exec node@22 -- npm config set save-exact true || log_info "npm config set save-exact failed (non-fatal — node may not be provisioned yet)"

  log_success "mise runtimes provisioned"
}
