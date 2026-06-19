# Lifecycle and Orchestration Review

## Findings

- **High - Final verification is not consistently the last mutation boundary.** The shared shipping contract updates docs before gates in `v1/rules/skill-contracts.md:169`, and `/ship-current-work` routes docs/plan maintenance before verification in `v1/skills/ship-current-work/SKILL.md:38`. But the orchestrator skeleton runs the final gate before closeout in `v1/rules/orchestrator/lifecycle.md:175`, `/ship-plans` lists verification before plan-maintenance in `v1/skills/ship-plans/SKILL.md:56`, and authoring rules run gates before doc/plan frontmatter updates in `v1/rules/authoring-rules.md:121`. That lets "green" predate final docs/frontmatter edits.

- **High - Persisting tracked plans between planning and review is underspecified.** Planning workers may write tracked plans, but read-only planners return text inline and persistence needs a write-capable worker or orchestrator in `v1/rules/subagent/planning.md:24` and `v1/rules/subagent/planning.md:28`. `/orchestrate` then says the planner drafts tracked plans and the review worker reviews plan files in `v1/skills/orchestrate/SKILL.md:64` and `v1/skills/orchestrate/SKILL.md:71`, but no phase clearly persists and commits those files. This weakens resumability.

- **Medium - `abandoned` and `okay_to_delete` semantics conflict.** `abandoned` says set `okay_to_delete: true` in `v1/plan-lifecycle.md:35`, while the `okay_to_delete` field says true means the plan shipped and context migrated in `v1/plan-lifecycle.md:40`. Cleanup skills handle shipped and abandoned together, including migration, in `v1/skills/clear-plans/SKILL.md:57`. The field definition should cover abandoned plans explicitly.

- **Medium - Review-worker fix authority is not matched by the rule bundle.** Review rules allow authorized fixes by following implementation-worker discipline in `v1/rules/subagent/review.md:22`, and `/orchestrate` says shipped-review workers may fix and commit obvious misses in `v1/skills/orchestrate/SKILL.md:83`. But the review bundle only includes `review.md` plus source in `v1/rules/orchestrator/dispatch.md:91`. Either route fixes to implementation workers or expand the dispatch when fixes are authorized.

- **Low - Read-only parallelism overstates verification safety.** Lifecycle correctly says scarce resources serialize in `v1/rules/orchestrator/lifecycle.md:124`, but dispatch says read-only workers, including verification, run in parallel "at any time" in `v1/rules/orchestrator/dispatch.md:142`. Qualify this for scarce-resource gates and final consolidated gates.

## What Works

- The orchestrator/worker split is clear and repeated consistently across `skill-contracts`, `workflow-kit`, decisions, and the orchestrator rules.
- Run docs are coherent: opt-in, hub-owned, plan-lifecycle-shaped, and disposable after migration.
- Worker reports have the right resumability fields: inspected files, checks, durable migration needs, blockers, residual risk, and commit/no-change status.
- Commit concurrency is enforceable: serial editing by default, worktrees or patches for parallel editing, and read-only fan-out where safe.

## Biggest Pitches

- Make one canonical phase order: last mutation, final drift gate, closeout report.
- Add an explicit "persist planner output" subphase and actor for tracked plans.
- Redefine `okay_to_delete` as "shipped or abandoned, and durable context migrated or none exists."
- Remove review-worker commits from `/orchestrate`, or require the implementation/repo rule bundle whenever a review worker may fix.
- Tighten read-only parallelism wording around verification gates.

## Open Questions

- Should planning workers be allowed to edit and commit plan files, or should a maintenance worker persist planner output?
- Should the final consolidated gate always run after plan frontmatter and run-doc closeout edits?
- Should abandoned plans require the same migration sanity check as shipped plans before `okay_to_delete: true`?
- Should review workers ever commit fixes, or should fixes always route through implementation workers?

## Checks

- Files/docs inspected: `docs/index.md`, `docs/overview.md`, `docs/_meta/manifest.md`, `docs/architecture/workflow-kit.md`, `docs/decisions/agent-docs.md`, `docs/agent-context/orchestrating.md`, `docs/plans/index.md`, `docs/plans/orchestrator/repo-wide-review-2026-06-19/hub.md`, `v1/agent-docs-guide.md`, `v1/plan-lifecycle.md`, `v1/plan-template.md`, `v1/rules/skill-contracts.md`, `v1/rules/authoring-rules.md`, `v1/rules/orchestrator/*`, `v1/rules/subagent/*`, and lifecycle-relevant skill bodies.
- Checks run: `rg --files`, targeted `rg -n`, `nl -ba`, `find docs/plans/orchestrator/repo-wide-review-2026-06-19 -maxdepth 3 -type f -print`, and `git status --short`.
- Result: read-only review completed. Full verifier intentionally not run. Existing deleted `docs/plans/` files were not restored, staged, or modified.
- Durable migration candidates if accepted: canonical final-gate ordering, tracked-plan persistence actor, abandoned cleanup semantics, and review-worker fix authority.
- Blockers: none. Residual risk: this was a targeted lifecycle review, not a full verifier or exhaustive skill audit.
- Explicit no-change result: no files edited, staged, or committed.
