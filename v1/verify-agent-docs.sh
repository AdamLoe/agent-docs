#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'GATE FAIL: %s\n' "$*" >&2
  exit 1
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

require_file() {
  local path=$1
  [ -f "$repo_root/$path" ] || fail "missing required file: $path"
}

require_dir() {
  local path=$1
  [ -d "$repo_root/$path" ] || fail "missing required directory: $path"
}

require_executable() {
  local path=$1
  [ -x "$repo_root/$path" ] || fail "missing executable script: $path"
}

require_git_executable_mode() {
  local path=$1
  local mode

  git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
    return 0
  git -C "$repo_root" ls-files --error-unmatch -- "$path" >/dev/null 2>&1 ||
    return 0

  mode=$(git -C "$repo_root" ls-files --stage -- "$path" | awk '{ print $1; exit }')
  [ "$mode" = "100755" ] ||
    fail "Git index must record executable script: $path"
}

find_python_cmd() {
  if command -v python3 >/dev/null 2>&1; then
    printf 'python3\n'
  elif command -v python >/dev/null 2>&1; then
    printf 'python\n'
  fi
}

require_doc_route() {
  local index_path=$1
  local target=$2
  local label=$3

  grep -Fq "[\`$target\`]($target)" "$repo_root/$index_path" ||
    fail "$label index missing route to $target"
}

require_manifest_change_to_doc() {
  local manifest_path=$1
  local surface=$2
  local owning_doc=$3
  local label=$4

  grep -Fq "| $surface | $owning_doc |" "$repo_root/$manifest_path" ||
    fail "$label missing change-to-doc row for $surface"
}

require_ownership_surface_path() {
  local ownership_path=$1
  local surface=$2
  local owner_path=$3
  local label=$4
  local python_cmd

  if command -v jq >/dev/null 2>&1; then
    jq -e --arg surface "$surface" --arg owner_path "$owner_path" '
      any(.owners[]?; .surface == $surface and ((.paths // []) | index($owner_path) != null))
    ' "$repo_root/$ownership_path" >/dev/null ||
      fail "$label ownership missing surface '$surface' path '$owner_path'"
    return
  fi

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] ||
    fail "cannot validate $label ownership; install jq or python"

  if ! "$python_cmd" - "$repo_root/$ownership_path" "$surface" "$owner_path" <<'PY'
import json
import sys

json_path, surface, owner_path = sys.argv[1:]
with open(json_path, "r", encoding="utf-8") as handle:
    data = json.load(handle)

owners = data.get("owners")
if not isinstance(owners, list):
    raise SystemExit(1)

for owner in owners:
    if not isinstance(owner, dict) or owner.get("surface") != surface:
        continue
    paths = owner.get("paths")
    if isinstance(paths, list) and owner_path in paths:
        raise SystemExit(0)

raise SystemExit(1)
PY
  then
    fail "$label ownership missing surface '$surface' path '$owner_path'"
  fi
}

manifest="$repo_root/docs/_meta/manifest.md"
ownership="$repo_root/docs/_meta/ownership.json"

require_file "docs/index.md"
require_file "docs/overview.md"
require_file "docs/repository-layout.md"
require_file "docs/_meta/manifest.md"
require_file "docs/_meta/ownership.json"
require_file "v1/template/docs/index.md"
require_file "v1/template/docs/repository-layout.md"
require_file "v1/template/docs/_meta/manifest.md"
require_file "v1/template/docs/_meta/ownership.json"
require_dir "docs/architecture"
require_dir "docs/decisions"
require_dir "docs/agent-context"
require_dir "docs/plans"

for scalar_slot in repo_name agent_docs_version code_root; do
  grep -Eq "^${scalar_slot}:[[:space:]]*[^[:space:]]+" "$manifest" ||
    fail "manifest missing slot '$scalar_slot'"
done

for section_slot in change-to-doc drift-gates drift-verification decisions-domains; do
  grep -Eq "^## ${section_slot}[[:space:]]*$" "$manifest" ||
    fail "manifest missing slot '$section_slot'"
done

grep -Fq 'bash v1/verify-agent-docs.sh' "$manifest" ||
  fail "manifest drift-gates must call bash v1/verify-agent-docs.sh"

require_doc_route "docs/index.md" "repository-layout.md" "docs"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Repository layout inventory" \
  "docs/repository-layout.md" \
  "docs/_meta/manifest.md"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "repository-layout" \
  "docs/repository-layout.md" \
  "docs/_meta/ownership.json"
require_doc_route "v1/template/docs/index.md" "repository-layout.md" "template docs"
require_manifest_change_to_doc \
  "v1/template/docs/_meta/manifest.md" \
  "Repository layout inventory" \
  "docs/repository-layout.md" \
  "v1/template/docs/_meta/manifest.md"
require_ownership_surface_path \
  "v1/template/docs/_meta/ownership.json" \
  "repository-layout" \
  "docs/repository-layout.md" \
  "v1/template/docs/_meta/ownership.json"

ownership_paths=$(mktemp "${TMPDIR:-/tmp}/agent-docs-ownership.XXXXXX")
trap 'rm -f "$ownership_paths"' EXIT

if command -v jq >/dev/null 2>&1; then
  jq -e '.owners | type == "array"' "$ownership" >/dev/null ||
    fail "ownership.json missing owners array"
  jq -r '.owners[].paths[]?' "$ownership" > "$ownership_paths" ||
    fail "ownership.json failed to parse"
else
  python_cmd=$(find_python_cmd)

  [ -n "$python_cmd" ] ||
    fail "cannot validate ownership.json; install jq or python"

  if ! "$python_cmd" - "$ownership" > "$ownership_paths" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    data = json.load(handle)

owners = data.get("owners")
if not isinstance(owners, list):
    raise SystemExit("owners must be an array")

for index, owner in enumerate(owners):
    if not isinstance(owner, dict):
        raise SystemExit(f"owner {index} must be an object")
    paths = owner.get("paths")
    if not isinstance(paths, list):
        raise SystemExit(f"owner {index} paths must be an array")
    for owner_path in paths:
        if not isinstance(owner_path, str) or not owner_path:
            raise SystemExit(f"owner {index} has an invalid path")
        print(owner_path)
PY
  then
    fail "ownership.json failed to parse"
  fi
fi

[ -s "$ownership_paths" ] || fail "ownership.json has no owner paths"
while IFS= read -r owner_path; do
  [ -n "$owner_path" ] || fail "ownership.json contains an empty owner path"
  case "$owner_path" in
    /*) fail "ownership path must be repo-relative: $owner_path" ;;
  esac
  normalized_path=${owner_path%/}
  [ -e "$repo_root/$normalized_path" ] ||
    fail "ownership path does not exist: $owner_path"
done < "$ownership_paths"

require_file "v1/skills/registry.md"

skill_count=0
for skill_file in "$repo_root"/v1/skills/*/SKILL.md; do
  [ -e "$skill_file" ] || continue
  skill_count=$((skill_count + 1))
  skill_dir=$(basename "$(dirname "$skill_file")")
  frontmatter_name=$(
    awk -F': *' '
      /^---$/ { fence += 1; next }
      fence == 1 && /^name:[[:space:]]*/ { print $2; exit }
    ' "$skill_file"
  )

  [ "$frontmatter_name" = "$skill_dir" ] ||
    fail "name mismatch in v1/skills/$skill_dir/SKILL.md"
  grep -Fq "| \`$skill_dir\` |" "$repo_root/v1/skills/registry.md" ||
    fail "registry missing skill: $skill_dir"
done
[ "$skill_count" -gt 0 ] || fail "no skill definitions found under v1/skills"

require_file "v1/rules/skill-contracts.md"
grep -Fq 'review-[none|low|medium|high|max]' "$repo_root/v1/rules/skill-contracts.md" ||
  fail "review dial vocabulary missing"
grep -Fq 'cost-[low|medium|high|max]' "$repo_root/v1/rules/skill-contracts.md" ||
  fail "cost dial vocabulary missing"

require_file "v1/rules/orchestrating.md"
for dial in cost-low cost-medium cost-high cost-max review-none review-high; do
  grep -Fq "$dial" "$repo_root/v1/rules/orchestrating.md" ||
    fail "orchestration dial '$dial' missing"
done

adapter_doc="$repo_root/docs/architecture/install-and-adapters.md"
grep -Fq '~/.claude/skills/<name>' "$adapter_doc" ||
  fail "claude copy target undocumented"
grep -Fq '~/.agents/skills/<name>' "$adapter_doc" ||
  fail "codex copy target undocumented"

candidate_files() {
  find "$repo_root/README.md" "$repo_root/docs" "$repo_root/v1" \
    \( -path "$repo_root/v1/verify-agent-docs.sh" -o -path "$repo_root/v1/.claude-plugin" \) -prune -o \
    -type f -print
}

reject_any_match() {
  local pattern=$1
  local message=$2
  local file
  local match

  while IFS= read -r file; do
    match=$(grep -IEn -m 1 "$pattern" "$file" || true)
    [ -z "$match" ] ||
      fail "$message: ${file#$repo_root/}:$match"
  done < <(candidate_files)
}

allow_retired_reference() {
  local relative_file=$1
  local label=$2
  local line_text=$3

  case "$label|$relative_file|$line_text" in
    'new-project-prompt|v1/agent-docs-guide.md|`v1/new-project-prompt.md` is retired; `/rebuild-agent-docs` is the') return 0 ;;
    'fresh-planning-chat|docs/decisions/agent-docs.md|`v1/skills/plan/SKILL.md`; the older `fresh-planning-chat` name is retired.') return 0 ;;
  esac

  return 1
}

reject_unapproved_retired_name() {
  local pattern=$1
  local label=$2
  local file
  local match
  local line_text
  local relative_file

  while IFS= read -r file; do
    while IFS= read -r match; do
      [ -n "$match" ] || continue
      line_text=${match#*:}
      relative_file=${file#$repo_root/}
      allow_retired_reference "$relative_file" "$label" "$line_text" &&
        continue
      fail "unapproved retired name '$label' remains: $relative_file:$match"
    done < <(grep -IEn "$pattern" "$file" || true)
  done < <(candidate_files)
}

reject_any_match '[.]agent-docs/(current|src)' "stale canonical path remains"
reject_unapproved_retired_name 'new-project[-]prompt' 'new-project-prompt'
reject_unapproved_retired_name 'fresh-planning-chat' 'fresh-planning-chat'
reject_unapproved_retired_name 'grand-orchestrator|fresh-orchestrator' 'retired orchestration skill'
reject_any_match 'docs/ownership[.]md' "ownership prose doc referenced instead of docs/_meta/ownership.json"
reject_any_match 'v1/[.]claude-plugin' "retired Claude plugin path referenced"
[ ! -e "$repo_root/v1/.claude-plugin" ] ||
  fail "retired Claude plugin path exists: v1/.claude-plugin"

for script_path in v1/install.sh v1/copy-skills.sh v1/verify-agent-docs.sh; do
  require_executable "$script_path"
  require_git_executable_mode "$script_path"
done

bash "$repo_root/v1/copy-skills.sh" --check "$repo_root" ||
  fail "copied skill adapters are stale"

printf 'ALL AGENT-DOCS GATES PASS\n'
