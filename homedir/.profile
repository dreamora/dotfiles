#############################################################
# Generic environment configuration that applies to all shells.
# Interactive-only setup (functions, aliases) lives in .zshrc.
#############################################################

brew_path="$(command -v brew 2>/dev/null)"
if [ -z "$brew_path" ]; then
  if [ -x /opt/homebrew/bin/brew ]; then
    brew_path=/opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then
    brew_path=/usr/local/bin/brew
  fi
fi

if [ -n "$brew_path" ]; then
  eval "$("$brew_path" shellenv)"
fi
unset brew_path

source "$HOME/.shellvars"
source "$HOME/.shellpaths"

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
