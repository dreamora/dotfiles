#!/usr/bin/env bash
# Module: macos/finder.sh — Finder preferences
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_finder_defaults() {
  log_step "Applying Finder defaults"

  # Keep folders on top when sorting by name (macOS Sierra 10.12+)
  defaults write com.apple.finder _FXSortFoldersFirst -bool true

  # Allow quitting Finder via Cmd+Q (also hides desktop icons)
  defaults write com.apple.finder QuitMenuItem -bool true

  # Disable window animations and Get Info animations
  defaults write com.apple.finder DisableAllAnimations -bool true

  # Set Desktop as the default location for new Finder windows (PfLo for custom path)
  defaults write com.apple.finder NewWindowTarget -string "PfDe"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

  # Show hidden files by default
  defaults write com.apple.finder AppleShowAllFiles -bool true

  # Show all filename extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Show status bar at bottom of Finder window
  defaults write com.apple.finder ShowStatusBar -bool true

  # Show path bar at bottom of Finder window
  defaults write com.apple.finder ShowPathbar -bool true

  # Allow text selection in Quick Look previews
  defaults write com.apple.finder QLEnableTextSelection -bool true

  # Display full POSIX path as Finder window title
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

  # Search the current folder by default when performing a Finder search
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

  # Disable the warning when changing a file extension
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # Enable spring loading for directories (hover over folder to expand)
  defaults write NSGlobalDomain com.apple.springing.enabled -bool true

  # Remove the spring loading delay for directories (instant expand)
  defaults write NSGlobalDomain com.apple.springing.delay -float 0

  # Avoid creating .DS_Store files on network volumes
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Disable disk image verification for faster mounting
  defaults write com.apple.frameworks.diskimages skip-verify -bool true
  defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
  defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

  # Automatically open a new Finder window when a volume is mounted
  defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
  defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
  defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true

  # Use list view in all Finder windows by default (icnv=icon, clmv=column, Flwv=gallery)
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

  # Disable the warning before emptying the Trash
  defaults write com.apple.finder WarnOnEmptyTrash -bool false

  # Empty Trash securely by default
  defaults write com.apple.finder EmptyTrashSecurely -bool true

  # Enable AirDrop over Ethernet and on unsupported Macs running Lion
  defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

  # Optional: Show external hard drives, servers, and removable media on desktop
  # defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
  # defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
  # defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
  # defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

  # Expand File Info panes: General, Open with, Sharing & Permissions
  defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

  # Restart Finder to apply changes
  killall Finder

  log_success "Finder defaults applied"
}

apply_finder_defaults
