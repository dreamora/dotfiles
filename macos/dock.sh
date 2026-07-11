#!/usr/bin/env bash
# Module: macos/dock.sh — Dock preferences
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_dock_defaults() {
  log_step "Applying Dock defaults"

  # Wipe all default app icons from the Dock (useful for new Mac setup)
  defaults write com.apple.dock persistent-apps -array ""

  # Enable highlight hover effect for the grid view of a stack (Dock)
  defaults write com.apple.dock mouse-over-hilite-stack -bool true

  # Set the icon size of Dock items to 36 pixels
  defaults write com.apple.dock tilesize -int 36

  # Change minimize/maximize window effect to scale (vs genie)
  defaults write com.apple.dock mineffect -string "scale"

  # Minimize windows into their application's icon
  defaults write com.apple.dock minimize-to-application -bool true

  # Enable spring loading for all Dock items
  defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

  # Show indicator lights for open applications in the Dock
  defaults write com.apple.dock show-process-indicators -bool true

  # Don't animate opening applications from the Dock
  defaults write com.apple.dock launchanim -bool false

  # Speed up Mission Control animations (0.1s vs default 0.5s)
  defaults write com.apple.dock expose-animation-duration -float 0.1

  # Group windows by application in Mission Control (classic Exposé behavior)
  defaults write com.apple.dock expose-group-by-app -bool true

  # Optional: Only show active applications in the Dock
  # defaults write com.apple.dock static-only -bool true

  # Optional: Disable Dashboard (macOS 10.12–10.14 only; removed in Catalina)
  # defaults write com.apple.dock mcx-disabled -bool true

  # Optional: Don't show Dashboard as a Space
  # defaults write com.apple.dock dashboard-in-overlay -bool true

  # Don't automatically rearrange Spaces based on most recent use
  defaults write com.apple.dock mru-spaces -bool false

  # Remove the auto-hiding Dock delay (show immediately)
  defaults write com.apple.dock autohide-delay -float 0

  # Remove the animation when hiding/showing the Dock (instant)
  defaults write com.apple.dock autohide-time-modifier -float 0

  # Automatically hide and show the Dock
  defaults write com.apple.dock autohide -bool true

  # Make Dock icons of hidden applications translucent
  defaults write com.apple.dock showhidden -bool true

  # Make Dock more transparent (hide mirror effect)
  defaults write com.apple.dock hide-mirror -bool true

  # Optional: Enable 2D Dock appearance
  # defaults write com.apple.dock no-glass -bool true

  # Optional: Disable the Launchpad gesture (pinch with thumb and three fingers)
  # defaults write com.apple.dock showLaunchpadGestureEnabled -int 0

  # Optional: Add a spacer to the left side of the Dock
  # defaults write com.apple.dock persistent-apps -array-add '{tile-data={}; tile-type="spacer-tile";}'

  # Optional: Add a spacer to the right side of the Dock
  # defaults write com.apple.dock persistent-others -array-add '{tile-data={}; tile-type="spacer-tile";}'

  # Optional: Customize Launchpad layout (columns and rows)
  # defaults write com.apple.dock springboard-columns -int 9
  # defaults write com.apple.dock springboard-rows -int 3

  # Reset Launchpad layout (keep desktop wallpaper intact)
  defaults write com.apple.dock ResetLaunchPad -bool TRUE

  # Hot corners (all commented out — uncomment to enable)
  # Top left corner → Mission Control
  # defaults write com.apple.dock wvous-tl-corner -int 2
  # defaults write com.apple.dock wvous-tl-modifier -int 0
  # Top right corner → Desktop
  # defaults write com.apple.dock wvous-tr-corner -int 4
  # defaults write com.apple.dock wvous-tr-modifier -int 0
  # Bottom right corner → Start screen saver
  # defaults write com.apple.dock wvous-br-corner -int 5
  # defaults write com.apple.dock wvous-br-modifier -int 0

  # Restart Dock to apply changes
  killall Dock

  log_success "Dock defaults applied"
}

apply_dock_defaults
