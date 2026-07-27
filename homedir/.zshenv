fpath=($fpath $HOME/.zsh/func)
path=(
  "$HOME/.local/share/mise/shims"
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  $path
)
typeset -U fpath path PATH
