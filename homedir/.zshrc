##############################################################################
# Interactive zsh setup. Environment/PATH config lives in .zprofile/.profile.
##############################################################################

# Ensure env is present even for non-login interactive shells
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  source ~/.profile
fi

##############################################################################
# History
##############################################################################
HISTSIZE=10000                # Number of commands loaded into memory
HISTFILESIZE=20000            # Number of commands stored in the file
SAVEHIST=10000                # Number of commands saved to disk
HISTFILE="$HOME/.zsh_history" # Where to save history to disk
HISTDUP=erase                 # Erase duplicates in the history file
setopt appendhistory          # Append history to the history file (no overwriting)
setopt sharehistory           # Share history across terminals
setopt incappendhistory       # Immediately append to the history file

##############################################################################
# Functions and aliases
##############################################################################
source "$HOME/.shellfn"
source "$HOME/.shellaliases"

##############################################################################
# Completions - single cached compinit
##############################################################################
fpath=($HOMEBREW_PREFIX/share/zsh-completions $HOMEBREW_PREFIX/share/zsh/site-functions $fpath)
[[ -d "$HOME/.docker/completions" ]] && fpath=($HOME/.docker/completions $fpath)
[[ -d "$HOME/.zsh/completions" ]] && fpath=($HOME/.zsh/completions $fpath)

autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

[[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"

##############################################################################
# Interactive tooling
##############################################################################
command -v fzf &>/dev/null && source <(fzf --zsh)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd j)"
command -v mise &>/dev/null && eval "$(mise activate zsh)"
command -v atuin &>/dev/null && eval "$(atuin init zsh)"
command -v starship &>/dev/null && eval "$(starship init zsh)"

##############################################################################
# Keybindings and options
##############################################################################
bindkey -v
unsetopt correct

##############################################################################
# Local/optional integrations
##############################################################################
if [[ -n "$VIRTUAL_ENV" && -f "$VIRTUAL_ENV/bin/activate" ]]; then
  source "$VIRTUAL_ENV/bin/activate"
fi

[[ -f "$HOME/development/.env" ]] && source "$HOME/development/.env"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

##############################################################################
# Plugins (keep syntax highlighting last)
##############################################################################
source "$HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
