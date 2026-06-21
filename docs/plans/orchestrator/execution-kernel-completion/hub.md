---
status:        active
owner:         orchestrator
last_updated:  2026-06-21
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Run hub — Execution-kernel completion

Executing [`../agent-docs-execution-kernel-completion-plan.md`](../agent-docs-execution-kernel-completion-plan.md)
straight-through (user choice): all 6 waves, stop only for genuine
blockers/decisions, report at the end. Dials: cost-medium, review-medium.

## Hazards / limits (carry forward)

- **Rewrites the running kit.** Waves edit `src/rules/**`, `src/skills/**`, and
  `src/verify-agent-docs.sh` — the files workers run on. Route workers by explicit
  `src/...` path; the live `~/.agentdocs/` runtime is NOT refreshed during the run
  (install needs user permission). High resume risk → this hub.
- **Manual canaries can't be run by me** (live Claude Code + Codex). Left for the
  user; the run completes the automated exit gate only.
- **Aggressive budgets.** Per the plan, a target that can't be met WITHOUT cutting
  correctness requires an explicit decision entry — STOP and ask, don't gut a rule.
- **Enforcement flip is LAST.** Wave 5 flips profiles report-only→enforced + makes
  the gate fail on violations. Must come AFTER budgets are met (Waves 3–4) or the
  gate red-blocks everything.

## True baseline (measured at run start, post-refactor)

Profiles over budget (7/11): planning.tracked 2069/1300, implementation.code
1820/1700, implementation.code-docs 3248/2500, implementation.tracked 3901/2500,
review.docs 1747/1000, maintenance.docs 2528/1700, maintenance.plan 3199/1800.
Within budget (4/11): planning.brief 417/700, review.generic 319/700, review.plan
972/1000, verification.readonly 309/500.
Skills: 18/21 load `lifecycle.md`; 15/21 spell out `rules/subagent/` bundles; all
11 profiles `report-only`. Launch totals (quick-fix/orchestrate) not emitted by
context-report directly — Wave 0 measures them.

## Wave tracker

| Wave | Outcome | Status | Last observed fact | Commit |
|---|---|---|---|---|
| 0 | Truthful baseline + freeze (fixtures, re-measure, update plan baseline) | done | launches: quick-fix 3557/≤1200, orchestrate 5796/≤2000; fixture src/verify-fixtures/baseline.md | 7f3809d |
| 1a | Scenario matrix → fixture + resolver modes + verifier reads fixture | done | context-profiles 892→503; launches −389 each (qf 3168, orch 5407); --resolve/--measure-launch added | fc07685 |
| 1b | Role-card "what you read" rewrites (subagent/*.md) | active | 6 role cards; profiles must be sole context authority | — |
| 2 | Align role + mutation contracts (closeout authority, remove fix-enabled review) | pending | — | — |
| 3 | Meet worker + launch budgets (compress runtime rules, no correctness loss) | pending | — | — |
| 4 | Finish skill recipes (21 skills → profile IDs; review-app defaults) | pending | — | — |
| 5 | Source-bound verifier gates + flip enforcement | pending | — | — |
| 6 | Durable migration + closeout | pending | — | — |

Editing serial on the shared tree. Review where risk warrants (verifier rewrite,
budget compression). Final gate after the last mutation.

## Decisions log

| # | Decision | Source |
|---|---|---|
| E1 | Execute straight-through to the automated exit gate; manual Claude/Codex canaries handed to user. | user |
| E2 | Plan doc already fixed for the refactor (f2d7c7b); prior context-simplification plan was deleted, so this is the single live plan. | prior turn |

## Streams

- `streams/` (one note per wave, worker-written)

## Open questions / blockers

- None yet.
