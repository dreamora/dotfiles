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

# History
HISTSIZE=10000
HISTFILESIZE=20000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt incappendhistory

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

# Private variables (API keys, tokens)
[[ -f "$HOME/.private_vars.inc" ]] && source "$HOME/.private_vars.inc"

# NVM
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Mise (runtime manager)
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='ag -g ""'

# Atuin (shell history)
if command -v atuin &>/dev/null; then
  [[ -f "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
  eval "$(atuin init zsh)"
fi

# jj completion
if command -v jj &>/dev/null; then
  source <(jj util completion zsh)
fi

# VI mode
set -o VI

# Additional PATHs
export PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"
[[ -d "$HOME/.bun" ]] && export BUN_INSTALL="$HOME/.bun" && export PATH="$BUN_INSTALL/bin:$PATH"
[[ -d "$HOME/.cache/lm-studio/bin" ]] && export PATH="$PATH:$HOME/.cache/lm-studio/bin"
[[ -d "$HOME/.lmstudio/bin" ]] && export PATH="$PATH:$HOME/.lmstudio/bin"
[[ -d "$HOME/.console-ninja" ]] && export PATH="$HOME/.console-ninja/.bin:$PATH"

# Google Cloud SDK
if [[ -d "$HOME/google-cloud-sdk" ]]; then
  [[ -d "$HOME/google-cloud-sdk/bin" ]] && export PATH="$HOME/google-cloud-sdk/bin:$PATH"
  [[ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]] && source "$HOME/google-cloud-sdk/completion.zsh.inc"
  [[ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]] && source "$HOME/google-cloud-sdk/path.zsh.inc"
fi

# Android
export ANDROID_TOOLING="$HOME/development/android-tooling/platform-tools"
export ANDROID_HOME="$HOME/development/android-tooling/android-sdk"
if [[ -d "$ANDROID_HOME" ]]; then
  export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/latest:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
fi
if [[ -d "$HOME/Applications/Android Studio.app" ]]; then
  export JAVA_HOME="$HOME/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

# Docker CLI completions
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=("$HOME/.docker/completions" $fpath)
  autoload -Uz compinit
  compinit
fi

# Kiro shell integration
[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
