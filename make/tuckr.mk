# ===========================================================================
# make/tuckr.mk — Tuckr dotfile symlink management
# ===========================================================================

TUCKR_GROUPS := zsh git vim neovim tmux screen ruby node asdf crontab

.PHONY: dotfiles dotfiles-rm dotfiles-preflight dotfiles-dryrun dotfiles-verify tuckr-status $(TUCKR_GROUPS)

dotfiles: $(SENTINEL_DIR)/.done-core-deps dotfiles-backup dotfiles-preflight  ## Deploy all dotfile groups via Tuckr (backup + preflight first)
	@$(HELPERS) && bot "Deploying dotfiles with Tuckr..."
	@tuckr set \*
	@bash $(DOTFILES_DIR)/scripts/audit_log.sh log dotfiles deployed || true
	@$(HELPERS) && ok "All dotfiles deployed"
	@$(MAKE) dotfiles-verify
	@$(HELPERS) && bot "Deploying dotfiles with Tuckr..."
	@tuckr set \*
	@$(HELPERS) && ok "All dotfiles deployed"
	@$(MAKE) dotfiles-verify

dotfiles-rm:                                            ## Remove all dotfile symlinks
	@$(HELPERS) && bot "Removing dotfile symlinks..."
	@tuckr unset \*
	@$(HELPERS) && ok "All dotfiles removed"

tuckr-status:                                           ## Show Tuckr deployment status
	@tuckr status

dotfiles-preflight: $(SENTINEL_DIR)/.done-core-deps      ## Check for conflicts and prerequisites before deployment
	@$(HELPERS) && bot "Running dotfiles preflight checks..."
	@if ! command -v tuckr >/dev/null 2>&1; then \
		$(HELPERS) && error "tuckr not found — run: gmake bootstrap"; exit 1; \
	fi
	@if ! command -v jq >/dev/null 2>&1; then \
		$(HELPERS) && error "jq not found — run: gmake bootstrap"; exit 1; \
	fi
	@CONFLICTS=0; \
	for group in $(TUCKR_GROUPS); do \
		out="$$(tuckr status $$group 2>&1 || true)"; \
		if echo "$$out" | grep -q "Not Symlinked:"; then \
			$(HELPERS) && warn "$$group: has conflicting files (tuckr would overwrite)"; \
			echo "$$out" | grep 'Not Symlinked:' -A 20 | grep '^ ' | head -10; \
			CONFLICTS=$$((CONFLICTS + 1)); \
		fi; \
	done; \
	if [ "$$CONFLICTS" -gt 0 ]; then \
		$(HELPERS) && error "Preflight failed: $$CONFLICTS group(s) have conflicts. Resolve before deploying."; \
		exit 1; \
	fi
	@$(HELPERS) && ok "Preflight passed — no conflicts detected"

dotfiles-dryrun: $(SENTINEL_DIR)/.done-core-deps         ## Preview deployment without making filesystem changes
	@$(HELPERS) && bot "Dry-run dotfiles deployment (no filesystem changes)..."
	@tuckr -n set \*
	@$(HELPERS) && ok "Dry-run complete"

dotfiles-verify:                                          ## Verify all groups are symlinked correctly (exit non-zero on failure)
	@$(HELPERS) && bot "Verifying dotfiles deployment..."
	@FAILED=0; \
	for group in $(TUCKR_GROUPS); do \
		out="$$(tuckr status $$group 2>&1 || true)"; \
		if echo "$$out" | grep -q "Symlinked:"; then \
			$(HELPERS) && ok "$$group: symlinked"; \
		else \
			$(HELPERS) && error "$$group: NOT symlinked"; \
			FAILED=$$((FAILED + 1)); \
		fi; \
	done; \
	if [ "$$FAILED" -gt 0 ]; then \
		$(HELPERS) && error "Verify failed: $$FAILED group(s) not deployed. Run: gmake dotfiles"; \
		exit 1; \
	fi
	@$(HELPERS) && ok "All groups verified"

# --- Individual group targets ---
# Usage: gmake zsh, gmake git, gmake neovim, etc.
$(TUCKR_GROUPS): $(SENTINEL_DIR)/.done-core-deps
	@$(HELPERS) && bot "Deploying $@ group..."
	@tuckr set $@
	@$(HELPERS) && ok "$@ deployed"
