# ===========================================================================
# make/packages.mk — Package installation from packages.json
#
# Reads packages.json profiles and installs via lib_sh/requirers.sh helpers.
# Replaces install_packages.sh and Brewfile.
# ===========================================================================

.PHONY: packages-common packages-private packages-entertainment packages-work packages-work-optional

# Internal helper: install all package types for a given profile key
# Usage: $(call install_profile,common)
define install_profile
	@$(HELPERS) && \
	for pkg_json in $$(jq -r '.$(1).brew[]? | @base64' packages.json 2>/dev/null); do \
		name=$$(echo "$$pkg_json" | base64 --decode | jq -r '.name'); \
		opts=$$(echo "$$pkg_json" | base64 --decode | jq -r '.options // empty'); \
		require_brew "$$name" "$$opts"; \
	done
	@$(HELPERS) && \
	for pkg_json in $$(jq -r '.$(1).cask[]? | @base64' packages.json 2>/dev/null); do \
		name=$$(echo "$$pkg_json" | base64 --decode | jq -r '.name'); \
		opts=$$(echo "$$pkg_json" | base64 --decode | jq -r '.options // empty'); \
		require_cask "$$name" "$$opts"; \
	done
	@$(HELPERS) && \
	for pkg in $$(jq -r '.$(1).npm[]? // empty' packages.json 2>/dev/null); do \
		require_npm "$$pkg"; \
	done
	@$(HELPERS) && \
	for pkg in $$(jq -r '.$(1).gem[]? // empty' packages.json 2>/dev/null); do \
		require_gem "$$pkg"; \
	done
	@$(HELPERS) && \
	for pkg in $$(jq -r '.$(1).vscode[]? // empty' packages.json 2>/dev/null); do \
		require_vscode "$$pkg"; \
	done
	@$(HELPERS) && \
	for mas_json in $$(jq -r '.$(1).mas[]? | @base64' packages.json 2>/dev/null); do \
		name=$$(echo "$$mas_json" | base64 --decode | jq -r '.name'); \
		id=$$(echo "$$mas_json" | base64 --decode | jq -r '.id'); \
		require_mas "$$name" "$$id"; \
	done
endef

# --- Install taps first (shared across all profiles) ---
.PHONY: install-taps
install-taps: $(SENTINEL_DIR)/.done-core-deps
	@$(HELPERS) && bot "Installing Homebrew taps..."
	@$(HELPERS) && \
	for tap in $$(jq -r '.taps[]' packages.json); do \
		require_tap "$$tap"; \
	done

# --- Profile targets ---
packages-common: install-taps                           ## Install common packages
	@$(HELPERS) && bot "Installing common packages..."
	$(call install_profile,common)
	@$(HELPERS) && ok "Common packages installed"

packages-private: install-taps                          ## Install private packages
	@$(HELPERS) && bot "Installing private packages..."
	$(call install_profile,private)
	@$(HELPERS) && ok "Private packages installed"

packages-entertainment: install-taps                    ## Install entertainment packages
	@$(HELPERS) && bot "Installing entertainment packages..."
	$(call install_profile,entertainment)
	@$(HELPERS) && ok "Entertainment packages installed"

packages-work: install-taps                             ## Install work packages
	@$(HELPERS) && bot "Installing work packages..."
	$(call install_profile,work)
	@$(HELPERS) && ok "Work packages installed"

packages-work-optional: install-taps                    ## Install work-optional packages
	@$(HELPERS) && bot "Installing work-optional packages..."
	$(call install_profile,work-optional)
	@$(HELPERS) && ok "Work-optional packages installed"
