# Wave 1a stream — Scenario fixture + read-only resolver modes

Profile: implementation.code-docs. One mutating worker; commits its own slice.

## Scenario fixture

- Path: `src/verify-fixtures/workflow-scenarios.json`
- Format: JSON, parsed via the verifier's existing Python helper
  (`find_python_cmd`). Chosen over a tracked table because the scenario
  validation in `validate_context_profiles()` is already Python-based and the
  needle checks read structured fields cleanly; JSON keeps the matrix machine-
  clean and off every Markdown runtime-load surface. The same field order as the
  old in-doc table is preserved (`scenario_id`, `task_shape`,
  `expected_questions`, `expected_profiles`, `expected_phases`,
  `expected_mutator_count`, `state_basis_fields`, `final_ordering`,
  `budget_expectation`), so downstream needle checks and `--context-report`
  SCENARIO output are unchanged.
- All 11 scenario rows moved verbatim from the `## Scenario Contract` table in
  `src/rules/context-profiles.md`. That table is gone from the runtime load
  surface; a one-line pointer to the fixture replaces it (still names
  `bounded-quick-fix` so the human-owned contract anchor and the existing
  `require_text` check both hold). Never auto-loaded by any skill:
  `rg -l "workflow-scenarios|verify-fixtures" src/skills` is empty.

## Verifier changes (`src/verify-agent-docs.sh`)

- `scenario_rows()` now reads the fixture (new `scenario_fixture()` helper)
  instead of parsing an 11-column table out of `context-profiles.md`. Output is
  still tab-separated in the same column order, so `context_report()` consumes
  it unchanged.
- `validate_context_profiles()` Python now takes the fixture path as a third arg
  and loads `scenario_rows` from JSON; profile rows still parse from
  `context-profiles.md`. Required-scenario set, `checks` needle map, and budget
  checks are unchanged — the relocated source did not weaken any check.
- Added `require_file "src/verify-fixtures/workflow-scenarios.json"` to the kit
  checks so the fixture is mandatory.

## New read-only resolver modes (additive, write nothing, no copied rule bodies)

- `--resolve <profile-id>`: prints that one profile's core_paths, overlays,
  mutation capability, budget, resolved word total, enforcement, and budget
  exception. Resolves ONE profile via `context_profile_rows()` without emitting
  the whole table. Unknown id fails nonzero.
- `--measure-launch <skill-name>`: prints the Wave-0 controlled launch total —
  skill body + `skill-contracts.md` + the startup orchestrator/role rules the
  SKILL body names (`context-profiles.md`, `dispatch.md`, `lifecycle.md`,
  detected by grepping the body) + `docs/index.md` + `docs/_meta/manifest.md`.
  Task-routed source/tests excluded. Unknown skill fails nonzero.

Sample output lines:

```
RESOLVE implementation.code
  core_paths: src/rules/subagent/implementation.md, src/rules/repo-rules.md, src/rules/coding-style.md
  overlays: source/tests selected by task
  mutation: mutating
  budget: 1700
  resolved_words: 1820
  enforcement: report-only
```

```
MEASURE-LAUNCH quick-fix
  skill-body             487
  skill-contracts        831
  context-profiles       503
  dispatch               803
  docs-index             114
  manifest-slots         430
  TOTAL                  3168
```

## context-profiles.md word delta

- Before: 892 words. After: 503 words (−389), exactly the scenario matrix that
  left the runtime load. Owner Contract + Profiles table stay human-owned in the
  file.

## Launch-measurement effect

Removing the matrix from `context-profiles.md` drops the measured launches below
the Wave-0 figures by the same 389 words (the file is loaded at startup):

- `quick-fix` controlled launch: 3,557 → 3,168 words.
- `orchestrate` classifier launch: 5,796 → 5,407 words (lifecycle.md still
  detected and included).

The formula is identical to Wave 0; only the `context-profiles.md` input shrank.
This is the intended effect of relocating verifier-only data, not a regression.

## Gate results

- `bash src/verify-agent-docs.sh` → exit 0, `ALL AGENT-DOCS GATES PASS`.
- `bash src/verify-agent-docs.sh --context-report` → exit 0; 11 PROFILE + 11
  SCENARIO lines (scenarios now from the fixture); `CONTEXT REPORT PASS`.
- `bash src/verify-agent-docs.sh --resolve implementation.code` → exit 0;
  `RESOLVE PASS`.
- `bash src/verify-agent-docs.sh --measure-launch quick-fix` → exit 0; TOTAL
  3168; `MEASURE-LAUNCH PASS`.
- `rg -l "workflow-scenarios|verify-fixtures" src/skills` → empty.

## Durable facts for later waves

- Scenario matrix is verifier-only data living in
  `src/verify-fixtures/workflow-scenarios.json`; field order mirrors the retired
  in-doc table. Wave 5 strengthens these checks against actual source/contracts.
- `--resolve` and `--measure-launch` are the read-only resolver surface Wave 4
  wires skills to; they write nothing and copy no rule bodies.
- `verify-fixtures/` has no ownership/manifest rows yet (matches `baseline.md`
  precedent); Wave 6 owns adding resolver/fixture ownership + manifest coverage.
