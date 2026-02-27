# ===========================================================================
# make/audit.mk — Audit trail and toolchain conflict detection
# ===========================================================================

.PHONY: audit-log audit-summary toolchain-check toolchain-check-gate

audit-log:                                              ## Show last 20 audit log entries for destructive operations
	@bash $(DOTFILES_DIR)/scripts/audit_log.sh tail

audit-summary:                                          ## Show daily summary of destructive operations
	@bash $(DOTFILES_DIR)/scripts/audit_log.sh summary

toolchain-check:                                        ## Check for conflicting runtime managers (node/ruby/python)
	@bash $(DOTFILES_DIR)/scripts/toolchain_check.sh

toolchain-check-gate:                                   ## Toolchain check with non-zero exit on critical conflicts
	@bash $(DOTFILES_DIR)/scripts/toolchain_check.sh --gate
