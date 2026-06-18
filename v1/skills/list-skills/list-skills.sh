#!/usr/bin/env bash
set -euo pipefail

filter=${1:-}
project_root=${AGENT_DOCS_PROJECT_ROOT:-$PWD}

declare -A seen_global=()
declare -A seen_project=()

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
    seen_global) printf '**Global (agent-docs)**\n' ;;
    seen_project) printf '**Project**\n' ;;
  esac

  printf '%s\n' "${rows[@]}" |
    sort -f |
    while IFS=$'\t' read -r name description; do
      printf -- '- `/%s` — %s\n' "$name" "$description"
    done
  printf '\n'
}

print_group seen_global \
  "${HOME:?HOME is not set}/.agents/skills" \
  "${HOME:?HOME is not set}/.claude/skills"

print_group seen_project \
  "$project_root/.agents/skills" \
  "$project_root/.claude/skills"

printf 'Source of truth: agent-docs global skills live in `~/agent-docs/v1/skills/`; Claude reads copied skills in `~/.claude/skills/` and Codex reads copied skills in `~/.agents/skills/`. Project skills live in the repo `.agents/skills/` or `.claude/skills/` directories.\n'
