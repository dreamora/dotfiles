#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/utils.sh"
# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/bootstrap.sh"
# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/profile.sh"
# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/packages.sh"
# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/stow.sh"
# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/antidote.sh"
# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/macos-defaults.sh"
# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/hosts.sh"
# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/mise.sh"

usage() {
  cat <<USAGE
Usage: ./install.sh [options]

Options:
  -h, --help          Show this help message
      --dry-run       Print planned actions without installing or changing state
      --packages      Install packages without prompting
      --skip-packages Skip packages without prompting
      --defaults      Apply macOS defaults without prompting
      --skip-defaults Skip macOS defaults without prompting
      --skip-hosts    Skip /etc/hosts update
      --hostname      Set hostname without prompting
      --skip-hostname Skip hostname without prompting
      --skip-mise     Skip mise runtime provisioning
      --force-stow    Back up conflicting files and force stow
      --profile=NAME  Use machines/NAME.yaml, NAME, or a profile path
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      --dry-run)
        export DOTFILES_DRY_RUN=1
        ;;
      --packages)
        _WITH_PACKAGES=1
        ;;
      --skip-packages)
        _SKIP_PACKAGES=1
        ;;
      --defaults)
        _WITH_DEFAULTS=1
        ;;
      --skip-defaults)
        _SKIP_DEFAULTS=1
        ;;
      --skip-hosts)
        _SKIP_HOSTS=1
        ;;
      --hostname)
        _WITH_HOSTNAME=1
        ;;
      --skip-hostname)
        _SKIP_HOSTNAME=1
        ;;
      --skip-mise)
        _SKIP_MISE=1
        ;;
      --force-stow)
        _FORCE_STOW=1
        ;;
      --profile=*)
        DOTFILES_PROFILE_OVERRIDE="${1#*=}"
        export DOTFILES_PROFILE_OVERRIDE
        ;;
      --profile)
        shift
        [[ -n "${1:-}" ]] || die "--profile requires a value"
        DOTFILES_PROFILE_OVERRIDE="$1"
        export DOTFILES_PROFILE_OVERRIDE
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
    shift
  done
}

profile_from_override() {
  local profile="$1"
  local candidate

  for candidate in \
    "$profile" \
    "${DOTFILES_DIR}/${profile}" \
    "${DOTFILES_DIR}/machines/${profile}" \
    "${DOTFILES_DIR}/machines/${profile}.yaml"; do
    if [[ -f "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  die "Profile not found: $profile"
}

select_install_profile() {
  if [[ -n "${DOTFILES_PROFILE_OVERRIDE:-}" ]]; then
    profile_from_override "$DOTFILES_PROFILE_OVERRIDE"
    return 0
  fi
  select_profile
}

run_bootstrap() {
  if is_dry_run; then
    detect_os
    log_info "[dry-run] Would bootstrap minimal dependencies"
    return 0
  fi
  bootstrap_deps
}

dry_run_or() {
  local message="$1"
  shift
  if is_dry_run; then
    log_info "[dry-run] Would $message"
    return 0
  fi
  "$@"
}

parse_args "$@"

run_bootstrap

SELECTED_PROFILE="$(select_install_profile)"
load_profile "$SELECTED_PROFILE"

if ! is_dry_run; then
  prompt_and_patch_git_identity "$SELECTED_PROFILE"
fi

if [[ "${_FORCE_STOW:-0}" == "1" ]]; then
  apply_stow --force
else
  apply_stow
fi
dry_run_or "set up antidote" setup_antidote
dry_run_or "apply git config" apply_git_config

if [[ "${_SKIP_DEFAULTS:-0}" == "1" ]]; then
  log_info "[skip] macOS defaults disabled"
elif [[ "${_WITH_DEFAULTS:-0}" == "1" ]]; then
  apply_macos_defaults
elif is_dry_run; then
  log_info "[dry-run] Would apply macOS defaults"
else
  read -r -p "Apply macOS defaults? [y|N] " response
  if [[ "$response" =~ ^(yes|y|Y)$ ]]; then
    apply_macos_defaults
  else
    log_info "[skip] macOS defaults (user declined)"
  fi
fi

if [[ "${_SKIP_HOSTNAME:-0}" == "1" ]]; then
  log_info "[skip] Hostname update disabled"
elif [[ "${_WITH_HOSTNAME:-0}" == "1" ]]; then
  dry_run_or "apply hostname" apply_hostname
elif is_dry_run; then
  log_info "[dry-run] Would set hostname to $DOTFILES_HOSTNAME"
else
  read -r -p "Set hostname to \"$DOTFILES_HOSTNAME\"? [y|N] " response
  if [[ "$response" =~ ^(yes|y|Y)$ ]]; then
    apply_hostname
  else
    log_info "[skip] Hostname (user declined)"
  fi
fi

if [[ "${_SKIP_HOSTS:-0}" == "1" ]]; then
  log_info "[skip] Hosts update disabled"
else
  update_hosts
fi

if [[ "${_SKIP_MISE:-0}" == "1" ]]; then
  log_info "[skip] mise provisioning disabled"
else
  dry_run_or "provision mise runtimes" setup_mise_tools
fi

if [[ "${_SKIP_PACKAGES:-0}" == "1" ]]; then
  log_info "[skip] Package installation disabled"
elif [[ "${_WITH_PACKAGES:-0}" == "1" ]]; then
  install_packages "$SELECTED_PROFILE"
elif is_dry_run; then
  log_info "[dry-run] Would install packages for $SELECTED_PROFILE"
else
  read -r -p "Install packages (brew/cask/npm/mas/gem)? [y|N] " response
  if [[ "$response" =~ ^(yes|y|Y)$ ]]; then
    install_packages "$SELECTED_PROFILE"
  else
    log_info "[skip] Package installation (user declined)"
  fi
fi
log_success "Installation complete!"
