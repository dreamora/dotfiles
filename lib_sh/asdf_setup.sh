#!/usr/bin/env bash

# This script contains the function for setting up asdf plugins

function install_asdf_plugins() {
  bot "Installing ASDF plugins..."
  asdf plugin add nodejs
  asdf plugin add bun
  ok
}
