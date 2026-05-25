killall -9 fork
brew services stop syncthing
killall -9 syncthing

brew uninstall syncthing
brew uninstall --cask fork syncthing-app teamviewer ghostty cmux
brew install --cask iterm2
