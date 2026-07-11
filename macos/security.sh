#!/usr/bin/env bash
# Module: macos/security.sh — Security and privacy preferences
# Sourced by lib/macos-defaults.sh via: ( source "macos/security.sh" )
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_security_defaults() {
  log_step "Applying Security defaults"

  ##############################################################################
  # Firewall                                                                   #
  ##############################################################################

  # Enable firewall (1 = on for specific services, 2 = on for essential services)
  sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

  # Enable firewall stealth mode (no response to ICMP / ping requests)
  sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -int 1

  # Optional: Enable firewall logging
  # sudo defaults write /Library/Preferences/com.apple.alf loggingenabled -int 1

  # Optional: Do not allow signed software to receive incoming connections
  # sudo defaults write /Library/Preferences/com.apple.alf allowsignedenabled -bool false

  # Optional: Disable IR remote control
  # sudo defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled -bool false

  # Optional: Turn Bluetooth off completely
  # sudo defaults write /Library/Preferences/com.apple.Bluetooth ControllerPowerState -int 0

  # Optional: Disable wifi captive portal
  # sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.captive.control Active -bool false

  # Optional: Disable Bonjour multicast advertisements
  # sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true

  ##############################################################################
  # Login window                                                               #
  ##############################################################################

  # Do not show password hints at login window
  sudo defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0

  # Disable guest account login
  sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false

  # Optional: Display login window as name and password (vs. list of users)
  # sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

  # Reveal IP address, hostname, OS version, etc. when clicking the clock in login window
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

  ##############################################################################
  # LaunchServices                                                             #
  ##############################################################################

  # Disable the "Are you sure you want to open this application?" dialog
  defaults write com.apple.LaunchServices LSQuarantine -bool false

  ##############################################################################
  # Screen saver / lock                                                        #
  ##############################################################################

  # Require password immediately after sleep or screen saver begins
  defaults write com.apple.screensaver askForPassword -int 1

  # Require password immediately (no delay) after screen saver begins
  defaults write com.apple.screensaver askForPasswordDelay -int 0

  log_success "Security defaults applied"
}

apply_security_defaults
