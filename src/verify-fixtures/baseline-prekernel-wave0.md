# Pre-kernel baseline, Wave 0, 2026-06-21

Frozen reference for `docs/plans/agent-docs-focused-execution-kernel-build-plan.md`.
This is the pre-change reference Wave 1a's `--equivalence` proof checks the kernel
against (byte-identical profile + scenario facts). Captured verbatim against the
current `src/` tree; numbers are not editorialized. This is NOT a generated
report — it is a manually frozen snapshot.

Commit at measurement: `c2c726b` on branch `overhaul-agent-docs-install-workflow`.

> The sibling `baseline.md` is the older snapshot for the completed
> `agent-docs-execution-kernel-completion-plan.md` (pre-enforcement, 21 skills,
> report-only profiles). It is stale for this plan; use THIS file as the
> pre-kernel reference.

## Gate result at HEAD

Source: `bash src/verify-agent-docs.sh`

- Exit code: **1 (FAIL)** at clean `c2c726b`, BEFORE any Wave-0 edits.
- Sole cause (pre-existing, unrelated): `GATE FAIL: plan budget word cap
  exceeded for docs/plans/agent-docs-focused-execution-kernel-build-plan.md:
  2828 > 2600`. The build plan is committed and unmodified; the over-budget
  condition exists at HEAD independent of Wave-0 work.
- All context-profile checks and all source-bound contract checks pass
  (`CONTRACT-CHECK TOTAL VIOLATIONS: 0`); only the doc-budget stage fails.

## Profile totals vs budget (11 profiles)

Source: `bash src/verify-agent-docs.sh --context-report`. All 11 are
`enforcement: enforced`, `budget_exception: none`.

| Profile | Words | Budget | Mutation |
|---|---:|---:|---|
| `planning.brief` | 463 | 700 | read-only |
| `planning.tracked` | 1542 | 1600 | mutating |
| `implementation.code` | 1278 | 1700 | mutating |
| `implementation.code-docs` | 2071 | 2500 | mutating |
| `implementation.tracked` | 2498 | 2500 | mutating |
| `review.generic` | 355 | 700 | read-only |
| `review.docs` | 1148 | 1200 | read-only |
| `review.plan` | 782 | 1000 | read-only |
| `maintenance.docs` | 1571 | 1700 | mutating |
| `maintenance.plan` | 2016 | 2100 | mutating |
| `verification.readonly` | 319 | 500 | read-only |

11/11 within budget; 11/11 `enforced`.

## Launch budgets and constants

Source: `bash src/verify-agent-docs.sh --measure-launch <skill>`; constants from
`src/verify-agent-docs.sh`.

`--measure-launch orchestrate` (classifier):

| Component | Words |
|---|---:|
| skill-body | 900 |
| skill-contracts | 637 |
| lifecycle | 1037 |
| docs-index | 114 |
| manifest-slots | 495 |
| **TOTAL** | **3183** |

`--measure-launch quick-fix` (fixed):

| Component | Words |
|---|---:|
| skill-body | 502 |
| skill-contracts | 637 |
| docs-index | 114 |
| manifest-slots | 495 |
| **TOTAL** | **1748** |

Hardcoded budget constants in `src/verify-agent-docs.sh`: `fixed_budget=2000`,
`classifier_budget=3300`. `classifier_allowlist=" orchestrate fresh-chat
start-session "`.

## Scenario fixture (11 rows)

Source: `src/verify-fixtures/workflow-scenarios.json` (`scenarios` array, 11
entries). Representative verbatim traces:

- `bounded-quick-fix` — profiles `implementation.code, verification.readonly;
  no classifier`; phases `one implementation worker then final verification`;
  mutators `1`; final `gate observes post-mutation state`.
- `named-plan-shipping` — profiles `implementation.tracked,
  verification.readonly`; phases `implement, migrate, close plan, verify`;
  mutators `1`; final `plan closeout before final gate`.
- `dirty-tree-shipping` — profiles `implementation.code-docs,
  verification.readonly`; phases `inspect, mutate owned files, verify`;
  mutators `1`; final `owned staging before commit`.
- `failed-verification` — profiles `verification.readonly, then mutator
  profile`; phases `verification reports; fix routed out`; mutators `0 before
  fix`; final `verifier never mutates`.

Remaining rows: `unclear-small-work`, `medium-brief-plan`, `tracked-change-plan`,
`docs-repair`, `report-only-review`, `configured-app-review`, `resume-invalidated`.
The full 11-row matrix is the authority; no `planning.scope` row exists yet
(added in Wave 2). All rows are `budget_expectation: report-only`.
