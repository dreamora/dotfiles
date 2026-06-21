#!/usr/bin/env bash
# migrate.sh — Migrate from old homedir/ stow structure to new modular structure
#
# Usage: ./migrate.sh [--dry-run|-n] [--help|-h]

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export DOTFILES_DIR

# shellcheck source=/dev/null
source "${DOTFILES_DIR}/lib/utils.sh"

OLD_HOMEDIR_FILES=(
  .zshrc .shellaliases .shellfn .shellpaths .shellvars
  .gitconfig .gitignore .p10k.zsh .profile .zprofile .zshenv .zlogout
  .tmux.conf .vimrc .screenrc .crontab .gemrc .tool-versions
  .init_gitaliases.sh setup-githooks.sh .git_template .vim .config
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Migrate from the old monolithic homedir/ stow structure to the new modular
structure (homedir-common/, homedir-darwin/, configs/, etc.).

Options:
  --dry-run, -n    Show what would happen without making changes
  --help, -h       Show this help message
EOF
}

detect_migration_needed() {
  local found=0
  local target link_dest
  for file in "${OLD_HOMEDIR_FILES[@]}"; do
    target="${HOME}/${file}"
    if [[ -L "$target" ]]; then
      link_dest="$(readlink "$target")"
      if [[ "$link_dest" == *homedir* ]]; then
        log_info "Old link: ${target} → ${link_dest}"
        found=$(( found + 1 ))
      fi
    fi
  done
  if [[ "$found" -gt 0 ]]; then
    log_warn "Migration needed: ${found} old-style link(s) found in ${HOME}"
    return 0
  else
    log_success "System appears to already be on new structure (no old-style links found)"
    return 1
  fi
}

backup_old_state() {
  local backup_dir
  backup_dir="${HOME}/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"
  log_step "Backing up symlink targets to: ${backup_dir}"
  mkdir -p "$backup_dir"

  local target link_dest
  for file in "${OLD_HOMEDIR_FILES[@]}"; do
    target="${HOME}/${file}"
    if [[ -L "$target" ]]; then
      link_dest="$(readlink "$target")"
      if [[ "$link_dest" == *homedir* ]]; then
        if [[ -d "$target" ]]; then
          cp -RL "$target" "${backup_dir}/${file}"
        else
          cp -L "$target" "${backup_dir}/${file}"
        fi
        log_info "Backed up: ${file}"
      fi
    fi
  done
  log_success "Backup complete: ${backup_dir}"
}

unstow_old() {
  log_step "Removing old homedir/ stow links"
  if [[ ! -d "${DOTFILES_DIR}/homedir" ]]; then
    log_warn "homedir/ not found in ${DOTFILES_DIR} — skipping unstow"
    return 0
  fi
  if ! command -v stow >/dev/null 2>&1; then
    die "stow not found. Install with: brew install stow"
  fi
  stow -D --dir "${DOTFILES_DIR}" --target "${HOME}" homedir
  log_success "Old symlinks removed"
}

print_next_steps() {
  log_step "Migration complete! Next steps:"
  log_info "  1. Ensure you're on the right branch:"
  log_info "     git checkout feat/modular-restructure"
  log_info "  2. Run the new installer:"
  log_info "     ./install.sh"
}

main() {
  local dry_run=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n) dry_run=1 ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done

  detect_migration_needed || exit 0

  if [[ "$dry_run" == "1" ]]; then
    log_info "[dry-run] Would backup symlink targets to: ${HOME}/.dotfiles_backup/<timestamp>"
    log_info "[dry-run] Would unstow: ${DOTFILES_DIR}/homedir → ${HOME}"
    log_info "[dry-run] No changes made."
    exit 0
  fi

  log_warn "This will remove old symlinks from your home directory."
  read -r -p "Proceed? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { log_info "Aborted."; exit 0; }

  backup_old_state
  unstow_old
  print_next_steps
}

main "$@"
