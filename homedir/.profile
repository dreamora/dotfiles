#############################################################
# Generic environment configuration that applies to all shells.
# Interactive-only setup (functions, aliases) lives in .zshrc.
#############################################################

# Resolve Homebrew once for login shells and non-login interactive zsh.
if command -v brew >/dev/null 2>&1; then
  _dotfiles_brew="$(command -v brew)"
elif [ -x /opt/homebrew/bin/brew ]; then
  _dotfiles_brew=/opt/homebrew/bin/brew
elif [ -x /usr/local/bin/brew ]; then
  _dotfiles_brew=/usr/local/bin/brew
fi
if [ -n "${_dotfiles_brew:-}" ]; then
  eval "$("$_dotfiles_brew" shellenv)"
fi
unset _dotfiles_brew

[ -r "$HOME/.shellvars" ] && source "$HOME/.shellvars"
[ -r "$HOME/.shellpaths" ] && source "$HOME/.shellpaths"

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

if [ -f "$HOME/.cargo/env" ]; then
  source "$HOME/.cargo/env"
fi
