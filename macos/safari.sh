#!/usr/bin/env bash
# Module: macos/safari.sh — Safari and WebKit preferences
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_safari_defaults() {
  log_step "Applying Safari defaults"

  # Set Safari's home page to blank for faster loading
  defaults write com.apple.Safari HomePage -string "about:blank"

  # Prevent Safari from opening "safe" files automatically after downloading
  defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

  # Allow hitting the Backspace key to go to the previous page in history
  # Note: Broken on macOS Mojave — see https://apple.stackexchange.com/q/338313
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

  # Hide Safari's bookmarks bar by default
  defaults write com.apple.Safari ShowFavoritesBar -bool false

  # Hide Safari's sidebar in Top Sites
  defaults write com.apple.Safari ShowSidebarInTopSites -bool false

  # Disable Safari's thumbnail cache for History and Top Sites (saves disk space)
  defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

  # Enable Safari's internal debug menu
  defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

  # Make Safari's search banners default to Contains instead of Starts With
  defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

  # Remove useless icons from Safari's bookmarks bar
  defaults write com.apple.Safari ProxiesInBookmarksBar "()"

  # Enable the Develop menu and the Web Inspector in Safari
  defaults write com.apple.Safari IncludeDevelopMenu -bool true
  defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

  # Add a context menu item for showing the Web Inspector in web views (system-wide)
  defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

  # Optional: Warn about fraudulent websites
  # defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

  log_success "Safari defaults applied"
}

apply_safari_defaults
