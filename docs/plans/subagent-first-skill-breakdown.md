---
status:        draft
owner:         unassigned
last_updated:  2026-06-18
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Subagent-first skill breakdown

## Mission

Define how each current skill should behave after the workflow kit moves to a
subagent-first model. This is the detailed companion to
[`workflow-rule-abstraction.md`](workflow-rule-abstraction.md).

Each user-facing skill becomes an orchestrator entry point. Its job is to
bootstrap, classify, choose worker phases, pass exact rule-file routes, track
worker evidence, and report to the human. The actual task work happens in
subagents using rules under `v1/rules/subagent/`.

## Rule Folder Targets

The migration should create two class-specific rule folders:

```text
v1/rules/orchestrator/
  lifecycle.md
  dispatch.md
  run-docs.md

v1/rules/subagent/
  planning.md
  implementation.md
  review.md
  docs-maintenance.md
  plan-maintenance.md
  verification.md
  capture.md
```

Universal rules stay at `v1/rules/`:

- `skill-contracts.md` — startup contract, dials, human stops, model policy,
  and the subagent-first expectation for user-facing skills.
- `repo-rules.md` — git, commit, push, staging, and destructive-command
  discipline.
- `authoring-rules.md` — documentation maintenance and migration rules.
- `coding-style.md` — code quality and implementation principles.

`v1/plan-lifecycle.md` remains the canonical plan metadata/lifecycle owner
unless implementation decides to add a compatibility pointer from
`v1/rules/subagent/plan-maintenance.md`.

## Dispatch Baseline

Every orchestrator dispatch should name exact rule files. Workers should not
discover the workflow tree.

Base dispatch shape:

```text
Role:
Task:
Input docs/plans/context:
Read these exact rules:
- ~/agent-docs/v1/rules/subagent/<role>.md
- <any universal rule required for this role>
Expected output:
Expected checks/evidence:
Report back with:
```

Standard worker report:

- outcome
- files/docs touched or inspected
- checks run and result
- durable facts/decisions needing migration
- blockers, assumptions, residual risk
- commit hash, when the worker committed

## Common Rule Bundles

These bundles are shorthand for the per-skill matrix below.

| Bundle | Rule files |
|---|---|
| Orchestrator core | `v1/rules/skill-contracts.md`, `v1/rules/orchestrator/lifecycle.md`, `v1/rules/orchestrator/dispatch.md` |
| Stateful orchestration | Orchestrator core + `v1/rules/orchestrator/run-docs.md`, `v1/plan-lifecycle.md` |
| Planning worker | `v1/rules/subagent/planning.md`, `v1/plan-lifecycle.md`, `v1/plan-template.md` |
| Implementation worker | `v1/rules/subagent/implementation.md`, `v1/rules/coding-style.md`, `v1/rules/authoring-rules.md`, `v1/rules/repo-rules.md` |
| Review worker | `v1/rules/subagent/review.md`, plus the role-specific source being reviewed |
| Docs-maintenance worker | `v1/rules/subagent/docs-maintenance.md`, `v1/rules/authoring-rules.md` |
| Plan-maintenance worker | `v1/rules/subagent/plan-maintenance.md`, `v1/plan-lifecycle.md`, `v1/rules/authoring-rules.md` |
| Verification worker | `v1/rules/subagent/verification.md`, `v1/rules/repo-rules.md` |
| Capture worker | `v1/rules/subagent/capture.md` |

## Skill Breakdown

### `fresh-chat`

Orchestrator overview: bootstrap a new session, load only enough docs router
context to classify the user's first task, then route the request to the
smallest owning orchestrator skill. It usually does not spawn task workers
itself unless the request is a read-only context answer.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md` for `repo_name` and `code_root`.
- `docs/index.md`.
- `docs/overview.md`.
- The smallest route for the user's actual request.

Worker phases:

- Optional context-reading worker for broad read-only questions.
- Otherwise hand off to `plan`, `quick-fix`, `orchestrate`, `check-docs`, or
  another owning skill.

Rules passed to workers:

- Context-reading worker: Review worker or docs-maintenance worker, depending
  on whether the task is explanatory or a docs-quality check.

Closeout evidence:

- Routed command or answered context question.
- Any docs/code routes loaded.
- Any next skill the user should invoke, if fresh-chat cannot directly route.

### `plan`

Orchestrator overview: turn rough user intent into discussion, briefs, or
tracked planning docs by dispatching planning workers. The top-level agent
owns questioning, concern grouping, workstream split, and final doc placement;
planning workers do investigation and draft implementer-ready material.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md` for `repo_name` and `code_root`.
- `docs/index.md`.
- `docs/overview.md`.
- The smallest task route: architecture index, decisions index,
  `docs/agent-context/index.md`, `docs/plans/index.md`,
  `docs/_meta/ownership.json`, or `docs/repository-layout.md`.

Worker phases:

- Planning worker for each separable concern or workstream.
- Optional review worker for broad/risky plan material.
- Optional docs-maintenance worker if planning creates or edits tracked docs.

Rules passed to workers:

- Planning worker bundle.
- Review worker bundle for plan critique.
- Docs-maintenance worker bundle when writing architecture/decision context.

Closeout evidence:

- Questions asked and answered.
- Created/edited planning docs.
- Open assumptions that survived intake.
- Recommended implementation skill or orchestration path.

### `orchestrate`

Orchestrator overview: own the full lifecycle for a change request. It is the
clearest expression of the new model: classify, create phases, launch workers,
track observed state, manage run docs when needed, and communicate with the
human.

Orchestrator reads:

- Orchestrator core.
- Stateful orchestration rules when run docs are requested or resume risk is
  high.
- `docs/_meta/manifest.md` for `code_root`, `change-to-doc`, `drift-gates`,
  and `drift-verification`.
- `docs/index.md`.
- `docs/overview.md`.
- `v1/plan-lifecycle.md`.

Worker phases:

- Planning worker for ambiguous, broad, or durable work.
- Review worker for plan review and shipped-work review.
- Implementation worker for quick-fix or plan implementation phases.
- Verification worker for final consolidated gates.
- Docs-maintenance or plan-maintenance worker for migration/cleanup closeout.

Rules passed to workers:

- Planning worker bundle for plan/brief phases.
- Implementation worker bundle for implementation phases.
- Review worker bundle for plan and work review phases.
- Verification worker bundle for gate phases.
- Plan-maintenance worker bundle for shipped plan/run-doc closeout.

Closeout evidence:

- Lifecycle used.
- Worker phases run and skipped.
- Worker reports and observed facts.
- Commits made.
- Gates run.
- Assumptions and remaining blockers.

### `quick-fix`

Orchestrator overview: route one bounded fix through a single implementation
worker, then optionally a review or verification worker. It should not become
an inline implementation skill; it is the small-work orchestrator.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md` for `code_root`, `change-to-doc`, `drift-gates`,
  and `drift-verification`.
- `docs/index.md`.
- `docs/overview.md`.
- Task-specific docs only when classification needs them.

Worker phases:

- Implementation worker for the fix.
- Verification worker if the implementation worker cannot run the right gate
  or if a final manifest gate is better isolated.
- Review worker only when the fix touches user-facing, cross-cutting, or
  correctness-sensitive behavior.

Rules passed to workers:

- Implementation worker bundle.
- Verification worker bundle when separated.
- Review worker bundle for optional review.

Closeout evidence:

- Problem fixed.
- Files changed.
- Checks run.
- Docs updated or not needed.
- Commit hash.
- Follow-up, if the fix could not fully close.

### `ship-plans`

Orchestrator overview: implement named plans by launching one or more
implementation workers, using the plans as the coordination source. It decides
parallelism by workstream/plan boundaries and consolidates final verification
and plan closeout.

Orchestrator reads:

- Orchestrator core.
- Stateful orchestration rules when multiple streams or run docs are in play.
- `docs/_meta/manifest.md` for `code_root`, `change-to-doc`, `drift-gates`,
  and `drift-verification`.
- `docs/index.md`.
- `docs/overview.md`.
- `docs/plans/index.md`.
- `v1/plan-lifecycle.md`.
- Each named plan in full.

Worker phases:

- Planning worker only when a named plan is not implementation-ready.
- Implementation workers per plan or workstream.
- Review worker for broad or risky shipped work.
- Verification worker for final consolidated gates.
- Plan-maintenance worker to migrate durable plan context and set status.

Rules passed to workers:

- Planning worker bundle for plan repair.
- Implementation worker bundle plus `v1/plan-lifecycle.md`.
- Review worker bundle plus named plan paths.
- Verification worker bundle.
- Plan-maintenance worker bundle.

Closeout evidence:

- Plans implemented or remaining blocked.
- Plan status updates.
- Docs migration targets.
- Commits made.
- Gates run.

### `ship-current-work`

Orchestrator overview: finish the current dirty tree by dispatching inspection,
docs migration, verification, and commit work. It coordinates finalization
rather than doing every diff inspection inline.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md` for `code_root`, `change-to-doc`, `drift-gates`,
  `drift-verification`, and `decisions-domains`.
- `docs/_meta/ownership.json`.
- Current `git status --short`, diff stats, and changed filenames.

Worker phases:

- Review worker to inspect current diff and identify missing docs/tests.
- Docs-maintenance worker to update owning architecture/decision docs.
- Plan-maintenance worker if plans were touched or completed.
- Verification worker to run targeted and manifest gates.
- Implementation worker only if obvious missing work must be fixed.

Rules passed to workers:

- Review worker bundle plus manifest/ownership.
- Docs-maintenance worker bundle.
- Plan-maintenance worker bundle when relevant.
- Verification worker bundle.
- Implementation worker bundle for fixups.

Closeout evidence:

- Diff inspected.
- Docs/plan migration done or not needed.
- Gates run.
- Commit hash.
- Any residual risk.

### `review-shipped-work`

Orchestrator overview: coordinate review of completed or in-progress plan work.
The review worker leads with findings; fix workers are launched only for
obvious, authorized misses.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md` for `code_root`, `change-to-doc`, `drift-gates`,
  and `drift-verification`.
- `docs/index.md`.
- `docs/overview.md`.
- `docs/plans/index.md`.
- `v1/plan-lifecycle.md`.
- Each named plan in full.

Worker phases:

- Review worker for plan-vs-implementation state.
- Implementation worker for obvious fixes, if authorized by the skill.
- Docs-maintenance worker for missing durable docs.
- Plan-maintenance worker for shipped status/migration corrections.
- Verification worker for gates after fixes.

Rules passed to workers:

- Review worker bundle plus named plans.
- Implementation worker bundle for fixups.
- Docs-maintenance worker bundle.
- Plan-maintenance worker bundle.
- Verification worker bundle.

Closeout evidence:

- Findings by severity.
- Fix commits, if any.
- Plan status/docs migration state.
- Checks run.
- Whether another implementation prompt is needed.

### `review-plans`

Orchestrator overview: coordinate high-level plan review before implementation.
The review worker checks product shape, scope, sequencing, ownership,
dependencies, and orchestration risks.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md` for `repo_name`, `code_root`, and plan/orchestration
  slots.
- `docs/index.md`.
- `docs/overview.md`.
- `docs/plans/index.md`.
- `v1/plan-lifecycle.md`.
- `v1/plan-template.md`.
- Each named plan.

Worker phases:

- Review worker for each named plan or coherent plan cluster.
- Planning worker if the review output should be applied into revised plan
  text and the user asked for edits.

Rules passed to workers:

- Review worker bundle with plan-review lens.
- Planning worker bundle only for applied plan edits.

Closeout evidence:

- Findings first, ordered by severity.
- Open questions.
- Whether plans are implementation-ready.
- Suggested plan edits or applied edits, if authorized.

### `review-plans-health`

Orchestrator overview: coordinate a hygiene review over `docs/plans/`.
Normally one plan-maintenance or review worker can inspect plan status,
staleness, duplication, blocked work, and cleanup readiness.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md`.
- `docs/plans/index.md`.
- `v1/plan-lifecycle.md`.
- `v1/plan-template.md`.
- `docs/_meta/ownership.json` when judging migration targets.

Worker phases:

- Plan-maintenance worker to inspect plan/run-folder health.
- Review worker only for broader planning-shape critique.

Rules passed to workers:

- Plan-maintenance worker bundle.
- Review worker bundle when requested lens is broader than hygiene.

Closeout evidence:

- Overall plan health.
- Actionable findings.
- Ready-for-cleanup list.
- Needs-human list.
- Recommended next cleanup action.

### `review-docs-shape`

Orchestrator overview: coordinate an editorial and structural review of docs.
It is report-only unless a later skill applies changes.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md`.
- `docs/_meta/ownership.json`.
- `docs/overview.md`.
- Relevant index docs.
- Target docs/subtrees.
- Active plans when direction matters.

Worker phases:

- Docs-maintenance worker for architecture/decision shape and ownership
  review.
- Review worker for broad editorial/product fit.

Rules passed to workers:

- Docs-maintenance worker bundle.
- Review worker bundle with docs-shape lens.

Closeout evidence:

- Findings by severity.
- Structural recommendations.
- Suggested next skill: `fix-docs-drift`, `check-docs`, new plan, or leave
  clean.

### `review-skills`

Orchestrator overview: coordinate review of the skill suite, registry, and
rule docs for drift, duplicated policy, adapter assumptions, and lifecycle
gaps.

Orchestrator reads:

- Orchestrator core.
- `v1/skills/registry.md`.
- `v1/agent-docs-guide.md`.
- `v1/rules/skill-contracts.md`.
- `v1/rules/repo-rules.md`.
- `v1/rules/orchestrator/` and `v1/rules/subagent/` after they exist.
- Representative skill bodies selected by risk.

Worker phases:

- Review worker for registry/skill consistency.
- Docs-maintenance worker for rule-doc shape and duplicated policy.
- Verification worker for static checks when applying fixes is authorized.

Rules passed to workers:

- Review worker bundle.
- Docs-maintenance worker bundle.
- Verification worker bundle for applied fixes.

Closeout evidence:

- Registry drift.
- Duplicate policy.
- Missing verification or commit semantics.
- Adapter/discovery risks.
- Proposed or applied fixes.

### `check-docs`

Orchestrator overview: coordinate read-only mechanical drift checks for named
docs. It should dispatch one or more docs-maintenance workers by doc or
subtree and aggregate concise reports.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md` for `code_root`, `change-to-doc`, `drift-gates`,
  and `drift-verification`.
- `docs/_meta/ownership.json` when needed.
- Named doc paths.

Worker phases:

- Docs-maintenance worker for each doc or doc cluster.
- Verification worker only when a named drift gate is cheap and directly
  relevant.

Rules passed to workers:

- Docs-maintenance worker bundle.
- Verification worker bundle when applicable.

Closeout evidence:

- One short report per checked doc.
- Drift findings.
- House-rule findings.
- Recommended next action.

### `fix-docs-drift`

Orchestrator overview: coordinate the heavyweight docs drift repair flow. It
already uses subagents today; after migration it should become a cleaner
orchestrator over docs-maintenance, review, and verification workers.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md` for `repo_name`, `code_root`, `change-to-doc`,
  `drift-gates`, and `drift-verification`.
- `docs/_meta/ownership.json`.
- `docs/architecture/` and `docs/decisions/` inventory.

Worker phases:

- Docs-maintenance workers by architecture/decision subtree or ownership area.
- Review worker for hard ownership/rationale calls.
- Verification worker for drift gates.
- Implementation worker only for script/verifier fixes discovered during the
  sweep.

Rules passed to workers:

- Docs-maintenance worker bundle with drift-verification slot.
- Review worker bundle for ambiguous findings.
- Verification worker bundle.
- Implementation worker bundle for code/script fixes.

Closeout evidence:

- Docs fixed.
- Deferred human decisions.
- Gates run.
- Commit hash.

### `clear-plans`

Orchestrator overview: coordinate plan cleanup over disk/git state. The main
worker is a plan-maintenance worker that buckets plans/run folders, migrates
durable context, flags freshly migrated plans, and deletes only already
verified cleanup candidates.

Orchestrator reads:

- Orchestrator core.
- `docs/plans/index.md`.
- `v1/plan-lifecycle.md`.
- `docs/_meta/manifest.md`.
- `docs/_meta/ownership.json` as needed for migration targets.

Worker phases:

- Plan-maintenance worker for sweep and migration.
- Docs-maintenance worker for architecture/decision updates.
- Verification worker for final drift gates if files changed.

Rules passed to workers:

- Plan-maintenance worker bundle.
- Docs-maintenance worker bundle.
- Verification worker bundle.

Closeout evidence:

- Deleted.
- Migrated -> flagged.
- Left in flight / long-lived.
- Needs human.
- Commit hash when changes were made.

### `doctor`

Orchestrator overview: coordinate scaffold and registry health validation. It
is report-only by default, but can spawn fix workers when the user asks to
repair failures.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md`.
- `docs/_meta/ownership.json`.
- `v1/skills/registry.md`.
- `v1/rules/skill-contracts.md`.
- Static gate commands from manifest `drift-gates`.

Worker phases:

- Verification worker for scaffold, manifest, registry, and stale-reference
  checks.
- Docs-maintenance worker for doc scaffold fixes when authorized.
- Implementation worker for verifier/script fixes when authorized.

Rules passed to workers:

- Verification worker bundle.
- Docs-maintenance worker bundle for docs repairs.
- Implementation worker bundle for script repairs.

Closeout evidence:

- Critical failures.
- Repairable failures.
- Warnings.
- Gates run.
- Next step.

### `rebuild-agent-docs`

Orchestrator overview: coordinate adoption or repair of a repo's docs scaffold.
This is a mutating maintenance workflow with template seeding, manifest/
ownership repair, and final shipping.

Orchestrator reads:

- Orchestrator core.
- `v1/agent-docs-guide.md`.
- `v1/template/docs/` inventory.
- Current docs path and existing manifest/ownership files if present.

Worker phases:

- Docs-maintenance worker for scaffold inventory and migration.
- Implementation worker for script/template repairs if needed.
- Verification worker for `verify-agent-docs.sh`.
- Plan-maintenance worker if the rebuild creates or retires plan material.

Rules passed to workers:

- Docs-maintenance worker bundle.
- Implementation worker bundle when scripts/templates change.
- Verification worker bundle.
- Plan-maintenance worker bundle when relevant.

Closeout evidence:

- Scaffold files created/updated.
- Manifest and ownership state.
- Gates run.
- Commit hash.

### `wrap-up-current-chat`

Orchestrator overview: coordinate capture of durable knowledge from the
current chat into architecture/decision docs. It should use a docs-maintenance
worker to decide what is durable and where it belongs.

Orchestrator reads:

- Orchestrator core.
- `docs/_meta/manifest.md`.
- `docs/_meta/ownership.json`.
- Relevant architecture/decision docs named by the chat or ownership data.
- `docs/plans/index.md` and `v1/plan-lifecycle.md` if a plan was wrapped.

Worker phases:

- Docs-maintenance worker for durable context migration.
- Plan-maintenance worker when plan status should change.
- Verification worker if repo files changed.

Rules passed to workers:

- Docs-maintenance worker bundle.
- Plan-maintenance worker bundle when relevant.
- Verification worker bundle.

Closeout evidence:

- What durable facts/rationale were migrated.
- Docs changed.
- Plan status changes, if any.
- Checks run.
- Commit hash if changes were committed.

### `list-skills`

Orchestrator overview: coordinate skill inventory reporting. This can be a
single inventory/verification worker because the task is read-only and
mechanical.

Orchestrator reads:

- `v1/skills/registry.md`.
- `v1/skills/*/SKILL.md` frontmatter.
- Adapter skill directories only if the user asks about installed copies.

Worker phases:

- Verification worker for inventory consistency.

Rules passed to workers:

- Verification worker bundle, with a narrow "inventory only" task.

Closeout evidence:

- Skill list grouped by source/category.
- Registry mismatches or missing skill dirs if discovered.

### `feedback-agent-docs`

Orchestrator overview: coordinate capture of kit-level feedback into the
upstream inbox. This is a capture workflow, not a repo-edit workflow.

Orchestrator reads:

- Skill-local routing rules for feedback vs repo changes.
- Existing feedback content from the user.
- Feedback inbox path.

Worker phases:

- Capture worker to validate the feedback payload and append JSONL.

Rules passed to workers:

- Capture worker bundle.

Closeout evidence:

- Feedback category/surface.
- Inbox record appended.
- No repo commit made.

### `review-docs-shape`, `check-docs`, and `fix-docs-drift` Relationship

These remain separate user-facing orchestrators because their user intent
differs:

- `review-docs-shape` asks whether the docs are shaped well.
- `check-docs` asks whether named docs are mechanically accurate.
- `fix-docs-drift` repairs drift across the tree.

They should share subagent docs-maintenance and verification rules, not merge
into one skill.

### `review-plans`, `review-plans-health`, and `clear-plans` Relationship

These remain separate user-facing orchestrators because they answer different
plan lifecycle questions:

- `review-plans` asks whether specific plans are good enough to implement.
- `review-plans-health` asks whether the plan tree is stale, blocked,
  duplicated, or ready for cleanup.
- `clear-plans` mutates plan state by migrating, flagging, and deleting.

They should share `v1/rules/subagent/plan-maintenance.md` where lifecycle
policy overlaps.

## Registry Impact

`v1/skills/registry.md` likely needs one new metadata column once the model is
implemented:

| Candidate column | Meaning |
|---|---|
| `Worker roles` | The subagent roles a skill normally dispatches, e.g. `planning`, `implementation`, `review`, `verification`. |

Avoid an `Execution` column that says `direct` vs `delegated`; that recreates
the old model. The registry should make orchestration explicit by naming the
worker roles each skill coordinates.

## Verification Expectations

Static checks worth adding to `v1/verify-agent-docs.sh`:

- Every rule file referenced in skill bodies exists.
- Every current skill in `v1/skills/registry.md` appears in this breakdown
  until the plan ships.
- Registry skill names match `v1/skills/<name>/SKILL.md` frontmatter.
- No user-facing skill references retired `delegate-on` / `delegate-off`
  vocabulary after migration.
- Copied skill adapters are fresh after skill edits.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts into:

- `architecture/workflow-kit.md` — per-skill orchestration shape and worker
  role routing.
- `decisions/agent-docs.md` — rationale for keeping user-facing skill names
  while changing their internal execution model.
- `_meta/ownership.json` — only if a new concept needs an explicit owner.

## See also

- [`workflow-rule-abstraction.md`](workflow-rule-abstraction.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/skills/registry.md`](../../v1/skills/registry.md)
- [`../../v1/rules/skill-contracts.md`](../../v1/rules/skill-contracts.md)
