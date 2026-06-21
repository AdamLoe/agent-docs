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
| `planning.brief` | inline implementation brief | `src/rules/subagent/planning.md` | task owner docs/source by concern | read-only | 700 | enforced |
| `planning.tracked` | persisted plan material | `src/rules/subagent/planning.md`, `src/plan-lifecycle.md`, `src/plan-template.md`, `src/rules/repo-rules.md` | authoring rules when plan edits touch durable docs | mutating | 1600 | enforced |
| `implementation.code` | bounded code change | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md` | source/tests selected by task; `src/rules/coding-style-rust.md` when task is Rust; `src/rules/coding-style-python.md` when task is Python; `src/rules/coding-style-frontend.md` when task is frontend/TS | mutating | 1700 | enforced |
| `implementation.code-docs` | code plus owning docs | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md`, `src/rules/authoring-rules.md` | manifest and ownership rows for touched surfaces; `src/rules/coding-style-rust.md` when task is Rust; `src/rules/coding-style-python.md` when task is Python; `src/rules/coding-style-frontend.md` when task is frontend/TS | mutating | 2500 | enforced |
| `implementation.tracked` | selected tracked-plan implementation and closeout; may close the selected plan when dispatch grants `plan_closeout` | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md`, `src/rules/authoring-rules.md`, `src/plan-lifecycle.md` | selected plans and owning architecture/decisions; `src/rules/coding-style-rust.md` when task is Rust; `src/rules/coding-style-python.md` when task is Python; `src/rules/coding-style-frontend.md` when task is frontend/TS | mutating | 2500 | enforced |
| `review.generic` | generic independent review | `src/rules/subagent/review.md` | named lens sources only | read-only | 700 | enforced |
| `review.docs` | docs/rules review | `src/rules/subagent/review.md`, `src/rules/authoring-rules.md` | named docs and ownership rows | read-only | 1200 | enforced |
| `review.plan` | plan review | `src/rules/subagent/review.md`, `src/plan-lifecycle.md` | selected plans and optional template | read-only | 1000 | enforced |
| `maintenance.docs` | docs repair or migration | `src/rules/subagent/docs-maintenance.md`, `src/rules/authoring-rules.md`, `src/rules/repo-rules.md` | manifest and ownership rows for touched docs | mutating | 1700 | enforced |
| `maintenance.plan` | plan/run lifecycle maintenance | `src/rules/subagent/plan-maintenance.md`, `src/plan-lifecycle.md`, `src/rules/authoring-rules.md`, `src/rules/repo-rules.md` | selected plans/run docs and owning docs | mutating | 2100 | enforced |
| `verification.readonly` | final or targeted gate execution | `src/rules/subagent/verification.md` | manifest drift-gates and named command output | read-only | 500 | enforced |

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

## Launch budgets

A skill's controlled launch is its body plus the irreducible startup surface:
the shared skill-contracts contract, the docs index, and its requested manifest
slots (a classifier additionally reads `orchestrator/lifecycle.md`). After the
Wave-5b honest `--measure-launch` fix — a `rules/...` path counts as a startup
load only when a sentence genuinely instructs reading it at launch, never when
it appears only in a prohibition, a `load only when/after` deferred-load gloss,
or a References pointer — the enforced launch budgets are E3 measured floors:

| Launch kind | Budget | Honest max | Headroom |
|---|---:|---|---:|
| fixed skill | 2000 | 1922 (`review-app`) | ~4% |
| classifier (`orchestrate`, `fresh-chat`, `start-session`) | 3300 | 3118 (`orchestrate`) | ~6% |

The aspirational 1200/2000 targets are unreachable: the shared startup surface
(skill-contracts 637 + docs index 114 + manifest slots 430 = 1181) loads on
every launch, and a classifier irreducibly reads lifecycle.md (1037). Per E3
these floors are documented target changes, not inflation to hide drift. The
verifier (`src/verify-agent-docs.sh`) holds the operative values and now gates on
them; this table is the human-owned record.

## See also

- [`context-profiles-reference.md`](context-profiles-reference.md) — rationale (do not auto-load).
- [`orchestrator/dispatch.md`](orchestrator/dispatch.md)
- [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md)
- [`../skills/registry.md`](../skills/registry.md)
