# ===========================================================================
# make/roles.mk — Machine role detection and host/role overlays
#
# Usage:
#   gmake role                  Show detected/configured role
#   gmake role-apply            Apply packages + config for detected role
#   gmake role-apply ROLE=work  Override role explicitly
#   gmake role-set ROLE=work    Persist role to ~/.dotfiles_role
#
# Role selection priority:
#   1. ROLE=xxx Make variable (explicit per-invocation override)
#   2. DOTFILES_ROLE env var
#   3. ~/.dotfiles_role file (persistent machine config)
#   4. hostname heuristics (auto-detect)
#   5. Default: 'personal'
#
# Supported roles:
#   personal    — personal/home machine (packages-common + packages-private)
#   work        — work machine (packages-work)
#   shared      — shared/minimal machine (packages-common only)
#
# To set a persistent role on a machine:
#   echo 'work' > ~/.dotfiles_role
#   # or: gmake role-set ROLE=work
# ===========================================================================

DOTFILES_ROLE_FILE := $(HOME)/.dotfiles_role

.PHONY: role role-apply role-set role-check

role:                                                   ## Show current machine role (auto-detected or configured)
	@DETECTED=$$(bash $(DOTFILES_DIR)/scripts/detect_role.sh); \
	echo ""; \
	echo "  Machine Role"; \
	echo "  ============"; \
	printf "  Role   : %s\n" "$$DETECTED"; \
	if [ -n "$(ROLE)" ]; then \
		echo "  Source : ROLE= Make variable"; \
	elif [ -n "$${DOTFILES_ROLE:-}" ]; then \
		echo "  Source : DOTFILES_ROLE env var"; \
	elif [ -f "$(DOTFILES_ROLE_FILE)" ]; then \
		echo "  Source : $(DOTFILES_ROLE_FILE)"; \
	else \
		echo "  Source : auto-detected from hostname"; \
	fi; \
	printf "  Override: echo 'work' > %s\n" "$(DOTFILES_ROLE_FILE)"; \
	echo ""

# Usage: gmake role-set ROLE=work
role-set:                                               ## Persist machine role to ~/.dotfiles_role (ROLE=work|personal|shared)
	@if [ -z "$(ROLE)" ]; then \
		echo "Usage: gmake role-set ROLE=work|personal|shared"; \
		exit 1; \
	fi
	@case "$(ROLE)" in \
		work|personal|shared) ;; \
		*) echo "Unknown role: $(ROLE). Valid: work, personal, shared"; exit 1 ;; \
	esac
	@echo "$(ROLE)" > "$(DOTFILES_ROLE_FILE)"
	@$(HELPERS) && ok "Role set to '$(ROLE)' in $(DOTFILES_ROLE_FILE)"

role-check:                                             ## Verify role file and env are consistent
	@DETECTED=$$(bash $(DOTFILES_DIR)/scripts/detect_role.sh); \
	echo ""; \
	echo "  Role Check"; \
	echo "  =========="; \
	printf "  ROLE Make var     : '%s'\n" "$(ROLE)"; \
	printf "  DOTFILES_ROLE env : '%s'\n" "$${DOTFILES_ROLE:-}"; \
	if [ -f "$(DOTFILES_ROLE_FILE)" ]; then \
		printf "  ~/.dotfiles_role  : '%s'\n" "$$(cat $(DOTFILES_ROLE_FILE))"; \
	else \
		echo "  ~/.dotfiles_role  : (not set)"; \
	fi; \
	printf "  Detected role     : '%s'\n" "$$DETECTED"; \
	echo ""

role-apply: $(SENTINEL_DIR)/.done-core-deps             ## Install packages for detected role (or ROLE= override)
	@EFFECTIVE_ROLE=$$(if [ -n "$(ROLE)" ]; then echo "$(ROLE)"; else bash $(DOTFILES_DIR)/scripts/detect_role.sh; fi); \
	$(HELPERS) && bot "Applying role: $$EFFECTIVE_ROLE"; \
	case "$$EFFECTIVE_ROLE" in \
		work) \
			$(MAKE) packages-work; \
			;; \
		personal) \
			$(MAKE) packages-common packages-private; \
			;; \
		shared) \
			$(MAKE) packages-common; \
			;; \
		*) \
			$(HELPERS) && error "Unknown role: $$EFFECTIVE_ROLE (valid: work, personal, shared)"; \
			exit 1; \
			;; \
	esac; \
	$(HELPERS) && ok "Role '$$EFFECTIVE_ROLE' packages applied"
