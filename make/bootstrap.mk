# ===========================================================================
# make/bootstrap.mk — Xcode CLT, Homebrew, Tuckr, jq
# ===========================================================================

.PHONY: bootstrap brew-update

bootstrap: $(SENTINEL_DIR)/.done-xcode $(SENTINEL_DIR)/.done-homebrew $(SENTINEL_DIR)/.done-core-deps ## Install prerequisites (Xcode, Homebrew, Tuckr, jq)

# --- Xcode Command Line Tools ---
$(SENTINEL_DIR)/.done-xcode:
	@$(HELPERS) && bot "Checking Xcode Command Line Tools..."
	@if ! xcode-select --print-path &>/dev/null; then \
		$(HELPERS) && action "Installing Xcode CLT..."; \
		xcode-select --install &>/dev/null; \
		until xcode-select --print-path &>/dev/null; do sleep 5; done; \
		$(HELPERS) && ok; \
	else \
		$(HELPERS) && ok "already installed"; \
	fi
	@touch $@

# --- Homebrew ---
$(SENTINEL_DIR)/.done-homebrew: $(SENTINEL_DIR)/.done-xcode
	@$(HELPERS) && bot "Checking Homebrew..."
	@if ! command -v brew &>/dev/null; then \
		$(HELPERS) && action "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		if [[ -f /opt/homebrew/bin/brew ]]; then eval "$$(/opt/homebrew/bin/brew shellenv)"; fi; \
		$(HELPERS) && ok; \
	else \
		$(HELPERS) && ok "already installed"; \
	fi
	@touch $@

# --- Core dependencies (Tuckr, jq, GNU Make) ---
$(SENTINEL_DIR)/.done-core-deps: $(SENTINEL_DIR)/.done-homebrew
	@$(HELPERS) && bot "Checking core dependencies..."
	@command -v tuckr &>/dev/null || { $(HELPERS) && action "Installing Tuckr..." && brew install tuckr && $(HELPERS) && ok; }
	@command -v jq &>/dev/null    || { $(HELPERS) && action "Installing jq..."    && brew install jq    && $(HELPERS) && ok; }
	@command -v gmake &>/dev/null || { $(HELPERS) && action "Installing GNU Make..." && brew install make && $(HELPERS) && ok; }
	@touch $@

# --- Brew update/upgrade ---
brew-update:                                            ## Update Homebrew and upgrade all packages
	@$(HELPERS) && bot "Updating Homebrew..."
	@brew update
	@$(HELPERS) && action "Upgrading packages..."
	@brew upgrade
	@$(HELPERS) && ok "Homebrew updated"
