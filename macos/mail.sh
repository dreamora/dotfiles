#!/usr/bin/env bash
# Module: macos/mail.sh — Mail.app preferences
set -euo pipefail

# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/../lib/utils.sh"

apply_mail_defaults() {
  log_step "Applying Mail defaults"

  # Disable send and reply animations in Mail.app
  defaults write com.apple.mail DisableReplyAnimations -bool true
  defaults write com.apple.mail DisableSendAnimations -bool true

  # Copy email addresses as 'foo@example.com' instead of 'Foo Bar <foo@example.com>'
  defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

  # Add keyboard shortcut Cmd+Enter to send email
  defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" -string "@\\U21a9"

  # Display emails in threaded mode, sorted by date (oldest at top)
  defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
  defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
  defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

  # Disable inline attachments (show icons instead of previews)
  defaults write com.apple.mail DisableInlineAttachmentViewing -bool true

  # Disable automatic spell checking in Mail.app
  defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"

  # Optional: Sort inbox by newest at top instead of oldest
  # defaults write com.apple.mail InboxViewerAttributes -dict-add "SortedDescending" -string "no"

  log_success "Mail defaults applied"
}

apply_mail_defaults
