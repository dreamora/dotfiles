#!/usr/bin/env bash

###########################
# This script restores backed up dotfiles
# @author Adam Eivy
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib/utils.sh

if [[ -z ${1:-} ]]; then
  log_error "you need to specify a backup folder date. Take a look in ~/.dotfiles_backup/ to see which backup date you wish to restore."
  exit 1
fi


log_step "Do you wish to change your shell back to bash?"
read -r -p "[Y|n] " response

if [[ $response =~ ^(no|n|N) ]];then
    log_info "ok, leaving shell as zsh..."
else
    log_info "ok, changing shell to bash..."
    chsh -s $(which bash)
    log_success "Shell changed to bash"
fi

log_step "Restoring dotfiles from backup..."

pushd ~/.dotfiles_backup/$1

for file in .*; do
  if [[ $file == "." || $file == ".." ]]; then
    continue
  fi

  log_step "~/$file"
  if [[ -e ~/$file ]]; then
      unlink $file;
      log_success "project dotfile $file unlinked"
  fi

  if [[ -e ./$file ]]; then
      mv ./$file ./
      log_success "$1 backup restored"
  fi
  log_success "done"
done

popd

log_success "Woot! All done."
