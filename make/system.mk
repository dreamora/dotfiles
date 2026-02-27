# ===========================================================================
# make/system.mk — System configuration (sudo, hosts, git identity, wallpaper)
#
# These are interactive/destructive operations that still prompt for
# confirmation where appropriate.
# ===========================================================================

.PHONY: system system-sudo system-hosts system-git-identity system-wallpaper

system: system-sudo system-hosts system-git-identity    ## Configure system settings (interactive)

# --- Passwordless sudo ---
system-sudo:                                            ## Setup passwordless sudo (interactive)
	@$(HELPERS) && bot "Sudo configuration..."
	@grep -q 'NOPASSWD:     ALL' /etc/sudoers.d/$$LOGNAME >/dev/null 2>&1 && { \
		$(HELPERS) && ok "Already configured"; \
		exit 0; \
	}; \
	sudo -v; \
	$(HELPERS) && bot "Do you want to setup passwordless sudo?"; \
	read -r -p "Make sudo passwordless? [y|N] " response; \
	if [[ $$response =~ (yes|y|Y) ]]; then \
		if ! grep -q "#includedir /private/etc/sudoers.d" /etc/sudoers; then \
			echo '#includedir /private/etc/sudoers.d' | sudo tee -a /etc/sudoers >/dev/null; \
		fi; \
		echo -e "Defaults:$$LOGNAME    !requiretty\n$$LOGNAME ALL=(ALL) NOPASSWD:     ALL" | sudo tee /etc/sudoers.d/$$LOGNAME; \
		$(HELPERS) && ok "Passwordless sudo configured"; \
	else \
		$(HELPERS) && ok "skipped"; \
	fi

# --- Ad-blocking hosts file ---
system-hosts:                                           ## Update /etc/hosts with ad-blocking list (interactive)
	@$(HELPERS) && bot "Hosts file configuration..."
	@read -r -p "Overwrite /etc/hosts with ad-blocking hosts file? [y|N] " response; \
	if [[ $$response =~ (yes|y|Y) ]]; then \
		$(HELPERS) && action "Downloading hosts file..."; \
		sudo curl -so $(DOTFILES_DIR)/configs/hosts https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts; \
		$(HELPERS) && action "Backing up current /etc/hosts..."; \
		sudo cp /etc/hosts /etc/hosts.backup; \
		sudo cp $(DOTFILES_DIR)/configs/hosts /etc/hosts; \
		$(HELPERS) && ok "Hosts file updated (backup at /etc/hosts.backup)"; \
	else \
		$(HELPERS) && ok "skipped"; \
	fi

# --- Git user identity ---
system-git-identity:                                    ## Configure git user name/email (interactive)
	@$(HELPERS) && bot "Git identity setup..."
	@# Only run if GITHUBUSER placeholder is still present
	@if grep -q 'user = GITHUBUSER' $(DOTFILES_DIR)/configs/git/.gitconfig 2>/dev/null; then \
		read -r -p "What is your git username? " githubuser; \
		fullname=$$(osascript -e "long user name of (system info)" 2>/dev/null || echo ""); \
		if [[ -n "$$fullname" ]]; then \
			firstname=$$(echo $$fullname | awk '{print $$1}'); \
			lastname=$$(echo $$fullname | awk '{print $$2}'); \
		fi; \
		if [[ -z "$$firstname" ]]; then \
			read -r -p "What is your first name? " firstname; \
			read -r -p "What is your last name? " lastname; \
		else \
			echo "I see your name is $$firstname $$lastname"; \
			read -r -p "Is this correct? [Y|n] " nameresponse; \
			if [[ $$nameresponse =~ ^(no|n|N) ]]; then \
				read -r -p "What is your first name? " firstname; \
				read -r -p "What is your last name? " lastname; \
			fi; \
		fi; \
		email=$$(dscl . -read /Users/$$(whoami) EMailAddress 2>/dev/null | sed "s/EMailAddress: //" || echo ""); \
		if [[ -z "$$email" ]]; then \
			read -r -p "What is your email? " email; \
		else \
			echo "Your email appears to be $$email"; \
			read -r -p "Is this correct? [Y|n] " emailresponse; \
			if [[ $$emailresponse =~ ^(no|n|N) ]]; then \
				read -r -p "What is your email? " email; \
			fi; \
		fi; \
		sed -i '' "s/GITHUBFULLNAME/$$firstname $$lastname/" $(DOTFILES_DIR)/configs/git/.gitconfig; \
		sed -i '' "s/GITHUBEMAIL/$$email/" $(DOTFILES_DIR)/configs/git/.gitconfig; \
		sed -i '' "s/GITHUBUSER/$$githubuser/" $(DOTFILES_DIR)/configs/git/.gitconfig; \
		$(HELPERS) && ok "Git identity configured for $$firstname $$lastname <$$email>"; \
	else \
		$(HELPERS) && ok "Git identity already configured"; \
	fi

# --- Custom wallpaper ---
system-wallpaper:                                       ## Set custom desktop wallpaper (interactive)
	@$(HELPERS) && bot "Wallpaper setup..."
	@if [[ -f $(DOTFILES_DIR)/img/wallpaper.jpg ]]; then \
		read -r -p "Set custom desktop wallpaper? [y|N] " response; \
		if [[ $$response =~ (yes|y|Y) ]]; then \
			$(HELPERS) && action "Setting wallpaper..."; \
			sudo cp /System/Library/CoreServices/DefaultDesktop.jpg $(DOTFILES_DIR)/img/DefaultDesktop.jpg 2>/dev/null || true; \
			sudo cp $(DOTFILES_DIR)/img/wallpaper.jpg /System/Library/CoreServices/DefaultDesktop.jpg 2>/dev/null || true; \
			$(HELPERS) && ok "Wallpaper set"; \
		else \
			$(HELPERS) && ok "skipped"; \
		fi; \
	else \
		$(HELPERS) && ok "No wallpaper.jpg found in img/, skipping"; \
	fi
