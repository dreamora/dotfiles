#############################################################
# Generic configuration that applies to all shells
#############################################################

source ~/.shellvars
source ~/.shellfn
source ~/.shellpaths
source ~/.shellaliases

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

# Atuin
if command -v atuin &>/dev/null; then
	if [ -d "$HOME/.atuin/bin/env" ]; then
		source "$HOME/.atuin/bin/env"
	fi
else
	echo 'Atuin not installed, skipping configuration'
fi
# End Atuin
