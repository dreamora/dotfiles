# ===========================================================================
# Dotfiles — Makefile
#
# Usage:
#   gmake help           Show all available targets
#   gmake all            Full base setup (dotfiles + dev tools)
#   gmake setup          Base + common packages
#   gmake work           Work machine profile
#   gmake private        Private machine profile
#   gmake entertainment  Entertainment profile
#   gmake everything     Install absolutely everything
#
# Requires GNU Make 4.x (install via: brew install make → use as gmake)
# ===========================================================================

SHELL := /bin/bash
.DEFAULT_GOAL := help
DOTFILES_DIR := $(shell pwd)

# Sentinel directory for idempotency tracking (gitignored)
SENTINEL_DIR := .make
$(shell mkdir -p $(SENTINEL_DIR))

# Shell helpers — source in recipes for colored output + require_* functions
HELPERS := source $(DOTFILES_DIR)/lib_sh/echos.sh && source $(DOTFILES_DIR)/lib_sh/requirers.sh

# ===========================================================================
# Includes
# ===========================================================================

include make/bootstrap.mk
include make/tuckr.mk
include make/tools.mk
include make/packages.mk
include make/system.mk
include make/macos.mk
include make/test.mk
include make/backup.mk
include make/drift.mk
include make/secrets.mk
include make/roles.mk
include make/audit.mk
include make/policy.mk
include make/backup.mk
include make/drift.mk
include make/secrets.mk
include make/roles.mk
include make/audit.mk

# ===========================================================================
# Profile Targets (compose sub-targets)
# ===========================================================================
.PHONY: all setup work private entertainment work-optional everything

all: bootstrap dotfiles tools                           ## Full base setup (dotfiles + dev tools)
setup: all packages-common                              ## Base setup + common packages
work: setup packages-work                               ## Work machine profile
private: setup packages-private                         ## Private machine profile
entertainment: setup packages-entertainment             ## Entertainment profile
work-optional: work packages-work-optional              ## Work + optional extras
everything: setup packages-private packages-entertainment packages-work packages-work-optional ## Install absolutely everything

# ===========================================================================
# Maintenance
# ===========================================================================
.PHONY: update status clean brewfile

update: brew-update dotfiles                            ## Update Homebrew + redeploy dotfiles
status: tuckr-status                                    ## Show dotfile deployment status

clean:                                                  ## Remove sentinel files (force full re-run)
	@rm -rf $(SENTINEL_DIR)
	@echo "Sentinel files cleared. Next run will re-execute all targets."

brewfile:                                               ## Generate Brewfile from packages.json
	@echo "# Generated from packages.json — do not edit directly" > Brewfile
	@echo "# Regenerate with: gmake brewfile" >> Brewfile
	@echo "" >> Brewfile
	@$(HELPERS) && for tap in $$(jq -r '.taps[]' packages.json); do \
		echo "tap \"$$tap\"" >> Brewfile; \
	done
	@echo "" >> Brewfile
	@for profile in common private entertainment work work-optional; do \
		echo "# --- $$profile ---" >> Brewfile; \
		jq -r ".$$profile.brew[]? | .name" packages.json 2>/dev/null | while read -r pkg; do \
			echo "brew \"$$pkg\"" >> Brewfile; \
		done; \
		jq -r ".$$profile.cask[]? | .name" packages.json 2>/dev/null | while read -r pkg; do \
			echo "cask \"$$pkg\"" >> Brewfile; \
		done; \
		echo "" >> Brewfile; \
	done
	@echo "Brewfile generated from packages.json"

# ===========================================================================
# Help
# ===========================================================================
.PHONY: help
help:                                                   ## Show available targets
	@echo ""
	@echo "  \\[._.]/ Dotfiles Management (Tuckr + GNU Make)"
	@echo "  ================================================"
	@echo ""
	@echo "  Profiles:"
	@echo "    gmake all              Full base setup (dotfiles + tools)"
	@echo "    gmake setup            Base + common packages"
	@echo "    gmake work             Work machine"
	@echo "    gmake private          Private machine"
	@echo "    gmake entertainment    Games & media"
	@echo "    gmake everything       Install absolutely everything"
	@echo ""
	@echo "  All targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sed 's/^[^:]*://' | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-24s\033[0m %s\n", $$1, $$2}'
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "    \033[36m%-24s\033[0m %s\n", $$1, $$2}'
	@echo ""
