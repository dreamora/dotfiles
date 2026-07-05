#!/usr/bin/env bash

###
# OS-aware GNU Stow symlink manager for dotfiles restructure.
# Stows homedir-common/, homedir-{darwin,linux}/, configs/, configs-{darwin,linux}/, scripts/
# @author Sisyphus
###

set -euo pipefail

# shellcheck source=lib/utils.sh
source "${BASH_SOURCE[0]%/*}/utils.sh"

# ============================================================================
# INTERNAL HELPERS
# ============================================================================

_stow_pkg_has_content() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    return 1
  fi
  local found
  found="$(find "$dir" -mindepth 1 -not -name ".gitkeep" -print -quit 2>/dev/null)"
  if [[ -n "$found" ]]; then
    return 0
  fi
  return 1
}

_backup_conflicting_targets() {
  local pkg_dir="$1"
  local target="$2"
  local backup_dir="$3"

  local file
  while IFS= read -r -d '' file; do
    local rel
    rel="${file#"${pkg_dir}/"}"
    local target_file="${target}/${rel}"
    if [[ -e "$target_file" && ! -L "$target_file" ]]; then
      local backup_dest="${backup_dir}/${rel}"
      mkdir -p "$(dirname "$backup_dest")"
      mv "$target_file" "$backup_dest"
      log_info "Backed up: ${target_file} → ${backup_dest}"
    fi
  done < <(find "$pkg_dir" -type f -not -name ".gitkeep" -print0)
}

_check_stow_conflicts() {
  local stow_dir="$1"
  local target="$2"
  local pkg="$3"

  local sim_output
  local sim_exit=0
  sim_output="$(stow --simulate --restow \
    --dir "${stow_dir}" \
    --target "${target}" \
    "${pkg}" 2>&1)" || sim_exit=$?

  if [[ "$sim_exit" -ne 0 ]]; then
    echo "${sim_output}"
    return 1
  fi
  return 0
}

# ============================================================================
# MAIN: apply_stow
# ============================================================================

# apply_stow [--force] [--dry-run]: stow all OS-appropriate dirs into $HOME / ~/.config.
# --force backs up conflicting real files; --dry-run also enabled by DOTFILES_DRY_RUN=1.
apply_stow() {
  local force=0
  local arg
  for arg in "$@"; do
    case "$arg" in
      --force)   force=1 ;;
      --dry-run) export DOTFILES_DRY_RUN=1 ;;
      *)         ;;
    esac
  done

  require_command "stow" "brew install stow"
  detect_os

  local -a stow_jobs=()

  stow_jobs+=("homedir-common|${HOME}")
  if [[ "${DOTFILES_OS}" == "darwin" ]]; then
    stow_jobs+=("homedir-darwin|${HOME}")
  elif [[ "${DOTFILES_OS}" == "linux" ]]; then
    stow_jobs+=("homedir-linux|${HOME}")
  fi

  stow_jobs+=("configs|${HOME}/.config")
  if [[ "${DOTFILES_OS}" == "darwin" ]]; then
    stow_jobs+=("configs-darwin|${HOME}/.config")
  elif [[ "${DOTFILES_OS}" == "linux" ]]; then
    stow_jobs+=("configs-linux|${HOME}/.config")
  fi
  stow_jobs+=("scripts|${HOME}/.local/bin")

  if is_dry_run; then
    log_info "[DRY RUN] Would ensure ${HOME}/.config exists"
    log_info "[DRY RUN] Would ensure ${HOME}/.local/bin exists"
  else
    mkdir -p "${HOME}/.config"
    mkdir -p "${HOME}/.local/bin"
  fi

  local backup_dir
  backup_dir="${HOME}/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"
  local stowed_count=0

  local job
  for job in "${stow_jobs[@]}"; do
    local pkg="${job%%|*}"
    local target="${job##*|}"
    local pkg_dir="${DOTFILES_DIR}/${pkg}"

    if ! _stow_pkg_has_content "${pkg_dir}"; then
      log_info "Skipping ${pkg} (directory empty or not present)"
      continue
    fi

    log_step "Stowing ${pkg} → ${target}"

    if is_dry_run; then
      log_info "[DRY RUN] stow --restow --dir \"${DOTFILES_DIR}\" --target \"${target}\" ${pkg}"
      stowed_count=$(( stowed_count + 1 ))
      continue
    fi

    local conflict_out=""
    if ! conflict_out="$(_check_stow_conflicts "${DOTFILES_DIR}" "${target}" "${pkg}")"; then
      if [[ "$force" -eq 0 ]]; then
        log_error "Stow conflicts detected for ${pkg} → ${target}:"
        echo "${conflict_out}" >&2
        log_error "Re-run with --force to back up conflicting files and proceed."
        return 1
      fi
      log_warn "Conflicts in ${pkg}; backing up to ${backup_dir}"
      _backup_conflicting_targets "${pkg_dir}" "${target}" "${backup_dir}"
    fi

    stow --restow \
      --dir "${DOTFILES_DIR}" \
      --target "${target}" \
      "${pkg}" || {
      log_error "stow --restow failed for ${pkg} → ${target}"
      return 1
    }

    stowed_count=$(( stowed_count + 1 ))
    log_success "Stowed: ${pkg} → ${target}"
  done

  local noun="directories"
  if [[ "$stowed_count" -eq 1 ]]; then
    noun="directory"
  fi
  log_success "Summary: ${stowed_count} ${noun} stowed."
}
