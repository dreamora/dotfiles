##
## macos.mk — macOS system defaults
## All targets use 'defaults write' and system commands.
## Run 'gmake macos' to apply everything, or individual targets.
##

SHELL := /bin/bash
DOTFILES_DIR := $(shell git rev-parse --show-toplevel 2>/dev/null || echo "$$HOME/.dotfiles")
HELPERS := source $(DOTFILES_DIR)/lib_sh/echos.sh

.PHONY: macos macos-security macos-ssd macos-ui macos-input macos-screen
.PHONY: macos-finder macos-dock macos-safari macos-mail macos-spotlight
.PHONY: macos-terminal macos-timemachine macos-activity macos-apps macos-messages macos-kill

macos: macos-security macos-ssd macos-ui macos-input macos-screen macos-finder macos-dock macos-safari macos-mail macos-spotlight macos-terminal macos-timemachine macos-activity macos-apps macos-messages macos-kill ## Apply all macOS system defaults
	@$(HELPERS) && bot "All macOS defaults applied. Some changes require a logout/restart."

macos-security: ## Firewall, remote access, login security
	@$(HELPERS) && bot "Security settings..."
	@$(HELPERS) && running "Enable firewall (on for specific services)"
	sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable firewall stealth mode"
	sudo defaults write /Library/Preferences/com.apple.alf stealthenabled -int 1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable remote Apple events"
	sudo systemsetup -setremoteappleevents off
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable remote login"
	-sudo systemsetup -setremotelogin off
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable wake-on modem"
	sudo systemsetup -setwakeonmodem off
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable wake-on LAN"
	sudo systemsetup -setwakeonnetworkaccess off
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable file-sharing via AFP or SMB"
	-sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.AppleFileServer.plist 2>/dev/null
	-sudo launchctl unload -w /System/Library/LaunchDaemons/com.apple.smbd.plist 2>/dev/null
	@$(HELPERS) && ok
	@$(HELPERS) && running "Do not show password hints"
	sudo defaults write /Library/Preferences/com.apple.loginwindow RetriesUntilHint -int 0
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable guest account login"
	sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable the 'Are you sure you want to open this application?' dialog"
	defaults write com.apple.LaunchServices LSQuarantine -bool false
	@$(HELPERS) && ok

macos-ssd: ## SSD tweaks: disable hibernation, sleep image, motion sensor
	@$(HELPERS) && bot "SSD-specific tweaks..."
	@$(HELPERS) && running "Disable hibernation (speeds up entering sleep mode)"
	sudo pmset -a hibernatemode 0
	@$(HELPERS) && ok
	@$(HELPERS) && running "Remove sleep image file to save disk space"
	sudo rm -rf /Private/var/vm/sleepimage
	@$(HELPERS) && ok
	@$(HELPERS) && running "Create zero-byte file in place of sleep image"
	sudo touch /Private/var/vm/sleepimage
	@$(HELPERS) && ok
	@$(HELPERS) && running "Lock sleep image so it can't be rewritten"
	sudo chflags uchg /Private/var/vm/sleepimage
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable the sudden motion sensor (not useful for SSDs)"
	sudo pmset -a sms 0
	@$(HELPERS) && ok

macos-ui: ## General UI/UX: menu bar, save dialogs, system-wide settings
	@$(HELPERS) && bot "Standard system UI/UX changes..."
	@$(HELPERS) && running "Close any open System Preferences panes"
	-osascript -e 'tell application "System Preferences" to quit' 2>/dev/null
	@$(HELPERS) && ok
	@$(HELPERS) && running "Always boot in verbose mode"
	sudo nvram boot-args="-v"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Allow 'locate' command"
	-sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist >/dev/null 2>&1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set standby delay to 24 hours"
	sudo pmset -a standbydelay 86400
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable sound effects on boot"
	sudo nvram SystemAudioVolume=" "
	@$(HELPERS) && ok
	@$(HELPERS) && running "Menu bar: disable transparency"
	defaults write NSGlobalDomain AppleEnableMenuBarTransparency -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Menu bar: hide Time Machine, Volume, User icons; show Bluetooth, AirPort, Battery, Clock"
	for domain in ~/Library/Preferences/ByHost/com.apple.systemuiserver.*; do \
		defaults write "$${domain}" dontAutoLoad -array \
			"/System/Library/CoreServices/Menu Extras/TimeMachine.menu" \
			"/System/Library/CoreServices/Menu Extras/Volume.menu" \
			"/System/Library/CoreServices/Menu Extras/User.menu"; \
	done
	defaults write com.apple.systemuiserver menuExtras -array \
		"/System/Library/CoreServices/Menu Extras/Bluetooth.menu" \
		"/System/Library/CoreServices/Menu Extras/AirPort.menu" \
		"/System/Library/CoreServices/Menu Extras/Battery.menu" \
		"/System/Library/CoreServices/Menu Extras/Clock.menu"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set highlight color to green"
	defaults write NSGlobalDomain AppleHighlightColor -string "0.764700 0.976500 0.568600"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set sidebar icon size to medium"
	defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
	@$(HELPERS) && ok
	@$(HELPERS) && running "Increase window resize speed for Cocoa applications"
	defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
	@$(HELPERS) && ok
	@$(HELPERS) && running "Expand save panel by default"
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
	defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Expand print panel by default"
	defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
	defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Save to disk (not to iCloud) by default"
	defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Automatically quit printer app once print jobs complete"
	defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Display ASCII control characters using caret notation"
	defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable automatic termination of inactive apps"
	defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable the crash reporter"
	defaults write com.apple.CrashReporter DialogType -string "none"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set Help Viewer windows to non-floating mode"
	defaults write com.apple.helpviewer DevMode -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Reveal IP, hostname, OS when clicking clock in login window"
	sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
	@$(HELPERS) && ok
	@$(HELPERS) && running "Restart automatically if the computer freezes"
	sudo systemsetup -setrestartfreeze on
	@$(HELPERS) && ok
	@$(HELPERS) && running "Never go into computer sleep mode"
	sudo systemsetup -setcomputersleep Off >/dev/null
	@$(HELPERS) && ok
	@$(HELPERS) && running "Check for software updates daily"
	defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable smart quotes"
	defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable smart dashes"
	defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
	@$(HELPERS) && ok

macos-input: ## Trackpad, keyboard, mouse, Bluetooth input settings
	@$(HELPERS) && bot "Trackpad, keyboard, mouse, input settings..."
	@$(HELPERS) && running "Trackpad: enable tap to click for this user and login screen"
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
	defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
	defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Trackpad: map bottom right corner to right-click"
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
	defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
	defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
	defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Increase sound quality for Bluetooth headphones/headsets"
	defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable full keyboard access for all controls (Tab in modal dialogs)"
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
	@$(HELPERS) && ok
	@$(HELPERS) && running "Use scroll gesture with Ctrl modifier to zoom"
	defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
	defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144
	@$(HELPERS) && ok
	@$(HELPERS) && running "Follow keyboard focus while zoomed in"
	defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable press-and-hold for keys (enable key repeat)"
	defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set blazingly fast keyboard repeat rate"
	defaults write NSGlobalDomain KeyRepeat -int 2
	defaults write NSGlobalDomain InitialKeyRepeat -int 10
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set language and text formats (English/US)"
	defaults write NSGlobalDomain AppleLanguages -array "en"
	defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
	defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
	defaults write NSGlobalDomain AppleMetricUnits -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable auto-correct"
	defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
	@$(HELPERS) && ok

macos-screen: ## Screenshots, screensaver, HiDPI display settings
	@$(HELPERS) && bot "Screen and display settings..."
	@$(HELPERS) && running "Require password immediately after sleep or screen saver"
	defaults write com.apple.screensaver askForPassword -int 1
	defaults write com.apple.screensaver askForPasswordDelay -int 0
	@$(HELPERS) && ok
	@$(HELPERS) && running "Save screenshots to the Desktop"
	defaults write com.apple.screencapture location -string "$${HOME}/Desktop"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Save screenshots in PNG format"
	defaults write com.apple.screencapture type -string "png"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable shadow in screenshots"
	defaults write com.apple.screencapture disable-shadow -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable subpixel font rendering on non-Apple LCDs"
	defaults write NSGlobalDomain AppleFontSmoothing -int 2
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable HiDPI display modes (requires restart)"
	sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
	@$(HELPERS) && ok

macos-finder: ## Finder preferences: view mode, hidden files, spring loading
	@$(HELPERS) && bot "Finder settings..."
	@$(HELPERS) && running "Keep folders on top when sorting by name"
	defaults write com.apple.finder _FXSortFoldersFirst -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Allow quitting Finder via ⌘+Q"
	defaults write com.apple.finder QuitMenuItem -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable window animations and Get Info animations"
	defaults write com.apple.finder DisableAllAnimations -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set Desktop as the default location for new Finder windows"
	defaults write com.apple.finder NewWindowTarget -string "PfDe"
	defaults write com.apple.finder NewWindowTargetPath -string "file://$${HOME}/Desktop/"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Show hidden files by default"
	defaults write com.apple.finder AppleShowAllFiles -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Show all filename extensions"
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Show status bar"
	defaults write com.apple.finder ShowStatusBar -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Show path bar"
	defaults write com.apple.finder ShowPathbar -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Allow text selection in Quick Look"
	defaults write com.apple.finder QLEnableTextSelection -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Display full POSIX path as Finder window title"
	defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Search current folder by default"
	defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable warning when changing a file extension"
	defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable spring loading for directories"
	defaults write NSGlobalDomain com.apple.springing.enabled -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Remove spring loading delay for directories"
	defaults write NSGlobalDomain com.apple.springing.delay -float 0
	@$(HELPERS) && ok
	@$(HELPERS) && running "Avoid creating .DS_Store files on network volumes"
	defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable disk image verification"
	defaults write com.apple.frameworks.diskimages skip-verify -bool true
	defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
	defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Automatically open a new Finder window when a volume is mounted"
	defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
	defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
	defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Use list view in all Finder windows by default"
	defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable warning before emptying Trash"
	defaults write com.apple.finder WarnOnEmptyTrash -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Empty Trash securely by default"
	defaults write com.apple.finder EmptyTrashSecurely -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable AirDrop over Ethernet and on unsupported Macs"
	defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Expand File Info panes: General, Open with, Sharing & Permissions"
	defaults write com.apple.finder FXInfoPanesExpanded -dict \
		General -bool true \
		OpenWith -bool true \
		Privileges -bool true
	@$(HELPERS) && ok

macos-dock: ## Dock size, animation, Mission Control settings
	@$(HELPERS) && bot "Dock & Mission Control settings..."
	@$(HELPERS) && running "Wipe all default app icons from the Dock"
	defaults write com.apple.dock persistent-apps -array ""
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable highlight hover effect for grid view of a stack"
	defaults write com.apple.dock mouse-over-hilite-stack -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set Dock icon size to 36 pixels"
	defaults write com.apple.dock tilesize -int 36
	@$(HELPERS) && ok
	@$(HELPERS) && running "Change minimize/maximize window effect to scale"
	defaults write com.apple.dock mineffect -string "scale"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Minimize windows into their application's icon"
	defaults write com.apple.dock minimize-to-application -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable spring loading for all Dock items"
	defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Show indicator lights for open applications in the Dock"
	defaults write com.apple.dock show-process-indicators -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Don't animate opening applications from the Dock"
	defaults write com.apple.dock launchanim -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Speed up Mission Control animations"
	defaults write com.apple.dock expose-animation-duration -float 0.1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Group windows by application in Mission Control"
	defaults write com.apple.dock expose-group-by-app -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Don't automatically rearrange Spaces based on most recent use"
	defaults write com.apple.dock mru-spaces -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Remove the auto-hiding Dock delay"
	defaults write com.apple.dock autohide-delay -float 0
	@$(HELPERS) && ok
	@$(HELPERS) && running "Remove the animation when hiding/showing the Dock"
	defaults write com.apple.dock autohide-time-modifier -float 0
	@$(HELPERS) && ok
	@$(HELPERS) && running "Automatically hide and show the Dock"
	defaults write com.apple.dock autohide -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Make Dock icons of hidden applications translucent"
	defaults write com.apple.dock showhidden -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Make Dock more transparent"
	defaults write com.apple.dock hide-mirror -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Reset Launchpad, keep desktop wallpaper intact"
	find "$${HOME}/Library/Application Support/Dock" -name "*-*.db" -maxdepth 1 -delete
	defaults write com.apple.dock ResetLaunchPad -bool TRUE
	killall Dock
	@$(HELPERS) && ok

macos-safari: ## Safari & WebKit developer settings
	@$(HELPERS) && bot "Safari & WebKit settings..."
	@$(HELPERS) && running "Set Safari's home page to 'about:blank'"
	defaults write com.apple.Safari HomePage -string "about:blank"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Prevent Safari from opening 'safe' files automatically after downloading"
	defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Allow Backspace key to go to previous page in history"
	defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Hide Safari's bookmarks bar by default"
	defaults write com.apple.Safari ShowFavoritesBar -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Hide Safari's sidebar in Top Sites"
	defaults write com.apple.Safari ShowSidebarInTopSites -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable Safari's thumbnail cache for History and Top Sites"
	defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable Safari's debug menu"
	defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Make Safari's search banners default to Contains"
	defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Remove useless icons from Safari's bookmarks bar"
	defaults write com.apple.Safari ProxiesInBookmarksBar "()"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable Develop menu and Web Inspector in Safari"
	defaults write com.apple.Safari IncludeDevelopMenu -bool true
	defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
	defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Add context menu item for Web Inspector in web views"
	defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
	@$(HELPERS) && ok

macos-mail: ## Mail.app threading, shortcuts, spell check settings
	@$(HELPERS) && bot "Mail.app settings..."
	@$(HELPERS) && running "Disable send and reply animations"
	defaults write com.apple.mail DisableReplyAnimations -bool true
	defaults write com.apple.mail DisableSendAnimations -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Copy email addresses without display name"
	defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Add ⌘+Enter keyboard shortcut to send email"
	defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" -string "@\U21a9"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Display emails in threaded mode, sorted by date (oldest first)"
	defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
	defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
	defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable inline attachments (show icons only)"
	defaults write com.apple.mail DisableInlineAttachmentViewing -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable automatic spell checking"
	defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"
	@$(HELPERS) && ok

macos-spotlight: ## Spotlight indexing categories and order
	@$(HELPERS) && bot "Spotlight settings..."
	@$(HELPERS) && running "Change indexing order and disable some file types"
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
	@$(HELPERS) && ok
	@$(HELPERS) && running "Load new settings before rebuilding the index"
	-killall mds >/dev/null 2>&1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Make sure indexing is enabled for the main volume"
	sudo mdutil -i on / >/dev/null
	@$(HELPERS) && ok

macos-terminal: ## Terminal focus-follows-mouse setting
	@$(HELPERS) && bot "Terminal settings..."
	@$(HELPERS) && running "Enable focus follows mouse for Terminal.app"
	defaults write com.apple.terminal FocusFollowsMouse -bool true
	@$(HELPERS) && ok

macos-timemachine: ## Time Machine: disable auto-prompts and local backups
	@$(HELPERS) && bot "Time Machine settings..."
	@$(HELPERS) && running "Prevent Time Machine from prompting to use new drives as backup"
	defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable local Time Machine backups"
	hash tmutil &>/dev/null && sudo tmutil disablelocal || true
	@$(HELPERS) && ok

macos-activity: ## Activity Monitor display, columns, refresh rate
	@$(HELPERS) && bot "Activity Monitor settings..."
	@$(HELPERS) && running "Show the main window when launching Activity Monitor"
	defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Visualize CPU usage in the Activity Monitor Dock icon"
	defaults write com.apple.ActivityMonitor IconType -int 5
	@$(HELPERS) && ok
	@$(HELPERS) && running "Show all processes in Activity Monitor"
	defaults write com.apple.ActivityMonitor ShowCategory -int 101
	@$(HELPERS) && ok
	@$(HELPERS) && running "Sort Activity Monitor results by CPU usage"
	defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
	defaults write com.apple.ActivityMonitor SortDirection -int 0
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set columns for each Activity Monitor tab"
	defaults write com.apple.ActivityMonitor "UserColumnsPerTab v5.0" -dict \
		'0' '( Command, CPUUsage, CPUTime, Threads, PID, UID, Ports )' \
		'1' '( Command, ResidentSize, Threads, Ports, PID, UID,  )' \
		'2' '( Command, PowerScore, 12HRPower, AppSleep, UID, powerAssertion )' \
		'3' '( Command, bytesWritten, bytesRead, Architecture, PID, UID, CPUUsage )' \
		'4' '( Command, txBytes, rxBytes, PID, UID, txPackets, rxPackets, CPUUsage )'
	@$(HELPERS) && ok
	@$(HELPERS) && running "Sort columns in each Activity Monitor tab"
	defaults write com.apple.ActivityMonitor UserColumnSortPerTab -dict \
		'0' '{ direction = 0; sort = CPUUsage; }' \
		'1' '{ direction = 0; sort = ResidentSize; }' \
		'2' '{ direction = 0; sort = 12HRPower; }' \
		'3' '{ direction = 0; sort = bytesWritten; }' \
		'4' '{ direction = 0; sort = txBytes; }'
	@$(HELPERS) && ok
	@$(HELPERS) && running "Set refresh frequency to 2 seconds"
	defaults write com.apple.ActivityMonitor UpdatePeriod -int 2
	@$(HELPERS) && ok
	@$(HELPERS) && running "Show Data in the Disk graph (instead of IO)"
	defaults write com.apple.ActivityMonitor DiskGraphType -int 1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Show Data in the Network graph (instead of packets)"
	defaults write com.apple.ActivityMonitor NetworkGraphType -int 1
	@$(HELPERS) && ok
	@$(HELPERS) && running "Change Dock icon to show Disk Activity"
	defaults write com.apple.ActivityMonitor IconType -int 3
	@$(HELPERS) && ok

macos-apps: ## TextEdit, Disk Utility, App Store debug/developer settings
	@$(HELPERS) && bot "App-specific settings (TextEdit, Disk Utility, App Store)..."
	@$(HELPERS) && running "Enable debug menu in Address Book"
	defaults write com.apple.addressbook ABShowDebugMenu -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable Dashboard dev mode"
	defaults write com.apple.dashboard devmode -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Use plain text mode for new TextEdit documents"
	defaults write com.apple.TextEdit RichText -int 0
	@$(HELPERS) && ok
	@$(HELPERS) && running "Open and save files as UTF-8 in TextEdit"
	defaults write com.apple.TextEdit PlainTextEncoding -int 4
	defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable debug menu in Disk Utility"
	defaults write com.apple.DiskUtility DUDebugMenuEnabled -bool true
	defaults write com.apple.DiskUtility advanced-image-options -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable WebKit Developer Tools in the Mac App Store"
	defaults write com.apple.appstore WebKitDeveloperExtras -bool true
	@$(HELPERS) && ok
	@$(HELPERS) && running "Enable Debug Menu in the Mac App Store"
	defaults write com.apple.appstore ShowDebugMenu -bool true
	@$(HELPERS) && ok

macos-messages: ## Messages: disable emoji substitution and smart quotes
	@$(HELPERS) && bot "Messages settings..."
	@$(HELPERS) && running "Disable automatic emoji substitution"
	defaults write com.apple.messageshelper.MessageController SOInputLineSettings \
		-dict-add "automaticEmojiSubstitutionEnablediMessage" -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable smart quotes in Messages"
	defaults write com.apple.messageshelper.MessageController SOInputLineSettings \
		-dict-add "automaticQuoteSubstitutionEnabled" -bool false
	@$(HELPERS) && ok
	@$(HELPERS) && running "Disable continuous spell checking in Messages"
	defaults write com.apple.messageshelper.MessageController SOInputLineSettings \
		-dict-add "continuousSpellCheckingEnabled" -bool false
	@$(HELPERS) && ok

macos-kill: ## Kill affected apps so macOS defaults take effect
	@$(HELPERS) && running "Flushing preferences cache"
	killall cfprefsd 2>/dev/null || true
	@$(HELPERS) && ok
	@$(HELPERS) && bot "Killing affected applications (they will restart automatically)..."
	@for app in "Activity Monitor" "Address Book" "Calendar" "Contacts" "cfprefsd" \
		"Dock" "Finder" "Mail" "Messages" "Safari" "SystemUIServer" \
		"iCal" "Terminal" "Ghostty"; do \
		killall "$${app}" >/dev/null 2>&1 || true; \
	done
	@$(HELPERS) && ok
