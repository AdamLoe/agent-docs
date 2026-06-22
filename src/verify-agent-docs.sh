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
  bash src/verify-agent-docs.sh --contract-check
  bash src/verify-agent-docs.sh --resolve <profile-id>
  bash src/verify-agent-docs.sh --resolve --skill <name> [--phase <id>] [--repo <path>] [--risk <tag>]
  bash src/verify-agent-docs.sh --equivalence
  bash src/verify-agent-docs.sh --measure-launch <skill-name>
  bash src/verify-agent-docs.sh --scaffold <repo-root>

Default mode validates the agent-docs kit checkout that contains this script.
The --context-report mode prints the read-only context profile and scenario
contract, including exact files, conditions, word totals, and budget exceptions.
It may print measurements even when red, but it exits nonzero and does not print
PASS while an enforced profile is over budget or a contract check fails.
Scenario rows are read from the never-auto-loaded kernel authority
src/kernel/scenarios.json.
The --contract-check mode runs the source-bound contract checks
(launch budgets, lifecycle startup loads, subagent-bundle spell-outs, read-only
role authority, plan_closeout consistency, review-app pre-audit/eager loads,
scenario source-binding, report fields, and final-ordering). These checks GATE:
it prints every violation with file:line where possible, then exits nonzero and
does not print PASS when any violation exists.
The --resolve mode prints one profile's core rule paths, conditional overlays,
mutation capability, and budget so a skill can resolve a single profile without
loading the whole table. With --skill/--phase/--repo/--risk flags instead of a
positional id, --resolve runs the exact-context MERGE: it joins the kernel
profile (core rules + overlays + budget + exact resolved size) with the repo's
manifest fields, execution.yaml fields (a notice when absent, since Wave 4 adds
it), task-routed doc/source hints, allowed packs (packs.json - empty until Wave
4), and the named checks. The merge is references-only and read-only: it copies
no rule/doc/source body and writes no artifact, and a read-only profile is never
resolved into a mutation capability or a mutator pack (no self-upgrade).
The --equivalence mode is the single-authority proof for the kernel
(src/kernel/*.json): it asserts the superseded Markdown profile table and JSON
scenario fixture are gone, the kernel still resolves all profiles/scenarios, and
no profile/scenario/budget fact lives in both the kernel and Markdown/bash. It
exits nonzero on any violation.
The --measure-launch mode prints the controlled launch word total for one skill
(skill body, shared startup contract, startup orchestrator/role rules, docs
index, and requested manifest slots), excluding task-routed source/tests. An
orchestrator/role rule counts only when the skill body genuinely instructs
reading it at startup; a rules/... path appearing only in a prohibition, a
deferred-load gloss, or a References pointer does not count.
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

# execution.yaml is the per-repo execution binding (human-authored YAML). The
# kernel stays JSON read by stdlib json; execution.yaml needs a YAML parser. Per
# the PyYAML-optional policy, this validator TRIES to import a YAML parser:
# present, it validates the FULL schema (every required top-level key, scalar
# types, and the {} / [] container shapes); absent, it degrades to a shallow
# presence/text check plus an "install pyyaml" remediation. Both branches leave
# the gate GREEN so the core gate runs offline on any bash + stdlib-python host.
EXECUTION_YAML_REQUIRED_KEYS="schema_version language roots commands path_to_check services browser database protected_paths forbidden_paths generated_paths scarce_resources pack_routes bootstrap secrets observability network test_data"

validate_execution_yaml() {
  validate_execution_yaml_under "$repo_root" "$1" "$2"
}

validate_execution_yaml_under() {
  local root=$1
  local path=$2
  local label=$3
  local python_cmd

  [ -f "$root/$path" ] ||
    fail "$label missing required execution binding: $path"

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot validate execution.yaml; install python"

  "$python_cmd" - "$root/$path" "$label" "$EXECUTION_YAML_REQUIRED_KEYS" <<'PY' || fail "$label execution.yaml validation failed: $path"
import sys, pathlib

path = pathlib.Path(sys.argv[1])
label = sys.argv[2]
required = sys.argv[3].split()
text = path.read_text(encoding="utf-8")

try:
    import yaml
except ImportError:
    # Graceful degradation: no parser, so we cannot validate the schema. Run a
    # shallow presence/text check (each required key visibly present as a
    # top-level `key:` line) and emit a clear remediation. Still GREEN.
    missing = [k for k in required if not any(
        line.split("#", 1)[0].rstrip().startswith(k + ":")
        for line in text.splitlines())]
    if missing:
        print(f"EXECUTION-YAML FAIL ({label}): missing top-level keys "
              f"{', '.join(missing)} in {path}", file=sys.stderr)
        raise SystemExit(1)
    print(f"  {label}: execution.yaml present, {len(required)} required keys "
          f"text-checked (install pyyaml for full execution.yaml validation)")
    raise SystemExit(0)

# Parser present: validate the full schema.
try:
    data = yaml.safe_load(text)
except yaml.YAMLError as exc:
    print(f"EXECUTION-YAML FAIL ({label}): not valid YAML: {exc}", file=sys.stderr)
    raise SystemExit(1)

if not isinstance(data, dict):
    print(f"EXECUTION-YAML FAIL ({label}): top level must be a mapping", file=sys.stderr)
    raise SystemExit(1)

errors = []
for key in required:
    if key not in data:
        errors.append(f"missing required key: {key}")

# Type contracts for the keys whose shape the resolver and workers rely on.
list_keys = ["language", "path_to_check", "services", "protected_paths",
             "forbidden_paths", "generated_paths", "scarce_resources",
             "pack_routes"]
map_keys = ["roots", "commands", "browser", "database", "bootstrap",
            "secrets", "observability", "network", "test_data"]
for key in list_keys:
    if key in data and data[key] is not None and not isinstance(data[key], list):
        errors.append(f"{key} must be a list")
for key in map_keys:
    if key in data and data[key] is not None and not isinstance(data[key], dict):
        errors.append(f"{key} must be a mapping")
if "schema_version" in data and not isinstance(data["schema_version"], int):
    errors.append("schema_version must be an integer")
# commands must name every operational command slot (null is allowed).
if isinstance(data.get("commands"), dict):
    for slot in ("format", "lint", "typecheck", "targeted_test",
                 "full_test", "build", "smoke"):
        if slot not in data["commands"]:
            errors.append(f"commands missing slot: {slot}")

if errors:
    for e in errors:
        print(f"EXECUTION-YAML FAIL ({label}): {e} in {path}", file=sys.stderr)
    raise SystemExit(1)

print(f"  {label}: execution.yaml full-schema valid "
      f"({len(required)} required keys, parser=PyYAML)")
PY
}

# validate_kernel_packs: the kernel pack gates (Wave 4b). Every pack in packs.json
# must (a) carry a trigger — at least one path_glob or risk_tag (a pack without a
# trigger FAILS, since the merge rule cannot route an un-triggered pack), (b) name
# a rule_leaf that exists on disk, and (c) name an evidence requirement. Reads the
# kernel with stdlib json only (no YAML); writes nothing.
validate_kernel_packs() {
  local python_cmd
  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot validate kernel packs; install python"

  "$python_cmd" - "$repo_root/src/kernel/packs.json" "$repo_root" <<'PY' || fail "kernel pack validation failed: src/kernel/packs.json"
import json, pathlib, sys

packs_path = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])
data = json.loads(packs_path.read_text(encoding="utf-8"))
packs = data.get("packs", [])

errors = []
seen = set()
for i, p in enumerate(packs):
    pid = p.get("id")
    if not pid:
        errors.append(f"pack #{i} missing id")
        continue
    if pid in seen:
        errors.append(f"duplicate pack id: {pid}")
    seen.add(pid)
    trig = p.get("trigger") or {}
    globs = trig.get("path_globs") or []
    tags = trig.get("risk_tags") or []
    if not globs and not tags:
        errors.append(f"pack {pid} has NO trigger (needs path_globs or risk_tags)")
    leaf = p.get("rule_leaf")
    if not leaf:
        errors.append(f"pack {pid} missing rule_leaf")
    elif not (repo_root / leaf).is_file():
        errors.append(f"pack {pid} rule_leaf missing on disk: {leaf}")
    if not p.get("evidence"):
        errors.append(f"pack {pid} missing evidence requirement")

if errors:
    for e in errors:
        print(f"KERNEL-PACK FAIL: {e}", file=sys.stderr)
    raise SystemExit(1)
print(f"  kernel packs valid: {len(packs)} packs, each with a trigger, an "
      f"existing rule_leaf, and an evidence requirement")
PY
}

# Profile rows come from the kernel (src/kernel/profiles.json), the sole machine
# authority for worker context profiles since the Wave 1b cutover. Emits one
# tab-separated row per profile in the legacy column order so every downstream
# consumer (profile_word_total, context_report, resolve_profile) is unchanged.
context_profile_rows() {
  local python_cmd
  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot read kernel profiles; install python"

  "$python_cmd" - "$repo_root/src/kernel/profiles.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)

fields = [
    "id", "purpose", "core_rule_paths", "overlays",
    "mutation_capability", "budget_words", "enforcement_status",
]
for row in data.get("profiles", []):
    print("\t".join(str(row.get(field, "")) for field in fields))
PY
}

scenario_fixture() {
  printf '%s' "$repo_root/src/kernel/scenarios.json"
}

scenario_rows() {
  local python_cmd
  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot read scenario fixture; install python"

  "$python_cmd" - "$(scenario_fixture)" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as handle:
    data = json.load(handle)

fields = [
    "scenario_id", "task_shape", "expected_questions", "expected_profiles",
    "expected_phases", "expected_mutator_count", "state_basis_fields",
    "final_ordering", "budget_expectation",
]
for row in data.get("scenarios", []):
    print("\t".join(str(row.get(field, "")) for field in fields))
PY
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
  local enforced_violations=0
  local contract_violations=0

  section "context profiles"
  while IFS=$'\t' read -r id purpose core_paths overlays mutation budget status; do
    [ -z "$profile_filter" ] || [ "$id" = "$profile_filter" ] || continue
    found=1
    total=$(profile_word_total "$core_paths")
    exception="none"
    if [ "$total" -gt "$budget" ]; then
      # Wave 5b: an over-budget profile in an enforced status is a hard
      # violation; in report-only it is still merely reported.
      case "$status" in
        pilot-enforced|enforced)
          exception="OVER BUDGET in $status status: $total>$budget (enforced violation)"
          enforced_violations=$((enforced_violations + 1))
          ;;
        *)
          exception="over budget in $status status; correctness requires listed core files"
          ;;
      esac
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

  if [ -z "$profile_filter" ]; then
    contract_check || contract_violations=$?
  fi

  # Wave 5b: --context-report may print measurements even when red, but it must
  # exit nonzero and must not print PASS while an enforced violation exists.
  if [ "$enforced_violations" -ne 0 ] || [ "$contract_violations" -ne 0 ]; then
    fail "context report found enforced violations: $enforced_violations over-budget enforced profile(s), $contract_violations contract violation(s)"
  fi

  printf 'CONTEXT REPORT PASS\n'
}

# --resolve <profile-id>: print exactly one profile's resolved core rule paths,
# conditional overlays, mutation capability, and budget, so a skill/dispatch can
# resolve ONE profile without loading the whole profiles table. Writes nothing
# and emits no copied rule bodies.
resolve_profile() {
  local target=$1
  local found=0
  local id purpose core_paths overlays mutation budget status total exception
  local display_paths

  [ -n "$target" ] || { usage >&2; exit 2; }

  while IFS=$'\t' read -r id purpose core_paths overlays mutation budget status; do
    [ "$id" = "$target" ] || continue
    found=1
    total=$(profile_word_total "$core_paths")
    exception="none"
    if [ "$total" -gt "$budget" ]; then
      exception="over budget in $status status; correctness requires listed core files"
    fi
    display_paths=${core_paths//\`/}
    printf 'RESOLVE %s\n' "$id"
    printf '  core_paths: %s\n' "$display_paths"
    printf '  overlays: %s\n' "$overlays"
    printf '  mutation: %s\n' "$mutation"
    printf '  budget: %s\n' "$budget"
    printf '  resolved_words: %s\n' "$total"
    printf '  enforcement: %s\n' "$status"
    printf '  budget_exception: %s\n' "$exception"
  done < <(context_profile_rows)

  [ "$found" -eq 1 ] || fail "unknown context profile: $target"
  printf 'RESOLVE PASS\n'
}

# --resolve --skill/--phase/--repo/--risk: EXACT-CONTEXT MERGE resolution. The
# back-compat single-profile mode above takes one positional profile id; this
# merge mode takes named flags and emits the merged exact-context resolution a
# worker needs to start: the kernel profile (core rule paths + overlays + budget
# + EXACT resolved size) joined with the consuming repo's manifest fields,
# execution.yaml fields (when present; a clear notice when absent), task-routed
# docs with heading hints, source/test hints, and the ACTIVATED packs computed by
# the sole pack loader — (path-routes ∪ scoper-tags) ∩ execution-allowlist — as
# references (leaf path + trigger + evidence), plus the named checks. It is
# REFERENCES-ONLY and READ-ONLY: every line is a path + heading hint + size, it
# copies NO rule/doc/source body, and it WRITES NO artifact (no file, no temp,
# no generated context). No-self-upgrade invariant: the merge reports the kernel
# profile's mutation_capability verbatim, so a read-only profile can never be
# resolved into a mutating capability or an allowed mutator pack (the no-self-
# upgrade rule lives in src/rules/orchestrator/dispatch.md).
resolve_merge() {
  local skill="" phase="" repo="" risk=""
  local python_cmd

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --skill) skill=$2; shift 2 ;;
      --phase) phase=$2; shift 2 ;;
      --repo)  repo=$2;  shift 2 ;;
      --risk)  risk=$2;  shift 2 ;;
      *) usage >&2; exit 2 ;;
    esac
  done

  [ -n "$skill" ] || [ -n "$phase" ] || { usage >&2; exit 2; }

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot resolve merged context; install python"

  # Default the consuming repo to the source checkout when --repo is omitted.
  [ -n "$repo" ] || repo=$repo_root

  "$python_cmd" - \
    "$repo_root/src/kernel/profiles.json" \
    "$repo_root/src/kernel/workflows.json" \
    "$repo_root/src/kernel/packs.json" \
    "$repo_root" \
    "$skill" "$phase" "$repo" "$risk" <<'PY' || fail "merged context resolution failed"
import json, re, sys, pathlib

profiles_path = pathlib.Path(sys.argv[1])
workflows_path = pathlib.Path(sys.argv[2])
packs_path = pathlib.Path(sys.argv[3])
repo_root = pathlib.Path(sys.argv[4])
skill, phase, repo, risk = sys.argv[5], sys.argv[6], sys.argv[7], sys.argv[8]
repo = pathlib.Path(repo)

profiles = {p["id"]: p for p in json.loads(profiles_path.read_text(encoding="utf-8"))["profiles"]}
workflows = {w["skill"]: w for w in json.loads(workflows_path.read_text(encoding="utf-8"))["workflows"]}
packs = json.loads(packs_path.read_text(encoding="utf-8"))

notices = []

# --- 1. Pick the profile from --skill or --phase -------------------------------
# A skill names the profile(s) it dispatches in its body ("Profile: `id`"). The
# resolver picks the profile the skill body names that the skill's kernel
# workflow also allows; this never copies the skill body, only matches ids.
profile_id = None
wf = workflows.get(skill) if skill else None
allowed = set(wf.get("allowed_profiles", [])) if wf else set()

if skill:
    body_path = repo_root / "src" / "skills" / skill / "SKILL.md"
    if not body_path.is_file():
        print(f"MERGE-RESOLVE FAIL: unknown skill {skill!r}", file=sys.stderr)
        raise SystemExit(1)
    body = body_path.read_text(encoding="utf-8")
    # Profiles named in the body, ordered by FIRST appearance: the primary worker
    # phase (and so the primary profile) is described before secondary phases
    # like a verification gate, so the earliest-named profile is the primary one.
    named = sorted(
        (pid for pid in profiles if re.search(r"`%s`" % re.escape(pid), body)),
        key=lambda pid: body.index("`%s`" % pid),
    )
    # Prefer a named profile the workflow allows; else earliest named; else workflow first.
    pick = [p for p in named if not allowed or p in allowed] or named
    if pick:
        profile_id = pick[0]
    elif wf and wf.get("allowed_profiles"):
        profile_id = wf["allowed_profiles"][0]
elif phase:
    # A phase id is a profile id (or a workflow first_phase that is a profile id).
    if phase in profiles:
        profile_id = phase
    else:
        for w in workflows.values():
            if w.get("first_phase") == phase and w.get("allowed_profiles"):
                profile_id = w["allowed_profiles"][0]
                break

if profile_id is None or profile_id not in profiles:
    print(f"MERGE-RESOLVE FAIL: could not resolve a profile from "
          f"skill={skill!r} phase={phase!r}", file=sys.stderr)
    raise SystemExit(1)

prof = profiles[profile_id]

# --- 2. EXACT resolved size of the profile's core rule paths -------------------
# Reference (path + word size) only; never the rule body itself.
core_refs = []
resolved_words = 0
for raw in prof["core_rule_paths"].split(","):
    rel = raw.strip().strip("`")
    target = repo_root / rel
    size = len(target.read_text(encoding="utf-8").split()) if target.is_file() else None
    if size is None:
        print(f"MERGE-RESOLVE FAIL: missing rule path {rel}", file=sys.stderr)
        raise SystemExit(1)
    resolved_words += size
    core_refs.append((rel, size))

# --- 3. Manifest fields from the (consuming) repo ------------------------------
# References to the manifest slots a worker routes through, not their contents.
manifest_path = repo / "docs" / "_meta" / "manifest.md"
manifest_fields = []
if manifest_path.is_file():
    mtext = manifest_path.read_text(encoding="utf-8")
    for slot in ("repo_name", "code_root"):
        m = re.search(r"^%s:\s*(.+)$" % slot, mtext, re.MULTILINE)
        if m:
            manifest_fields.append((slot, m.group(1).strip()))
    for section in ("change-to-doc", "drift-gates", "drift-verification"):
        if re.search(r"^##\s+%s\b" % re.escape(section), mtext, re.MULTILINE):
            manifest_fields.append((f"manifest §{section}",
                                    f"{manifest_path}#{section}"))
else:
    notices.append(f"no manifest at {manifest_path} (repo not scaffolded)")

# --- 4. execution.yaml fields (the per-repo execution binding) -----------------
# Surface which operational + Q9 sections the binding carries as references the
# worker routes through; never copy the field VALUES (PyYAML may be absent, so
# parse only when available and fall back to a top-level-key text scan).
exec_path = repo / "docs" / "_meta" / "execution.yaml"
exec_fields = []
EXEC_SECTIONS = [
    "language", "roots", "commands", "path_to_check", "services", "browser",
    "database", "protected_paths", "forbidden_paths", "generated_paths",
    "scarce_resources", "pack_routes", "bootstrap", "secrets", "observability",
    "test_data", "network",
]
# pack_routes drives pack activation in section 5: each entry routes a path OR a
# risk to a pack id. We parse it (when a YAML parser is present) into the two
# halves the merge rule needs: the ids reachable by a PATH route and the ids
# reachable by a RISK route (keyed by the risk tag). Without a parser we can only
# detect section presence, so activation degrades to empty with a clear notice.
route_path_pack_ids = set()          # pack ids the repo routes by a path entry
route_risk_pack_ids = {}             # risk-tag -> {pack ids routed by that risk}
exec_allowlist_ids = set()           # union of all routed pack ids (allowlist)
pack_routes_parsed = False
if exec_path.is_file():
    etext = exec_path.read_text(encoding="utf-8")
    present = []
    try:
        import yaml  # optional; references-only either way
        edata = yaml.safe_load(etext)
        if isinstance(edata, dict):
            present = [s for s in EXEC_SECTIONS if s in edata]
            routes = edata.get("pack_routes") or []
            if isinstance(routes, list):
                pack_routes_parsed = True
                for entry in routes:
                    if not isinstance(entry, dict):
                        continue
                    pid = entry.get("pack")
                    if not pid:
                        continue
                    exec_allowlist_ids.add(pid)
                    if "path" in entry:
                        route_path_pack_ids.add(pid)
                    if "risk" in entry:
                        route_risk_pack_ids.setdefault(entry["risk"], set()).add(pid)
    except ImportError:
        notices.append("pyyaml absent: execution.yaml sections detected by "
                       "top-level-key scan (install pyyaml for full validation); "
                       "pack activation needs a parser and is reported empty")
        present = [s for s in EXEC_SECTIONS if any(
            line.split("#", 1)[0].rstrip().startswith(s + ":")
            for line in etext.splitlines())]
    exec_fields.append(("execution.yaml", str(exec_path)))
    if present:
        exec_fields.append(("sections", ", ".join(present)))
else:
    notices.append(f"no execution binding at {exec_path} (repo not scaffolded "
                   "with docs/_meta/execution.yaml); operational/pack-routing "
                   "fields unavailable - resolving with kernel + manifest only")

# --- 5. Activated packs: (path-routes ∪ scoper-tags) ∩ execution-allowlist ------
# This is the SOLE pack loader. Three sets, intersected deterministically:
#   path-routes      = pack ids the repo routes by a `path:` entry in pack_routes
#                      (a diff would narrow these per-file; the resolver has no
#                      diff, so it surfaces the full routed-by-path set);
#   scoper-tags      = pack ids reachable from the scope brief's risk tag (--risk):
#                      a `risk:` route whose tag matches, OR a pack whose own
#                      trigger.risk_tags name the requested risk and that the repo
#                      also routed (in the allowlist);
#   execution-allowlist = every pack id the repo's pack_routes references.
# A pack NOT in the allowlist can never activate (the pack non-activation
# property). Read-only profiles are reported but never gain a mutator pack
# (no self-upgrade). Report references only: leaf path + trigger + evidence; copy
# no leaf body; write no artifact.
pack_by_id = {p["id"]: p for p in packs.get("packs", []) if p.get("id")}

def pack_risk_tags(p):
    trig = p.get("trigger") or {}
    return set(trig.get("risk_tags") or [])

# path-routes ∪ scoper-tags (the requested activation set), before allowlist gating.
requested = set(route_path_pack_ids)
if risk:
    requested |= route_risk_pack_ids.get(risk, set())
    requested |= {pid for pid, p in pack_by_id.items() if risk in pack_risk_tags(p)}

# ∩ execution-allowlist — and the pack must exist in the kernel.
activated_pack_ids = sorted(
    pid for pid in (requested & exec_allowlist_ids) if pid in pack_by_id
)

# Allowlisted-but-unknown ids (routed to a pack the kernel does not define) are a
# binding error worth surfacing, not silently dropping.
unknown_routed = sorted(exec_allowlist_ids - set(pack_by_id))
if unknown_routed:
    notices.append("execution.yaml routes unknown pack id(s): "
                   + ", ".join(unknown_routed))

if not pack_by_id:
    notices.append("packs.json defines no packs; nothing can activate")
elif not exec_allowlist_ids and pack_routes_parsed:
    notices.append("repo pack_routes is empty: no pack is in the execution "
                   "allowlist, so no pack activates (pack non-activation)")

# --- 6. Emit references-only merged resolution ---------------------------------
print(f"MERGE-RESOLVE skill={skill or '-'} phase={phase or '-'} "
      f"repo={repo} risk={risk or '-'}")
print(f"  profile: {profile_id}")
print(f"  purpose: {prof['purpose']}")
print(f"  mutation_capability: {prof['mutation_capability']}")
print(f"  budget_words: {prof['budget_words']}")
print(f"  resolved_words: {resolved_words}")
within = "within" if resolved_words <= int(prof["budget_words"]) else "OVER"
print(f"  budget_status: {within} ({resolved_words}/{prof['budget_words']})")
print("  core_rule_paths (reference only, sizes in words):")
for rel, size in core_refs:
    print(f"    - {rel} [{size}w]")
print(f"  overlays: {prof['overlays']}")
print("  manifest_fields:")
for name, val in manifest_fields or [("(none)", "")]:
    print(f"    - {name}: {val}")
print("  execution_yaml:")
for name, val in exec_fields or [("(absent)", "see notices")]:
    print(f"    - {name}: {val}")
print("  task_routed_docs (heading hints from dispatch; route via manifest "
      "change-to-doc + ownership):")
print("    - <named in dispatch> [path → heading hint]")
print("  source_test_hints (path → symbol; selected by task, never line "
      "numbers):")
print("    - <named in dispatch> [path → symbol]")
print("  execution_allowlist (repo pack_routes): "
      + (", ".join(sorted(exec_allowlist_ids)) or "(none)"))
print("  activated_packs (path-routes ∪ scoper-tags) ∩ execution-allowlist "
      "(references only — leaf path + trigger + evidence):")
if activated_pack_ids:
    for pid in activated_pack_ids:
        p = pack_by_id[pid]
        trig = p.get("trigger") or {}
        globs = ", ".join(trig.get("path_globs") or []) or "-"
        tags = ", ".join(trig.get("risk_tags") or []) or "-"
        print(f"    - {pid}")
        print(f"        rule_leaf: {p.get('rule_leaf')}")
        print(f"        trigger: paths[{globs}] risks[{tags}]")
        print(f"        evidence: {p.get('evidence')}")
else:
    print("    - (none)")
# Pack non-activation, made explicit: packs the kernel defines but the repo did
# NOT route stay unloaded. Naming them proves the property in the resolver output.
unactivated = sorted(set(pack_by_id) - set(activated_pack_ids))
if unactivated:
    print("  unactivated_packs (defined but not routed by this repo — NOT "
          "loaded): " + ", ".join(unactivated))
print("  checks (run the cheapest sufficient gate named by the dispatch / "
      "manifest drift-gates):")
print(f"    - {manifest_path}#drift-gates")
if prof["mutation_capability"] == "read-only":
    print("  self_upgrade: DENIED - read-only profile; resolution grants no "
          "mutation capability and no mutator pack")
else:
    print("  self_upgrade: profile is mutating by dispatch; a worker may "
          "request an ALLOWED pack post-discovery but may not change role")
for n in notices:
    print(f"  notice: {n}")
print("MERGE-RESOLVE PASS (references only; no rule/doc/source body copied; "
      "no artifact written)")
PY
}

# --equivalence: single-authority proof. Before the Wave 1b cutover this proved
# the shadow kernel byte-identical to the Markdown table + JSON fixture; those
# live comparison targets are gone now, so the byte-identity check has been
# retired and this mode asserts the kernel is the SOLE authority instead. It
# fails loudly if any superseded source returns, if the kernel cannot be
# resolved, or if any profile/scenario/budget machine fact still lives in
# Markdown/bash (the dual-authority detector). Writes nothing.
equivalence_check() {
  local python_cmd
  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot run equivalence check; install python"

  section "kernel single-authority proof"

  # 1. The superseded authorities must be gone (no resurrection of dual source).
  [ ! -f "$repo_root/src/verify-fixtures/workflow-scenarios.json" ] ||
    fail "superseded scenario fixture resurrected: src/verify-fixtures/workflow-scenarios.json"
  if grep -qE '^\| `[^`]+` \|.*\|.*\| (read-only|mutating|conditional) \|' \
     "$repo_root/src/rules/context-profiles.md"; then
    fail "superseded profile table resurrected in src/rules/context-profiles.md"
  fi
  printf 'ok   superseded Markdown profile table and JSON scenario fixture are gone\n'

  # 2. The kernel still parses and resolves all 14 profiles + 13 scenarios.
  #    (Wave 2 added the read-only planning.scope profile and the
  #    orchestrate-planning-scope-first scenario row; Wave 3 added the read-only
  #    docs.inspect and plans.inspect inspection profiles; Wave 5 added the
  #    blocked-handoff-discharge scenario row.)
  if ! "$python_cmd" - \
       "$repo_root/src/kernel/profiles.json" \
       "$(scenario_fixture)" <<'PY'
import json, sys
profiles = json.load(open(sys.argv[1], encoding="utf-8"))["profiles"]
scenarios = json.load(open(sys.argv[2], encoding="utf-8"))["scenarios"]
if len(profiles) != 14:
    raise SystemExit(f"kernel profiles count {len(profiles)} != 14")
if len(scenarios) != 13:
    raise SystemExit(f"kernel scenarios count {len(scenarios)} != 13")
print(f"ok   kernel resolves {len(profiles)} profiles and {len(scenarios)} scenarios")
PY
  then
    fail "kernel did not resolve the expected profile/scenario inventory"
  fi

  # 3. Dual-authority detector: no profile/scenario/budget machine fact may live
  #    in BOTH the kernel and Markdown/bash. Reuses the kernel-wide check.
  detect_dual_authority

  printf 'EQUIVALENCE PASS\n'
}

# detect_dual_authority: fail if any machine fact owned by the kernel (a profile
# row field, a budget constant, the classifier allowlist, or a scenario row)
# still also lives in Markdown (context-profiles.md) or in a bash literal in this
# script. This is the single hardest Wave 1b acceptance criterion: after the
# cutover the kernel is the sole authority, so these facts must appear nowhere
# else as data.
detect_dual_authority() {
  local profiles_md="$repo_root/src/rules/context-profiles.md"
  local self="$repo_root/src/verify-agent-docs.sh"
  local python_cmd
  local violations=0

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot detect dual authority; install python"

  # No profile data row (`id | ... | mutation | budget | status`) in Markdown.
  if grep -qE '^\| `[^`]+` \|.*\| (read-only|mutating|conditional) \|' "$profiles_md"; then
    printf 'WARN profile data row still in src/rules/context-profiles.md\n' >&2
    violations=$((violations + 1))
  fi
  # No budget/scenario column header table in the profile owner doc.
  if grep -qE '^\| id \| purpose \| core_rule_paths \|' "$profiles_md"; then
    printf 'WARN profile column-header table still in src/rules/context-profiles.md\n' >&2
    violations=$((violations + 1))
  fi
  # Reconcile against the KERNEL's real values: no enforced budget number
  # (per-profile budget_words or the launch budgets), no classifier-allowlist
  # name, and no scenario_id may reappear as Markdown TABLE DATA in the profile
  # owner doc. Restricting to table cells (lines starting with `|`) keeps human
  # rationale prose allowed: the measured-floor numbers (1542/1148/2016) are not
  # kernel facts so they never match, and prose that names a classifier as an
  # example (e.g. the heaviest-skill rationale) is not a data cell. Reads the
  # kernel live so a re-added budget table or scenario row is caught without
  # hardcoding the numbers here.
  if ! "$python_cmd" - \
       "$repo_root/src/kernel/profiles.json" \
       "$(scenario_fixture)" \
       "$profiles_md" <<'PY'
import json, re, sys

profiles = json.load(open(sys.argv[1], encoding="utf-8"))
scenarios = json.load(open(sys.argv[2], encoding="utf-8"))["scenarios"]
doc = open(sys.argv[3], encoding="utf-8").read()

budget_numbers = {str(p["budget_words"]) for p in profiles["profiles"]}
budgets = profiles["budgets"]
budget_numbers.add(str(budgets["fixed_skill_launch"]))
budget_numbers.add(str(budgets["classifier_skill_launch"]))
classifier_names = set(budgets["classifier_skills"])
scenario_ids = {s["scenario_id"] for s in scenarios}

# Only Markdown table DATA rows count as duplicated data. A table row starts
# with "|"; skip the header/separator rows (a separator is all -:| chars).
def data_rows(text):
    for line in text.splitlines():
        s = line.strip()
        if not s.startswith("|"):
            continue
        if re.fullmatch(r"\|[\s:\-|]+\|?", s):
            continue
        yield s

bad = []
for row in data_rows(doc):
    cells = [c.strip() for c in row.strip().strip("|").split("|")]
    for cell in cells:
        # Standalone numeric cell that equals a kernel budget number.
        if cell in budget_numbers:
            bad.append(f"kernel budget number {cell} as table data")
        # Backticked or bare token cell that equals a classifier name / scenario id.
        token = cell.strip("`")
        if token in classifier_names:
            bad.append(f"classifier-allowlist name {token!r} as table data")
        if token in scenario_ids:
            bad.append(f"scenario_id {token!r} as table data")

if bad:
    for b in dict.fromkeys(bad):
        print(b, file=sys.stderr)
    raise SystemExit(1)
PY
  then
    printf 'WARN kernel budget/classifier/scenario fact reappears as table data in src/rules/context-profiles.md\n' >&2
    violations=$((violations + 1))
  fi
  # No hardcoded budget constants or classifier allowlist literal in bash. A
  # resurrection is a real bash ASSIGNMENT of the value (optionally `local`),
  # e.g. `  local fixed_budget=2000`. Lines that merely mention the literal as a
  # grep argument (this detector's own machinery) or in a comment are excluded
  # by requiring assignment syntax at the statement start and rejecting `grep`.
  if grep -vE 'grep' "$self" |
     grep -qE '^[[:space:]]*(local[[:space:]]+)?(fixed_budget=2000|classifier_budget=3300)\b'; then
    printf 'WARN hardcoded budget constant assigned in src/verify-agent-docs.sh\n' >&2
    violations=$((violations + 1))
  fi
  if grep -vE 'grep' "$self" |
     grep -qE '^[[:space:]]*(local[[:space:]]+)?classifier_allowlist=" orchestrate fresh-chat start-session "'; then
    printf 'WARN hardcoded classifier_allowlist literal assigned in src/verify-agent-docs.sh\n' >&2
    violations=$((violations + 1))
  fi
  if [ "$violations" -ne 0 ]; then
    fail "dual authority detected: $violations machine fact(s) live in both the kernel and Markdown/bash"
  fi
  printf 'ok   no profile/scenario/budget fact lives in both the kernel and Markdown/bash\n'
}

# skill_startup_loads_rule <skill-file> <rule-relpath>: exit 0 iff the skill body
# GENUINELY instructs reading the named rule at startup. Sentence/paragraph
# aware (markdown wraps a "read ... <path>" instruction across soft line breaks),
# mirroring the contract-check sentence logic. A rule is a startup load only when
# some sentence both (a) names the `rules/<rule>` path and (b) carries a read/
# load/open verb, AND that sentence is NOT a prohibition ("do not", "never",
# "n't", "no pre-load", "without loading"), NOT a deferred load ("load only
# when/after <condition>"), and NOT a References/See-also pointer bullet. The
# trailing "References (do not auto-load)" / "See also" section is dropped whole
# because those are non-loading pointers. Writes nothing. Honest --measure-launch
# (Wave 5b): a `rules/...` path string appearing only in a prohibition, a
# deferred-load gloss, or a References pointer no longer counts as a startup load.
skill_startup_loads_rule() {
  local skill_file=$1
  local rule_relpath=$2
  local python_cmd

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot detect startup loads; install python"

  "$python_cmd" - "$skill_file" "$rule_relpath" <<'PY'
import re, sys, pathlib

skill_file = pathlib.Path(sys.argv[1])
rule_relpath = sys.argv[2]
text = skill_file.read_text(encoding="utf-8")

# Drop trailing non-loading pointer sections (References / See also). Bullets
# there only point at a file, they do not instruct a startup read.
body = re.split(r"^##\s+(?:References|See also)\b", text, maxsplit=1,
                flags=re.MULTILINE | re.IGNORECASE)[0]

# Unwrap soft line breaks so a "read ... <path>" instruction split across lines
# is one contiguous sentence; split paragraphs on blank lines, sentences on
# enders.
sentences = []
for para in re.split(r"\n\s*\n", body):
    flat = re.sub(r"\s+", " ", para).strip()
    if not flat:
        continue
    sentences.extend(s.strip() for s in re.split(r"(?<=[.;])\s+", flat) if s.strip())

# Match the rule path as it appears in skill bodies (runtime ~/.agentdocs/ form
# or repo-relative src/ form), anchored on the rules/<relpath> tail.
PATH = re.compile(r"rules/" + re.escape(rule_relpath))
LOAD_VERB = re.compile(r"\b(read|load|pre-load|open)\b", re.I)
NEGATION = re.compile(r"\bdo not\b|\bdon't\b|\bdon’t\b|\bnever\b|n't\b|"
                      r"n’t\b|no pre-load|not load|without loading", re.I)
# "load only when/after <condition>" is a deferred load, not a startup load.
DEFERRED = re.compile(r"\b(load|read|open)\b[^.;]*\bonly (when|after|once)\b", re.I)
# A reference-pointer bullet: "- `...path` — gloss" (em-dash gloss, no verb).
POINTER = re.compile(r"^- `[^`]*` —")

for s in sentences:
    if not PATH.search(s) or not LOAD_VERB.search(s):
        continue
    if NEGATION.search(s) or DEFERRED.search(s) or POINTER.match(s):
        continue
    raise SystemExit(0)
raise SystemExit(1)
PY
}

# --measure-launch <skill-name>: print the controlled launch word total for one
# skill using the Wave-0 formula: skill body + shared startup contract
# (skill-contracts.md) + the orchestrator/role rules that skill loads at startup
# (detected from the SKILL body) + docs/index.md + requested manifest slots
# (docs/_meta/manifest.md). Task-routed source/tests/docs are excluded. Writes
# nothing and emits no copied rule bodies.
measure_launch() {
  local skill_name=$1
  local skill_file="$repo_root/src/skills/$skill_name/SKILL.md"
  local total=0
  local label path count

  [ -n "$skill_name" ] || { usage >&2; exit 2; }
  [ -f "$skill_file" ] || fail "unknown skill: $skill_name"

  printf 'MEASURE-LAUNCH %s\n' "$skill_name"

  add_startup_file() {
    local file=$1
    local file_label=$2
    [ -f "$file" ] || fail "launch file missing for $skill_name: ${file#$repo_root/}"
    count=$(wc -w < "$file")
    count=${count//[[:space:]]/}
    total=$((total + count))
    printf '  %-22s %s\n' "$file_label" "$count"
  }

  # Skill body.
  add_startup_file "$skill_file" "skill-body"

  # Shared startup contract loaded by every skill bootstrap.
  add_startup_file "$repo_root/src/rules/skill-contracts.md" "skill-contracts"

  # Orchestrator/role rules this skill names in its startup body. Only count what
  # the skill actually loads at launch, not task-routed overlays, and not a path
  # that appears only in a prohibition, a deferred-load gloss, or a References
  # pointer (honest measurement; see skill_startup_loads_rule).
  for rule in context-profiles.md orchestrator/dispatch.md orchestrator/lifecycle.md; do
    if skill_startup_loads_rule "$skill_file" "$rule"; then
      label=${rule##*/}
      add_startup_file "$repo_root/src/rules/$rule" "${label%.md}"
    fi
  done

  # Docs router entry and the requested manifest slots.
  add_startup_file "$repo_root/docs/index.md" "docs-index"
  add_startup_file "$repo_root/docs/_meta/manifest.md" "manifest-slots"

  printf '  %-22s %s\n' "TOTAL" "$total"
  printf 'MEASURE-LAUNCH PASS\n'
}

# launch_total <skill-name>: print ONLY the controlled launch word total for one
# skill, using the same Wave-0 formula as measure_launch (skill body +
# skill-contracts + the orchestrator/role rules the skill names at startup +
# docs/index + manifest slots). Quiet variant for the contract checks. Writes
# nothing.
launch_total() {
  local skill_name=$1
  local skill_file="$repo_root/src/skills/$skill_name/SKILL.md"
  local total=0
  local count rule

  [ -f "$skill_file" ] || fail "unknown skill: $skill_name"

  add_quiet() {
    local file=$1
    [ -f "$file" ] || fail "launch file missing for $skill_name: ${file#$repo_root/}"
    count=$(wc -w < "$file")
    count=${count//[[:space:]]/}
    total=$((total + count))
  }

  add_quiet "$skill_file"
  add_quiet "$repo_root/src/rules/skill-contracts.md"
  for rule in context-profiles.md orchestrator/dispatch.md orchestrator/lifecycle.md; do
    skill_startup_loads_rule "$skill_file" "$rule" && add_quiet "$repo_root/src/rules/$rule"
  done
  add_quiet "$repo_root/docs/index.md"
  add_quiet "$repo_root/docs/_meta/manifest.md"

  printf '%s' "$total"
}

# --contract-check: SOURCE-BOUND contract checks. Every check below is an
# assertion over actual files (skill bodies, role cards, profile owner, scenario
# fixture), NOT a phrase match over a self-authored table. Each prints a CLEAN
# line or one WARN line per violation (with file:line where possible) and
# increments a violation counter. As of Wave 5b these checks GATE: the function
# returns the violation count, and every caller (default gate, --contract-check,
# --context-report) FAILs (exits nonzero) and refuses to print PASS when the
# count is nonzero. The function still prints all WARN lines first so a red run
# is fully diagnosable. Also surfaced as a section inside --context-report.
#
# Budgets (E3 measured floors, now ENFORCED launch budgets in Wave 5b):
#   fixed skill controlled launch  <= 2000   (honest max 1922 = review-app;
#                                              floor + ~4% headroom)
#   classifier controlled launch   <= 3300   (honest max 3118 = orchestrate;
#                                              floor + ~6% headroom; allowlist:
#                                              orchestrate, fresh-chat,
#                                              start-session)
# These floors are irreducible: the shared startup contract (skill-contracts 637)
# + docs index (114) + requested manifest slots (430) = 1181 words load on every
# launch regardless of skill body, and a classifier additionally reads
# lifecycle.md (1037). The aspirational 1200/2000 targets are unreachable without
# deleting that irreducible normative startup surface (Decision E3). After the
# honest --measure-launch fix (path strings in prohibitions, deferred-load
# glosses, and References pointers no longer count as startup loads), zero skills
# exceed these floors.
contract_check() {
  local violations=0
  local skill_dir skill_name skill_file total budget kind clean
  local match python_cmd
  local fixed_budget classifier_budget classifier_allowlist

  section "source-bound contract checks (enforced; gating)"

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot run contract checks; install python"

  # Launch budgets come from the kernel (src/kernel/profiles.json budgets), the
  # sole authority since the Wave 1b cutover. classifier_allowlist is rebuilt
  # from the kernel's classifier_skills as " name name name " for the
  # whitespace-bounded substring match the checks below rely on.
  fixed_budget=$(
    "$python_cmd" - "$repo_root/src/kernel/profiles.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["budgets"]["fixed_skill_launch"])
PY
  )
  classifier_budget=$(
    "$python_cmd" - "$repo_root/src/kernel/profiles.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1], encoding="utf-8"))["budgets"]["classifier_skill_launch"])
PY
  )
  classifier_allowlist=$(
    "$python_cmd" - "$repo_root/src/kernel/profiles.json" <<'PY'
import json, sys
skills = json.load(open(sys.argv[1], encoding="utf-8"))["budgets"]["classifier_skills"]
print(" " + " ".join(skills) + " ")
PY
  )

  # ---- Check 1: launch budgets -------------------------------------------
  # For every skill, compute the controlled launch total and warn if it exceeds
  # the kernel's enforced launch budget for its kind (fixed_skill_launch for a
  # fixed skill, classifier_skill_launch for an allowlisted classifier).
  printf -- '-- check 1: controlled launch budgets --\n'
  clean=1
  for skill_dir in "$repo_root"/src/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    [ -f "$skill_dir/SKILL.md" ] || continue
    total=$(launch_total "$skill_name")
    case "$classifier_allowlist" in
      *" $skill_name "*) kind=classifier; budget=$classifier_budget ;;
      *) kind=fixed; budget=$fixed_budget ;;
    esac
    if [ "$total" -gt "$budget" ]; then
      printf 'WARN launch over budget: %s (%s) launch=%s > %s\n' \
        "$skill_name" "$kind" "$total" "$budget"
      violations=$((violations + 1))
      clean=0
    else
      printf 'ok   %s (%s) launch=%s/%s\n' "$skill_name" "$kind" "$total" "$budget"
    fi
  done
  [ "$clean" -eq 1 ] && printf 'CLEAN: all skill launches within budget\n'

  # ---- Check 2: fixed skills must not load lifecycle.md at startup --------
  # A startup load is a line that names the lifecycle.md rule path AS something
  # the skill reads/loads, e.g. "read .../rules/orchestrator/lifecycle.md".
  # Excluded so prohibitions and pointers don't false-positive:
  #   - lines that prohibit loading ("do not", "never", "don't", "no pre-load");
  #   - "References"/"See also" pointer lines (a leading "- " bullet that only
  #     points at the file with a trailing em-dash gloss, not a read verb);
  #   - the 3 allowlisted classifiers (which legitimately load it).
  printf -- '-- check 2: fixed skills must not startup-load lifecycle.md --\n'
  clean=1
  for skill_dir in "$repo_root"/src/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    skill_file="$skill_dir/SKILL.md"
    [ -f "$skill_file" ] || continue
    case "$classifier_allowlist" in *" $skill_name "*) continue ;; esac
    # Startup-load line: contains lifecycle.md path AND a read/load verb, and is
    # NOT a prohibition and NOT a "- ... — ..." reference-pointer bullet.
    while IFS= read -r match; do
      [ -n "$match" ] || continue
      violations=$((violations + 1))
      clean=0
      printf 'WARN fixed skill startup-loads lifecycle.md: src/skills/%s/SKILL.md:%s\n' \
        "$skill_name" "$match"
    done < <(
      grep -nE 'orchestrator/lifecycle\.md' "$skill_file" |
        grep -iE 'read |load |open ' |
        grep -ivE 'do not|don.t|never|no pre-load|not load|without loading' |
        grep -vE '^[0-9]+:- `[^`]*` —'
    )
  done
  [ "$clean" -eq 1 ] && printf 'CLEAN: no fixed skill startup-loads lifecycle.md\n'

  # ---- Check 3: no spelled-out subagent bundles in skills ----------------
  # Skills must name profile IDs + use --resolve, not list rules/subagent/ role
  # cards. Warn on any literal rules/subagent/ path in a skill body.
  printf -- '-- check 3: no spelled-out subagent bundle paths in skills --\n'
  clean=1
  while IFS= read -r skill_file; do
    while IFS= read -r match; do
      [ -n "$match" ] || continue
      violations=$((violations + 1))
      clean=0
      printf 'WARN skill names a subagent role-card path: %s:%s\n' \
        "${skill_file#$repo_root/}" "$match"
    done < <(grep -nE 'rules/subagent/' "$skill_file" || true)
  done < <(find "$repo_root"/src/skills -name SKILL.md | sort)
  [ "$clean" -eq 1 ] && printf 'CLEAN: no skill spells out a subagent bundle path\n'

  # ---- Check 4: review/verification are read-only ------------------------
  # Warn if review.md or verification.md grants edit/stage/commit authority.
  # Match AUTHORITY-GRANTING wording only; the prohibition "Never edit, stage,
  # or commit" and the "commit/safety discipline" pointer must NOT false-positive.
  printf -- '-- check 4: review/verification role cards stay read-only --\n'
  clean=1
  for readonly_rule in review verification; do
    skill_file="$repo_root/src/rules/subagent/$readonly_rule.md"
    [ -f "$skill_file" ] || { printf 'WARN missing role card: src/rules/subagent/%s.md\n' "$readonly_rule"; violations=$((violations + 1)); clean=0; continue; }
    while IFS= read -r match; do
      [ -n "$match" ] || continue
      violations=$((violations + 1))
      clean=0
      printf 'WARN %s role card grants mutation authority: src/rules/subagent/%s.md:%s\n' \
        "$readonly_rule" "$readonly_rule" "$match"
    done < <(
      grep -niE 'you (may|can) (edit|stage|commit)|commit before reporting|stage (only |)owned|may fix|authorized fix|fix-enabled|fix enabled|made a fix|apply the fix' \
        "$skill_file" |
        grep -ivE 'never (edit|stage|commit)|do not (edit|stage|commit)'
    )
  done
  [ "$clean" -eq 1 ] && printf 'CLEAN: review and verification role cards are read-only\n'

  # ---- Check 5: closeout authority consistency ---------------------------
  # plan_closeout must appear consistently across implementation.md, the kernel
  # profile owner (implementation.tracked record), and dispatch.md. The profile
  # authority moved from the context-profiles Markdown table to the kernel in the
  # Wave 1b cutover, so the grant is now asserted against src/kernel/profiles.json.
  printf -- '-- check 5: plan_closeout authority consistency --\n'
  clean=1
  declare -A closeout_present=()
  for pair in \
    "src/rules/subagent/implementation.md" \
    "src/kernel/profiles.json" \
    "src/rules/orchestrator/dispatch.md"; do
    if grep -Fq 'plan_closeout' "$repo_root/$pair"; then
      closeout_present[$pair]=1
    else
      closeout_present[$pair]=0
    fi
  done
  for pair in "${!closeout_present[@]}"; do
    if [ "${closeout_present[$pair]}" -eq 0 ]; then
      violations=$((violations + 1))
      clean=0
      printf 'WARN plan_closeout absent where required: %s\n' "$pair"
    fi
  done
  # Extra cross-check: the kernel must carry it on the implementation.tracked
  # profile record (its purpose field grants the closeout).
  if ! "$python_cmd" - "$repo_root/src/kernel/profiles.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
row = next((p for p in data["profiles"] if p["id"] == "implementation.tracked"), None)
raise SystemExit(0 if row and "plan_closeout" in json.dumps(row) else 1)
PY
  then
    violations=$((violations + 1))
    clean=0
    printf 'WARN kernel implementation.tracked profile missing plan_closeout grant\n'
  fi
  [ "$clean" -eq 1 ] && printf 'CLEAN: plan_closeout authority is consistent across role/profile/dispatch\n'

  # ---- Check 6: review-app no pre-audit stop / no eager run+plan load ----
  # Warn if review-app/SKILL.md contains a positive pre-audit "confirm the run
  # shape" stop, or a positive STARTUP load of run-docs/plan-lifecycle. The rule
  # is sentence-aware (markdown wraps mid-sentence, so a line grep splits
  # negations from their verb): a violation is a SENTENCE that both reads/loads
  # the path (or confirms the run shape) AND carries no negation or gating
  # phrase. Gating phrases ("only after/when", "after approval/findings",
  # "before creating", "if chosen", "once") and prohibitions ("do not", "never",
  # "n't") clear it, so the current skill's gated loads and "Do NOT pre-load"
  # prohibition do not false-positive.
  printf -- '-- check 6: review-app has no pre-audit confirm / eager load --\n'
  clean=1
  skill_file="$repo_root/src/skills/review-app/SKILL.md"
  if [ ! -f "$skill_file" ]; then
    printf 'WARN missing skill: src/skills/review-app/SKILL.md\n'
    violations=$((violations + 1)); clean=0
  else
    local ra_out ra_violations
    ra_out=$(
      "$python_cmd" - "$skill_file" <<'PY' || true
import re, sys, pathlib

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
# Drop the trailing "References (do not auto-load)" section: those are pointer
# bullets, not startup-load instructions.
body = re.split(r"^##\s+References", text, maxsplit=1, flags=re.MULTILINE)[0]

# Unwrap soft line breaks so a sentence is contiguous, then split on sentence
# enders. Markdown paragraphs are separated by blank lines.
sentences = []
for para in re.split(r"\n\s*\n", body):
    flat = re.sub(r"\s+", " ", para).strip()
    if not flat:
        continue
    sentences.extend(s.strip() for s in re.split(r"(?<=[.;])\s+", flat) if s.strip())

NEGATION = re.compile(r"\bdo not\b|\bdon't\b|\bdon’t\b|\bnever\b|n't\b|n’t\b", re.I)
GATING = re.compile(
    r"only after|only when|only once|after approval|after findings|after the user|"
    r"before creating|if chosen|opts? in|once the|once run|once findings",
    re.I,
)
LOAD_VERB = re.compile(r"\b(load|pre-load|read|open)\b", re.I)
PATH = re.compile(r"run-docs\.md|plan-lifecycle\.md")
CONFIRM = re.compile(
    r"confirm (the|this|a|that)? ?(run|audit)[ -]?(shape|config|configuration|plan)|"
    r"reconfirm|present (a|the)? ?(full )?run-?shape summary|"
    r"confirm (the )?run shape|stop to confirm",
    re.I,
)

violations = 0
for s in sentences:
    low = s.lower()
    negated = bool(NEGATION.search(s)) or bool(GATING.search(s))
    # Eager startup load of run-docs/plan-lifecycle.
    if PATH.search(s) and LOAD_VERB.search(s) and not negated:
        print(f"WARN review-app eager run-doc/plan startup load: {s}")
        violations += 1
    # Positive pre-audit confirmation stop.
    if CONFIRM.search(s) and not (NEGATION.search(s)):
        print(f"WARN review-app pre-audit confirmation stop: {s}")
        violations += 1
print(f"__VIOLATIONS__ {violations}")
PY
    )
    ra_violations=$(printf '%s\n' "$ra_out" | awk '/^__VIOLATIONS__/{print $2}')
    printf '%s\n' "$ra_out" | grep -v '^__VIOLATIONS__' | grep -E '^WARN' || true
    violations=$((violations + ${ra_violations:-0}))
    [ "${ra_violations:-0}" -ne 0 ] && clean=0
  fi
  [ "$clean" -eq 1 ] && printf 'CLEAN: review-app has no pre-audit confirm stop or eager run-doc/plan load\n'

  # ---- Check 7: scenario source-binding ----------------------------------
  # For each scenario row whose scenario_id maps cleanly to a skill, assert the
  # profile IDs named in expected_profiles are actually named in that skill body.
  # Unmappable scenarios are listed as "unmapped" rather than failing.
  printf -- '-- check 7: scenario expected_profiles named in mapped skill --\n'
  local scenario_out
  scenario_out=$(
    "$python_cmd" - "$(scenario_fixture)" "$repo_root" <<'PY'
import json, re, sys, pathlib

fixture = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])
data = json.loads(fixture.read_text(encoding="utf-8"))

# scenario_id -> skill whose body must name the scenario's expected profiles.
# Only clean, unambiguous mappings; everything else is reported "unmapped".
mapping = {
    "bounded-quick-fix": "quick-fix",
    "medium-brief-plan": "plan",
    "tracked-change-plan": "plan",
    "dirty-tree-shipping": "ship-current-work",
    "named-plan-shipping": "ship-plans",
    "docs-repair": "fix-docs-drift",
    "configured-app-review": "review-app",
}

profile_re = re.compile(
    r"\b(?:planning|implementation|review|maintenance|verification)\."
    r"[a-z][a-z-]*\b"
)

violations = 0
for row in data.get("scenarios", []):
    sid = row.get("scenario_id", "")
    expected = row.get("expected_profiles", "")
    want = sorted(set(profile_re.findall(expected)))
    skill = mapping.get(sid)
    if skill is None:
        print(f"UNMAPPED {sid}: expected_profiles={expected!r} (no clean skill mapping)")
        continue
    body_path = repo_root / "src" / "skills" / skill / "SKILL.md"
    if not body_path.is_file():
        print(f"WARN {sid}: mapped skill missing: src/skills/{skill}/SKILL.md")
        violations += 1
        continue
    body = body_path.read_text(encoding="utf-8")
    missing = [p for p in want if p not in body]
    if missing:
        print(
            f"WARN {sid}->{skill}: expected profiles not named in skill body: "
            f"{missing}"
        )
        violations += 1
    else:
        print(f"ok   {sid}->{skill}: profiles {want} all named")
print(f"__VIOLATIONS__ {violations}")
PY
  )
  local sc_violations
  sc_violations=$(printf '%s\n' "$scenario_out" | awk '/^__VIOLATIONS__/{print $2}')
  printf '%s\n' "$scenario_out" | grep -v '^__VIOLATIONS__'
  violations=$((violations + ${sc_violations:-0}))
  [ "${sc_violations:-0}" -eq 0 ] && printf 'CLEAN: all mapped scenarios name their expected profiles\n'

  # ---- Check 8: report-field + final-ordering presence -------------------
  # Warn if dispatch.md Worker Reports lacks any required field, or lifecycle.md
  # lacks the "final gate after last mutation" rule.
  printf -- '-- check 8: report fields + final-ordering presence --\n'
  clean=1
  local dispatch_file="$repo_root/src/rules/orchestrator/dispatch.md"
  local lifecycle_file="$repo_root/src/rules/orchestrator/lifecycle.md"
  # Required Worker Report fields (observed commit/dirty, sources+precedence,
  # evidence, touched paths, commits/no-change, invalidation conditions).
  declare -A report_fields=(
    ["observed commit and dirty"]="observed commit/dirty state"
    ["sources inspected and precedence"]="sources + precedence"
    ["evidence"]="evidence"
    ["touched paths"]="touched paths"
    ["commits"]="commits / no-change"
    ["invalidation conditions"]="invalidation conditions"
  )
  if [ ! -f "$dispatch_file" ]; then
    printf 'WARN missing dispatch.md\n'; violations=$((violations + 1)); clean=0
  else
    for needle in \
      "observed commit and dirty" \
      "sources inspected and precedence" \
      "evidence" \
      "touched paths" \
      "commits" \
      "invalidation conditions"; do
      if ! grep -Fq "$needle" "$dispatch_file"; then
        printf 'WARN dispatch.md Worker Reports missing field: %s (%s)\n' \
          "$needle" "${report_fields[$needle]}"
        violations=$((violations + 1)); clean=0
      fi
    done
  fi
  if [ ! -f "$lifecycle_file" ]; then
    printf 'WARN missing lifecycle.md\n'; violations=$((violations + 1)); clean=0
  else
    # The "final gate after the last mutation" rule, expressed either as the
    # ship-order checkpoint or the green-gate invariant.
    if ! grep -qiE 'final (consolidated |)(drift |)gate after the last mutation|final gate observes the state after' "$lifecycle_file"; then
      printf 'WARN lifecycle.md missing "final gate after last mutation" rule\n'
      violations=$((violations + 1)); clean=0
    fi
  fi
  [ "$clean" -eq 1 ] && printf 'CLEAN: report fields and final-ordering rule present\n'

  # ---- Check 9: planning.scope is the fixed first /orchestrate phase ------
  # Wave 2 made planning.scope the deterministic entry phase of every
  # /orchestrate run (no inline bounded/briefed/tracked classification; the
  # cost regression is accepted). This GATES three coupled facts together:
  #   (a) the orchestrate-mapped scenario row names planning.scope FIRST in
  #       expected_profiles;
  #   (b) the kernel orchestrate workflow's first_phase is planning.scope;
  #   (c) the orchestrate skill body still commits to dispatching planning.scope
  #       first (so the controller can't silently drop the entry phase).
  # Any drift in one of the three fails the gate.
  printf -- '-- check 9: planning.scope is the fixed first /orchestrate phase --\n'
  local scope_out scope_violations
  scope_out=$(
    "$python_cmd" - \
      "$(scenario_fixture)" \
      "$repo_root/src/kernel/workflows.json" \
      "$repo_root/src/skills/orchestrate/SKILL.md" <<'PY'
import json, re, sys, pathlib

scenarios = json.load(open(sys.argv[1], encoding="utf-8"))["scenarios"]
workflows = json.load(open(sys.argv[2], encoding="utf-8"))["workflows"]
skill_body = pathlib.Path(sys.argv[3]).read_text(encoding="utf-8")

violations = 0
profile_re = re.compile(
    r"\b(?:planning|implementation|review|maintenance|verification)\."
    r"[a-z][a-z-]*\b"
)

# (a) the orchestrate-mapped scenario row names planning.scope FIRST.
row = next(
    (s for s in scenarios if s["scenario_id"] == "orchestrate-planning-scope-first"),
    None,
)
if row is None:
    print("WARN missing scenario row: orchestrate-planning-scope-first")
    violations += 1
else:
    found = profile_re.findall(row.get("expected_profiles", ""))
    if not found or found[0] != "planning.scope":
        print(
            "WARN orchestrate-planning-scope-first: expected_profiles must name "
            f"planning.scope first, got {found!r}"
        )
        violations += 1
    else:
        print("ok   scenario row names planning.scope as the first entry phase")

# (b) the kernel orchestrate workflow first_phase is planning.scope.
wf = next((w for w in workflows if w["id"] == "orchestrate"), None)
if wf is None or wf.get("first_phase") != "planning.scope":
    print(
        "WARN kernel orchestrate workflow first_phase must be planning.scope, "
        f"got {wf.get('first_phase') if wf else None!r}"
    )
    violations += 1
elif "planning.scope" not in wf.get("allowed_profiles", []):
    print("WARN kernel orchestrate workflow allowed_profiles missing planning.scope")
    violations += 1
else:
    print("ok   kernel orchestrate workflow enters at planning.scope")

# (c) the orchestrate skill body commits to dispatching planning.scope first.
commits_first = (
    "planning.scope" in skill_body
    and re.search(
        r"planning\.scope[^\n]{0,80}\bfirst\b|\bfirst\b[^\n]{0,80}planning\.scope|"
        r"always dispatch(?:es)?[^\n]{0,40}planning\.scope|"
        r"planning\.scope[^\n]{0,40}always",
        skill_body,
        re.I,
    )
)
if not commits_first:
    print("WARN orchestrate skill body no longer commits to dispatching planning.scope first")
    violations += 1
else:
    print("ok   orchestrate skill body dispatches planning.scope first")

print(f"__VIOLATIONS__ {violations}")
PY
  )
  scope_violations=$(printf '%s\n' "$scope_out" | awk '/^__VIOLATIONS__/{print $2}')
  printf '%s\n' "$scope_out" | grep -v '^__VIOLATIONS__'
  violations=$((violations + ${scope_violations:-0}))
  [ "${scope_violations:-0}" -eq 0 ] && printf 'CLEAN: planning.scope is the fixed first /orchestrate phase\n'

  # ---- Check 10: clean-handoff git invariant consistency -----------------
  # Wave 5 replaced "a mutating worker commits every completed slice" with the
  # clean-handoff invariant. This GATES that the invariant is stated CONSISTENTLY
  # across the orchestrator dispatch rule, the universal git rule, and every
  # mutating role card, and that NONE of them has reverted to commit-every-slice
  # language. A file fails if it is missing the invariant's load-bearing concepts
  # (three terminal states + discharge), OR if it re-introduces the retired
  # micro-commit cadence ("commit your/its/their completed slice before
  # reporting", "commit-heavy by design", "commit every slice"). It bites if any
  # one of the five files drifts.
  printf -- '-- check 10: clean-handoff git invariant consistency --\n'
  local handoff_out handoff_violations
  handoff_out=$(
    "$python_cmd" - "$repo_root" <<'PY'
import pathlib, re, sys

repo_root = pathlib.Path(sys.argv[1])

# The canonical home (repo-rules.md) must carry the full invariant; dispatch.md
# (and its rationale leaf) likewise. The three mutating role cards must carry the
# three terminal states. Every file in the set must avoid commit-every-slice
# language.
full = [
    "src/rules/repo-rules.md",
    "src/rules/orchestrator/dispatch.md",
]
cards = [
    "src/rules/subagent/implementation.md",
    "src/rules/subagent/docs-maintenance.md",
    "src/rules/subagent/plan-maintenance.md",
]

# Retired commit-every-slice cadence: the exact phrasings the invariant replaces.
# Each alternative is a POSITIVE mandate; the negations the surviving docs use
# ("must not micro-commit every slice", "do not micro-commit per slice") are
# excluded by requiring the cadence verb not be a "micro-commit" and by the
# NEGATED guard applied at the call site.
REVERTED = re.compile(
    r"commit(?:s|ed)?\s+(?:your|its|their|the)\s+completed\s+slice\s+before\s+reporting"
    r"|commit\s+it\s+before\s+reporting"
    r"|commit-heavy\s+by\s+design"
    r"|(?<!micro-)(?<!micro )commit\s+every\s+(?:completed\s+)?slice"
    r"|commit\s+each\s+slice",
    re.I,
)
# A reverted match inside a prohibition ("must not", "never", "do not", "n't")
# is the invariant being RESTATED, not violated.
NEGATED_CADENCE = re.compile(
    r"(?:must not|never|do not|don't|don’t|not)\s+(?:\w+[- ]){0,3}"
    r"(?:micro-)?commit\s+(?:every|each)\s+(?:completed\s+)?slice",
    re.I,
)
# Load-bearing concepts of the invariant.
NO_DIRT = re.compile(r"never\s+hands?\s+off\s+unexplained\s+owned\s+dirt", re.I)
COMMITTED = re.compile(r"\bcommitted\b", re.I)
CLEAN_NOOP = re.compile(r"clean\s+no-op", re.I)
BLOCKED = re.compile(r"blocked\s+handoff", re.I)
DISCHARGE = re.compile(
    r"(committed\s+or\s+reverted|commit\s+or\s+revert).{0,40}before\s+final\s+verification"
    r"|discharge",
    re.I,
)

violations = 0

def check(rel, require_full):
    global violations
    path = repo_root / rel
    if not path.is_file():
        print(f"WARN clean-handoff source missing: {rel}")
        violations += 1
        return
    text = path.read_text(encoding="utf-8")
    flat = re.sub(r"\s+", " ", text)
    m = REVERTED.search(flat)
    if m and not NEGATED_CADENCE.search(flat[max(0, m.start() - 40):m.end()]):
        print(f"WARN {rel} reverts to commit-every-slice language: {m.group(0)!r}")
        violations += 1
    # Every file must name the three terminal states.
    missing = []
    if not COMMITTED.search(flat):
        missing.append("committed")
    if not CLEAN_NOOP.search(flat):
        missing.append("clean no-op")
    if not BLOCKED.search(flat):
        missing.append("blocked handoff")
    if require_full:
        if not NO_DIRT.search(flat):
            missing.append("never-hands-off-unexplained-owned-dirt")
        if not DISCHARGE.search(flat):
            missing.append("discharge-before-final-verification")
    if missing:
        print(f"WARN {rel} missing clean-handoff concepts: {missing}")
        violations += 1
    else:
        print(f"ok   {rel} states the clean-handoff invariant consistently")

for rel in full:
    check(rel, require_full=True)
for rel in cards:
    check(rel, require_full=False)

print(f"__VIOLATIONS__ {violations}")
PY
  )
  handoff_violations=$(printf '%s\n' "$handoff_out" | awk '/^__VIOLATIONS__/{print $2}')
  printf '%s\n' "$handoff_out" | grep -v '^__VIOLATIONS__'
  violations=$((violations + ${handoff_violations:-0}))
  [ "${handoff_violations:-0}" -eq 0 ] && printf 'CLEAN: clean-handoff git invariant is consistent across dispatch, repo-rules, and mutating role cards\n'

  # ---- Total -------------------------------------------------------------
  # Wave 5b: these checks GATE. Report the count, then return it so callers fail
  # (and refuse to print PASS) on any nonzero violation. WARN lines above remain
  # so a red run is fully diagnosable before the failure.
  printf 'CONTRACT-CHECK TOTAL VIOLATIONS: %s (enforced; gating)\n' "$violations"
  return "$violations"
}

validate_context_profiles() {
  local python_cmd

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] ||
    fail "cannot validate context profiles; install python"

  if ! "$python_cmd" - "$repo_root/src/kernel/profiles.json" "$repo_root" "$(scenario_fixture)" <<'PY'
import json
import pathlib
import sys

profile_path = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])
scenario_fixture = pathlib.Path(sys.argv[3])

# Profiles come from the kernel (sole authority since the Wave 1b cutover). The
# row order matches the legacy table columns so the validation below is
# unchanged: id, purpose, core_rule_paths, overlays, mutation, budget, status.
profile_fields = [
    "id", "purpose", "core_rule_paths", "overlays",
    "mutation_capability", "budget_words", "enforcement_status",
]
try:
    profile_data = json.loads(profile_path.read_text(encoding="utf-8"))
except (OSError, ValueError) as exc:
    raise SystemExit(f"cannot read kernel profiles {profile_path}: {exc}")
profile_rows = [
    [str(row.get(field, "")) for field in profile_fields]
    for row in profile_data.get("profiles", [])
]

# Scenarios are verifier-only data; they live in the never-auto-loaded kernel so
# they leave the runtime context-profiles load surface. Field order matches the
# old in-doc table columns so downstream needle checks are unchanged.
scenario_fields = [
    "scenario_id", "task_shape", "expected_questions", "expected_profiles",
    "expected_phases", "expected_mutator_count", "state_basis_fields",
    "final_ordering", "budget_expectation",
]
try:
    fixture_data = json.loads(scenario_fixture.read_text(encoding="utf-8"))
except (OSError, ValueError) as exc:
    raise SystemExit(f"cannot read scenario fixture {scenario_fixture}: {exc}")
scenario_rows = [
    [str(row.get(field, "")) for field in scenario_fields]
    for row in fixture_data.get("scenarios", [])
]

required_profiles = {
    "planning.brief", "planning.tracked", "implementation.code",
    "implementation.code-docs", "implementation.tracked", "review.generic",
    "review.docs", "review.plan", "maintenance.docs", "maintenance.plan",
    "verification.readonly", "docs.inspect", "plans.inspect",
}
seen_profiles = {row[0] for row in profile_rows}
missing = required_profiles - seen_profiles
if missing:
    raise SystemExit(f"missing context profiles: {sorted(missing)}")

for row in profile_rows:
    profile_id, _, paths, _, mutation, budget, status = row
    if mutation not in {"read-only", "mutating", "conditional"}:
        raise SystemExit(f"{profile_id}: invalid mutation capability {mutation}")
    if (profile_id.startswith("review.")
            or profile_id == "verification.readonly"
            or profile_id.endswith(".inspect")) and mutation != "read-only":
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
    "orchestrate-planning-scope-first",
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
    "orchestrate-planning-scope-first": ["planning.scope first", "no inline classification before it"],
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
  require_file_under "$root" "docs/_meta/execution.yaml" "$label"
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

  validate_execution_yaml_under "$root" "docs/_meta/execution.yaml" "$label"

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
  --contract-check)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    contract_violations=0
    contract_check || contract_violations=$?
    if [ "$contract_violations" -ne 0 ]; then
      fail "contract check found $contract_violations source-bound violation(s)"
    fi
    printf 'CONTRACT-CHECK PASS\n'
    exit 0
    ;;
  --resolve)
    # Back-compat: `--resolve <profile-id>` resolves one profile (positional
    # arg, no leading dash). Merge mode: `--resolve --skill/--phase/--repo/--risk`
    # emits the merged exact-context resolution (references only, writes nothing).
    case "${2:-}" in
      "") usage >&2; exit 2 ;;
      --skill|--phase|--repo|--risk)
        shift
        resolve_merge "$@"
        exit 0
        ;;
      *)
        [ "$#" -eq 2 ] || { usage >&2; exit 2; }
        resolve_profile "$2"
        exit 0
        ;;
    esac
    ;;
  --equivalence)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    equivalence_check
    exit 0
    ;;
  --measure-launch)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    measure_launch "$2"
    exit 0
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
require_file "src/kernel/profiles.json"
require_file "src/kernel/scenarios.json"
require_file "src/kernel/workflows.json"
require_file "src/kernel/packs.json"
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
require_text "src/kernel/profiles.json" "implementation.code" \
  "kernel profiles missing implementation.code"
require_text "src/kernel/scenarios.json" "bounded-quick-fix" \
  "kernel scenarios missing bounded-quick-fix"
require_text "src/rules/context-profiles.md" "src/kernel/profiles.json" \
  "context-profiles.md must point at the kernel as the machine authority"

section "context profile checks"
validate_context_profiles

# Single-authority guard: after the Wave 1b cutover the kernel is the sole owner
# of profile/scenario/budget facts; this fails if any such fact reappears in
# Markdown or as a bash literal.
detect_dual_authority

# Wave 5b: the source-bound contract checks (launch budgets, lifecycle startup
# loads, subagent-bundle spell-outs, read-only role authority, plan_closeout
# consistency, review-app pre-audit/eager loads, scenario source-binding, report
# fields, final-ordering) now GATE the default run. Any nonzero violation count
# fails the whole gate.
section "source-bound contract checks"
contract_violations=0
contract_check || contract_violations=$?
[ "$contract_violations" -eq 0 ] ||
  fail "source-bound contract check found $contract_violations violation(s)"

section "documentation budget checks"
validate_word_budgets

section "execution.yaml binding checks"
validate_execution_yaml "docs/_meta/execution.yaml" "dogfood"
validate_execution_yaml "src/template/docs/_meta/execution.yaml" "template"

section "kernel pack checks"
# Gate (a) + (b): every pack carries a trigger and an existing rule_leaf.
validate_kernel_packs

# Gates (c) + (d): the deterministic pack-merge rule, proven against the dogfood
# repo. The resolver is the SOLE pack loader; agent-docs (bash + markdown) routes
# only testing-reliability + deployment-ops, so the irrelevant packs MUST stay
# unactivated, and the resolver MUST write no artifact. Capture the resolver
# output and a clean-tree snapshot, then assert.
pack_resolve_out=$(bash "$repo_root/src/verify-agent-docs.sh" \
  --resolve --skill quick-fix --repo "$repo_root" 2>&1) ||
  fail "pack-merge resolve (dogfood) did not run"
pack_tree_after=$(cd "$repo_root" && git status --porcelain 2>/dev/null)

# (c) pack non-activation: frontend/accessibility/db-migration/auth-security are
# NOT in the dogfood pack_routes, so they must NOT appear as activated packs.
for unrouted in frontend accessibility db-migration auth-security \
                backend-api performance-concurrency; do
  if printf '%s\n' "$pack_resolve_out" |
       awk '/^  activated_packs/{f=1;next} /^  unactivated_packs/{f=0} f' |
       grep -Eq -- "^    - ${unrouted}\$"; then
    fail "pack non-activation broken: '$unrouted' activated on the dogfood repo "
  fi
done
# Positive control: a routed pack DOES activate (proves the merge actually fires).
printf '%s\n' "$pack_resolve_out" |
  awk '/^  activated_packs/{f=1;next} /^  unactivated_packs/{f=0} f' |
  grep -Eq -- '^    - testing-reliability$' ||
  fail "pack-merge broken: routed pack 'testing-reliability' did NOT activate"
printf '  pack non-activation proven: irrelevant packs stay unloaded; '
printf 'routed testing-reliability activates\n'

# (d) the resolver writes no artifact: the tree is no dirtier after resolving.
git_clean_before=$(cd "$repo_root" && git status --porcelain 2>/dev/null)
if [ "$pack_tree_after" != "$git_clean_before" ]; then
  fail "resolver wrote an artifact: git status changed across --resolve"
fi
printf '%s\n' "$pack_resolve_out" |
  grep -Fq 'references only; no rule/doc/source body copied; no artifact written' ||
  fail "resolver did not certify references-only / no-artifact output"
printf '  resolver is references-only and wrote no artifact\n'

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
    normalized_ref=${ref_path#\~/.agentdocs/}
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
    relative_file=${file#$repo_root/}
    case "$relative_file" in
      # Plans are transient migration scratch, not durable context; they may
      # document a rename in old->new form. Durable surfaces are still scanned.
      docs/plans/*) continue ;;
    esac
    while IFS= read -r match; do
      [ -n "$match" ] || continue
      line_text=${match#*:}
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
reject_unapproved_retired_name '(^|[^-])check-docs([^a-z-]|$)' 'check-docs'
reject_unapproved_retired_name 'review-plans-health' 'review-plans-health'
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
  export-chatgpt-context.sh \
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
