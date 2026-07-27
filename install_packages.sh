#!/usr/bin/env bash

# This script installs packages from software list files grouped by package type.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$DOTFILES_DIR" || exit 1

# shellcheck disable=SC1091
source "$DOTFILES_DIR/lib_sh/echos.sh"
# shellcheck disable=SC1091
source "$DOTFILES_DIR/lib_sh/requirers.sh"

MODE="install"
PROFILE="combined"
SOFTWARE_DIR="${SOFTWARE_DIR:-$DOTFILES_DIR/software}"
profile_explicit=0

for arg in "$@"; do
  case "$arg" in
    --check|--validate)
      if [[ "$MODE" != "install" ]]; then
        error "Package modes are mutually exclusive."
        exit 1
      fi
      MODE="check"
      ;;
    --bootstrap-install)
      if [[ "$MODE" != "install" ]]; then
        error "Package modes are mutually exclusive."
        exit 1
      fi
      MODE="bootstrap-install"
      ;;
    --bootstrap-verify)
      if [[ "$MODE" != "install" ]]; then
        error "Package modes are mutually exclusive."
        exit 1
      fi
      MODE="bootstrap-verify"
      ;;
    combined|all|common|private|business)
      PROFILE="$arg"
      profile_explicit=1
      ;;
    -*)
      error "Unexpected option '$arg'. Usage: ./install_packages.sh [--check] [software_dir] [profile] | ./install_packages.sh --bootstrap-install|--bootstrap-verify [software_dir]"
      exit 1
      ;;
    *)
      if [[ -d "$arg" ]]; then
        SOFTWARE_DIR="$(cd "$arg" && pwd -P)"
      else
        error "Unexpected argument '$arg'. Usage: ./install_packages.sh [--check] [software_dir] [profile] | ./install_packages.sh --bootstrap-install|--bootstrap-verify [software_dir]"
        exit 1
      fi
      ;;
  esac
done

if [[ "$MODE" == bootstrap-* && $profile_explicit -eq 1 ]]; then
  error "Bootstrap modes use the common bootstrap manifest and do not accept a profile."
  exit 1
fi

case "$PROFILE" in
  combined|all|common|private|business)
    ;;
  *)
    error "Unknown profile '$PROFILE'. Expected combined, common, private, or business."
    exit 1
    ;;
esac

overlay_dirs=()
case "$PROFILE" in
  private)
    overlay_dirs=("private")
    ;;
  business)
    overlay_dirs=("business")
    ;;
  combined|all)
    overlay_dirs=("private" "business")
    ;;
  common)
    overlay_dirs=()
    ;;
esac

trim_manifest_line() {
  local line="$1"

  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  printf '%s' "$line"
}

manifest_has_entries() {
  local file="$1"
  local raw line

  [[ -f "$file" ]] || return 1

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    line="$(trim_manifest_line "$raw")"
    [[ -n "$line" ]] && return 0
  done < "$file"

  return 1
}

manifest_files_for_type() {
  local type="$1"
  local files=()
  local overlay

  if [[ "$type" == "brew" ]]; then
    files+=("$SOFTWARE_DIR/bootstrap.list")
  fi
  files+=("$SOFTWARE_DIR/$type.list")

  for overlay in "${overlay_dirs[@]}"; do
    files+=("$SOFTWARE_DIR/$overlay/$type.list")
  done

  printf '%s\n' "${files[@]}"
}

require_root_manifest() {
  local type="$1"
  local file="$SOFTWARE_DIR/$type.list"

  if [[ ! -f "$file" ]]; then
    error "Missing required software manifest: $file"
    return 1
  fi
}

validate_manifest_line() {
  local type="$1"
  local line="$2"
  local source_file="$3"
  local part1 part2 part3

  case "$type" in
    tap|npm|gem|vscode)
      if [[ "$line" == *"|"* ]]; then
        error "Malformed $type entry in $source_file: $line"
        return 1
      fi
      part1="$(trim_manifest_line "$line")"
      if [[ -z "$part1" ]]; then
        error "Malformed $type entry in $source_file: package name is required"
        return 1
      fi
      ;;
    cask)
      IFS='|' read -r part1 part2 part3 <<< "$line"
      part1="$(trim_manifest_line "$part1")"
      part2="$(trim_manifest_line "${part2:-}")"
      if [[ -z "$part1" || -n "${part3:-}" || ( "$line" == *"|"* && -z "$part2" ) ]]; then
        error "Malformed cask entry in $source_file: $line"
        return 1
      fi
      ;;
    brew)
      IFS='|' read -r part1 part2 part3 <<< "$line"
      part1="$(trim_manifest_line "$part1")"
      part2="$(trim_manifest_line "${part2:-}")"
      if [[ -z "$part1" || -n "${part3:-}" || ( "$line" == *"|"* && -z "$part2" ) ]]; then
        error "Malformed brew entry in $source_file: $line"
        return 1
      fi
      ;;
    mas)
      IFS='|' read -r part1 part2 part3 <<< "$line"
      part1="$(trim_manifest_line "$part1")"
      part2="$(trim_manifest_line "${part2:-}")"
      if [[ -z "$part1" || -z "$part2" || -n "${part3:-}" || ! "$part2" =~ ^[0-9]+$ ]]; then
        error "Malformed mas entry in $source_file: $line"
        return 1
      fi
      ;;
    *)
      error "Unknown package type '$type' in $source_file"
      return 1
      ;;
  esac

  return 0
}

brew_manifest_name() {
  local line="$1"
  local name

  IFS='|' read -r name _ <<< "$line"
  trim_manifest_line "$name"
}

validate_bootstrap_manifest() {
  local bootstrap_file="$SOFTWARE_DIR/bootstrap.list"
  local raw line name existing
  local bootstrap_names=()

  if ! manifest_has_entries "$bootstrap_file"; then
    error "Missing or empty required bootstrap manifest: $bootstrap_file"
    return 1
  fi

  while IFS= read -r raw || [[ -n "$raw" ]]; do
    line="$(trim_manifest_line "$raw")"
    [[ -z "$line" ]] && continue
    validate_manifest_line "brew" "$line" "$bootstrap_file" || return 1
    name="$(brew_manifest_name "$line")"
    for existing in "${bootstrap_names[@]}"; do
      if [[ "$existing" == "$name" ]]; then
        error "Duplicate bootstrap formula '$name' in $bootstrap_file"
        return 1
      fi
    done
    bootstrap_names+=("$name")
  done < "$bootstrap_file"
}

validate_bootstrap_ownership() {
  local bootstrap_file="$SOFTWARE_DIR/bootstrap.list"
  local file raw line bootstrap_line bootstrap_name brew_name
  local brew_files=("$SOFTWARE_DIR/brew.list")
  local overlay

  for overlay in "${overlay_dirs[@]}"; do
    brew_files+=("$SOFTWARE_DIR/$overlay/brew.list")
  done

  for file in "${brew_files[@]}"; do
    [[ -f "$file" ]] || continue
    while IFS= read -r raw || [[ -n "$raw" ]]; do
      line="$(trim_manifest_line "$raw")"
      [[ -z "$line" ]] && continue
      validate_manifest_line "brew" "$line" "$file" || return 1
      brew_name="$(brew_manifest_name "$line")"

      while IFS= read -r bootstrap_line || [[ -n "$bootstrap_line" ]]; do
        bootstrap_line="$(trim_manifest_line "$bootstrap_line")"
        [[ -z "$bootstrap_line" ]] && continue
        bootstrap_name="$(brew_manifest_name "$bootstrap_line")"
        if [[ "$bootstrap_name" == "$brew_name" ]]; then
          error "Formula '$brew_name' is owned by both $bootstrap_file and $file"
          return 1
        fi
      done < "$bootstrap_file"
    done < "$file"
  done
}

provider_available() {
  local type="$1"
  local label="$2"

  case "$type" in
    npm)
      if ! command -v mise >/dev/null 2>&1; then
        warn "skipping $label; mise is not installed"
        return 1
      fi
      ;;
    mas)
      if ! command -v mas >/dev/null 2>&1; then
        warn "skipping $label; mas is not installed"
        return 1
      fi
      ;;
    vscode)
      if ! command -v code >/dev/null 2>&1; then
        warn "skipping $label; VS Code command line tool 'code' is not installed"
        return 1
      fi
      ;;
  esac

  return 0
}

install_manifest_line() {
  local type="$1"
  local line="$2"
  local source_file="$3"
  local name options id part2 part3

  validate_manifest_line "$type" "$line" "$source_file" || return 1

  if [[ "$MODE" == "check" ]]; then
    return 0
  fi

  case "$type" in
    tap)
      require_tap "$line" || return 1
      ;;
    brew)
      IFS='|' read -r name options part3 <<< "$line"
      if [[ -n "${part3:-}" ]]; then
        error "Malformed brew entry in $source_file: $line"
        return 1
      fi
      name="$(trim_manifest_line "$name")"
      options="$(trim_manifest_line "${options:-}")"
      if [[ -n "$options" ]]; then
        require_brew "$name" "$options" || return 1
      else
        require_brew "$name" || return 1
      fi
      ;;
    cask)
      IFS='|' read -r name options part3 <<< "$line"
      if [[ -n "${part3:-}" ]]; then
        error "Malformed cask entry in $source_file: $line"
        return 1
      fi
      name="$(trim_manifest_line "$name")"
      options="$(trim_manifest_line "${options:-}")"
      if [[ -n "$options" ]]; then
        require_cask "$name" "$options" || return 1
      else
        require_cask "$name" || return 1
      fi
      ;;
    npm)
      require_npm "$line" || return 1
      ;;
    gem)
      require_gem "$line" || return 1
      ;;
    mas)
      IFS='|' read -r name id part3 <<< "$line"
      if [[ -n "${part3:-}" ]]; then
        error "Malformed mas entry in $source_file: $line"
        return 1
      fi
      name="$(trim_manifest_line "$name")"
      id="$(trim_manifest_line "$id")"
      require_mas "$name" "$id" || return 1
      ;;
    vscode)
      require_vscode "$line" || return 1
      ;;
  esac
}

process_manifest_file() {
  local type="$1"
  local file="$2"
  local raw line

  [[ -f "$file" ]] || return 0

  while IFS= read -r raw <&3 || [[ -n "$raw" ]]; do
    line="$(trim_manifest_line "$raw")"
    [[ -z "$line" ]] && continue
    install_manifest_line "$type" "$line" "$file" || return 1
  done 3< "$file"
}

install_type() {
  local type="$1"
  local label="$2"
  local file
  local active_files=()
  local response="n"

  require_root_manifest "$type" || return 1

  while IFS= read -r file; do
    if manifest_has_entries "$file"; then
      active_files+=("$file")
    fi
  done < <(manifest_files_for_type "$type")

  if [[ ${#active_files[@]} -eq 0 ]]; then
    action "skipping $label (no packages defined)"
    return 0
  fi

  if [[ "$MODE" == "check" ]]; then
    action "validating $label manifests"
    for file in "${active_files[@]}"; do
      process_manifest_file "$type" "$file" || return 1
    done
    ok
    return 0
  fi

  if [[ -n ${CI:-} ]]; then
    action "skipping $label in CI"
    return 0
  fi

  provider_available "$type" "$label" || return 0

  read -r -p "Do you want to install $label? [y|N] " response
  if [[ ! $response =~ (yes|y|Y) ]]; then
    action "skipping $label installation"
    return 0
  fi

  action "installing $label"
  for file in "${active_files[@]}"; do
    process_manifest_file "$type" "$file" || return 1
  done
  ok
}

run_bootstrap_mode() {
  local bootstrap_file="$SOFTWARE_DIR/bootstrap.list"
  local raw line name
  local errors=0

  validate_bootstrap_manifest || return 1

  if [[ "$MODE" == "bootstrap-install" ]]; then
    bot "Installing bootstrap Homebrew formulae"
    process_manifest_file "brew" "$bootstrap_file" || return 1
    ok "Bootstrap Homebrew formulae installed"
    return 0
  fi

  bot "Verifying bootstrap Homebrew formulae"
  while IFS= read -r raw || [[ -n "$raw" ]]; do
    line="$(trim_manifest_line "$raw")"
    [[ -z "$line" ]] && continue
    name="$(brew_manifest_name "$line")"
    if brew list --formula "$name" >/dev/null 2>&1; then
      ok "$name installed"
    else
      error "Missing bootstrap Homebrew formula: $name"
      errors=$((errors + 1))
    fi
  done < "$bootstrap_file"

  if [[ $errors -gt 0 ]]; then
    error "$errors bootstrap Homebrew formula(e) missing"
    return 1
  fi
  ok "Bootstrap Homebrew formulae verified"
}

if [[ "$MODE" == bootstrap-* ]]; then
  run_bootstrap_mode || exit 1
  exit 0
fi

validate_bootstrap_manifest || exit 1
validate_bootstrap_ownership || exit 1

if [[ "$MODE" == "check" ]]; then
  bot "Validating software manifests for profile: $PROFILE"
else
  bot "Installing packages for profile: $PROFILE"
fi

install_type "tap" "Homebrew taps" || exit 1
install_type "brew" "Homebrew utilities" || exit 1
install_type "cask" "Homebrew desktop apps" || exit 1
install_type "npm" "NPM global packages" || exit 1
install_type "mas" "Mac App Store apps" || exit 1
install_type "gem" "Ruby gems" || exit 1
install_type "vscode" "VS Code extensions" || exit 1

if [[ "$MODE" == "check" ]]; then
  ok "Software manifest validation complete for profile: $PROFILE"
else
  ok "Package installation complete for profile: $PROFILE"
fi
