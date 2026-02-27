#!/usr/bin/env bash
###############################################################################
# bootstrap.sh — Minimal bootstrap for fresh macOS machines
#
# This script installs only what's needed to run `gmake`:
#   1. Xcode Command Line Tools
#   2. Homebrew
#   3. GNU Make (brew install make → provides gmake)
#
# After that, everything is managed by the Makefile:
#   gmake all          # Full base setup
#   gmake work         # Work machine profile
#   gmake private      # Private machine profile
#   gmake everything   # Install absolutely everything
#   gmake help         # Show all available targets
###############################################################################

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Colors (minimal, no lib_sh dependency) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()  { echo -e "${CYAN}[info]${RESET}  $*"; }
ok()    { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${RESET}  $*"; }
fail()  { echo -e "${RED}[error]${RESET} $*"; exit 1; }

# --- Step 1: Xcode Command Line Tools ---
if ! xcode-select --print-path &>/dev/null; then
  info "Installing Xcode Command Line Tools..."
  xcode-select --install &>/dev/null
  until xcode-select --print-path &>/dev/null; do
    sleep 5
  done
  ok "Xcode CLT installed"
else
  ok "Xcode CLT already installed"
fi

# --- Step 2: Homebrew ---
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to PATH for this session (Apple Silicon vs Intel)
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  ok "Homebrew installed"
else
  ok "Homebrew already installed"
fi

# --- Step 3: GNU Make (modern, not Apple's 2006 v3.81) ---
if ! command -v gmake &>/dev/null; then
  info "Installing GNU Make (modern version via Homebrew)..."
  brew install make
  ok "GNU Make installed (available as 'gmake')"
else
  ok "GNU Make already installed"
fi

# --- Step 4: Hand off to gmake ---
echo ""
info "Bootstrap complete. Handing off to GNU Make..."
echo ""
echo -e "  ${CYAN}Available profiles:${RESET}"
echo -e "    ${GREEN}gmake all${RESET}            Full base setup (dotfiles + tools)"
echo -e "    ${GREEN}gmake setup${RESET}          Base setup + common packages"
echo -e "    ${GREEN}gmake work${RESET}           Work machine profile"
echo -e "    ${GREEN}gmake private${RESET}        Private machine profile"
echo -e "    ${GREEN}gmake entertainment${RESET}  Entertainment profile"
echo -e "    ${GREEN}gmake everything${RESET}     Install absolutely everything"
echo -e "    ${GREEN}gmake help${RESET}           Show all available targets"
echo ""

# If an argument was passed, run that target
if [[ $# -gt 0 ]]; then
  info "Running: gmake $*"
  cd "$DOTFILES_DIR"
  exec gmake "$@"
else
  info "Run 'gmake <target>' from $DOTFILES_DIR to continue setup."
  info "Example: cd $DOTFILES_DIR && gmake setup"
fi
