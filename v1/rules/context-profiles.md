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
| `planning.brief` | inline implementation brief | `v1/rules/subagent/planning.md` | task owner docs/source by concern | read-only | 700 | report-only |
| `planning.tracked` | persisted plan material | `v1/rules/subagent/planning.md`, `v1/plan-lifecycle.md`, `v1/plan-template.md`, `v1/rules/repo-rules.md` | authoring rules when plan edits touch durable docs | mutating | 1300 | report-only |
| `implementation.code` | bounded code change | `v1/rules/subagent/implementation.md`, `v1/rules/repo-rules.md`, `v1/rules/coding-style.md` | source/tests selected by task | mutating | 1700 | report-only |
| `implementation.code-docs` | code plus owning docs | `v1/rules/subagent/implementation.md`, `v1/rules/repo-rules.md`, `v1/rules/coding-style.md`, `v1/rules/authoring-rules.md` | manifest and ownership rows for touched surfaces | mutating | 2500 | report-only |
| `implementation.tracked` | selected tracked-plan implementation and closeout | `v1/rules/subagent/implementation.md`, `v1/rules/repo-rules.md`, `v1/rules/coding-style.md`, `v1/rules/authoring-rules.md`, `v1/plan-lifecycle.md` | selected plans and owning architecture/decisions | mutating | 2500 | report-only |
| `review.generic` | generic independent review | `v1/rules/subagent/review.md` | named lens sources only | read-only | 700 | report-only |
| `review.docs` | docs/rules review | `v1/rules/subagent/review.md`, `v1/rules/authoring-rules.md` | named docs and ownership rows | read-only | 1000 | report-only |
| `review.plan` | plan review | `v1/rules/subagent/review.md`, `v1/plan-lifecycle.md` | selected plans and optional template | read-only | 1000 | report-only |
| `maintenance.docs` | docs repair or migration | `v1/rules/subagent/docs-maintenance.md`, `v1/rules/authoring-rules.md`, `v1/rules/repo-rules.md` | manifest and ownership rows for touched docs | mutating | 1700 | report-only |
| `maintenance.plan` | plan/run lifecycle maintenance | `v1/rules/subagent/plan-maintenance.md`, `v1/plan-lifecycle.md`, `v1/rules/authoring-rules.md`, `v1/rules/repo-rules.md` | selected plans/run docs and owning docs | mutating | 1800 | report-only |
| `verification.readonly` | final or targeted gate execution | `v1/rules/subagent/verification.md` | manifest drift-gates and named command output | read-only | 500 | report-only |

## Scenario Contract

The verifier treats these rows as a report-only behavioral contract. Each row
names expected questions, profiles, phases, mutator count, state-basis fields,
final ordering, and budget expectation.

| scenario_id | task_shape | expected_questions | expected_profiles | expected_phases | expected_mutator_count | state_basis_fields | final_ordering | budget_expectation |
|---|---|---|---|---|---:|---|---|---|
| `bounded-quick-fix` | supplied bounded fix | none; no dial picker | `implementation.code`, `verification.readonly`; no classifier | one implementation worker then final verification | 1 | HEAD plus exact dirty paths | gate observes post-mutation state | report-only within budget |
| `unclear-small-work` | small but underspecified | one material task question; no dial picker | `planning.brief` before implementation | question then brief or route | 0 | HEAD plus exact dirty paths | no worker before answer | report-only |
| `medium-brief-plan` | medium unclear change | none after supplied intent | `planning.brief` | read-only planning brief | 0 | HEAD plus exact dirty paths | inline brief before mutation | report-only |
| `tracked-change-plan` | explicit tracked plan creation | none after supplied intent | `planning.tracked` | plan write and commit | 1 | HEAD plus exact dirty paths | plan persistence before review | report-only |
| `dirty-tree-shipping` | ship with unrelated dirt | none unless dirt blocks | `implementation.code-docs`, `verification.readonly` | inspect, mutate owned files, verify | 1 | HEAD plus exact dirty paths | owned staging before commit | report-only |
| `named-plan-shipping` | selected existing plan | none for draft status | `implementation.tracked`, `verification.readonly` | implement, migrate, close plan, verify | 1 | HEAD plus exact dirty paths | plan closeout before final gate | report-only |
| `docs-repair` | docs-only repair | none when scope supplied | `maintenance.docs`, `verification.readonly` | docs maintenance then gate | 1 | HEAD plus exact dirty paths | docs mutation before final gate | report-only |
| `report-only-review` | independent review | none when lens supplied | `review.generic` | review only | 0 | HEAD plus exact dirty paths | findings route to mutator | report-only |
| `configured-app-review` | supplied audit config | no reconfirmation; approval before plans | `review.generic`, `planning.tracked` after approval | audit, findings, approved plans | 1 after approval | HEAD plus exact dirty paths | plan creation waits for approval | report-only |
| `failed-verification` | gate failure | none unless fix choice needed | `verification.readonly`, then mutator profile | verification reports; fix routed out | 0 before fix | observed commit plus dirty paths | verifier never mutates | report-only |
| `resume-invalidated` | worker resume after overlap | none; force delta reread or fresh worker | original profile plus reread | invalidate, reread or respawn | unchanged | intervening commit and dirty overlap | no stale resume before reread | report-only |

## See also

- [`orchestrator/dispatch.md`](orchestrator/dispatch.md)
- [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md)
- [`../skills/registry.md`](../skills/registry.md)
