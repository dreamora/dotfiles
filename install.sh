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
      --skip-packages Skip package installation
      --skip-defaults Skip macOS defaults
      --skip-hosts    Skip /etc/hosts update
      --skip-mise     Skip mise runtime provisioning
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
      --skip-packages)
        _SKIP_PACKAGES=1
        ;;
      --skip-defaults)
        _SKIP_DEFAULTS=1
        ;;
      --skip-hosts)
        _SKIP_HOSTS=1
        ;;
      --skip-mise)
        _SKIP_MISE=1
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
  local selected_lines=()
  if [[ -n "${DOTFILES_PROFILE_OVERRIDE:-}" ]]; then
    profile_from_override "$DOTFILES_PROFILE_OVERRIDE"
    return 0
  fi
  mapfile -t selected_lines < <(select_profile)
  echo "${selected_lines[-1]}"
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

if [[ "${_SKIP_PACKAGES:-0}" == "1" ]]; then
  log_info "[skip] Package installation disabled"
elif is_dry_run; then
  log_info "[dry-run] Would install packages for $SELECTED_PROFILE"
else
  install_packages "$SELECTED_PROFILE"
fi

apply_stow
dry_run_or "set up antidote" setup_antidote
dry_run_or "apply git config" apply_git_config

if [[ "${_SKIP_DEFAULTS:-0}" != "1" ]]; then
  apply_macos_defaults
else
  log_info "[skip] macOS defaults disabled"
fi

dry_run_or "apply hostname" apply_hostname

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
log_success "Installation complete!"
