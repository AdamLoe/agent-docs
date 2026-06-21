#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'GATE FAIL: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  bash src/verify-agent-docs.sh
  bash src/verify-agent-docs.sh --context-report [--profile <id>]
  bash src/verify-agent-docs.sh --scaffold <repo-root>

Default mode validates the agent-docs kit checkout that contains this script.
The --context-report mode prints the read-only context profile and scenario
contract, including exact files, conditions, word totals, and budget exceptions.
The --scaffold mode validates only the target repo's docs/ scaffold, manifest,
ownership JSON, routing, and unresolved scaffold placeholders.
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

trim_field() {
  local value=$1
  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}
  value=${value#\`}
  value=${value%\`}
  printf '%s' "$value"
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
    src/template/docs/index.md \
    src/template/docs/architecture/index.md \
    src/template/docs/decisions/index.md \
    src/template/docs/agent-context/index.md \
    src/template/docs/plans/index.md; do
    require_word_limit "$file" 250 "router/index budget"
  done

  for file in docs/overview.md src/template/docs/overview.md; do
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

  for file in "$repo_root"/src/skills/*/SKILL.md; do
    require_file_word_limit "$file" 900 "skill body budget"
  done

  for file in "$repo_root"/src/rules/subagent/*.md; do
    require_file_word_limit "$file" 500 "subagent role-card budget"
  done

  for file in "$repo_root"/src/rules/*.md; do
    require_file_word_limit "$file" 1800 "generic rule budget"
  done

  for file in "$repo_root"/src/rules/orchestrator/*.md; do
    require_file_word_limit "$file" 2200 "orchestrator rule budget"
  done

  require_word_limit "src/plan-lifecycle.md" 900 "plan lifecycle budget"
  require_word_limit "src/plan-template.md" 500 "plan template budget"
  require_word_limit "src/agent-docs-guide.md" 3500 "adoption guide budget"
  require_word_limit "docs/repository-layout.md" 350 "repository layout budget"
}

context_profile_rows() {
  awk -F'|' '
    /^\| `[^`]+` \|/ && NF == 9 {
      for (i = 2; i <= 8; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
        gsub(/^`|`$/, "", $i)
      }
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $2, $3, $4, $5, $6, $7, $8
    }
  ' "$repo_root/src/rules/context-profiles.md"
}

scenario_rows() {
  awk -F'|' '
    /^\| `[^`]+` \|/ && NF == 11 {
      for (i = 2; i <= 10; i++) {
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i)
        gsub(/^`|`$/, "", $i)
      }
      printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $2, $3, $4, $5, $6, $7, $8, $9, $10
    }
  ' "$repo_root/src/rules/context-profiles.md"
}

profile_word_total() {
  local core_paths=$1
  local total=0
  local path
  local count

  IFS=',' read -ra paths <<< "$core_paths"
  for path in "${paths[@]}"; do
    path=$(trim_field "$path")
    path=${path#\`}
    path=${path%\`}
    [ -f "$repo_root/$path" ] || fail "context profile references missing path: $path"
    count=$(wc -w < "$repo_root/$path")
    count=${count//[[:space:]]/}
    total=$((total + count))
  done

  printf '%s' "$total"
}

context_report() {
  local profile_filter=${1:-}
  local found=0
  local id purpose core_paths overlays mutation budget status total exception
  local display_paths
  local display_profiles

  section "context profiles"
  while IFS=$'\t' read -r id purpose core_paths overlays mutation budget status; do
    [ -z "$profile_filter" ] || [ "$id" = "$profile_filter" ] || continue
    found=1
    total=$(profile_word_total "$core_paths")
    exception="none"
    if [ "$total" -gt "$budget" ]; then
      exception="over budget in report-only status; correctness requires listed core files"
    fi
    display_paths=${core_paths//\`/}
    printf 'PROFILE %s\n' "$id"
    printf '  purpose: %s\n' "$purpose"
    printf '  files: %s\n' "$display_paths"
    printf '  conditions: %s\n' "$overlays"
    printf '  mutation: %s\n' "$mutation"
    printf '  words: %s/%s\n' "$total" "$budget"
    printf '  enforcement: %s\n' "$status"
    printf '  budget_exception: %s\n' "$exception"
  done < <(context_profile_rows)

  [ "$found" -eq 1 ] || fail "unknown context profile: $profile_filter"

  section "scenario contract"
  if [ -z "$profile_filter" ]; then
    while IFS=$'\t' read -r id _ _ profiles phases mutators state final budget_expectation; do
      display_profiles=${profiles//\`/}
      printf 'SCENARIO %s profiles=%s phases=%s mutators=%s state=%s final=%s budget=%s\n' \
        "$id" "$display_profiles" "$phases" "$mutators" "$state" "$final" "$budget_expectation"
    done < <(scenario_rows)
  else
    printf 'SCENARIO CONTRACT AVAILABLE: rerun without --profile for all rows\n'
  fi

  printf 'CONTEXT REPORT PASS\n'
}

validate_context_profiles() {
  local python_cmd

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] ||
    fail "cannot validate context profiles; install python"

  if ! "$python_cmd" - "$repo_root/src/rules/context-profiles.md" "$repo_root" <<'PY'
import pathlib
import re
import sys

profile_path = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])
text = profile_path.read_text(encoding="utf-8")

profile_rows = []
scenario_rows = []
for line in text.splitlines():
    if not line.startswith("| `"):
        continue
    cells = [cell.strip().strip("`") for cell in line.strip().strip("|").split("|")]
    if len(cells) == 7:
        profile_rows.append(cells)
    elif len(cells) == 9:
        scenario_rows.append(cells)

required_profiles = {
    "planning.brief", "planning.tracked", "implementation.code",
    "implementation.code-docs", "implementation.tracked", "review.generic",
    "review.docs", "review.plan", "maintenance.docs", "maintenance.plan",
    "verification.readonly",
}
seen_profiles = {row[0] for row in profile_rows}
missing = required_profiles - seen_profiles
if missing:
    raise SystemExit(f"missing context profiles: {sorted(missing)}")

for row in profile_rows:
    profile_id, _, paths, _, mutation, budget, status = row
    if mutation not in {"read-only", "mutating", "conditional"}:
        raise SystemExit(f"{profile_id}: invalid mutation capability {mutation}")
    if (profile_id.startswith("review.") or profile_id == "verification.readonly") and mutation != "read-only":
        raise SystemExit(f"{profile_id}: read-only profile has mutation capability {mutation}")
    if status not in {"report-only", "pilot-enforced", "enforced"}:
        raise SystemExit(f"{profile_id}: invalid enforcement status {status}")
    try:
        budget_value = int(budget)
    except ValueError as exc:
        raise SystemExit(f"{profile_id}: invalid budget {budget}") from exc
    total = 0
    for raw_path in paths.split(","):
        rule_path = raw_path.strip().strip("`")
        target = repo_root / rule_path
        if not target.is_file():
            raise SystemExit(f"{profile_id}: missing rule path {rule_path}")
        total += len(target.read_text(encoding="utf-8").split())
    if status in {"pilot-enforced", "enforced"} and total > budget_value:
        raise SystemExit(f"{profile_id}: word budget exceeded {total}>{budget_value}")

required_scenarios = {
    "bounded-quick-fix", "unclear-small-work", "medium-brief-plan",
    "tracked-change-plan", "dirty-tree-shipping", "named-plan-shipping",
    "docs-repair", "report-only-review", "configured-app-review",
    "failed-verification", "resume-invalidated",
}
seen_scenarios = {row[0] for row in scenario_rows}
missing = required_scenarios - seen_scenarios
if missing:
    raise SystemExit(f"missing scenario rows: {sorted(missing)}")

checks = {
    "bounded-quick-fix": ["no classifier", "implementation.code", "one implementation", "gate observes post-mutation"],
    "unclear-small-work": ["one material task question", "no dial picker"],
    "medium-brief-plan": ["planning.brief", "read-only"],
    "tracked-change-plan": ["planning.tracked", "plan write"],
    "dirty-tree-shipping": ["exact dirty paths", "owned staging"],
    "named-plan-shipping": ["implementation.tracked", "closeout before final gate"],
    "docs-repair": ["maintenance.docs", "docs maintenance"],
    "report-only-review": ["review.generic", "review only"],
    "configured-app-review": ["no reconfirmation", "approval before plans"],
    "failed-verification": ["verification.readonly", "verifier never mutates"],
    "resume-invalidated": ["intervening commit", "reread or respawn"],
}
row_text = {row[0]: " | ".join(row[1:]) for row in scenario_rows}
for scenario_id, needles in checks.items():
    haystack = row_text[scenario_id]
    for needle in needles:
        if needle not in haystack:
            raise SystemExit(f"{scenario_id}: missing required check text {needle!r}")
PY
  then
    fail "context profile contract invalid"
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

case "${1:-}" in
  "")
    ;;
  --context-report)
    case "$#" in
      1)
        context_report
        exit 0
        ;;
      3)
        [ "$2" = "--profile" ] || { usage >&2; exit 2; }
        context_report "$3"
        exit 0
        ;;
      *)
        usage >&2
        exit 2
        ;;
    esac
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

# The default mode is the agent-docs SOURCE-repo self-consistency gate: manifest
# rows, ownership, skill registry, context profiles, and budgets all resolve
# relative to this checkout. The script also ships inside the runtime bundle as
# ~/.agentdocs/verify-agent-docs.sh, where those source surfaces do not exist.
# When run outside the source repo, degrade gracefully and point at the runtime
# mode (--scaffold) instead of failing on missing source files.
if [ ! -f "$repo_root/src/skills/registry.md" ] ||
   ! grep -Eq '^repo_name:[[:space:]]*agent-docs[[:space:]]*$' \
     "$repo_root/docs/_meta/manifest.md" 2>/dev/null; then
  printf 'not the agent-docs source repo; source self-consistency checks are skipped.\n'
  printf 'use --scaffold <repo-root> to validate a consuming repo, or run this gate from the agent-docs checkout.\n'
  exit 0
fi

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
require_file "src/rules/context-profiles.md"
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

grep -Fq 'bash src/verify-agent-docs.sh' "$manifest" ||
  fail "manifest drift-gates must call bash src/verify-agent-docs.sh"

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
  "src/template/docs/, src/verify-agent-docs.sh, src/skills/rebuild-agent-docs/SKILL.md, src/skills/doctor/SKILL.md, src/agent-docs-guide.md, docs/architecture/workflow-kit.md" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Drift gates, budget checks, context reports, and agent-readiness verifier" \
  "docs/_meta/manifest.md, src/verify-agent-docs.sh" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Context efficiency, profiles, and documentation budgets" \
  "src/rules/context-profiles.md, src/rules/authoring-rules.md, src/rules/skill-contracts.md, src/rules/orchestrator/dispatch.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md, src/verify-agent-docs.sh" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Runtime usage reporting when raw counts are exposed" \
  "src/rules/orchestrator/dispatch.md, src/rules/subagent/, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md" \
  "docs/_meta/manifest.md"
require_manifest_change_to_doc \
  "docs/_meta/manifest.md" \
  "Command families and skill inventory" \
  "src/skills/registry.md, docs/architecture/workflow-kit.md" \
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
  "src/template/docs/" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "agent-readiness-verifier" \
  "src/verify-agent-docs.sh" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "context-efficiency" \
  "src/rules/authoring-rules.md" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "documentation-budgets" \
  "src/verify-agent-docs.sh" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "context-profiles" \
  "src/rules/context-profiles.md" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "runtime-usage-reporting" \
  "src/rules/orchestrator/dispatch.md" \
  "docs/_meta/ownership.json"
require_ownership_surface_path \
  "docs/_meta/ownership.json" \
  "command-families" \
  "src/skills/registry.md" \
  "docs/_meta/ownership.json"

validate_ownership_paths_under "$repo_root" "docs/_meta/ownership.json" "docs/_meta"

for layout_path in \
  ".gitattributes" \
  "src/agent-docs-guide.md" \
  "src/plan-lifecycle.md" \
  "src/plan-template.md"; do
  require_layout_path "$layout_path"
done

require_text "src/rules/authoring-rules.md" "Cache-stable layer" \
  "authoring rules missing cache-stable layer policy"
require_text "src/rules/authoring-rules.md" "Task-specific layer" \
  "authoring rules missing task-specific layer policy"
require_text "src/rules/authoring-rules.md" "Never-auto-loaded layer" \
  "authoring rules missing never-auto-loaded layer policy"
require_text "src/rules/authoring-rules.md" "Documentation class budgets" \
  "authoring rules missing documentation class budgets"
require_text "docs/architecture/workflow-kit.md" "Context layers" \
  "workflow architecture missing context layer contract"
require_text "src/rules/context-profiles.md" "implementation.code" \
  "context profile owner missing implementation.code"
require_text "src/rules/context-profiles.md" "bounded-quick-fix" \
  "context scenario contract missing bounded-quick-fix"

section "context profile checks"
validate_context_profiles

section "documentation budget checks"
validate_word_budgets

section "scaffold template checks"
check_scaffold_tree "$repo_root/src/template" "template docs scaffold"

require_file "src/skills/registry.md"

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

  [ -d "$repo_root/src/skills/$name" ] ||
    fail "registry has stale skill row with no directory: $name"

  case "$mode" in
    bootstrap|planning|mutating|report-only|capture) ;;
    "lifecycle orchestration"|"review with optional fixes"|"review with approved planning"|"report-only by default") ;;
    *) fail "registry row for $name has invalid mode: $mode" ;;
  esac

  case "$commits" in
    no|"only through routed skills"|"only if it edits tracked docs/plans (via workers)") ;;
    "yes, via worker"|"yes, via workers"|"yes, via plan-maintenance worker"|"yes, via docs-maintenance worker") ;;
    "yes, via plan-maintenance worker for opted-in run docs and approved plans") ;;
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
  ' "$repo_root/src/skills/registry.md"
)
[ "$registry_row_count" -gt 0 ] || fail "registry has no skill rows"

skill_count=0
for skill_file in "$repo_root"/src/skills/*/SKILL.md; do
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
    fail "name mismatch in src/skills/$skill_dir/SKILL.md"
  grep -Fq "| \`$skill_dir\` |" "$repo_root/src/skills/registry.md" ||
    fail "registry missing skill: $skill_dir"
done
[ "$skill_count" -gt 0 ] || fail "no skill definitions found under src/skills"

require_file "src/rules/skill-contracts.md"
grep -Fq 'review-[none|low|medium|high|max]' "$repo_root/src/rules/skill-contracts.md" ||
  fail "review dial vocabulary missing"
grep -Fq 'cost-[low|medium|high|max]' "$repo_root/src/rules/skill-contracts.md" ||
  fail "cost dial vocabulary missing"

require_dir "src/rules/orchestrator"
require_dir "src/rules/subagent"
for orch_rule in lifecycle dispatch run-docs; do
  require_file "src/rules/orchestrator/$orch_rule.md"
done
for worker_rule in planning implementation review docs-maintenance plan-maintenance verification; do
  require_file "src/rules/subagent/$worker_rule.md"
done
[ ! -e "$repo_root/src/rules/orchestrating.md" ] ||
  fail "retired src/rules/orchestrating.md still exists; split it into src/rules/orchestrator/"
for dial in cost-low cost-medium cost-high cost-max review-none review-high; do
  grep -Fq "$dial" "$repo_root/src/rules/orchestrator/lifecycle.md" ||
    fail "orchestration dial '$dial' missing"
done

for fixed_skill in quick-fix plan ship-current-work ship-plans review-app; do
  match=$(grep -IEn -m 1 'src/rules/orchestrator/lifecycle[.]md' "$repo_root/src/skills/$fixed_skill/SKILL.md" || true)
  [ -z "$match" ] ||
    fail "fixed skill loads generic classifier by default: src/skills/$fixed_skill/SKILL.md:$match"
done

for readonly_rule in review verification; do
  match=$(grep -IEn -m 1 'fix-enabled|fix enabled|authorized fix|commit before reporting|made a fix|Stay read-only unless|may fix' "$repo_root/src/rules/subagent/$readonly_rule.md" || true)
  [ -z "$match" ] ||
    fail "$readonly_rule rule grants mutation authority: $match"
done

# Every src/rules path referenced in a skill body must resolve to a real file
# or directory, so dispatch routes never point nowhere.
while IFS= read -r skill_file; do
  while IFS= read -r ref_path; do
    [ -n "$ref_path" ] || continue
    normalized_ref=${ref_path#\~/agent-docs/}
    normalized_ref=${normalized_ref%/}
    [ -e "$repo_root/$normalized_ref" ] ||
      fail "skill ${skill_file#$repo_root/} references missing rule path: $ref_path"
  done < <(grep -oE 'src/rules/[A-Za-z0-9/_.-]+' "$skill_file" | sort -u)
done < <(find "$repo_root"/src/skills -name SKILL.md)

# The retired execution-model vocabulary must not return to skill bodies or the
# registry. (Decision docs and disposable plans may still name these terms to
# explain why they were dropped, so this check is scoped to the skill suite.)
for retired_token in delegate-on delegate-off no-intake direct-execution; do
  while IFS= read -r skill_surface; do
    match=$(grep -IEn -m 1 "$retired_token" "$skill_surface" || true)
    [ -z "$match" ] ||
      fail "retired execution-model token '$retired_token' in ${skill_surface#$repo_root/}:$match"
  done < <(find "$repo_root"/src/skills -name SKILL.md; printf '%s\n' "$repo_root/src/skills/registry.md")
done

adapter_doc="$repo_root/docs/architecture/install-and-adapters.md"
grep -Fq '~/.claude/skills/<name>' "$adapter_doc" ||
  fail "claude copy target undocumented"
grep -Fq '~/.agents/skills/<name>' "$adapter_doc" ||
  fail "codex copy target undocumented"

candidate_files() {
  find "$repo_root/README.md" "$repo_root/AGENTS.md" "$repo_root/CLAUDE.md" "$repo_root/docs" "$repo_root/src" \
    \( -path "$repo_root/src/verify-agent-docs.sh" -o -path "$repo_root/src/.claude-plugin" \) -prune -o \
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

policy_candidate_files() {
  find "$repo_root/README.md" "$repo_root/AGENTS.md" "$repo_root/CLAUDE.md" "$repo_root/docs" "$repo_root/src" \
    \( -path "$repo_root/src/verify-agent-docs.sh" -o -path "$repo_root/docs/plans" -o -path "$repo_root/src/.claude-plugin" \) -prune -o \
    -type f -print
}

reject_policy_match() {
  local pattern=$1
  local message=$2
  local file
  local match

  while IFS= read -r file; do
    match=$(grep -IEn -m 1 "$pattern" "$file" || true)
    [ -z "$match" ] ||
      fail "$message: ${file#$repo_root/}:$match"
  done < <(policy_candidate_files)
}

allow_retired_reference() {
  local relative_file=$1
  local label=$2
  local line_text=$3

  case "$label|$relative_file|$line_text" in
    'new-project-prompt|src/agent-docs-guide.md|`v1/new-project-prompt.md` is retired; `/rebuild-agent-docs` is the') return 0 ;;
    'fresh-planning-chat|docs/decisions/agent-docs.md|`src/skills/plan/SKILL.md`; the older `fresh-planning-chat` name is retired.') return 0 ;;
    'new-project-prompt|docs/plans/orchestrator/runtime-install-model/streams/ws1-rename.md|  and the allowlisted `v1/new-project-prompt.md` retired-name mention.') return 0 ;;
    'new-project-prompt|docs/plans/orchestrator/runtime-install-model/streams/ws1-rename.md|- `allow_retired_reference` allowlist in verifier: `v1/new-project-prompt.md`') return 0 ;;
    'new-project-prompt|docs/plans/orchestrator/runtime-install-model/hub.md|  file mentioning retired names (e.g. `new-project-prompt`, possibly') return 0 ;;
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
reject_any_match 'src/[.]claude-plugin' "retired Claude plugin path referenced"
reject_policy_match 'Token usage:' "default token usage boilerplate remains"
reject_policy_match 'unavailable_reason' "usage-unavailable boilerplate remains"
reject_policy_match 'telemetry JSONL|--telemetry-jsonl' "telemetry JSONL policy remains"
reject_policy_match 'fix-enabled|fix enabled' "fix-enabled review/verification path remains"
[ ! -e "$repo_root/src/.claude-plugin" ] ||
  fail "retired Claude plugin path exists: src/.claude-plugin"

for script_path in \
  install-agentdocs-local.sh \
  src/install-agentdocs.sh \
  src/export-chatgpt-context.sh \
  src/verify-agent-docs.sh; do
  require_executable "$script_path"
  require_git_executable_mode "$script_path"
done

# Adapter freshness: copied managed skills in each tool destination must match
# the installed runtime skills under ~/.agentdocs/skills/. The installers own
# the copy; this gate only observes that installed copies are not stale. It is
# skipped when the runtime is not installed (e.g. a fresh checkout in CI).
section "local adapter freshness checks"
check_adapter_freshness() {
  local skills_root="${HOME:?HOME is not set}/.agentdocs/skills"
  local marker=".agent-docs-managed"
  local dest_root skill_dir skill_name dest existing name

  if [ ! -d "$skills_root" ]; then
    printf 'runtime skills not installed (%s); skipping adapter freshness\n' \
      "$skills_root"
    return 0
  fi

  for dest_root in "$HOME/.agents/skills" "$HOME/.claude/skills"; do
    [ ! -L "$dest_root" ] ||
      fail "$dest_root is a symlink; refusing to check a tool-owned skill root"
    [ -d "$dest_root" ] || fail "missing skill destination: $dest_root"

    for existing in "$dest_root"/*; do
      { [ -e "$existing" ] || [ -L "$existing" ]; } || continue
      name=$(basename "$existing")
      if [ -e "$existing/$marker" ] && [ ! -d "$skills_root/$name" ]; then
        fail "$existing is managed by agent-docs but no matching runtime skill exists"
      fi
    done

    for skill_dir in "$skills_root"/*/; do
      [ -d "$skill_dir" ] || continue
      skill_name=$(basename "$skill_dir")
      dest="$dest_root/$skill_name"

      [ -d "$dest" ] || fail "missing copied skill: $dest"
      [ -e "$dest/$marker" ] || fail "$dest exists but is not managed by agent-docs"
      diff -qr --exclude="$marker" "$skill_dir" "$dest" >/dev/null ||
        fail "$dest is stale; run install-agentdocs-local.sh"
    done

    printf 'agent-docs skills are fresh in %s\n' "$dest_root"
  done
}
check_adapter_freshness

printf 'ALL AGENT-DOCS GATES PASS\n'
