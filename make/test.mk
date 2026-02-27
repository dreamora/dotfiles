##
## test.mk - Dotfiles test harness targets
##

SHELL := /bin/bash

.PHONY: test test-full test-lint test-quick

test: test-quick ## Run core dotfiles test harness (non-destructive)

test-quick: ## Run fast structural and config tests
	@bash tests/run_tests.sh --quick

test-lint: ## Run shell lint and syntax checks only
	@bash tests/run_tests.sh --lint

test-full: ## Run full suite including symlink tests (LOCAL ONLY - requires tuckr deployed)
	@bash tests/run_tests.sh --full
