# ===========================================================================
# make/tools.mk — Dev tool setup (NVM, ASDF, fonts, vim plugins, etc.)
#
# These targets handle post-symlink setup that was previously in install.sh
# or would have been in Tuckr hooks. Make is the primary orchestrator.
# ===========================================================================

.PHONY: tools tool-zsh tool-git tool-vim tool-node tool-asdf tool-fonts shell-bench

tools: tool-zsh tool-git tool-vim tool-node tool-asdf tool-fonts ## Setup all dev tools

# --- ZSH: oh-my-zsh, powerlevel10k, default shell ---
tool-zsh:                                               ## ZSH setup (oh-my-zsh, p10k, default shell)
	@$(HELPERS) && bot "ZSH setup..."
	@# Ensure oh-my-zsh and z-zsh submodules are initialized
	@git -C $(DOTFILES_DIR) submodule update --init oh-my-zsh z-zsh 2>/dev/null || true
	@# Ensure powerlevel10k theme is present
	@if [[ ! -d "$(DOTFILES_DIR)/oh-my-zsh/custom/themes/powerlevel10k" ]]; then \
		$(HELPERS) && action "Cloning powerlevel10k..."; \
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
			$(DOTFILES_DIR)/oh-my-zsh/custom/themes/powerlevel10k; \
	fi
	@# Set ZSH as default shell if not already
	@CURRENT=$$(dscl . -read /Users/$$USER UserShell 2>/dev/null | awk '{print $$2}'); \
	if [[ "$$CURRENT" != "/bin/zsh" ]]; then \
		$(HELPERS) && action "Setting ZSH as default shell..."; \
		sudo dscl . -change /Users/$$USER UserShell $$SHELL /bin/zsh 2>/dev/null; \
	fi
	@$(HELPERS) && ok "ZSH configured"

# --- Git: commit template, global hooks ---
tool-git:                                               ## Git setup (commit template, hooks)
	@$(HELPERS) && bot "Git setup..."
	@# Set commit template
	@git config --global commit.template ~/.gitmessage 2>/dev/null || true
	@# Set global template directory for git hooks
	@git config --global init.templateDir ~/.git_template 2>/dev/null || true
	@$(HELPERS) && ok "Git configured"

# --- Vim: Vundle submodule + plugin install ---
tool-vim:                                               ## Vim setup (Vundle plugins)
	@$(HELPERS) && bot "Vim setup..."
	@# Ensure Vundle submodule is initialized
	@git -C $(DOTFILES_DIR) submodule update --init configs/vim/.vim/bundle/Vundle.vim 2>/dev/null || true
	@# Install plugins (non-interactive)
	@vim +PluginInstall +qall >/dev/null 2>&1 || true
	@$(HELPERS) && ok "Vim plugins installed"

# --- Node.js: NVM + install from .nvmrc ---
tool-node: $(SENTINEL_DIR)/.done-core-deps              ## Node.js setup (NVM + install)
	@$(HELPERS) && bot "Node.js setup..."
	@$(HELPERS) && require_brew nvm
	@mkdir -p ~/.nvm
	@# Install node version from .nvmrc (if NVM is available)
	@export NVM_DIR=~/.nvm; \
	if [[ -f "$$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]]; then \
		source "$$(brew --prefix nvm)/nvm.sh"; \
		nvm install 2>/dev/null || nvm install stable; \
	fi
	@npm config set save-exact true 2>/dev/null || true
	@$(HELPERS) && ok "Node.js configured"

# --- ASDF: plugin setup ---
tool-asdf: $(SENTINEL_DIR)/.done-core-deps              ## ASDF version manager plugin setup
	@$(HELPERS) && bot "ASDF setup..."
	@source $(DOTFILES_DIR)/lib_sh/asdf_setup.sh && install_asdf_plugins 2>/dev/null || true
	@$(HELPERS) && ok "ASDF configured"

# --- Fonts: JetBrains Mono Nerd Font ---
tool-fonts: $(SENTINEL_DIR)/.done-core-deps             ## Install Nerd Fonts
	@$(HELPERS) && bot "Installing fonts..."
	@$(HELPERS) && require_brew fontconfig
	@brew tap homebrew/cask-fonts 2>/dev/null || true
	@$(HELPERS) && require_cask font-jetbrains-mono-nerd-font
	@$(HELPERS) && ok "Fonts installed"

# --- Shell startup benchmark ---
shell-bench:                                            ## Benchmark zsh startup time against 500ms budget
	@bash $(DOTFILES_DIR)/scripts/shell_bench.sh

shell-bench-profile:                                    ## Benchmark zsh startup with zprof profiling output
	@bash $(DOTFILES_DIR)/scripts/shell_bench.sh --profile

shell-bench-ci:                                         ## Benchmark zsh startup in CI mode (non-zero exit if over budget)
	@bash $(DOTFILES_DIR)/scripts/shell_bench.sh --ci
