#!/usr/bin/env bash

set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
  printf 'error: not inside a Git repository\n' >&2
  exit 2
}

cd "$repo_root"

if git diff --cached --quiet --; then
  printf 'No staged commit candidate. Stage or identify one before auditing documentation.\n'
  exit 0
fi

declare -a doc_files=()
declare -a shell_files=()
declare -a records=()

is_documentation() {
  case "$1" in
    README | README.* | CHANGELOG | CHANGELOG.* | CONTRIBUTING | CONTRIBUTING.* | docs/* | doc/* | *.md | *.mdx | *.rst | *.adoc | *.txt)
      return 0
      ;;
  esac
  return 1
}

is_shell_script() {
  local path=$1
  local first_line

  case "$path" in
    *.sh | *.bash | *.zsh | *.ksh | *.fish)
      return 0
      ;;
  esac

  first_line=$(git show ":$path" 2>/dev/null | sed -n '1p')
  grep -Eq '^#!.*(ba|z|k)?sh([[:space:]]|$)|^#!.*fish([[:space:]]|$)' <<<"$first_line"
}

while IFS= read -r -d '' path; do
  if is_documentation "$path"; then
    doc_files+=("$path")
  fi
  if is_shell_script "$path"; then
    shell_files+=("$path")
  fi
done < <(git ls-files -z --cached)

while IFS= read -r -d '' status; do
  case "$status" in
    R* | C*)
      IFS= read -r -d '' old_path
      IFS= read -r -d '' new_path
      records+=("$status" "$old_path" "$new_path")
      ;;
    *)
      IFS= read -r -d '' path
      case "$status" in
        A* | D*)
          records+=("$status" "$path" "")
          ;;
      esac
      ;;
  esac
done < <(git diff --cached --name-status -z -M -C --)

if ((${#records[@]} == 0)); then
  printf 'No staged additions, deletions, copies, renames, or moves. No path-reference scan required.\n'
  exit 0
fi

search_files() {
  local label=$1
  local needle=$2
  local exclude=$3
  local matches
  shift 3
  local files=("$@")

  printf '\n%s matches for %q:\n' "$label" "$needle"
  if ((${#files[@]} == 0)); then
    printf '  (no files in scan surface)\n'
    return
  fi

  matches=$(git grep --cached -n -F -e "$needle" -- "${files[@]}" || true)
  if [[ -n $exclude && -n $matches ]]; then
    matches=$(grep -Fv -- "$exclude" <<<"$matches" || true)
  fi

  if [[ -n $matches ]]; then
    printf '%s\n' "$matches"
  else
    printf '  (none)\n'
  fi
}

scan_path() {
  local path=$1
  local basename=${path##*/}

  search_files 'Documentation' "$path" '' "${doc_files[@]}"
  search_files 'Shell script' "$path" '' "${shell_files[@]}"

  if [[ $basename != "$path" ]]; then
    search_files 'Documentation standalone basename' "$basename" "$path" "${doc_files[@]}"
    search_files 'Shell script standalone basename' "$basename" "$path" "${shell_files[@]}"
  fi
}

printf 'Staged structural changes:\n'

index=0
while ((index < ${#records[@]})); do
  status=${records[index]}
  old_path=${records[index + 1]}
  new_path=${records[index + 2]}
  index=$((index + 3))

  if [[ -n $new_path ]]; then
    printf '\n%s  %s -> %s\n' "$status" "$old_path" "$new_path"
    scan_path "$old_path"
    scan_path "$new_path"
  else
    printf '\n%s  %s\n' "$status" "$old_path"
    scan_path "$old_path"
  fi
done

printf '\nReview matches against HEAD plus the staged index. Matches are candidates, not automatic defects.\n'
