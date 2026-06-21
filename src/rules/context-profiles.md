# Context profiles (agent-docs v1)

GENERIC. App-independent. This file is the canonical owner for worker context
profiles. Skills and dispatch rules name profile IDs from this table; they do
not copy profile tables, rule bundles, or mutation policy.

Expanded rationale (do not auto-load):
[`context-profiles-reference.md`](context-profiles-reference.md).

## Owner Contract

Each profile row defines:

- `id` - stable profile ID used by skills and dispatches.
- `purpose` - the work shape the profile supports.
- `core_rule_paths` - exact rule files loaded before task-routed sources.
- `overlays` - conditional files loaded only when the named condition is true.
- `mutation_capability` - `read-only`, `mutating`, or `conditional` (`review.*`
  and `verification.*` are always `read-only`).
- `budget_words` - report target for core rule files, excluding task-routed
  docs/source/tests.
- `enforcement_status` - `report-only`, `pilot-enforced`, or `enforced`
  (only the latter two make an over-budget total a hard failure).

Budget exceptions must name the exact files and the correctness reason in the
context report. Enforcement is enabled only after the profile, converted skills,
scenario rows, and verifier checks agree.

## Profiles

| id | purpose | core_rule_paths | overlays | mutation_capability | budget_words | enforcement_status |
|---|---|---|---|---|---:|---|
| `planning.brief` | inline implementation brief | `src/rules/subagent/planning.md` | task owner docs/source by concern | read-only | 700 | report-only |
| `planning.tracked` | persisted plan material | `src/rules/subagent/planning.md`, `src/plan-lifecycle.md`, `src/plan-template.md`, `src/rules/repo-rules.md` | authoring rules when plan edits touch durable docs | mutating | 1600 | report-only |
| `implementation.code` | bounded code change | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md` | source/tests selected by task; `src/rules/coding-style-rust.md` when task is Rust; `src/rules/coding-style-python.md` when task is Python; `src/rules/coding-style-frontend.md` when task is frontend/TS | mutating | 1700 | report-only |
| `implementation.code-docs` | code plus owning docs | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md`, `src/rules/authoring-rules.md` | manifest and ownership rows for touched surfaces; `src/rules/coding-style-rust.md` when task is Rust; `src/rules/coding-style-python.md` when task is Python; `src/rules/coding-style-frontend.md` when task is frontend/TS | mutating | 2500 | report-only |
| `implementation.tracked` | selected tracked-plan implementation and closeout; may close the selected plan when dispatch grants `plan_closeout` | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md`, `src/rules/authoring-rules.md`, `src/plan-lifecycle.md` | selected plans and owning architecture/decisions; `src/rules/coding-style-rust.md` when task is Rust; `src/rules/coding-style-python.md` when task is Python; `src/rules/coding-style-frontend.md` when task is frontend/TS | mutating | 2500 | report-only |
| `review.generic` | generic independent review | `src/rules/subagent/review.md` | named lens sources only | read-only | 700 | report-only |
| `review.docs` | docs/rules review | `src/rules/subagent/review.md`, `src/rules/authoring-rules.md` | named docs and ownership rows | read-only | 1200 | report-only |
| `review.plan` | plan review | `src/rules/subagent/review.md`, `src/plan-lifecycle.md` | selected plans and optional template | read-only | 1000 | report-only |
| `maintenance.docs` | docs repair or migration | `src/rules/subagent/docs-maintenance.md`, `src/rules/authoring-rules.md`, `src/rules/repo-rules.md` | manifest and ownership rows for touched docs | mutating | 1700 | report-only |
| `maintenance.plan` | plan/run lifecycle maintenance | `src/rules/subagent/plan-maintenance.md`, `src/plan-lifecycle.md`, `src/rules/authoring-rules.md`, `src/rules/repo-rules.md` | selected plans/run docs and owning docs | mutating | 2100 | report-only |
| `verification.readonly` | final or targeted gate execution | `src/rules/subagent/verification.md` | manifest drift-gates and named command output | read-only | 500 | report-only |

## Scenario Contract

Workflow scenarios are a report-only behavioral contract (expected questions,
profiles, phases, mutator count, state-basis fields, final ordering, budget
expectation per task shape). That matrix is verifier-only data and lives in the
never-auto-loaded fixture `src/verify-fixtures/workflow-scenarios.json`, not on
this runtime-loaded file. No skill or runtime context loads that fixture; rerun
`bash src/verify-agent-docs.sh --context-report` to see the `bounded-quick-fix`
and other scenario rows.

## Budget floors

Three profiles were raised to their measured correctness floors after Wave-3
relocation removed all relocatable content with zero correctness loss (Decision
E3). The residual is irreducible normative contract — deleting rules to hit the
original aspirational targets would reduce correctness, not improve context
economy. Raising the budgets is a documented target change per E3, not inflation
to hide drift.

| Profile | Old budget | New budget | Measured floor |
|---|---:|---:|---:|
| `planning.tracked` | 1300 | 1600 | 1542 |
| `review.docs` | 1000 | 1200 | 1148 |
| `maintenance.plan` | 1800 | 2100 | 2016 |

## See also

- [`context-profiles-reference.md`](context-profiles-reference.md) — rationale (do not auto-load).
- [`orchestrator/dispatch.md`](orchestrator/dispatch.md)
- [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md)
- [`../skills/registry.md`](../skills/registry.md)
