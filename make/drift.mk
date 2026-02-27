# ===========================================================================
# make/drift.mk — Drift detection between declared and actual state
# ===========================================================================

.PHONY: drift drift-gate drift-json

drift:                                                  ## Report declared-vs-actual drift (dotfiles + packages)
	@bash $(DOTFILES_DIR)/scripts/drift_check.sh

drift-gate:                                             ## Drift check with non-zero exit on critical drift (for CI)
	@bash $(DOTFILES_DIR)/scripts/drift_check.sh --gate

drift-json:                                             ## Drift check with JSON output (for tooling)
	@bash $(DOTFILES_DIR)/scripts/drift_check.sh --json
