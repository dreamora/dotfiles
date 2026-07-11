#!/usr/bin/env bash
# Module: macos/keyboard.sh — Keyboard, input, and accessibility preferences
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_keyboard_defaults() {
  log_step "Applying Keyboard defaults"

  # Increase sound quality for Bluetooth headphones/headsets (bitpool min = 40)
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

  # Enable full keyboard access for all controls (Tab in modal dialogs)
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

  # Use scroll gesture with Ctrl key to zoom the screen
  defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
  # Ctrl key modifier mask for zoom (262144 = Ctrl)
  defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144

  # Follow keyboard focus while zoomed in
  defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

  # Disable press-and-hold for keys in favor of key repeat
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Optional: Re-enable press-and-hold for accented characters
  # defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool true

  # Set a blazingly fast keyboard repeat rate (2 = fast, 6 = default)
  defaults write NSGlobalDomain KeyRepeat -int 2
  # Set initial key repeat delay (10 = short, 68 = default)
  defaults write NSGlobalDomain InitialKeyRepeat -int 10

  # Set language to English (US) with USD currency and metric units
  defaults write NSGlobalDomain AppleLanguages -array "en"
  defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
  defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
  defaults write NSGlobalDomain AppleMetricUnits -bool true

  # Disable auto-correct (annoying when typing code)
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

  # Disable smart quotes (annoying when typing code)
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

  # Disable smart dashes (annoying when typing code)
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

  log_success "Keyboard defaults applied"
}

apply_keyboard_defaults
