##############################################################################
# Login-shell environment. Interactive-only setup lives in .zshrc.
##############################################################################

eval "$(/opt/homebrew/bin/brew shellenv)"

# Shell-agnostic (Bash or Zsh) environment config: vars and paths
source ~/.profile
