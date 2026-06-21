#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'export-chatgpt-context.sh: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  bash export-chatgpt-context.sh [--output-dir <dir>]
  bash export-chatgpt-context.sh --stdout
  bash export-chatgpt-context.sh --list-groups

Exports this repo as Markdown chunks that can be pasted into ChatGPT for
planning. By default, files are written under chatgpt-context-export/.

Options:
  --output-dir <dir>     Directory for generated Markdown chunks.
  --stdout              Print all chunks to stdout instead of writing files.
  --include-untracked   Include untracked, non-ignored files.
  --list-groups         Print the export group names and exit.
  -h, --help            Show this help.
EOF
}

resolve_repo_root() {
  local script_dir
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

  if git -C "$script_dir" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$script_dir" rev-parse --show-toplevel
    return
  fi

  cd "$script_dir/.." && pwd
}

repo_root=$(resolve_repo_root)
repo_root=${repo_root%/}
output_dir="$repo_root/chatgpt-context-export"
stdout=false
include_untracked=false
list_groups=false

while [ "${1:-}" != "" ]; do
  case "$1" in
    --output-dir)
      [ "${2:-}" != "" ] || die "--output-dir needs a value"
      output_dir=$2
      shift 2
      ;;
    --stdout)
      stdout=true
      shift
      ;;
    --include-untracked)
      include_untracked=true
      shift
      ;;
    --list-groups)
      list_groups=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      die "unexpected argument: $1"
      ;;
  esac
done

case "$output_dir" in
  /*) ;;
  *) output_dir="$repo_root/$output_dir" ;;
esac
output_dir=${output_dir%/}

group_ids="
00-top-level
01-docs-root-and-meta
02-agent-context
03-architecture
04-decisions
05-plans
06-agent-docs-guide
07-src-top-level
08-rules
09-orchestrator-rules
10-subagent-rules
11-skills
12-template
13-other
"

group_title() {
  case "$1" in
    00-top-level) printf 'Top-Level Files' ;;
    01-docs-root-and-meta) printf 'Docs Root And Metadata' ;;
    02-agent-context) printf 'Agent Context' ;;
    03-architecture) printf 'Architecture' ;;
    04-decisions) printf 'Decisions' ;;
    05-plans) printf 'Plans' ;;
    06-agent-docs-guide) printf 'Agent Docs Guide' ;;
    07-src-top-level) printf 'src Top-Level Files' ;;
    08-rules) printf 'Rules' ;;
    09-orchestrator-rules) printf 'Orchestrator Rules' ;;
    10-subagent-rules) printf 'Subagent Rules' ;;
    11-skills) printf 'Skills' ;;
    12-template) printf 'Template' ;;
    13-other) printf 'Other Files' ;;
    *) printf '%s' "$1" ;;
  esac
}

classify_path() {
  case "$1" in
    */*)
      case "$1" in
        docs/_meta/*|docs/index.md|docs/overview.md|docs/repository-layout.md)
          printf '01-docs-root-and-meta'
          ;;
        docs/agent-context/*)
          printf '02-agent-context'
          ;;
        docs/architecture/*)
          printf '03-architecture'
          ;;
        docs/decisions/*)
          printf '04-decisions'
          ;;
        docs/plans/*)
          printf '05-plans'
          ;;
        src/agent-docs-guide.md)
          printf '06-agent-docs-guide'
          ;;
        src/rules/orchestrator/*)
          printf '09-orchestrator-rules'
          ;;
        src/rules/subagent/*)
          printf '10-subagent-rules'
          ;;
        src/rules/*)
          printf '08-rules'
          ;;
        src/skills/*)
          printf '11-skills'
          ;;
        src/template/*)
          printf '12-template'
          ;;
        src/*)
          printf '07-src-top-level'
          ;;
        *)
          printf '13-other'
          ;;
      esac
      ;;
    *)
      printf '00-top-level'
      ;;
  esac
}

language_for_path() {
  case "$1" in
    *.sh) printf 'bash' ;;
    *.md) printf 'markdown' ;;
    *.json) printf 'json' ;;
    *.jsonl) printf 'jsonl' ;;
    *.yml|*.yaml) printf 'yaml' ;;
    *.toml) printf 'toml' ;;
    *.py) printf 'python' ;;
    *.rs) printf 'rust' ;;
    *.js) printf 'javascript' ;;
    *.ts) printf 'typescript' ;;
    *.tsx) printf 'tsx' ;;
    *.css) printf 'css' ;;
    *) printf 'text' ;;
  esac
}

fence_for_file() {
  awk '
    {
      line = $0
      while (match(line, /~+/)) {
        if (RLENGTH > max) {
          max = RLENGTH
        }
        line = substr(line, RSTART + RLENGTH)
      }
    }
    END {
      n = max + 1
      if (n < 3) {
        n = 3
      }
      for (i = 0; i < n; i++) {
        printf "~"
      }
      printf "\n"
    }
  ' "$1"
}

path_is_text() {
  local abs_path=$1

  [ ! -s "$abs_path" ] && return 0
  LC_ALL=C grep -Iq . "$abs_path"
}

render_file() {
  local path=$1
  local abs_path="$repo_root/$path"
  local fence
  local language
  local bytes

  bytes=$(wc -c < "$abs_path" | tr -d ' ')
  printf '## `%s`\n\n' "$path"
  printf '_Bytes: %s_\n\n' "$bytes"

  if ! path_is_text "$abs_path"; then
    printf '_Binary file omitted._\n\n'
    return
  fi

  fence=$(fence_for_file "$abs_path")
  language=$(language_for_path "$path")
  printf '%s%s\n' "$fence" "$language"
  sed -n '1,$p' "$abs_path"
  printf '\n%s\n\n' "$fence"
}

render_group() {
  local group_id=$1
  local path_list=$2
  local title
  local path

  [ -s "$path_list" ] || return 0

  title=$(group_title "$group_id")
  printf '# agent-docs ChatGPT Context: %s\n\n' "$title"
  printf 'Source repo: `%s`\n\n' "$repo_root"
  printf 'Paste this chunk into ChatGPT as source context for planning. Treat file paths as authoritative and prefer current file contents over summaries.\n\n'
  printf 'Included files:\n\n'
  while IFS= read -r path; do
    printf -- '- `%s`\n' "$path"
  done < "$path_list"
  printf '\n'

  while IFS= read -r path; do
    render_file "$path"
  done < "$path_list"
}

print_group_list() {
  local group_id

  for group_id in $group_ids; do
    printf '%s\t%s\n' "$group_id" "$(group_title "$group_id")"
  done
}

if [ "$list_groups" = true ]; then
  print_group_list
  exit 0
fi

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/agent-docs-context.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

for group_id in $group_ids; do
  : > "$tmp_dir/$group_id.paths"
done

all_paths="$tmp_dir/all.paths"
git -C "$repo_root" ls-files > "$all_paths"
if [ "$include_untracked" = true ]; then
  git -C "$repo_root" ls-files --others --exclude-standard >> "$all_paths"
fi

output_rel=
case "$output_dir/" in
  "$repo_root"/*)
    output_rel=${output_dir#"$repo_root"/}
    ;;
esac

sort -u "$all_paths" | while IFS= read -r path; do
  [ -n "$path" ] || continue
  [ -f "$repo_root/$path" ] || continue

  if [ "$output_rel" != "" ]; then
    case "$path" in
      "$output_rel"|"$output_rel"/*) continue ;;
    esac
  fi

  group_id=$(classify_path "$path")
  printf '%s\n' "$path" >> "$tmp_dir/$group_id.paths"
done

if [ "$stdout" = true ]; then
  first=true
  for group_id in $group_ids; do
    [ -s "$tmp_dir/$group_id.paths" ] || continue
    if [ "$first" = false ]; then
      printf -- '\n---\n\n'
    fi
    first=false
    render_group "$group_id" "$tmp_dir/$group_id.paths"
  done
  exit 0
fi

mkdir -p "$output_dir"

index_path="$output_dir/README.md"
{
  printf '# agent-docs ChatGPT Context Export\n\n'
  printf 'Generated from `%s`.\n\n' "$repo_root"
  printf 'Paste one or more chunks into ChatGPT for planning. Start with `00-top-level.md`, `01-docs-root-and-meta.md`, and the task-relevant chunk, then add more chunks as needed.\n\n'
  printf '## Chunks\n\n'
  for group_id in $group_ids; do
    [ -s "$tmp_dir/$group_id.paths" ] || continue
    printf -- '- [`%s.md`](%s.md) - %s\n' "$group_id" "$group_id" "$(group_title "$group_id")"
  done
} > "$index_path"

for group_id in $group_ids; do
  [ -s "$tmp_dir/$group_id.paths" ] || continue
  render_group "$group_id" "$tmp_dir/$group_id.paths" > "$output_dir/$group_id.md"
done

printf 'wrote ChatGPT context export to %s\n' "$output_dir"
