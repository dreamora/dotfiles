#!/usr/bin/env bash
# Module: macos/trackpad.sh — Trackpad preferences
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_trackpad_defaults() {
  log_step "Applying Trackpad defaults"

  # Enable tap to click for this user and the login screen
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

  # Map bottom-right corner to right-click (secondary click)
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
  defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
  defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true

  # Optional: Disable "natural" (Lion-style) scrolling direction
  # defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

  # Optional: Disable tap to click (restore default)
  # defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 0

  log_success "Trackpad defaults applied"
}

apply_trackpad_defaults
