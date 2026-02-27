# ===========================================================================
# make/backup.mk — Backup and rollback for dotfiles and system changes
#
# Usage:
#   gmake dotfiles-backup    Snapshot current $HOME dotfile state before deploy
#   gmake dotfiles-rollback  Restore from most recent dotfiles snapshot
#   gmake backup-list        List all available snapshots
#   gmake backup-clean       Remove snapshots older than 30 days
# ===========================================================================

BACKUP_DIR := $(HOME)/.dotfiles-backups
BACKUP_TS  := $(shell date +%Y%m%dT%H%M%S)
BACKUP_SNAP := $(BACKUP_DIR)/$(BACKUP_TS)

# Files tracked by dotfiles that live directly in $HOME (flat group members)
# Nested paths (e.g. .config/nvim) are handled separately in the recipe.
BACKUP_DOTFILES := \
	$(HOME)/.zshrc \
	$(HOME)/.shellaliases \
	$(HOME)/.shellfn \
	$(HOME)/.shellvars \
	$(HOME)/.shellpaths \
	$(HOME)/.gitconfig \
	$(HOME)/.gitignore \
	$(HOME)/.gitmessage \
	$(HOME)/.vimrc \
	$(HOME)/.tmux.conf \
	$(HOME)/.screenrc \
	$(HOME)/.gemrc \
	$(HOME)/.irbrc \
	$(HOME)/.npmrc \
	$(HOME)/.nvmrc \
	$(HOME)/.asdfrc \
	$(HOME)/.tool-versions \
	$(HOME)/.crontab

.PHONY: dotfiles-backup dotfiles-rollback backup-list backup-clean

dotfiles-backup:                                        ## Snapshot current dotfile state before deployment
	@$(HELPERS) && bot "Creating dotfiles backup snapshot..."
	@mkdir -p "$(BACKUP_SNAP)/home" "$(BACKUP_SNAP)/config"
	@COPIED=0; \
	for f in $(BACKUP_DOTFILES); do \
		if [ -e "$$f" ] || [ -L "$$f" ]; then \
			cp -P "$$f" "$(BACKUP_SNAP)/home/" 2>/dev/null && COPIED=$$((COPIED + 1)) || true; \
		fi; \
	done; \
	if [ -d "$(HOME)/.config/nvim" ]; then \
		cp -rP "$(HOME)/.config/nvim" "$(BACKUP_SNAP)/config/nvim" 2>/dev/null || true; \
	fi; \
	if [ -d "$(HOME)/.vim" ]; then \
		cp -rP "$(HOME)/.vim" "$(BACKUP_SNAP)/home/.vim" 2>/dev/null || true; \
	fi; \
	if [ -d "$(HOME)/.git_template" ]; then \
		cp -rP "$(HOME)/.git_template" "$(BACKUP_SNAP)/home/.git_template" 2>/dev/null || true; \
	fi; \
	SNAP_PATH="$(BACKUP_SNAP)"; \
	printf '{"timestamp":"%s","snapshot":"%s","dotfiles_dir":"%s"}\n' \
		"$(BACKUP_TS)" "$$SNAP_PATH" "$(DOTFILES_DIR)" \
		> "$(BACKUP_SNAP)/manifest.json"; \
	$(HELPERS) && ok "Backup complete: $(BACKUP_SNAP) ($$COPIED files)"

dotfiles-rollback:                                      ## Restore dotfiles from most recent backup snapshot
	@$(HELPERS) && bot "Rolling back dotfiles to previous snapshot..."
	@LATEST="$$(ls -1td $(BACKUP_DIR)/[0-9]* 2>/dev/null | head -1)"; \
	if [ -z "$$LATEST" ]; then \
		$(HELPERS) && error "No backup snapshots found in $(BACKUP_DIR)"; \
		exit 1; \
	fi; \
	$(HELPERS) && running "Restoring from: $$LATEST"; \
	if [ -d "$$LATEST/home" ]; then \
		for f in "$$LATEST/home/".*; do \
			[ -e "$$f" ] || continue; \
			base="$$(basename "$$f")"; \
			dest="$(HOME)/$$base"; \
			if [ -L "$$dest" ]; then \
				rm "$$dest"; \
			fi; \
			cp -rP "$$f" "$(HOME)/" 2>/dev/null || true; \
		done; \
	fi; \
	if [ -d "$$LATEST/config/nvim" ]; then \
		rm -rf "$(HOME)/.config/nvim"; \
		cp -rP "$$LATEST/config/nvim" "$(HOME)/.config/nvim" 2>/dev/null || true; \
	fi; \
	$(HELPERS) && ok "Rollback complete from: $$LATEST"

backup-list:                                            ## List all available dotfile backup snapshots
	@echo ""
	@echo "Dotfile backup snapshots in $(BACKUP_DIR):"
	@echo ""
	@ls -1td $(BACKUP_DIR)/[0-9]* 2>/dev/null | while read -r snap; do \
		ts="$$(basename "$$snap")"; \
		size="$$(du -sh "$$snap" 2>/dev/null | cut -f1)"; \
		printf "  %-20s  %s\n" "$$ts" "$$size"; \
	done || echo "  (no snapshots found)"
	@echo ""

backup-clean:                                           ## Remove backup snapshots older than 30 days
	@$(HELPERS) && bot "Cleaning snapshots older than 30 days..."
	@REMOVED=0; \
	find $(BACKUP_DIR) -maxdepth 1 -type d -name '[0-9]*' -mtime +30 | while read -r snap; do \
		rm -rf "$$snap"; \
		REMOVED=$$((REMOVED + 1)); \
		$(HELPERS) && ok "Removed: $$snap"; \
	done; \
	$(HELPERS) && ok "Cleanup complete"
