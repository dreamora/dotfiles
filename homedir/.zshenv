# PATH ownership: mise shims, cargo, ~/.local/bin — highest priority (see .shellpaths header)
fpath=($fpath $HOME/.zsh/func)
path=(
  "$HOME/.local/share/mise/shims"
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  $path
)
typeset -U fpath path PATH
