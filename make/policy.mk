# ===========================================================================
# make/policy.mk — Role-based policy enforcement and shared-machine guard rails
#
# Usage:
#   gmake policy-check          Validate current role against allowed operations
#   gmake policy-report         Show policy rules for current role
#
# Guard rails:
#   DOTFILES_NONINTERACTIVE=1   Suppress all interactive prompts (CI/automation)
#   DOTFILES_SHARED_MACHINE=1   Block unsafe operations on shared machines
#
# Environment variables:
#   DOTFILES_NONINTERACTIVE=1   Skip confirmations; fail-safe on destructive ops
#   DOTFILES_SHARED_MACHINE=1   Enable shared-machine guard rails
#
# Policy per role:
#   personal   — all operations allowed
#   work       — all operations allowed; SOPS keys required for secrets
#   shared     — system-sudo, system-wallpaper blocked by default
# ===========================================================================

.PHONY: policy-check policy-report

policy-check:                                           ## Validate current role against operation policy
	@ROLE=$$(bash $(DOTFILES_DIR)/scripts/detect_role.sh); \
	SHARED="$${DOTFILES_SHARED_MACHINE:-}"; \
	echo ""; \
	echo "  Policy Check"; \
	echo "  ============"; \
	printf "  Role              : %s\n" "$$ROLE"; \
	printf "  Shared machine    : %s\n" "$${SHARED:-no}"; \
	printf "  Non-interactive   : %s\n" "$${DOTFILES_NONINTERACTIVE:-no}"; \
	echo ""; \
	VIOLATIONS=0; \
	if [ "$$ROLE" = "shared" ] || [ -n "$$SHARED" ]; then \
		echo "  Shared-machine guard rails active:"; \
		echo "    [BLOCKED] system-sudo (passwordless sudo not allowed on shared machines)"; \
		echo "    [BLOCKED] system-wallpaper (desktop policy may restrict wallpaper changes)"; \
		echo "    [ALLOWED] dotfiles, dotfiles-verify, drift, drift-gate"; \
		echo "    [ALLOWED] packages-common only (no personal/work packages)"; \
		VIOLATIONS=$$((VIOLATIONS + 1)); \
	else \
		echo "  All operations permitted for role '$$ROLE'"; \
	fi; \
	echo ""; \
	if [ "$$VIOLATIONS" -gt 0 ]; then \
		echo "  Note: Set DOTFILES_SHARED_MACHINE=1 to enforce guard rails explicitly."; \
		echo "        Or set role: gmake role-set ROLE=shared"; \
	fi; \
	echo ""

policy-report:                                          ## Show full policy matrix for all roles
	@echo ""
	@echo "  Policy Matrix"
	@echo "  ============="
	@echo ""
	@echo "  Operation               personal  work   shared"
	@echo "  ─────────────────────────────────────────────────────"
	@echo "  dotfiles                  ✓         ✓      ✓"
	@echo "  dotfiles-verify           ✓         ✓      ✓"
	@echo "  packages-common           ✓         ✓      ✓"
	@echo "  packages-private          ✓         -      ✗"
	@echo "  packages-work             -         ✓      ✗"
	@echo "  system-sudo               ✓         ✓      ✗"
	@echo "  system-hosts              ✓         ✓      ⚠ (prompt)"
	@echo "  system-wallpaper          ✓         ✓      ✗"
	@echo "  system-git-identity       ✓         ✓      ✓"
	@echo "  drift, drift-gate         ✓         ✓      ✓"
	@echo "  secrets-*                 ✓         ✓      ✗"
	@echo ""
	@echo "  ✓=allowed  ✗=blocked  ⚠=permitted with extra warning  -=not applicable"
	@echo ""
