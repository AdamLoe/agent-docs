#!/usr/bin/env bash
set -euo pipefail

filter=${1:-}
project_root=${AGENT_DOCS_PROJECT_ROOT:-$PWD}
marker=".agent-docs-managed"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
candidate_source_root=$(cd "$script_dir/.." && pwd)
if [ "${AGENT_DOCS_SOURCE_ROOT:-}" != "" ]; then
  source_root=${AGENT_DOCS_SOURCE_ROOT%/}
elif [ -f "$candidate_source_root/registry.md" ]; then
  source_root=$candidate_source_root
else
  source_root="${HOME:?HOME is not set}/.agentdocs/skills"
fi

declare -A seen_source=()
declare -A seen_project=()

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

matches_filter() {
  local name=$1
  local description=$2

  [ "$filter" = "" ] && return 0

  local haystack
  haystack=$(printf '%s\n%s\n' "$name" "$description" | tr '[:upper:]' '[:lower:]')
  local needle
  needle=$(printf '%s' "$filter" | tr '[:upper:]' '[:lower:]')
  [[ "$haystack" == *"$needle"* ]]
}

description_for() {
  local skill_file=$1

  awk '
    /^description:/ {
      sub(/^description:[[:space:]]*/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$skill_file"
}

first_sentence() {
  awk '
    {
      text = $0
      period = index(text, ". ")
      if (period > 0) {
        print substr(text, 1, period)
      } else {
        print text
      }
    }
  '
}

scan_root() {
  local root=$1
  local -n seen=$2
  local -n rows_ref=$3
  local skill_dir skill_file name description

  [ -d "$root" ] || return 0

  for skill_dir in "$root"/*; do
    [ -d "$skill_dir" ] || continue
    skill_file="$skill_dir/SKILL.md"
    [ -f "$skill_file" ] || continue

    name=$(basename "$skill_dir")
    [[ -n ${seen[$name]+set} ]] && continue

    description=$(description_for "$skill_file")
    [ "$description" != "" ] || description="No description."
    matches_filter "$name" "$description" || continue

    seen[$name]=1
    rows_ref+=("$(printf '%s\t%s\n' "$name" "$description" | first_sentence)")
  done
}

print_group() {
  local title=$1
  shift

  local rows=()
  local root name description

  for root in "$@"; do
    scan_root "$root" "$title" rows
  done

  [ "${#rows[@]}" -gt 0 ] || return 0

  case "$title" in
    seen_source) printf '**Source (agent-docs)**\n' ;;
    seen_project) printf '**Project**\n' ;;
  esac

  printf '%s\n' "${rows[@]}" |
    sort -f |
    while IFS=$'\t' read -r name description; do
      printf -- '- `/%s` — %s\n' "$name" "$description"
    done
  printf '\n'
}

adapter_status() {
  local label=$1
  local root=$2
  local source_count=0
  local issue_count=0
  local examples=()
  local skill_dir skill_name dest existing name

  if [ -L "$root" ]; then
    printf -- '- %s `%s`: conflict (skill root is a symlink)\n' "$label" "$root"
    return 0
  fi

  if [ ! -d "$root" ]; then
    printf -- '- %s `%s`: missing destination\n' "$label" "$root"
    return 0
  fi

  for existing in "$root"/*; do
    path_exists "$existing" || continue
    name=$(basename "$existing")
    if [ -e "$existing/$marker" ] && [ ! -d "$source_root/$name" ]; then
      issue_count=$((issue_count + 1))
      [ "${#examples[@]}" -lt 3 ] && examples+=("stale:$name")
    fi
  done

  for skill_dir in "$source_root"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    dest="$root/$skill_name"
    source_count=$((source_count + 1))

    if [ ! -d "$dest" ]; then
      issue_count=$((issue_count + 1))
      [ "${#examples[@]}" -lt 3 ] && examples+=("missing:$skill_name")
    elif [ ! -e "$dest/$marker" ]; then
      issue_count=$((issue_count + 1))
      [ "${#examples[@]}" -lt 3 ] && examples+=("unmanaged:$skill_name")
    elif ! diff -qr --exclude="$marker" "$skill_dir" "$dest" >/dev/null; then
      issue_count=$((issue_count + 1))
      [ "${#examples[@]}" -lt 3 ] && examples+=("stale:$skill_name")
    fi
  done

  if [ "$issue_count" -eq 0 ]; then
    printf -- '- %s `%s`: fresh (%s source skills)\n' "$label" "$root" "$source_count"
  else
    printf -- '- %s `%s`: %s issue(s)' "$label" "$root" "$issue_count"
    if [ "${#examples[@]}" -gt 0 ]; then
      printf ' (%s)' "$(IFS=', '; printf '%s' "${examples[*]}")"
    fi
    printf '\n'
  fi
}

if [ ! -d "$source_root" ]; then
  printf 'Missing source skill root: `%s`\n' "$source_root"
  exit 1
fi

print_group seen_source "$source_root"

print_group seen_project \
  "$project_root/.agents/skills" \
  "$project_root/.claude/skills"

printf '**Installed adapter freshness**\n'
adapter_status "Codex" "${HOME:?HOME is not set}/.agents/skills"
adapter_status "Claude" "${HOME:?HOME is not set}/.claude/skills"
printf '\n'
printf 'Source of truth: agent-docs skills live in `~/.agentdocs/skills/`; Claude reads copied skills in `~/.claude/skills/` and Codex reads copied skills in `~/.agents/skills/`. Project skills live in the repo `.agents/skills/` or `.claude/skills/` directories.\n'
