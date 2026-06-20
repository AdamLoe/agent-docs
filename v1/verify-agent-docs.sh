#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'GATE FAIL: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  bash v1/verify-agent-docs.sh
  bash v1/verify-agent-docs.sh --telemetry-jsonl <run-log.jsonl>
  bash v1/verify-agent-docs.sh --scaffold <repo-root>

Default mode validates the agent-docs kit checkout that contains this script.
The --scaffold mode validates only the target repo's docs/ scaffold, manifest,
ownership JSON, routing, and unresolved scaffold placeholders.
The optional --telemetry-jsonl mode also validates raw token-usage JSONL when a
runtime provided it; omitted telemetry is reported as unavailable, not failed.
EOF
}

section() {
  printf '== %s ==\n' "$*"
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

require_file_under() {
  local root=$1
  local path=$2
  local label=$3

  [ -f "$root/$path" ] || fail "$label missing required file: $path"
}

require_dir_under() {
  local root=$1
  local path=$2
  local label=$3

  [ -d "$root/$path" ] || fail "$label missing required directory: $path"
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

  require_doc_route_under "$repo_root" "$index_path" "$target" "$label"
}

require_doc_route_under() {
  local root=$1
  local index_path=$2
  local target=$3
  local label=$4

  grep -Fq "[\`$target\`]($target)" "$root/$index_path" ||
    fail "$label index missing route to $target"
}

require_manifest_change_to_doc() {
  local manifest_path=$1
  local surface=$2
  local owning_doc=$3
  local label=$4

  require_manifest_change_to_doc_under \
    "$repo_root" "$manifest_path" "$surface" "$owning_doc" "$label"
}

require_manifest_change_to_doc_under() {
  local root=$1
  local manifest_path=$2
  local surface=$3
  local owning_doc=$4
  local label=$5

  grep -Fq "| $surface | $owning_doc |" "$root/$manifest_path" ||
    fail "$label missing change-to-doc row for $surface"
}

require_ownership_surface_path() {
  local ownership_path=$1
  local surface=$2
  local owner_path=$3
  local label=$4

  require_ownership_surface_path_under \
    "$repo_root" "$ownership_path" "$surface" "$owner_path" "$label"
}

require_ownership_surface_path_under() {
  local root=$1
  local ownership_path=$2
  local surface=$3
  local owner_path=$4
  local label=$5
  local python_cmd

  if command -v jq >/dev/null 2>&1; then
    jq -e --arg surface "$surface" --arg owner_path "$owner_path" '
      any(.owners[]?; .surface == $surface and ((.paths // []) | index($owner_path) != null))
    ' "$root/$ownership_path" >/dev/null ||
      fail "$label ownership missing surface '$surface' path '$owner_path'"
    return
  fi

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] ||
    fail "cannot validate $label ownership; install jq or python"

  if ! "$python_cmd" - "$root/$ownership_path" "$surface" "$owner_path" <<'PY'
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

require_manifest_scalar_under() {
  local root=$1
  local manifest_path=$2
  local scalar_slot=$3
  local label=$4
  local value

  value=$(
    awk -v slot="$scalar_slot" '
      $0 ~ "^" slot ":" {
        sub(/^[^:]*:[[:space:]]*/, "", $0)
        sub(/[[:space:]]+$/, "", $0)
        print
        found = 1
        exit
      }
      END { if (!found) exit 2 }
    ' "$root/$manifest_path"
  ) || fail "$label manifest missing slot '$scalar_slot'"

  [ -n "$value" ] ||
    fail "$label manifest slot '$scalar_slot' must not be empty"

  case "$value" in
    '<!-- fill -->'|fill|'"fill"'|'""'|"''")
      fail "$label manifest slot '$scalar_slot' has unresolved placeholder value"
      ;;
  esac
}

require_manifest_section_under() {
  local root=$1
  local manifest_path=$2
  local section_slot=$3
  local label=$4

  grep -Eq "^## ${section_slot}[[:space:]]*$" "$root/$manifest_path" ||
    fail "$label manifest missing section '$section_slot'"
}

validate_ownership_paths_under() {
  local root=$1
  local ownership_path=$2
  local label=$3
  local ownership_paths
  local owner_path
  local normalized_path
  local python_cmd

  ownership_paths=$(mktemp "${TMPDIR:-/tmp}/agent-docs-ownership.XXXXXX")

  if command -v jq >/dev/null 2>&1; then
    jq -e '.owners | type == "array"' "$root/$ownership_path" >/dev/null ||
      fail "$label ownership.json missing owners array"
    jq -r '.owners[].paths[]?' "$root/$ownership_path" > "$ownership_paths" ||
      fail "$label ownership.json failed to parse"
  else
    python_cmd=$(find_python_cmd)

    [ -n "$python_cmd" ] ||
      fail "cannot validate $label ownership.json; install jq or python"

    if ! "$python_cmd" - "$root/$ownership_path" > "$ownership_paths" <<'PY'
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
      fail "$label ownership.json failed to parse"
    fi
  fi

  [ -s "$ownership_paths" ] || fail "$label ownership.json has no owner paths"
  while IFS= read -r owner_path; do
    [ -n "$owner_path" ] || fail "$label ownership.json contains an empty owner path"
    case "$owner_path" in
      /*) fail "$label ownership path must be repo-relative: $owner_path" ;;
    esac
    normalized_path=${owner_path%/}
    [ -e "$root/$normalized_path" ] ||
      fail "$label ownership path does not exist: $owner_path"
  done < "$ownership_paths"

  rm -f "$ownership_paths"
}

require_no_scaffold_placeholders() {
  local root=$1
  local docs_path=$2
  local label=$3
  local match

  match=$(grep -RIn -m 1 -- '<!-- fill -->' "$root/$docs_path" || true)
  [ -z "$match" ] ||
    fail "$label contains unresolved '<!-- fill -->' placeholder: ${match#$root/}"

  match=$(grep -RIn -m 1 -- '"fill"' "$root/$docs_path" || true)
  [ -z "$match" ] ||
    fail "$label contains unresolved '\"fill\"' placeholder: ${match#$root/}"
}

require_word_limit_under() {
  local root=$1
  local path=$2
  local cap=$3
  local label=$4
  local count

  [ -f "$root/$path" ] || fail "$label word-count target missing: $path"
  count=$(wc -w < "$root/$path")
  count=${count//[[:space:]]/}
  [ "$count" -le "$cap" ] ||
    fail "$label word cap exceeded for $path: $count > $cap"
}

require_word_limit() {
  local path=$1
  local cap=$2
  local label=$3

  require_word_limit_under "$repo_root" "$path" "$cap" "$label"
}

require_file_word_limit() {
  local file=$1
  local cap=$2
  local label=$3
  local count

  [ -f "$file" ] || fail "$label word-count target missing: ${file#$repo_root/}"
  count=$(wc -w < "$file")
  count=${count//[[:space:]]/}
  [ "$count" -le "$cap" ] ||
    fail "$label word cap exceeded for ${file#$repo_root/}: $count > $cap"
}

require_text() {
  local path=$1
  local text=$2
  local message=$3

  grep -Fq "$text" "$repo_root/$path" || fail "$message"
}

require_layout_path() {
  local layout_path=$1

  grep -Fq "| \`$layout_path\` |" "$repo_root/docs/repository-layout.md" ||
    fail "repository layout missing stable path: $layout_path"
}

validate_word_budgets() {
  local file

  for file in \
    AGENTS.md \
    CLAUDE.md \
    docs/index.md \
    docs/architecture/index.md \
    docs/decisions/index.md \
    docs/agent-context/index.md \
    docs/plans/index.md \
    v1/template/docs/index.md \
    v1/template/docs/architecture/index.md \
    v1/template/docs/decisions/index.md \
    v1/template/docs/agent-context/index.md \
    v1/template/docs/plans/index.md; do
    require_word_limit "$file" 250 "router/index budget"
  done

  for file in docs/overview.md v1/template/docs/overview.md; do
    require_word_limit "$file" 350 "overview budget"
  done

  for file in "$repo_root"/docs/architecture/*.md; do
    require_file_word_limit "$file" 1500 "architecture budget"
  done

  for file in "$repo_root"/docs/decisions/*.md; do
    require_file_word_limit "$file" 2600 "decisions budget"
  done

  for file in "$repo_root"/docs/plans/*.md; do
    require_file_word_limit "$file" 2600 "plan budget"
  done

  for file in "$repo_root"/docs/plans/orchestrator/*/hub.md; do
    [ -e "$file" ] || continue
    require_file_word_limit "$file" 2600 "run hub budget"
  done

  while IFS= read -r file; do
    require_file_word_limit "$file" 1200 "run finding/stream budget"
  done < <(find "$repo_root/docs/plans/orchestrator" \
    \( -path '*/findings/*.md' -o -path '*/streams/*.md' \) -type f 2>/dev/null)

  for file in "$repo_root"/docs/agent-context/*.md; do
    require_file_word_limit "$file" 1200 "agent-context budget"
  done

  for file in "$repo_root"/v1/skills/*/SKILL.md; do
    require_file_word_limit "$file" 900 "skill body budget"
  done

  for file in "$repo_root"/v1/rules/subagent/*.md; do
    require_file_word_limit "$file" 500 "subagent role-card budget"
  done

  for file in "$repo_root"/v1/rules/*.md; do
    require_file_word_limit "$file" 1800 "generic rule budget"
  done

  for file in "$repo_root"/v1/rules/orchestrator/*.md; do
    require_file_word_limit "$file" 2200 "orchestrator rule budget"
  done

  require_word_limit "v1/plan-lifecycle.md" 900 "plan lifecycle budget"
  require_word_limit "v1/plan-template.md" 500 "plan template budget"
  require_word_limit "v1/agent-docs-guide.md" 3500 "adoption guide budget"
  require_word_limit "docs/repository-layout.md" 350 "repository layout budget"
}

validate_usage_telemetry_jsonl() {
  local telemetry_path=$1
  local python_cmd

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] ||
    fail "cannot validate usage telemetry JSONL; install python"

  if ! "$python_cmd" - "$telemetry_path" <<'PY'
import json
import sys

path = sys.argv[1]
count = 0

with open(path, "r", encoding="utf-8") as handle:
    for line_number, line in enumerate(handle, 1):
        line = line.strip()
        if not line:
            continue
        count += 1
        try:
            record = json.loads(line)
        except json.JSONDecodeError as exc:
            raise SystemExit(f"line {line_number}: invalid JSON: {exc}") from exc
        if not isinstance(record, dict):
            raise SystemExit(f"line {line_number}: telemetry record must be an object")

        unavailable = record.get("unavailable_reason")
        if unavailable is not None:
            if not isinstance(unavailable, str) or not unavailable.strip():
                raise SystemExit(f"line {line_number}: unavailable_reason must be non-empty")
            continue

        for key in ("input_tokens", "cached_input_tokens", "output_tokens"):
            value = record.get(key)
            if not isinstance(value, int) or value < 0:
                raise SystemExit(f"line {line_number}: {key} must be a non-negative integer")
        source = record.get("usage_source")
        if not isinstance(source, str) or not source.strip():
            raise SystemExit(f"line {line_number}: usage_source must be non-empty")
        if record["cached_input_tokens"] > record["input_tokens"]:
            raise SystemExit(f"line {line_number}: cached_input_tokens exceeds input_tokens")

if count == 0:
    raise SystemExit("telemetry JSONL contains no records")
PY
  then
    fail "usage telemetry JSONL invalid: $telemetry_path"
  fi
}

check_scaffold_tree() {
  local root=$1
  local label=$2
  local manifest_path=docs/_meta/manifest.md
  local ownership_path=docs/_meta/ownership.json
  local scalar_slot
  local section_slot

  require_file_under "$root" "docs/index.md" "$label"
  require_file_under "$root" "docs/overview.md" "$label"
  require_file_under "$root" "docs/repository-layout.md" "$label"
  require_file_under "$root" "$manifest_path" "$label"
  require_file_under "$root" "$ownership_path" "$label"
  require_dir_under "$root" "docs/architecture" "$label"
  require_dir_under "$root" "docs/decisions" "$label"
  require_dir_under "$root" "docs/agent-context" "$label"
  require_dir_under "$root" "docs/plans" "$label"

  for scalar_slot in repo_name agent_docs_version code_root; do
    require_manifest_scalar_under "$root" "$manifest_path" "$scalar_slot" "$label"
  done

  for section_slot in change-to-doc drift-gates drift-verification decisions-domains; do
    require_manifest_section_under "$root" "$manifest_path" "$section_slot" "$label"
  done

  require_doc_route_under "$root" "docs/index.md" "overview.md" "$label"
  require_doc_route_under "$root" "docs/index.md" "architecture/index.md" "$label"
  require_doc_route_under "$root" "docs/index.md" "decisions/index.md" "$label"
  require_doc_route_under "$root" "docs/index.md" "agent-context/index.md" "$label"
  require_doc_route_under "$root" "docs/index.md" "plans/index.md" "$label"
  require_doc_route_under "$root" "docs/index.md" "repository-layout.md" "$label"
  require_doc_route_under "$root" "docs/index.md" "_meta/manifest.md" "$label"
  require_doc_route_under "$root" "docs/index.md" "_meta/ownership.json" "$label"

  validate_ownership_paths_under "$root" "$ownership_path" "$label"
  require_ownership_surface_path_under \
    "$root" "$ownership_path" "repository-layout" "docs/repository-layout.md" "$label"

  require_no_scaffold_placeholders "$root" "docs" "$label"
}

telemetry_log=""

case "${1:-}" in
  "")
    ;;
  --telemetry-jsonl)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    [ -f "$2" ] || fail "telemetry JSONL path is not a file: $2"
    telemetry_log=$2
    ;;
  --scaffold)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    [ -d "$2" ] || fail "scaffold target is not a directory: $2"
    target_root=$(cd "$2" && pwd)
    section "consuming-repo scaffold checks: $target_root"
    check_scaffold_tree "$target_root" "scaffold target"
    printf 'SCAFFOLD GATES PASS\n'
    exit 0
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

section "kit repository checks"

manifest="$repo_root/docs/_meta/manifest.md"
ownership="$repo_root/docs/_meta/ownership.json"

require_file "docs/index.md"
require_file "docs/overview.md"
require_file "docs/repository-layout.md"
require_file "AGENTS.md"
require_file "CLAUDE.md"
require_file "docs/_meta/manifest.md"
require_file "docs/_meta/ownership.json"
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
for router_file in AGENTS.md CLAUDE.md; do
  grep -Fq 'docs/index.md' "$repo_root/$router_file" ||
    fail "$router_file must route to docs/index.md"
  ! grep -Fxq -- '- `docs/overview.md`' "$repo_root/$router_file" ||
    fail "$router_file must not list docs/overview.md as a mandatory startup route"
  grep -Fq 'router only' "$repo_root/$router_file" ||
    fail "$router_file must state that it is router only"
done
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Repository layout inventory" \
  "docs/repository-layout.md" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Router-only auto-loaded files" \
  "AGENTS.md, CLAUDE.md, README.md, docs/architecture/install-and-adapters.md" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Docs scaffold template and consuming-repo scaffold checks" \
  "v1/template/docs/, v1/verify-agent-docs.sh, v1/skills/rebuild-agent-docs/SKILL.md, v1/skills/doctor/SKILL.md, v1/agent-docs-guide.md, docs/architecture/workflow-kit.md" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Drift gates, budget checks, optional telemetry validation, and agent-readiness verifier" \
  "docs/_meta/manifest.md, v1/verify-agent-docs.sh" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Context efficiency and documentation budgets" \
  "v1/rules/authoring-rules.md, v1/rules/skill-contracts.md, v1/rules/orchestrator/dispatch.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md, v1/verify-agent-docs.sh" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Worker report usage reporting and optional telemetry validation" \
  "v1/rules/orchestrator/dispatch.md, v1/rules/subagent/, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md, v1/verify-agent-docs.sh" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Command families and skill inventory" \
  "v1/skills/registry.md, docs/architecture/workflow-kit.md" \
  "docs/_meta/manifest.md"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "repository-layout" \
  "docs/repository-layout.md" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "auto-loaded-router-files" \
  "AGENTS.md" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "auto-loaded-router-files" \
  "CLAUDE.md" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "docs-scaffold-template" \
  "v1/template/docs/" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "agent-readiness-verifier" \
  "v1/verify-agent-docs.sh" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "context-efficiency" \
  "v1/rules/authoring-rules.md" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "documentation-budgets" \
  "v1/verify-agent-docs.sh" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "usage-reporting" \
  "v1/rules/orchestrator/dispatch.md" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "command-families" \
  "v1/skills/registry.md" \
  "docs/_meta/ownership.json"

validate_ownership_paths_under "$repo_root" "docs/_meta/ownership.json" "docs/_meta"

for layout_path in \
  ".gitattributes" \
  "v1/agent-docs-guide.md" \
  "v1/plan-lifecycle.md" \
  "v1/plan-template.md"; do
  require_layout_path "$layout_path"
done

require_text "v1/rules/authoring-rules.md" "Cache-stable layer" \
  "authoring rules missing cache-stable layer policy"
require_text "v1/rules/authoring-rules.md" "Task-specific layer" \
  "authoring rules missing task-specific layer policy"
require_text "v1/rules/authoring-rules.md" "Never-auto-loaded layer" \
  "authoring rules missing never-auto-loaded layer policy"
require_text "v1/rules/authoring-rules.md" "Documentation class budgets" \
  "authoring rules missing documentation class budgets"
require_text "docs/architecture/workflow-kit.md" "Context layers" \
  "workflow architecture missing context layer contract"
require_text "v1/rules/orchestrator/dispatch.md" "Token usage:" \
  "dispatch report shape missing Token usage block"
require_text "v1/rules/orchestrator/dispatch.md" "unavailable_reason" \
  "dispatch report shape missing usage unavailable_reason"
require_text "v1/rules/skill-contracts.md" "Usage Reporting" \
  "skill contracts missing usage reporting policy"

for worker_rule in planning implementation review docs-maintenance plan-maintenance verification; do
  require_text "v1/rules/subagent/$worker_rule.md" "Token usage" \
    "subagent report shape missing token usage policy: $worker_rule"
  require_text "v1/rules/subagent/$worker_rule.md" "unavailable_reason" \
    "subagent report shape missing usage unavailable_reason: $worker_rule"
done

section "documentation budget checks"
validate_word_budgets

section "scaffold template checks"
check_scaffold_tree "$repo_root/v1/template" "template docs scaffold"

require_file "v1/skills/registry.md"

declare -A registry_seen=()
registry_row_count=0
while IFS=$'\t' read -r tag line_no name mode action worker_roles commits intake launch normal_input; do
  case "$tag" in
    MALFORMED)
      fail "malformed registry row at line $line_no: $name"
      ;;
    ROW)
      ;;
    *)
      fail "unexpected registry parser output: $tag"
      ;;
  esac

  [ "$name" != "" ] || fail "registry row at line $line_no has empty skill name"
  [ "$mode" != "" ] || fail "registry row for $name has empty mode"
  [ "$action" != "" ] || fail "registry row for $name has empty action"
  [ "$worker_roles" != "" ] || fail "registry row for $name has empty worker roles"
  [ "$commits" != "" ] || fail "registry row for $name has empty commits metadata"
  [ "$normal_input" != "" ] || fail "registry row for $name has empty normal input"

  [ -z "${registry_seen[$name]+set}" ] || fail "duplicate registry row for skill: $name"
  registry_seen[$name]=1
  registry_row_count=$((registry_row_count + 1))

  [ -d "$repo_root/v1/skills/$name" ] ||
    fail "registry has stale skill row with no directory: $name"

  case "$mode" in
    bootstrap|planning|mutating|report-only|capture) ;;
    "lifecycle orchestration"|"review with optional fixes"|"report-only by default") ;;
    *) fail "registry row for $name has invalid mode: $mode" ;;
  esac

  case "$commits" in
    no|"only through routed skills"|"only if it edits tracked docs/plans (via workers)") ;;
    "yes, via worker"|"yes, via workers"|"yes, via plan-maintenance worker"|"yes, via docs-maintenance worker") ;;
    "yes, only if a fix worker runs"|"only if user asks to apply edits"|"only if user asks to fix failures") ;;
    "no (writes the gitignored kit inbox)") ;;
    *) fail "registry row for $name has invalid commits metadata: $commits" ;;
  esac

  case "$intake" in
    asks|no-prompt) ;;
    *) fail "registry row for $name has invalid intake: $intake" ;;
  esac

  case "$launch" in
    cheap|mid|strong|strongest) ;;
    *) fail "registry row for $name has invalid launch tier: $launch" ;;
  esac
done < <(
  awk -F'|' '
    /^\| `[^`]+` \|/ {
      if (NF != 10) {
        printf "MALFORMED\t%d\t%s\n", NR, $0
        next
      }
      for (i = 2; i <= 9; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
      }
      name = $2
      gsub(/^`|`$/, "", name)
      printf "ROW\t%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", NR, name, $3, $4, $5, $6, $7, $8, $9
    }
  ' "$repo_root/v1/skills/registry.md"
)
[ "$registry_row_count" -gt 0 ] || fail "registry has no skill rows"

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

require_dir "v1/rules/orchestrator"
require_dir "v1/rules/subagent"
for orch_rule in lifecycle dispatch run-docs; do
  require_file "v1/rules/orchestrator/$orch_rule.md"
done
for worker_rule in planning implementation review docs-maintenance plan-maintenance verification; do
  require_file "v1/rules/subagent/$worker_rule.md"
done
[ ! -e "$repo_root/v1/rules/orchestrating.md" ] ||
  fail "retired v1/rules/orchestrating.md still exists; split it into v1/rules/orchestrator/"
for dial in cost-low cost-medium cost-high cost-max review-none review-high; do
  grep -Fq "$dial" "$repo_root/v1/rules/orchestrator/lifecycle.md" ||
    fail "orchestration dial '$dial' missing"
done

# Every v1/rules path referenced in a skill body must resolve to a real file
# or directory, so dispatch routes never point nowhere.
while IFS= read -r skill_file; do
  while IFS= read -r ref_path; do
    [ -n "$ref_path" ] || continue
    normalized_ref=${ref_path#\~/agent-docs/}
    normalized_ref=${normalized_ref%/}
    [ -e "$repo_root/$normalized_ref" ] ||
      fail "skill ${skill_file#$repo_root/} references missing rule path: $ref_path"
  done < <(grep -oE 'v1/rules/[A-Za-z0-9/_.-]+' "$skill_file" | sort -u)
done < <(find "$repo_root"/v1/skills -name SKILL.md)

# The retired execution-model vocabulary must not return to skill bodies or the
# registry. (Decision docs and disposable plans may still name these terms to
# explain why they were dropped, so this check is scoped to the skill suite.)
for retired_token in delegate-on delegate-off no-intake direct-execution; do
  while IFS= read -r skill_surface; do
    match=$(grep -IEn -m 1 "$retired_token" "$skill_surface" || true)
    [ -z "$match" ] ||
      fail "retired execution-model token '$retired_token' in ${skill_surface#$repo_root/}:$match"
  done < <(find "$repo_root"/v1/skills -name SKILL.md; printf '%s\n' "$repo_root/v1/skills/registry.md")
done

adapter_doc="$repo_root/docs/architecture/install-and-adapters.md"
grep -Fq '~/.claude/skills/<name>' "$adapter_doc" ||
  fail "claude copy target undocumented"
grep -Fq '~/.agents/skills/<name>' "$adapter_doc" ||
  fail "codex copy target undocumented"

candidate_files() {
  find "$repo_root/README.md" "$repo_root/AGENTS.md" "$repo_root/CLAUDE.md" "$repo_root/docs" "$repo_root/v1" \
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
reject_unapproved_retired_name 'agent-docs-doctor' 'agent-docs-doctor'
reject_unapproved_retired_name 'check-docs-consistency-some' 'check-docs-consistency-some'
reject_unapproved_retired_name 'fix-docs-drift-all' 'fix-docs-drift-all'
reject_unapproved_retired_name 'implement-plans' 'implement-plans'
reject_unapproved_retired_name 'review-agent-docs-skills' 'review-agent-docs-skills'
reject_unapproved_retired_name 'review-plans-custom' 'review-plans-custom'
reject_unapproved_retired_name 'review-plans-high-level' 'review-plans-high-level'
reject_unapproved_retired_name '(^|[^-])review-docs([^a-z-]|$)' 'review-docs'
reject_unapproved_retired_name '(^|[^-])review-work([^a-z-]|$)' 'review-work'
reject_any_match 'docs/ownership[.]md' "ownership prose doc referenced instead of docs/_meta/ownership.json"
reject_any_match 'v1/[.]claude-plugin' "retired Claude plugin path referenced"
[ ! -e "$repo_root/v1/.claude-plugin" ] ||
  fail "retired Claude plugin path exists: v1/.claude-plugin"

for script_path in v1/install.sh v1/copy-skills.sh v1/verify-agent-docs.sh; do
  require_executable "$script_path"
  require_git_executable_mode "$script_path"
done

section "local adapter freshness checks"
bash "$repo_root/v1/copy-skills.sh" --check "$repo_root" ||
  fail "copied skill adapters are stale"

section "optional usage telemetry checks"
if [ "$telemetry_log" = "" ]; then
  printf 'USAGE TELEMETRY CHECK SKIPPED: unavailable_reason=no telemetry JSONL provided\n'
else
  validate_usage_telemetry_jsonl "$telemetry_log"
  printf 'USAGE TELEMETRY JSONL PASS: %s\n' "$telemetry_log"
fi

printf 'ALL AGENT-DOCS GATES PASS\n'
