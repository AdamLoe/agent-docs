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
  bash src/verify-agent-docs.sh --measure-launch <skill-name>
  bash src/verify-agent-docs.sh --scaffold <repo-root>

Default mode validates the agent-docs kit checkout that contains this script.
The --context-report mode prints the read-only context profile and scenario
contract, including exact files, conditions, word totals, and budget exceptions.
Scenario rows are read from the never-auto-loaded fixture
src/verify-fixtures/workflow-scenarios.json.
The --contract-check mode runs the Wave-5a source-bound contract checks
(launch budgets, lifecycle startup loads, subagent-bundle spell-outs, read-only
role authority, plan_closeout consistency, review-app pre-audit/eager loads,
scenario source-binding, report fields, and final-ordering). All checks are
REPORT-ONLY: it warns and prints a violation count but exits 0.
The --resolve mode prints one profile's core rule paths, conditional overlays,
mutation capability, and budget so a skill can resolve a single profile without
loading the whole table.
The --measure-launch mode prints the controlled launch word total for one skill
(skill body, shared startup contract, startup orchestrator/role rules, docs
index, and requested manifest slots), excluding task-routed source/tests.
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

scenario_fixture() {
  printf '%s' "$repo_root/src/verify-fixtures/workflow-scenarios.json"
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

  if [ -z "$profile_filter" ]; then
    contract_check
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
  # the skill actually loads at launch, not task-routed overlays.
  for rule in context-profiles.md orchestrator/dispatch.md orchestrator/lifecycle.md; do
    if grep -Fq "rules/$rule" "$skill_file"; then
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
    grep -Fq "rules/$rule" "$skill_file" && add_quiet "$repo_root/src/rules/$rule"
  done
  add_quiet "$repo_root/docs/index.md"
  add_quiet "$repo_root/docs/_meta/manifest.md"

  printf '%s' "$total"
}

# --contract-check: Wave-5a SOURCE-BOUND contract checks. Every check below is an
# assertion over actual files (skill bodies, role cards, profile owner, scenario
# fixture), NOT a phrase match over a self-authored table. They are REPORT-ONLY:
# each prints a CLEAN line or one WARN line per violation (with file:line where
# possible) and increments a violation counter. The function never exits nonzero,
# never prints FAIL, and never changes enforcement_status. Flipping these to hard
# gates is Wave 5b. Also surfaced as a section inside --context-report.
#
# Budgets (E3 floors, recorded as the report-only documented budgets):
#   fixed skill controlled launch  <= 1800   (measured floor ~1683)
#   classifier controlled launch   <= 3200   (allowlist: orchestrate, fresh-chat,
#                                              start-session)
contract_check() {
  local fixed_budget=1800
  local classifier_budget=3200
  local classifier_allowlist=" orchestrate fresh-chat start-session "
  local violations=0
  local skill_dir skill_name skill_file total budget kind clean
  local match python_cmd

  section "wave-5a source-bound contract checks (report-only)"

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] || fail "cannot run contract checks; install python"

  # ---- Check 1: launch budgets -------------------------------------------
  # For every skill, compute the controlled launch total and warn if a fixed
  # skill exceeds 1800 or an allowlisted classifier exceeds 3200.
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
  # plan_closeout must appear consistently across implementation.md, the
  # context-profiles owner (implementation.tracked row), and dispatch.md.
  printf -- '-- check 5: plan_closeout authority consistency --\n'
  clean=1
  declare -A closeout_present=()
  for pair in \
    "src/rules/subagent/implementation.md" \
    "src/rules/context-profiles.md" \
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
  # Extra cross-check: context-profiles must carry it on the implementation.tracked row.
  if ! grep -E '`implementation.tracked`' "$repo_root/src/rules/context-profiles.md" | grep -Fq 'plan_closeout'; then
    violations=$((violations + 1))
    clean=0
    printf 'WARN context-profiles implementation.tracked row missing plan_closeout grant\n'
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

  # ---- Total -------------------------------------------------------------
  printf 'CONTRACT-CHECK TOTAL VIOLATIONS: %s (report-only; not gating)\n' "$violations"
  printf 'CONTRACT-CHECK PASS\n'
}

validate_context_profiles() {
  local python_cmd

  python_cmd=$(find_python_cmd)
  [ -n "$python_cmd" ] ||
    fail "cannot validate context profiles; install python"

  if ! "$python_cmd" - "$repo_root/src/rules/context-profiles.md" "$repo_root" "$(scenario_fixture)" <<'PY'
import json
import pathlib
import sys

profile_path = pathlib.Path(sys.argv[1])
repo_root = pathlib.Path(sys.argv[2])
scenario_fixture = pathlib.Path(sys.argv[3])
text = profile_path.read_text(encoding="utf-8")

profile_rows = []
for line in text.splitlines():
    if not line.startswith("| `"):
        continue
    cells = [cell.strip().strip("`") for cell in line.strip().strip("|").split("|")]
    if len(cells) == 7:
        profile_rows.append(cells)

# Scenarios are verifier-only data; they live in a never-auto-loaded fixture so
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
  --contract-check)
    [ "$#" -eq 1 ] || { usage >&2; exit 2; }
    contract_check
    exit 0
    ;;
  --resolve)
    [ "$#" -eq 2 ] || { usage >&2; exit 2; }
    resolve_profile "$2"
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
require_file "src/verify-fixtures/workflow-scenarios.json"
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
      docs/plans/orchestrator/*) continue ;;
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
