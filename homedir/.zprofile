##############################################################################
#Import the shell-agnostic (Bash or Zsh) environment config
##############################################################################
source ~/.profile

##############################################################################
# History Configuration
##############################################################################
HISTSIZE=10000                # Number of commands loaded into memory
HISTFILESIZE=20000            # Number of commands stored in the file
SAVEHIST=10000                # Number of commands saved to disk
HISTFILE="$HOME/.zsh_history" #Where to save history to disk
HISTDUP=erase                 #Erase duplicates in the history file
setopt    appendhistory       #Append history to the history file (no overwriting)
setopt    sharehistory        #Share history across terminals
setopt    incappendhistory    #Immediately append to the history file, not just when a term is killed

##############################################################################
# z-zsh setup
##############################################################################
. ~/.dotfiles/z-zsh/z.sh
function precmd () {
  z --add "$(pwd -P)"
}

eval "$(/opt/homebrew/bin/brew shellenv)"

if command -v pyenv &> /dev/null; then
	export PYENV_ROOT="$HOME/.pyenv"
	[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi
