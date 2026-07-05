#!/usr/bin/env bash
# Module: macos/general.sh — General system UI/UX preferences
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_general_defaults() {
  log_step "Applying General system defaults"

  # Disable menu bar transparency
  defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false

  # Hide Time Machine, Volume, and User icons from menu bar; show Bluetooth, AirPort, Battery, Clock
  for domain in "${HOME}"/Library/Preferences/ByHost/com.apple.systemuiserver.*; do
    defaults write "${domain}" dontAutoLoad -array \
      "/System/Library/CoreServices/Menu Extras/TimeMachine.menu" \
      "/System/Library/CoreServices/Menu Extras/Volume.menu" \
      "/System/Library/CoreServices/Menu Extras/User.menu"
  done
  defaults write com.apple.systemuiserver menuExtras -array \
    "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
    "/System/Library/CoreServices/Menu Extras/AirPort.menu" \
    "/System/Library/CoreServices/Menu Extras/Battery.menu" \
    "/System/Library/CoreServices/Menu Extras/Clock.menu"

  # Set highlight color to green
  defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"

  # Set sidebar icon size to medium (1 = small, 2 = medium, 3 = large)
  defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

  # Optional: Always show scrollbars (WhenScrolling, Automatic, Always)
  # defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

  # Increase window resize speed for Cocoa applications
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

  # Expand save panel by default
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

  # Expand print panel by default
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

  # Save to disk (not to iCloud) by default
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

  # Automatically quit printer app once print jobs complete
  defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

  # Disable the "Are you sure you want to open this application?" dialog (also in security.sh)
  defaults write com.apple.LaunchServices LSQuarantine -bool false

  # Display ASCII control characters using caret notation in standard text views
  defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true

  # Disable automatic termination of inactive apps
  defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

  # Optional: Disable smooth scrolling (for older Macs)
  # defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false

  # Optional: Disable Resume system-wide (re-open windows after restart)
  # defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false

  # Disable the crash reporter dialog
  defaults write com.apple.CrashReporter DialogType -string "none"

  # Set Help Viewer windows to non-floating mode
  defaults write com.apple.helpviewer DevMode -bool true

  # Check for software updates daily (not just once per week)
  defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

  ##############################################################################
  # Spotlight                                                                  #
  ##############################################################################

  # Set Spotlight indexing order and disable some file types from being indexed
  # Optional: Disable indexing for mounted volumes
  # sudo defaults write /.Spotlight-V100/VolumeConfiguration Exclusions -array "/Volumes"
  defaults write com.apple.spotlight orderedItems -array \
    '{"enabled" = 1;"name" = "APPLICATIONS";}' \
    '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
    '{"enabled" = 1;"name" = "DIRECTORIES";}' \
    '{"enabled" = 1;"name" = "PDF";}' \
    '{"enabled" = 1;"name" = "FONTS";}' \
    '{"enabled" = 0;"name" = "DOCUMENTS";}' \
    '{"enabled" = 0;"name" = "MESSAGES";}' \
    '{"enabled" = 0;"name" = "CONTACT";}' \
    '{"enabled" = 0;"name" = "EVENT_TODO";}' \
    '{"enabled" = 0;"name" = "IMAGES";}' \
    '{"enabled" = 0;"name" = "BOOKMARKS";}' \
    '{"enabled" = 0;"name" = "MUSIC";}' \
    '{"enabled" = 0;"name" = "MOVIES";}' \
    '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
    '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
    '{"enabled" = 0;"name" = "SOURCE";}'

  ##############################################################################
  # Terminal / iTerm2                                                          #
  ##############################################################################

  # Enable focus-follows-mouse for Terminal.app
  defaults write com.apple.terminal FocusFollowsMouse -bool true

  # Optional: Use only UTF-8 in Terminal.app
  # defaults write com.apple.terminal StringEncodings -array 4

  # Optional: Set a specific Terminal theme (replace TERM_PROFILE with theme name)
  # defaults write com.apple.terminal 'Default Window Settings' -string "${TERM_PROFILE}"
  # defaults write com.apple.terminal 'Startup Window Settings' -string "${TERM_PROFILE}"

  # Optional: iTerm2 — suppress quit prompt
  # defaults write com.googlecode.iterm2 PromptOnQuit -bool false

  # Optional: iTerm2 — hide tab title bars
  # defaults write com.googlecode.iterm2 HideTab -bool true

  # Optional: iTerm2 — enable system-wide hotkey
  # defaults write com.googlecode.iterm2 Hotkey -bool true

  # Optional: iTerm2 — hide pane titles in split panes
  # defaults write com.googlecode.iterm2 ShowPaneTitles -bool false

  # Optional: iTerm2 — animate split-terminal dimming
  # defaults write com.googlecode.iterm2 AnimateDimming -bool true

  # Optional: iTerm2 — hotkey binding (ctrl+backtick)
  # defaults write com.googlecode.iterm2 HotkeyChar -int 96
  # defaults write com.googlecode.iterm2 HotkeyCode -int 50
  # defaults write com.googlecode.iterm2 FocusFollowsMouse -int 1
  # defaults write com.googlecode.iterm2 HotkeyModifiers -int 262401

  # Optional: iTerm2 — set normal and non-ASCII fonts
  # defaults write com.googlecode.iterm2 "Normal Font" -string "Hack-Regular 12"
  # defaults write com.googlecode.iterm2 "Non Ascii Font" -string "RobotoMonoForPowerline-Regular 12"

  ##############################################################################
  # Time Machine                                                               #
  ##############################################################################

  # Prevent Time Machine from prompting to use new hard drives as backup volume
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

  ##############################################################################
  # Activity Monitor                                                           #
  ##############################################################################

  # Show the main window when launching Activity Monitor
  defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

  # Visualize CPU usage in the Activity Monitor Dock icon
  defaults write com.apple.ActivityMonitor IconType -int 5

  # Show all processes in Activity Monitor (101 = All Processes Hierarchically)
  defaults write com.apple.ActivityMonitor ShowCategory -int 101

  # Sort Activity Monitor results by CPU usage
  defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
  defaults write com.apple.ActivityMonitor SortDirection -int 0

  # Restart SystemUIServer to apply menu bar changes
  killall SystemUIServer

  log_success "General system defaults applied"
}

apply_general_defaults
