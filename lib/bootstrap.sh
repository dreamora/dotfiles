#!/usr/bin/env bash

###
# Two-stage minimal dependency installer for dotfiles restructure
# Stage 1: Raw package manager installs (git, stow, yq)
# Stage 2: After yq available, install antidote
# @author Sisyphus
###

source "${BASH_SOURCE[0]%/*}/utils.sh"

# ============================================================================
# STAGE 1: RAW PACKAGE MANAGER INSTALLS (git, stow, yq)
# ============================================================================

bootstrap_stage1_macos() {
  log_step "Stage 1: macOS — Xcode CLI + Homebrew + core tools"

  # Check/install Xcode CLI tools
  if ! xcode-select -p >/dev/null 2>&1; then
    log_info "Xcode CLI tools not found, installing..."
    xcode-select --install
    
    # Wait for installation to complete
    local timeout=0
    while ! xcode-select -p >/dev/null 2>&1; do
      sleep 5
      timeout=$((timeout + 5))
      if [[ $timeout -ge 120 ]]; then
        die "Xcode CLI tools installation timed out after 120s"
      fi
    done
    
    log_success "Xcode CLI tools installed"
    
    # Accept Xcode license
    sudo xcodebuild -license accept
  else
    log_info "Xcode CLI tools already installed"
  fi

  # Check/install Homebrew
  if ! command -v brew >/dev/null 2>&1; then
    log_info "Homebrew not found, installing..."
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      die "Failed to install Homebrew"
    fi
    log_success "Homebrew installed"
  else
    log_info "Homebrew already installed"
  fi

  # Install git via Homebrew
  if ! command -v git >/dev/null 2>&1; then
    log_info "Installing git via Homebrew..."
    if ! brew install git; then
      die "Failed to install git"
    fi
    log_success "git installed"
  else
    log_info "git already installed"
  fi

  # Install stow via Homebrew
  if ! command -v stow >/dev/null 2>&1; then
    log_info "Installing stow via Homebrew..."
    if ! brew install stow; then
      die "Failed to install stow"
    fi
    log_success "stow installed"
  else
    log_info "stow already installed"
  fi

  # Install yq via Homebrew
  if ! command -v yq >/dev/null 2>&1; then
    log_info "Installing yq via Homebrew..."
    if ! brew install yq; then
      die "Failed to install yq"
    fi
    log_success "yq installed"
  else
    log_info "yq already installed"
  fi
}

bootstrap_stage1_linux_ubuntu() {
  log_step "Stage 1: Linux (Ubuntu/Debian) — apt-get + core tools"

  # Update package lists
  log_info "Updating package lists..."
  if ! sudo apt-get update -y; then
    die "Failed to update package lists"
  fi

  # Install git
  if ! command -v git >/dev/null 2>&1; then
    log_info "Installing git via apt-get..."
    if ! sudo apt-get install -y git; then
      die "Failed to install git"
    fi
    log_success "git installed"
  else
    log_info "git already installed"
  fi

  # Install curl (needed for later stages)
  if ! command -v curl >/dev/null 2>&1; then
    log_info "Installing curl via apt-get..."
    if ! sudo apt-get install -y curl; then
      die "Failed to install curl"
    fi
    log_success "curl installed"
  else
    log_info "curl already installed"
  fi

  # Install stow
  if ! command -v stow >/dev/null 2>&1; then
    log_info "Installing stow via apt-get..."
    if ! sudo apt-get install -y stow; then
      die "Failed to install stow"
    fi
    log_success "stow installed"
  else
    log_info "stow already installed"
  fi

  # Install yq
  if ! command -v yq >/dev/null 2>&1; then
    log_info "Installing yq via apt-get..."
    if ! sudo apt-get install -y yq; then
      die "Failed to install yq"
    fi
    log_success "yq installed"
  else
    log_info "yq already installed"
  fi
}

bootstrap_stage1_linux_arch() {
  log_step "Stage 1: Linux (Arch) — pacman + core tools"

  # Install git
  if ! command -v git >/dev/null 2>&1; then
    log_info "Installing git via pacman..."
    if ! sudo pacman -Sy --noconfirm git; then
      die "Failed to install git"
    fi
    log_success "git installed"
  else
    log_info "git already installed"
  fi

  # Install curl
  if ! command -v curl >/dev/null 2>&1; then
    log_info "Installing curl via pacman..."
    if ! sudo pacman -Sy --noconfirm curl; then
      die "Failed to install curl"
    fi
    log_success "curl installed"
  else
    log_info "curl already installed"
  fi

  # Install stow
  if ! command -v stow >/dev/null 2>&1; then
    log_info "Installing stow via pacman..."
    if ! sudo pacman -Sy --noconfirm stow; then
      die "Failed to install stow"
    fi
    log_success "stow installed"
  else
    log_info "stow already installed"
  fi

  # Install yq
  if ! command -v yq >/dev/null 2>&1; then
    log_info "Installing yq via pacman..."
    if ! sudo pacman -Sy --noconfirm yq; then
      die "Failed to install yq"
    fi
    log_success "yq installed"
  else
    log_info "yq already installed"
  fi
}

# ============================================================================
# STAGE 2: ANTIDOTE PLUGIN MANAGER (after yq available)
# ============================================================================

bootstrap_stage2_macos() {
  log_step "Stage 2: macOS — antidote plugin manager"

  # Check if antidote already installed
  if brew list antidote >/dev/null 2>&1; then
    log_info "antidote already installed via Homebrew"
  else
    log_info "Installing antidote via Homebrew..."
    if ! brew install antidote; then
      die "Failed to install antidote"
    fi
    log_success "antidote installed"
  fi
}

bootstrap_stage2_linux() {
  log_step "Stage 2: Linux — antidote plugin manager"

  # Check if antidote already cloned
  if [[ -d "$HOME/.antidote" ]]; then
    log_info "antidote already cloned to ~/.antidote"
  else
    log_info "Cloning antidote to ~/.antidote..."
    if ! git clone https://github.com/mattmc3/antidote.git "$HOME/.antidote"; then
      die "Failed to clone antidote"
    fi
    log_success "antidote cloned"
  fi
}

# ============================================================================
# MAIN BOOTSTRAP FUNCTION
# ============================================================================

bootstrap_deps() {
  log_info "Starting dotfiles bootstrap..."

  # Detect OS
  detect_os

  # Stage 1: Install core tools
  case "$DOTFILES_OS" in
    darwin)
      bootstrap_stage1_macos
      ;;
    linux)
      case "$DOTFILES_DISTRO" in
        ubuntu)
          bootstrap_stage1_linux_ubuntu
          ;;
        arch)
          bootstrap_stage1_linux_arch
          ;;
        *)
          die "Unsupported Linux distro: $DOTFILES_DISTRO"
          ;;
      esac
      ;;
    *)
      die "Unsupported OS: $DOTFILES_OS"
      ;;
  esac

  # Verify Stage 1 dependencies
  log_step "Verifying Stage 1 dependencies..."
  require_command git "Install git manually"
  require_command stow "Install stow manually"
  require_command yq "Install yq manually"
  log_success "All Stage 1 dependencies verified"

  # Stage 2: Install antidote
  case "$DOTFILES_OS" in
    darwin)
      bootstrap_stage2_macos
      ;;
    linux)
      bootstrap_stage2_linux
      ;;
  esac

  log_success "Bootstrap complete!"
}

# ============================================================================
# GUARD: Do not execute any code when sourced
# ============================================================================
# This file only defines functions. No code executes on source.
