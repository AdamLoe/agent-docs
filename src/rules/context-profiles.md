# Context profiles (agent-docs v1)

GENERIC. App-independent. This file is the canonical owner for worker context
profiles. Skills and dispatch rules name profile IDs from this table; they do
not copy profile tables, rule bundles, or mutation policy.

## Owner Contract

Each profile row defines:

- `id` - stable profile ID used by skills and dispatches.
- `purpose` - the work shape the profile supports.
- `core_rule_paths` - exact rule files loaded before task-routed sources.
- `overlays` - conditional files loaded only when the named condition is true.
- `mutation_capability` - `read-only`, `mutating`, or `conditional`.
- `budget_words` - report target for core rule files, excluding task-routed
  docs/source/tests.
- `enforcement_status` - `report-only`, `pilot-enforced`, or `enforced`.

Budget exceptions must name the exact files and the correctness reason in the
context report. Enforcement is enabled only after the profile, converted skills,
scenario rows, and verifier checks agree.

## Profiles

| id | purpose | core_rule_paths | overlays | mutation_capability | budget_words | enforcement_status |
|---|---|---|---|---|---:|---|
| `planning.brief` | inline implementation brief | `src/rules/subagent/planning.md` | task owner docs/source by concern | read-only | 700 | report-only |
| `planning.tracked` | persisted plan material | `src/rules/subagent/planning.md`, `src/plan-lifecycle.md`, `src/plan-template.md`, `src/rules/repo-rules.md` | authoring rules when plan edits touch durable docs | mutating | 1300 | report-only |
| `implementation.code` | bounded code change | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md` | source/tests selected by task | mutating | 1700 | report-only |
| `implementation.code-docs` | code plus owning docs | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md`, `src/rules/authoring-rules.md` | manifest and ownership rows for touched surfaces | mutating | 2500 | report-only |
| `implementation.tracked` | selected tracked-plan implementation and closeout | `src/rules/subagent/implementation.md`, `src/rules/repo-rules.md`, `src/rules/coding-style.md`, `src/rules/authoring-rules.md`, `src/plan-lifecycle.md` | selected plans and owning architecture/decisions | mutating | 2500 | report-only |
| `review.generic` | generic independent review | `src/rules/subagent/review.md` | named lens sources only | read-only | 700 | report-only |
| `review.docs` | docs/rules review | `src/rules/subagent/review.md`, `src/rules/authoring-rules.md` | named docs and ownership rows | read-only | 1000 | report-only |
| `review.plan` | plan review | `src/rules/subagent/review.md`, `src/plan-lifecycle.md` | selected plans and optional template | read-only | 1000 | report-only |
| `maintenance.docs` | docs repair or migration | `src/rules/subagent/docs-maintenance.md`, `src/rules/authoring-rules.md`, `src/rules/repo-rules.md` | manifest and ownership rows for touched docs | mutating | 1700 | report-only |
| `maintenance.plan` | plan/run lifecycle maintenance | `src/rules/subagent/plan-maintenance.md`, `src/plan-lifecycle.md`, `src/rules/authoring-rules.md`, `src/rules/repo-rules.md` | selected plans/run docs and owning docs | mutating | 1800 | report-only |
| `verification.readonly` | final or targeted gate execution | `src/rules/subagent/verification.md` | manifest drift-gates and named command output | read-only | 500 | report-only |

## Scenario Contract

The verifier treats workflow scenarios as a report-only behavioral contract,
each naming expected questions, profiles, phases, mutator count, state-basis
fields, final ordering, and budget expectation. That matrix is verifier-only
data, so it lives in the never-auto-loaded fixture
`src/verify-fixtures/workflow-scenarios.json` instead of this runtime-loaded
file. The verifier reads it there; rerun `bash src/verify-agent-docs.sh
--context-report` to see the `bounded-quick-fix` and other scenario rows. No
skill or runtime context loads that fixture.

## See also

- [`orchestrator/dispatch.md`](orchestrator/dispatch.md)
- [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md)
- [`../skills/registry.md`](../skills/registry.md)
