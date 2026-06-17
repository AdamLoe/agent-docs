#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'copy-skills.sh: %s\n' "$*" >&2
  exit 1
}

resolve_repo_root() {
  if [ "${1:-}" != "" ]; then
    cd "$1" && pwd
    return
  fi

  git -C "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" rev-parse --show-toplevel
}

check_mode=false
if [ "${1:-}" = "--check" ]; then
  check_mode=true
  shift
fi

repo_root=$(resolve_repo_root "${1:-}")
repo_root=${repo_root%/}
source_root="$repo_root/v1/skills"
marker=".agent-docs-managed"

[ -d "$source_root" ] || die "missing $source_root"

copy_into() {
  local dest_root=$1

  if [ -L "$dest_root" ]; then
    rm "$dest_root"
  elif [ -e "$dest_root" ] && [ ! -d "$dest_root" ]; then
    die "$dest_root exists and is not a directory"
  fi

  mkdir -p "$dest_root"

  for existing in "$dest_root"/*; do
    [ -e "$existing" ] || continue
    name=$(basename "$existing")
    if [ -e "$existing/$marker" ] && [ ! -d "$source_root/$name" ]; then
      rm -rf "$existing"
    fi
  done

  for skill_dir in "$source_root"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    dest="$dest_root/$skill_name"

    if [ -e "$dest" ] && [ ! -e "$dest/$marker" ]; then
      die "$dest exists and is not managed by agent-docs"
    fi

    rm -rf "$dest"
    mkdir -p "$dest"
    cp -a "$skill_dir"/. "$dest"/
    printf '%s\n' "$source_root/$skill_name" > "$dest/$marker"
  done

  printf 'copied agent-docs skills to %s\n' "$dest_root"
}

check_into() {
  local dest_root=$1

  [ -d "$dest_root" ] || die "missing skill destination: $dest_root"

  for existing in "$dest_root"/*; do
    [ -e "$existing" ] || continue
    name=$(basename "$existing")
    if [ -e "$existing/$marker" ] && [ ! -d "$source_root/$name" ]; then
      die "$existing is managed by agent-docs but no matching source skill exists"
    fi
  done

  for skill_dir in "$source_root"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    dest="$dest_root/$skill_name"

    [ -d "$dest" ] || die "missing copied skill: $dest"
    [ -e "$dest/$marker" ] || die "$dest exists but is not managed by agent-docs"
    diff -qr --exclude="$marker" "$skill_dir" "$dest" >/dev/null ||
      die "$dest is stale; run copy-skills.sh"
  done

  printf 'agent-docs skills are fresh in %s\n' "$dest_root"
}

if [ "${AGENT_DOCS_SKILLS_DEST:-}" != "" ]; then
  if [ "$check_mode" = true ]; then
    check_into "$AGENT_DOCS_SKILLS_DEST"
  else
    copy_into "$AGENT_DOCS_SKILLS_DEST"
  fi
else
  home_dir=${HOME:?HOME is not set}
  if [ "$check_mode" = true ]; then
    check_into "$home_dir/.agents/skills"
    check_into "$home_dir/.claude/skills"
  else
    copy_into "$home_dir/.agents/skills"
    copy_into "$home_dir/.claude/skills"
  fi
fi
