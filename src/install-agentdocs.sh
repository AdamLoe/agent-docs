#!/usr/bin/env bash
set -euo pipefail

# Normal user install/update path: downloads an agent-docs bundle from GitHub
# and publishes it to the global runtime at ~/.agentdocs/, then refreshes the
# managed Claude/Codex skill copies. Install and update are the same operation.
#
# Runs both from a source checkout (src/install-agentdocs.sh) and from the
# installed runtime (~/.agentdocs/install-agentdocs.sh); it is self-contained so
# the installed copy needs nothing else from the bundle.

repo_slug="AdamLoe/agent-docs"
default_ref="main"

die() {
  printf 'install-agentdocs.sh: %s\n' "$*" >&2
  exit 1
}

dry_run=false
ref=""
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
      [ -z "$ref" ] || die "too many arguments"
      ref=$1
      shift
      ;;
  esac
done

[ "${1:-}" = "" ] || die "too many arguments"

home_dir=${HOME:?HOME is not set}
runtime_root="$home_dir/.agentdocs"
marker=".agent-docs-managed"
manifest_file="$runtime_root/.agentdocs-install-manifest"
claude_dest="$home_dir/.claude/skills"
codex_dest="$home_dir/.agents/skills"

bundle_dirs=(skills rules template)
bundle_files=(
  agent-docs-guide.md
  plan-lifecycle.md
  plan-template.md
  install-agentdocs.sh
  verify-agent-docs.sh
)

# A tag arg installs that tag archive; otherwise install the default branch as
# "latest". This is the simplest reliable resolution: the codeload archive needs
# no published release and no GitHub API.
if [ -n "$ref" ]; then
  archive_url="https://github.com/$repo_slug/archive/refs/tags/$ref.tar.gz"
  source_label="$ref"
else
  archive_url="https://github.com/$repo_slug/archive/refs/heads/$default_ref.tar.gz"
  source_label="$default_ref"
fi

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

# --- download + validate ---------------------------------------------------

download_archive() {
  local dest_archive=$1

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$archive_url" -o "$dest_archive" ||
      die "download failed: $archive_url"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$archive_url" -O "$dest_archive" ||
      die "download failed: $archive_url"
  else
    die "need curl or wget to download $archive_url"
  fi
}

# The tag archive expands to a single agent-docs-<ref>/ top-level dir holding the
# source checkout; the runtime bundle lives under its src/.
locate_src_root() {
  local extract_dir=$1
  local top

  top=$(find "$extract_dir" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  [ -n "$top" ] || die "downloaded archive has no top-level directory"
  [ -d "$top/src" ] || die "downloaded archive missing src/ bundle"
  printf '%s\n' "$top/src"
}

validate_bundle_shape() {
  local src_root=$1
  local dir file

  for dir in "${bundle_dirs[@]}"; do
    [ -d "$src_root/$dir" ] || die "downloaded bundle missing src/$dir"
  done
  for file in "${bundle_files[@]}"; do
    [ -f "$src_root/$file" ] || die "downloaded bundle missing src/$file"
  done
}

# --- runtime bundle replacement -------------------------------------------

stage_runtime() {
  local src_root=$1
  local staging=$2
  local dir file

  for dir in "${bundle_dirs[@]}"; do
    cp -a "$src_root/$dir" "$staging/$dir"
  done
  for file in "${bundle_files[@]}"; do
    cp -a "$src_root/$file" "$staging/$file"
  done
}

replace_runtime() {
  local staging=$1

  if [ -L "$runtime_root" ]; then
    die "$runtime_root is a symlink; refusing to replace a linked runtime root"
  fi
  if path_exists "$runtime_root" && [ ! -d "$runtime_root" ]; then
    die "$runtime_root exists and is not a directory"
  fi

  local feedback_backup=""
  if [ -f "$runtime_root/feedback.jsonl" ]; then
    feedback_backup=$(mktemp "${TMPDIR:-/tmp}/agentdocs-feedback.XXXXXX")
    cp -a "$runtime_root/feedback.jsonl" "$feedback_backup"
  fi

  rm -rf "$runtime_root"
  mkdir -p "$(dirname "$runtime_root")"
  mv "$staging" "$runtime_root"

  if [ -n "$feedback_backup" ]; then
    mv "$feedback_backup" "$runtime_root/feedback.jsonl"
  fi
}

write_install_manifest() {
  {
    printf 'source_kind: github\n'
    printf 'source_tag: %s\n' "$source_label"
    printf 'source_url: %s\n' "$archive_url"
    printf 'installed_at: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } > "$manifest_file"
}

# --- managed skill refresh (self-contained; same contract as the bundle) ---

prepare_dest_root() {
  local dest_root=$1

  if [ -L "$dest_root" ]; then
    die "$dest_root is a symlink; refusing to replace a tool-owned skill root"
  elif path_exists "$dest_root" && [ ! -d "$dest_root" ]; then
    die "$dest_root exists and is not a directory"
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
      rm -rf "$existing"
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

    rm -rf "$dest"
    mkdir -p "$dest"
    cp -a "$skill_dir"/. "$dest"/
    printf '%s\n' "$skills_root/$skill_name" > "$dest/$marker"
  done
}

refresh_into() {
  local dest_root=$1
  local skills_root="$runtime_root/skills"

  prepare_dest_root "$dest_root"
  preflight_unmanaged_conflicts "$dest_root" "$skills_root"
  remove_stale_managed "$dest_root" "$skills_root"
  copy_managed_skills "$dest_root" "$skills_root"
  printf 'refreshed agent-docs skills in %s\n' "$dest_root"
}

# --- run -------------------------------------------------------------------

if [ "$dry_run" = true ]; then
  # Offline: describe planned actions only, touch nothing.
  printf 'would download bundle (source kind: github, ref: %s)\n' "$source_label"
  printf '  from: %s\n' "$archive_url"
  printf 'would validate bundle shape: %s + %s\n' \
    "${bundle_dirs[*]}" "${bundle_files[*]}"
  printf 'would replace runtime bundle at %s\n' "$runtime_root"
  if [ -f "$runtime_root/feedback.jsonl" ]; then
    printf 'would preserve feedback.jsonl across runtime replace\n'
  fi
  printf 'would write install manifest %s (source kind: github, ref: %s)\n' \
    "$manifest_file" "$source_label"
  printf 'would refresh managed skills in %s and %s from %s/skills\n' \
    "$codex_dest" "$claude_dest" "$runtime_root"
  printf 'would remove stale managed skills no longer in the bundle\n'
  printf 'github install dry run complete\n'
  exit 0
fi

workdir=$(mktemp -d "${TMPDIR:-/tmp}/agentdocs-github.XXXXXX")
cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

archive="$workdir/bundle.tar.gz"
extract_dir="$workdir/extract"
mkdir -p "$extract_dir"

download_archive "$archive"
tar -xzf "$archive" -C "$extract_dir" || die "failed to extract $archive"

src_root=$(locate_src_root "$extract_dir")
validate_bundle_shape "$src_root"

staging="$workdir/staging"
mkdir -p "$staging"
stage_runtime "$src_root" "$staging"
replace_runtime "$staging"
write_install_manifest

refresh_into "$codex_dest"
refresh_into "$claude_dest"

printf 'agent-docs github install complete: %s (%s)\n' "$runtime_root" "$source_label"
