##############################################################################
# Login-shell environment. Interactive-only setup lives in .zshrc.
##############################################################################

# Shell-agnostic (Bash or Zsh) environment config: vars and paths
if [[ -r "$HOME/.profile" ]]; then
  source "$HOME/.profile"
fi
