# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew
if [[ "$(uname -m)" == "arm64" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Shell config: vars and paths first
[[ -f ~/.shellvars ]] && source ~/.shellvars
[[ -f ~/.shellpaths ]] && source ~/.shellpaths

# Antidote plugin manager
if [[ "$(uname)" == "Darwin" ]]; then
  antidote_home=/opt/homebrew/opt/antidote/share/antidote
else
  antidote_home=${ZDOTDIR:-$HOME}/.antidote
fi
source "$antidote_home/antidote.zsh"
antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt

# Shell functions and aliases
[[ -f ~/.shellaliases ]] && source ~/.shellaliases
[[ -f ~/.shellfn ]] && source ~/.shellfn

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
