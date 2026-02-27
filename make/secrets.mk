# ===========================================================================
# make/secrets.mk — Secrets management with SOPS + age
#
# Conventions:
#   - Encrypted files live in secrets/ with .sops.yaml extension
#   - age keys are stored at ~/.config/sops/age/keys.txt (NOT in repo)
#   - SOPS_AGE_KEY_FILE env var points to the key file
#   - Decrypt-at-use: decrypt to /tmp/, source, then shred
#
# Setup:
#   gmake secrets-setup    Install sops + age and generate key
#   gmake secrets-edit     Open an encrypted secret file for editing
#   gmake secrets-decrypt  Decrypt a secret to /tmp/ (ephemeral)
#   gmake secrets-status   Check which secret files exist and are encrypted
# ===========================================================================

SECRETS_DIR := $(DOTFILES_DIR)/secrets
SOPS_KEY_DIR := $(HOME)/.config/sops/age
SOPS_KEY_FILE := $(SOPS_KEY_DIR)/keys.txt

.PHONY: secrets-setup secrets-edit secrets-decrypt secrets-status secrets-check-key

secrets-setup: $(SENTINEL_DIR)/.done-core-deps          ## Install sops + age and generate age key (first-time setup)
	@$(HELPERS) && bot "Setting up SOPS + age..."
	@$(HELPERS) && require_brew sops
	@$(HELPERS) && require_brew age
	@mkdir -p "$(SOPS_KEY_DIR)"
	@chmod 700 "$(SOPS_KEY_DIR)"
	@if [ -f "$(SOPS_KEY_FILE)" ]; then \
		$(HELPERS) && ok "age key already exists at $(SOPS_KEY_FILE)"; \
	else \
		$(HELPERS) && running "Generating age key..."; \
		age-keygen -o "$(SOPS_KEY_FILE)" 2>/dev/null; \
		chmod 600 "$(SOPS_KEY_FILE)"; \
		PUBLIC_KEY=$$(grep "^# public key:" "$(SOPS_KEY_FILE)" | sed 's/# public key: //'); \
		$(HELPERS) && ok "age key generated at $(SOPS_KEY_FILE)"; \
		echo ""; \
		echo "  Your public key is: $$PUBLIC_KEY"; \
		echo "  Add it to secrets/.sops.yaml as an age recipient."; \
		echo "  BACK UP your private key file: $(SOPS_KEY_FILE)"; \
		echo ""; \
	fi
	@mkdir -p "$(SECRETS_DIR)"
	@if [ ! -f "$(SECRETS_DIR)/.sops.yaml" ]; then \
		PUBLIC_KEY=$$(grep "^# public key:" "$(SOPS_KEY_FILE)" | sed 's/# public key: //'); \
		printf 'creation_rules:\n  - path_regex: .*\\.sops\\..*\n    age: >-\n      %s\n' "$$PUBLIC_KEY" > "$(SECRETS_DIR)/.sops.yaml"; \
		$(HELPERS) && ok "Created $(SECRETS_DIR)/.sops.yaml with your public key"; \
	fi
	@$(HELPERS) && ok "Secrets setup complete"

secrets-check-key:                                      ## Verify age key is present and accessible
	@if [ -f "$(SOPS_KEY_FILE)" ]; then \
		$(HELPERS) && ok "age key present at $(SOPS_KEY_FILE)"; \
	else \
		$(HELPERS) && error "age key not found at $(SOPS_KEY_FILE)"; \
		echo "Run: gmake secrets-setup"; \
		exit 1; \
	fi
	@export SOPS_AGE_KEY_FILE="$(SOPS_KEY_FILE)"; \
	if command -v sops >/dev/null 2>&1; then \
		$(HELPERS) && ok "sops is installed"; \
	else \
		$(HELPERS) && error "sops not found — run: gmake secrets-setup"; \
		exit 1; \
	fi

secrets-status:                                         ## Show all secret files and their encryption status
	@$(HELPERS) && bot "Checking secrets status..."
	@if [ ! -d "$(SECRETS_DIR)" ]; then \
		echo "  No secrets/ directory found."; \
		echo "  Run: gmake secrets-setup to initialize."; \
	else \
		echo "  Secret files in $(SECRETS_DIR):"; \
		echo ""; \
		find "$(SECRETS_DIR)" -type f -not -name '.sops.yaml' -not -name '.gitkeep' 2>/dev/null | while read -r f; do \
			if grep -q '"sops":' "$$f" 2>/dev/null || grep -q 'sops_version:' "$$f" 2>/dev/null; then \
				printf "  [encrypted]  %s\n" "$$(basename $$f)"; \
			else \
				printf "  [PLAINTEXT!] %s  ← WARNING: not encrypted\n" "$$(basename $$f)"; \
			fi; \
		done; \
		echo ""; \
	fi

# Usage: gmake secrets-edit FILE=secrets/myfile.sops.env
secrets-edit: secrets-check-key                         ## Edit an encrypted secret file (FILE=path/to/file.sops.*)
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: gmake secrets-edit FILE=secrets/myfile.sops.env"; \
		exit 1; \
	fi
	@SOPS_AGE_KEY_FILE="$(SOPS_KEY_FILE)" sops "$(FILE)"

# Usage: gmake secrets-decrypt FILE=secrets/myfile.sops.env OUT=/tmp/myfile.env
secrets-decrypt: secrets-check-key                      ## Decrypt a secret file to /tmp/ for ephemeral use
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: gmake secrets-decrypt FILE=secrets/myfile.sops.env [OUT=/tmp/decrypted.env]"; \
		exit 1; \
	fi
	@OUT_FILE="${OUT:-/tmp/$$(basename $(FILE) .sops.env).env}"; \
	SOPS_AGE_KEY_FILE="$(SOPS_KEY_FILE)" sops -d "$(FILE)" > "$$OUT_FILE"; \
	$(HELPERS) && ok "Decrypted to $$OUT_FILE (ephemeral — shred when done: shred -u $$OUT_FILE)"
