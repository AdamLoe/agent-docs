#!/usr/bin/env bash
set -euo pipefail

# Dogfood/development installer: publishes the local src/ bundle to the global
# runtime at ~/.agentdocs/ and refreshes the managed Claude/Codex skill copies.
# Editing files in this checkout does not affect other projects until this runs.

die() {
  printf 'install-agentdocs-local.sh: %s\n' "$*" >&2
  exit 1
}

resolve_repo_root() {
  local script_dir
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  if git -C "$script_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$script_dir" rev-parse --show-toplevel
    return
  fi

  printf '%s\n' "$script_dir"
}

dry_run=false
while [ "${1:-}" != "" ]; do
  case "$1" in
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

[ "${1:-}" = "" ] || die "too many arguments"

repo_root=$(resolve_repo_root)
repo_root=${repo_root%/}
src_root="$repo_root/src"

# Files and directories the runtime bundle must contain.
bundle_dirs=(skills rules template)
bundle_files=(
  agent-docs-guide.md
  plan-lifecycle.md
  plan-template.md
  install-agentdocs.sh
  verify-agent-docs.sh
)

for dir in "${bundle_dirs[@]}"; do
  [ -d "$src_root/$dir" ] || die "missing source directory: src/$dir"
done
for file in "${bundle_files[@]}"; do
  [ -f "$src_root/$file" ] || die "missing source file: src/$file"
done

home_dir=${HOME:?HOME is not set}
runtime_root="$home_dir/.agentdocs"
marker=".agent-docs-managed"
manifest_file="$runtime_root/.agentdocs-install-manifest"
claude_dest="$home_dir/.claude/skills"
codex_dest="$home_dir/.agents/skills"

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

# --- runtime bundle replacement -------------------------------------------

replace_runtime() {
  if [ -L "$runtime_root" ]; then
    die "$runtime_root is a symlink; refusing to replace a linked runtime root"
  fi
  if path_exists "$runtime_root" && [ ! -d "$runtime_root" ]; then
    die "$runtime_root exists and is not a directory"
  fi

  if [ "$dry_run" = true ]; then
    printf 'would replace runtime bundle at %s with %s\n' "$runtime_root" "$src_root"
    if [ -f "$runtime_root/feedback.jsonl" ]; then
      printf 'would preserve feedback.jsonl across runtime replace\n'
    fi
    return
  fi

  local staging feedback_backup=""
  staging=$(mktemp -d "${TMPDIR:-/tmp}/agentdocs-local.XXXXXX")

  if [ -f "$runtime_root/feedback.jsonl" ]; then
    feedback_backup=$(mktemp "${TMPDIR:-/tmp}/agentdocs-feedback.XXXXXX")
    cp -a "$runtime_root/feedback.jsonl" "$feedback_backup"
  fi

  local dir file
  for dir in "${bundle_dirs[@]}"; do
    cp -a "$src_root/$dir" "$staging/$dir"
  done
  for file in "${bundle_files[@]}"; do
    cp -a "$src_root/$file" "$staging/$file"
  done

  rm -rf "$runtime_root"
  mkdir -p "$(dirname "$runtime_root")"
  mv "$staging" "$runtime_root"

  if [ -n "$feedback_backup" ]; then
    mv "$feedback_backup" "$runtime_root/feedback.jsonl"
  fi
}

write_install_manifest() {
  if [ "$dry_run" = true ]; then
    printf 'would write install manifest %s (source kind: local)\n' "$manifest_file"
    return
  fi

  {
    printf 'source_kind: local\n'
    printf 'source_path: %s\n' "$src_root"
    printf 'installed_at: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$manifest_file"
}

# --- managed skill refresh (mirrors the prior copy-skills.sh contract) -----

source_skills_root() {
  printf '%s\n' "$runtime_root/skills"
}

prepare_dest_root() {
  local dest_root=$1

  if [ -L "$dest_root" ]; then
    die "$dest_root is a symlink; refusing to replace a tool-owned skill root"
  elif path_exists "$dest_root" && [ ! -d "$dest_root" ]; then
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
  local skills_root=$2
  local skill_dir skill_name dest

  [ -d "$dest_root" ] || return 0

  for skill_dir in "$skills_root"/*/; do
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
  local skills_root=$2
  local existing name

  [ -d "$dest_root" ] || return 0

  for existing in "$dest_root"/*; do
    path_exists "$existing" || continue
    name=$(basename "$existing")
    if [ -e "$existing/$marker" ] && [ ! -d "$skills_root/$name" ]; then
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
  local skills_root=$2
  local skill_dir skill_name dest

  for skill_dir in "$skills_root"/*/; do
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
    printf '%s\n' "$skills_root/$skill_name" > "$dest/$marker"
  done
}

refresh_into() {
  local dest_root=$1
  local skills_root
  skills_root=$(source_skills_root)

  prepare_dest_root "$dest_root"
  preflight_unmanaged_conflicts "$dest_root" "$skills_root"
  remove_stale_managed "$dest_root" "$skills_root"
  copy_managed_skills "$dest_root" "$skills_root"

  if [ "$dry_run" = true ]; then
    printf 'dry run complete for %s\n' "$dest_root"
  else
    printf 'refreshed agent-docs skills in %s\n' "$dest_root"
  fi
}

# --- run -------------------------------------------------------------------

replace_runtime
write_install_manifest

# On a dry run the runtime bundle is not present; refresh from the live src/
# skills so planned actions stay accurate without mutating anything.
if [ "$dry_run" = true ]; then
  source_skills_root() { printf '%s\n' "$src_root/skills"; }
fi

refresh_into "$codex_dest"
refresh_into "$claude_dest"

if [ "$dry_run" = true ]; then
  printf 'local install dry run complete\n'
else
  printf 'agent-docs local install complete: %s\n' "$runtime_root"
fi
