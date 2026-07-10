#############################################################
# Generic environment configuration that applies to all shells.
# Interactive-only setup (functions, aliases) lives in .zshrc.
#############################################################

source ~/.shellvars
source ~/.shellpaths

if [ -f "$HOME/.private_vars.inc" ]; then
	source "$HOME/.private_vars.inc"
fi

# LM Studio CLI (lms)
if [ -d "$HOME/.cache/lm-studio/bin" ]; then
	export PATH="$PATH:$HOME/.cache/lm-studio/bin"
fi
if [ -d "$HOME/.lmstudio/bin" ]; then
	export PATH="$PATH:$HOME/.lmstudio/bin"
fi

if [ -d "$HOME/.cargo" ]; then
	source "$HOME/.cargo/env"
fi

# Atuin PATH setup (interactive init happens in .zshrc)
if [ -f "$HOME/.atuin/bin/env" ]; then
	source "$HOME/.atuin/bin/env"
fi
