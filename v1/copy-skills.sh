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
dry_run=false
while [ "${1:-}" != "" ]; do
  case "$1" in
    --check)
      check_mode=true
      shift
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

[ "$check_mode" = false ] || [ "$dry_run" = false ] ||
  die "--check and --dry-run cannot be combined"
[ "${2:-}" = "" ] || die "too many arguments"

repo_root=$(resolve_repo_root "${1:-}")
repo_root=${repo_root%/}
source_root="$repo_root/v1/skills"
marker=".agent-docs-managed"

[ -d "$source_root" ] || die "missing $source_root"

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

prepare_dest_root() {
  local dest_root=$1

  if [ -L "$dest_root" ]; then
    die "$dest_root is a symlink; refusing to replace a tool-owned skill root"
  elif [ -e "$dest_root" ] && [ ! -d "$dest_root" ]; then
    die "$dest_root exists and is not a directory"
  fi

  if [ "$dry_run" = true ]; then
    [ -d "$dest_root" ] || printf 'would create skill destination %s\n' "$dest_root"
    return
  fi

  mkdir -p "$dest_root"
}

preflight_unmanaged_conflicts() {
  local dest_root=$1
  local skill_dir
  local skill_name
  local dest

  [ -d "$dest_root" ] || return 0

  for skill_dir in "$source_root"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    dest="$dest_root/$skill_name"

    if path_exists "$dest" && [ ! -e "$dest/$marker" ]; then
      die "$dest exists and is not managed by agent-docs"
    fi
  done
}

remove_stale_managed() {
  local dest_root=$1
  local existing
  local name

  [ -d "$dest_root" ] || return 0

  for existing in "$dest_root"/*; do
    path_exists "$existing" || continue
    name=$(basename "$existing")
    if [ -e "$existing/$marker" ] && [ ! -d "$source_root/$name" ]; then
      if [ "$dry_run" = true ]; then
        printf 'would remove stale managed skill %s\n' "$existing"
      else
        rm -rf "$existing"
      fi
    fi
  done
}

copy_managed_skills() {
  local dest_root=$1
  local skill_dir
  local skill_name
  local dest

  for skill_dir in "$source_root"/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    dest="$dest_root/$skill_name"

    if [ "$dry_run" = true ]; then
      if path_exists "$dest"; then
        printf 'would refresh managed skill %s\n' "$dest"
      else
        printf 'would copy managed skill %s\n' "$dest"
      fi
      continue
    fi

    rm -rf "$dest"
    mkdir -p "$dest"
    cp -a "$skill_dir"/. "$dest"/
    printf '%s\n' "$source_root/$skill_name" > "$dest/$marker"
  done
}

copy_into() {
  local dest_root=$1

  prepare_dest_root "$dest_root"
  preflight_unmanaged_conflicts "$dest_root"
  remove_stale_managed "$dest_root"
  copy_managed_skills "$dest_root"

  if [ "$dry_run" = true ]; then
    printf 'dry run complete for %s\n' "$dest_root"
  else
    printf 'copied agent-docs skills to %s\n' "$dest_root"
  fi
}

check_into() {
  local dest_root=$1
  local existing
  local name
  local skill_dir
  local skill_name
  local dest

  [ ! -L "$dest_root" ] ||
    die "$dest_root is a symlink; refusing to check a tool-owned skill root"
  [ -d "$dest_root" ] || die "missing skill destination: $dest_root"

  for existing in "$dest_root"/*; do
    path_exists "$existing" || continue
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
