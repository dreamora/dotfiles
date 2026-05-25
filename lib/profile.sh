#!/usr/bin/env bash

###
# Machine profile selection and state management.
# Handles: profile selection (interactive first run), YAML parsing,
# hostname application, and git config setup.
# @author Sisyphus
###

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/utils.sh"

# ============================================================================
# CONSTANTS
# ============================================================================

DOTFILES_PROFILE_STATE="$HOME/.dotfiles_profile"

# ============================================================================
# select_profile()
# ============================================================================
# On first run: list machines/*.yaml numerically, prompt user to choose,
# save chosen path to state file, echo the chosen path.
# On subsequent runs: read state file, validate the path still exists, echo it.
#
# Usage:
#   profile_path="$(select_profile)"
# ============================================================================
select_profile() {
  # If state file exists and the stored profile path is still valid, use it
  if [[ -f "$DOTFILES_PROFILE_STATE" ]]; then
    local stored_path
    stored_path="$(cat "$DOTFILES_PROFILE_STATE")"
    if [[ -n "$stored_path" && -f "$stored_path" ]]; then
      log_info "Using saved profile: $stored_path"
      echo "$stored_path"
      return 0
    else
      log_warn "Saved profile path no longer exists: $stored_path — re-selecting"
    fi
  fi

  # Gather available profiles
  local profiles=()
  while IFS= read -r -d '' yaml_file; do
    profiles+=("$yaml_file")
  done < <(find "$DOTFILES_DIR/machines" -maxdepth 1 -name '*.yaml' -print0 | sort -z)

  if [[ ${#profiles[@]} -eq 0 ]]; then
    die "No machine profiles found in $DOTFILES_DIR/machines/"
  fi

  log_step "Select a machine profile"
  local i=1
  for profile in "${profiles[@]}"; do
    echo "  [$i] $(basename "$profile")"
    (( i++ )) || true
  done

  local choice
  read -r -p "Select profile [1-${#profiles[@]}]: " choice

  # Validate input
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#profiles[@]} )); then
    die "Invalid selection: $choice"
  fi

  local chosen_path="${profiles[$((choice - 1))]}"

  # Save to state file
  echo "$chosen_path" > "$DOTFILES_PROFILE_STATE"
  log_info "Profile saved to $DOTFILES_PROFILE_STATE"

  echo "$chosen_path"
}

# ============================================================================
# load_profile(profile_path)
# ============================================================================
# Parse a machines/*.yaml file with yq and export dotfiles variables.
# Exports:
#   DOTFILES_HOSTNAME     — .hostname
#   DOTFILES_GIT_NAME     — .git.name
#   DOTFILES_GIT_EMAIL    — .git.email
#   DOTFILES_ROLES        — .roles[] joined as space-separated string
#   DOTFILES_SHELL_THEME  — .shell.theme (optional, defaults to "")
#
# Usage:
#   load_profile "machines/personal-mac.yaml"
# ============================================================================
load_profile() {
  local profile_path="$1"

  if [[ -z "$profile_path" ]]; then
    die "load_profile: no profile path provided"
  fi

  if [[ ! -f "$profile_path" ]]; then
    die "load_profile: profile file not found: $profile_path"
  fi

  require_command yq "brew install yq"

  log_step "Loading profile: $profile_path"

  # SC2155: declare and assign separately to preserve exit codes
  local hostname
  hostname="$(yq e '.hostname' "$profile_path")" || die "Failed to parse .hostname from $profile_path"

  local git_name
  git_name="$(yq e '.git.name' "$profile_path")" || die "Failed to parse .git.name from $profile_path"

  local git_email
  git_email="$(yq e '.git.email' "$profile_path")" || die "Failed to parse .git.email from $profile_path"

  local roles
  roles="$(yq e '.roles | join(" ")' "$profile_path")" || die "Failed to parse .roles from $profile_path"

  local shell_theme
  shell_theme="$(yq e '.shell.theme // ""' "$profile_path")" || shell_theme=""

  # Validate required fields
  if [[ -z "$hostname" || "$hostname" == "null" ]]; then
    die "Profile $profile_path: .hostname is empty or null"
  fi
  if [[ -z "$git_name" || "$git_name" == "null" ]]; then
    die "Profile $profile_path: .git.name is empty or null"
  fi
  if [[ -z "$git_email" || "$git_email" == "null" ]]; then
    die "Profile $profile_path: .git.email is empty or null"
  fi
  if [[ -z "$roles" || "$roles" == "null" ]]; then
    die "Profile $profile_path: .roles is empty or null"
  fi

  # Normalize "null" from yq optional field
  if [[ "$shell_theme" == "null" ]]; then
    shell_theme=""
  fi

  # Export all variables
  DOTFILES_HOSTNAME="$hostname"
  DOTFILES_GIT_NAME="$git_name"
  DOTFILES_GIT_EMAIL="$git_email"
  DOTFILES_ROLES="$roles"
  DOTFILES_SHELL_THEME="$shell_theme"

  export DOTFILES_HOSTNAME
  export DOTFILES_GIT_NAME
  export DOTFILES_GIT_EMAIL
  export DOTFILES_ROLES
  export DOTFILES_SHELL_THEME

  log_info "Hostname:    $DOTFILES_HOSTNAME"
  log_info "Git name:    $DOTFILES_GIT_NAME"
  log_info "Git email:   $DOTFILES_GIT_EMAIL"
  log_info "Roles:       $DOTFILES_ROLES"
  if [[ -n "$DOTFILES_SHELL_THEME" ]]; then
    log_info "Shell theme: $DOTFILES_SHELL_THEME"
  fi
}

# ============================================================================
# apply_hostname()
# ============================================================================
# Set the machine hostname using DOTFILES_HOSTNAME.
# macOS: uses scutil (ComputerName, HostName, LocalHostName)
# Linux: uses hostnamectl
# Idempotent: skips if hostname is already set correctly.
#
# Usage:
#   apply_hostname
# ============================================================================
apply_hostname() {
  if [[ -z "${DOTFILES_HOSTNAME:-}" ]]; then
    die "apply_hostname: DOTFILES_HOSTNAME is not set — call load_profile first"
  fi

  log_step "Applying hostname: $DOTFILES_HOSTNAME"

  detect_os

  if [[ "$DOTFILES_OS" == "darwin" ]]; then
    _apply_hostname_macos
  elif [[ "$DOTFILES_OS" == "linux" ]]; then
    _apply_hostname_linux
  else
    die "apply_hostname: unsupported OS: $DOTFILES_OS"
  fi
}

# Internal: apply hostname on macOS via scutil
_apply_hostname_macos() {
  local current_computer_name
  current_computer_name="$(scutil --get ComputerName 2>/dev/null || echo "")"

  local current_hostname
  current_hostname="$(scutil --get HostName 2>/dev/null || echo "")"

  local current_local_hostname
  current_local_hostname="$(scutil --get LocalHostName 2>/dev/null || echo "")"

  if [[ "$current_computer_name" == "$DOTFILES_HOSTNAME" && \
        "$current_hostname" == "$DOTFILES_HOSTNAME" && \
        "$current_local_hostname" == "$DOTFILES_HOSTNAME" ]]; then
    log_info "Hostname already set to $DOTFILES_HOSTNAME — skipping"
    return 0
  fi

  log_info "Setting macOS hostnames to: $DOTFILES_HOSTNAME"
  sudo scutil --set ComputerName  "$DOTFILES_HOSTNAME"
  sudo scutil --set HostName      "$DOTFILES_HOSTNAME"
  sudo scutil --set LocalHostName "$DOTFILES_HOSTNAME"
  log_success "Hostname set to $DOTFILES_HOSTNAME"
}

# Internal: apply hostname on Linux via hostnamectl
_apply_hostname_linux() {
  local current_hostname
  current_hostname="$(hostname 2>/dev/null || echo "")"

  if [[ "$current_hostname" == "$DOTFILES_HOSTNAME" ]]; then
    log_info "Hostname already set to $DOTFILES_HOSTNAME — skipping"
    return 0
  fi

  log_info "Setting Linux hostname to: $DOTFILES_HOSTNAME"
  sudo hostnamectl set-hostname "$DOTFILES_HOSTNAME"
  log_success "Hostname set to $DOTFILES_HOSTNAME"
}

# ============================================================================
# apply_git_config()
# ============================================================================
# Set git global user.name and user.email from loaded profile variables.
# Requires load_profile to have been called first.
#
# Usage:
#   apply_git_config
# ============================================================================
apply_git_config() {
  if [[ -z "${DOTFILES_GIT_NAME:-}" || -z "${DOTFILES_GIT_EMAIL:-}" ]]; then
    die "apply_git_config: DOTFILES_GIT_NAME or DOTFILES_GIT_EMAIL is not set — call load_profile first"
  fi

  require_command git "brew install git"

  log_step "Applying git global config"
  log_info "Setting git user.name:  $DOTFILES_GIT_NAME"
  git config --global user.name  "$DOTFILES_GIT_NAME"

  log_info "Setting git user.email: $DOTFILES_GIT_EMAIL"
  git config --global user.email "$DOTFILES_GIT_EMAIL"

  log_success "Git config applied"
}

# ============================================================================
# GUARD: Do not execute any code when sourced
# ============================================================================
# This file only defines functions and constants. No code executes on source.
