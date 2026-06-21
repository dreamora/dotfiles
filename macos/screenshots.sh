#!/usr/bin/env bash
# Module: macos/screenshots.sh — Screen capture and display preferences
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_screenshots_defaults() {
  log_step "Applying Screenshots defaults"

  # Save screenshots to the Desktop
  defaults write com.apple.screencapture location -string "${HOME}/Desktop"

  # Optional: Save screenshots to a different location
  # defaults write com.apple.screencapture location -string "${HOME}/Documents/Screenshots"

  # Save screenshots in PNG format (BMP, GIF, JPG, PDF, TIFF also available)
  defaults write com.apple.screencapture type -string "png"

  # Optional: Save screenshots as JPG instead
  # defaults write com.apple.screencapture type -string "jpg"

  # Disable drop shadow in screenshots
  defaults write com.apple.screencapture disable-shadow -bool true

  # Enable subpixel font rendering on non-Apple LCDs (0 = disabled, 1 = light, 2 = medium, 3 = heavy)
  defaults write NSGlobalDomain AppleFontSmoothing -int 2

  # Enable HiDPI display modes (requires restart)
  sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

  log_success "Screenshots defaults applied"
}

apply_screenshots_defaults
