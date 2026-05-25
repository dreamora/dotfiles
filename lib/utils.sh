#!/usr/bin/env bash

###
# Core utilities: color constants, logging functions, OS detection, error handling
# @author Sisyphus
###

set -euo pipefail

# ============================================================================
# COLOR CONSTANTS
# ============================================================================

ESC_SEQ="\x1b["
COL_RESET="${ESC_SEQ}39;49;00m"
COL_RED="${ESC_SEQ}31;01m"
COL_GREEN="${ESC_SEQ}32;01m"
COL_YELLOW="${ESC_SEQ}33;01m"
COL_BLUE="${ESC_SEQ}34;01m"
# shellcheck disable=SC2034
COL_MAGENTA="${ESC_SEQ}35;01m"
# shellcheck disable=SC2034
COL_CYAN="${ESC_SEQ}36;01m"

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

# Log info message (blue [INFO])
log_info() {
  echo -e "${COL_BLUE}[INFO]${COL_RESET} $1"
}

# Log warning message (yellow [WARN])
log_warn() {
  echo -e "${COL_YELLOW}[WARN]${COL_RESET} $1"
}

# Log error message (red [ERROR])
log_error() {
  echo -e "${COL_RED}[ERROR]${COL_RESET} $1" >&2
}

# Log success message (green [OK])
log_success() {
  echo -e "${COL_GREEN}[OK]${COL_RESET} $1"
}

# Log step header (yellow ▸ step)
log_step() {
  echo -e "\n${COL_YELLOW}▸${COL_RESET} $1"
}

# ============================================================================
# ERROR HANDLING
# ============================================================================

# Die with error message and optional exit code (default 1)
die() {
  local message="$1"
  local exit_code="${2:-1}"
  log_error "$message"
  exit "$exit_code"
}

# ============================================================================
# OS DETECTION
# ============================================================================

# Detect OS and set DOTFILES_OS and DOTFILES_DISTRO
detect_os() {
  local os_type
  os_type="$(uname -s)"

  case "$os_type" in
    Darwin)
      DOTFILES_OS="darwin"
      DOTFILES_DISTRO="macos"
      ;;
    Linux)
      DOTFILES_OS="linux"
      # Detect Linux distro
      if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID:-}" in
          ubuntu)
            DOTFILES_DISTRO="ubuntu"
            ;;
          fedora)
            DOTFILES_DISTRO="fedora"
            ;;
          arch)
            DOTFILES_DISTRO="arch"
            ;;
          *)
            DOTFILES_DISTRO="unknown"
            ;;
        esac
      else
        DOTFILES_DISTRO="unknown"
      fi
      ;;
    *)
      die "Unsupported OS: $os_type"
      ;;
  esac

  export DOTFILES_OS
  export DOTFILES_DISTRO
}

# ============================================================================
# DOTFILES_DIR DETECTION
# ============================================================================

# Derive DOTFILES_DIR from script location (works regardless of how sourced)
# This script is at lib/utils.sh, so parent is lib/, grandparent is dotfiles root
_derive_dotfiles_dir() {
  local script_path
  local script_dir
  local parent_dir

  script_path="${BASH_SOURCE[0]}"

  # Handle readlink -f (not available on macOS without coreutils)
  if command -v greadlink >/dev/null 2>&1; then
    script_path="$(greadlink -f "$script_path")"
  else
    # Fallback: use cd to resolve symlinks
    script_dir="$(cd "$(dirname "$script_path")" && pwd)"
    script_path="$script_dir/$(basename "$script_path")"
  fi

  # Get directory of this script (lib/)
  script_dir="$(dirname "$script_path")"

  # Get parent directory (dotfiles root)
  parent_dir="$(cd "$script_dir/.." && pwd)"

  echo "$parent_dir"
}

DOTFILES_DIR="$(_derive_dotfiles_dir)"
export DOTFILES_DIR

# ============================================================================
# COMMAND CHECKING
# ============================================================================

# Check if command exists, die with helpful message if not
require_command() {
  local command="$1"
  local install_hint="${2:-}"

  if ! command -v "$command" >/dev/null 2>&1; then
    local msg="Command not found: $command"
    if [ -n "$install_hint" ]; then
      msg="$msg. Install with: $install_hint"
    fi
    die "$msg"
  fi
}

# ============================================================================
# DRY RUN SUPPORT
# ============================================================================

# Check if dry-run mode is enabled
is_dry_run() {
  [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]
}

# ============================================================================
# GUARD: Do not execute any code when sourced
# ============================================================================
# This file only defines functions and variables. No code executes on source.
