# ===========================================================================
# make/tuckr.mk — Tuckr dotfile symlink management
# ===========================================================================

TUCKR_GROUPS := zsh git vim neovim tmux screen ruby node asdf crontab

.PHONY: dotfiles dotfiles-rm tuckr-status $(TUCKR_GROUPS)

dotfiles: $(SENTINEL_DIR)/.done-core-deps               ## Deploy all dotfile groups via Tuckr
	@$(HELPERS) && bot "Deploying dotfiles with Tuckr..."
	@tuckr set \*
	@$(HELPERS) && ok "All dotfiles deployed"

dotfiles-rm:                                            ## Remove all dotfile symlinks
	@$(HELPERS) && bot "Removing dotfile symlinks..."
	@tuckr unset \*
	@$(HELPERS) && ok "All dotfiles removed"

tuckr-status:                                           ## Show Tuckr deployment status
	@tuckr status

# --- Individual group targets ---
# Usage: gmake zsh, gmake git, gmake neovim, etc.
$(TUCKR_GROUPS): $(SENTINEL_DIR)/.done-core-deps
	@$(HELPERS) && bot "Deploying $@ group..."
	@tuckr set $@
	@$(HELPERS) && ok "$@ deployed"
