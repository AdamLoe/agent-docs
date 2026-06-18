---
status:        shipped
owner:         unassigned
last_updated:  2026-06-18
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Subagent-first workflow architecture

> **Shipped.** The orchestrator/worker split landed: `v1/rules/orchestrator/`
> (lifecycle, dispatch, run-docs) and `v1/rules/subagent/` (planning,
> implementation, review, docs-maintenance, plan-maintenance, verification)
> exist; `v1/rules/orchestrating.md` was removed; `v1/rules/skill-contracts.md`,
> the registry, and every skill body were reframed as orchestrator entry points.
> Durable model + dispatch contract migrated to
> [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md); rationale
> to [`../decisions/agent-docs.md`](../decisions/agent-docs.md). Verifier extended
> for the new paths and retired tokens. Disposable.

## Mission

Rework the workflow kit around a deliberate separation between two classes of
agent workers:

- **Orchestrators** receive user requests, route them through the right
  lifecycle, choose phases, pass exact rule-file routes to workers, track
  evidence, and communicate with the human.
- **Subagents / workers** receive scoped role assignments and the exact rules
  for that role, then do the planning, implementation, review, maintenance, or
  verification work.

The goal is to make the workflow simpler by making the top-level agent a
workflow navigator instead of sometimes a navigator and sometimes the worker.
The runtime path should be obvious: user-facing commands orchestrate; worker
rules tell spawned agents how to do the actual task.

Done means the kit documents this class split, user-facing skills consistently
act as orchestrators, worker rule files exist for the major work roles, and
subagent dispatches pass exact rule-file links rather than copied rule prose or
open-ended discovery instructions. The detailed per-skill migration target is
tracked in
[`subagent-first-skill-breakdown.md`](subagent-first-skill-breakdown.md).

## Scope

In scope:

- Define the orchestrator/worker split as the central workflow model.
- Treat user-facing skills as orchestrator entry points, even when the
  resulting workflow launches only one worker.
- Define worker-facing rule files for planning, implementation, review,
  maintenance, and verification roles where needed.
- Split workflow rules into visibly separate `v1/rules/orchestrator/` and
  `v1/rules/subagent/` folders.
- Define how orchestrators select phases, spawn workers, pass rule routes,
  track evidence, and report to the human.
- Keep the docs subagent-first and optimized for the high-power workflow:
  concise dispatch, clean worker context, and minimal repeated discussion of
  whether subagents are being used.
- Remove the previous "delegate-on/delegate-off" model from this plan; the
  new default is subagent-first orchestration.
- Keep `cost-*` and `review-*` as intensity dials inside the orchestrated
  workflow, not as delegation switches.
- Remove no-intake and direct-execution categories from the workflow model.
  Small utilities should still be orchestrator entry points with one small
  worker phase, not a separate execution class.
- Update workflow architecture, decisions, skill contracts, orchestration
  rules, skill bodies, and registry metadata to reflect the new model.

Out of scope:

- Keeping a direct-worker mode as a first-class workflow goal.
- Creating separate command names for orchestrated vs direct execution.
- Spending durable rule context on repeated direct-vs-subagent comparisons.
  The docs should teach the subagent-first workflow without preserving direct
  execution as a supported path.
- Making subagents discover the workflow rule graph themselves.
- Keeping orchestration and worker instructions mixed in the same rule file
  when they can be separated cleanly.
- Forcing every task to become a large multi-agent run. Orchestration may
  launch a single worker for small tasks.
- Removing all local content from skills. Orchestrator skills still need
  routing, phase selection, status handling, and report expectations.

## Core Model

The workflow kit should stop trying to make one agent instruction set serve
two unrelated jobs.

Important decision: **subagent-first is the documented workflow, not an endless
runtime debate.** The docs should optimize for reducing useless context and
keeping worker prompts clean. They should not repeatedly explain "subagents or
no subagents"; they should teach orchestrators how to dispatch workers.

An **orchestrator** is responsible for workflow control:

- intake and request classification
- choosing the lifecycle path
- selecting the worker role for each phase
- passing exact rule-file routes to each worker
- deciding when work can run in parallel vs serial
- maintaining the live coordination surface
- recording observed evidence from worker reports
- asking the human only for decisions that change the work
- closing out with commits, gates, assumptions, and remaining blockers

A **worker/subagent** is responsible for role execution:

- reading the exact rules named by the orchestrator
- loading task-specific code/docs/context
- doing the assigned planning, implementation, review, maintenance, or
  verification work
- deciding detailed touched files from local investigation
- running the expected checks for the assignment
- committing its own changes before reporting when the assignment edits files
- reporting concise evidence back to the orchestrator

This split should simplify docs because orchestrator docs no longer need to
teach an agent how to implement code, and worker docs no longer need to teach
an agent how to run the whole lifecycle.

Reading is not the same as worker dispatch. Orchestrators may read and
summarize coordination state directly — indexes, the manifest, the registry,
plan metadata, git status — because that is routing work, not task execution.

Stated as a test, dispatch a worker when the step does any of:

- reads or reasons across more than a couple of files,
- makes a judgment call the human would want defended,
- mutates the repo, or
- runs a verification gate.

If none of these hold, the orchestrator does the step inline. This boundary is
uniform across every skill; it is not a per-skill "direct" class. It is why
`start-session` summarizes plan and git state inline while still dispatching
workers for cleanup review or verification.

A pure utility can therefore complete with no worker at all. `list-skills`
reading the registry, or `feedback-agent-docs` appending one record, are inline
routing/IO under the test above, not a hidden "direct" class. Do not invent a
one-line worker only to satisfy the orchestrator/worker shape: the shape exists
for fan-out and isolation, and when neither applies the inline path is the
orchestrator behaving correctly, not an exception to it.

Runtimes are expected to support worker dispatch. Claude Code, Codex, and
similar adapters own the mechanics of spawning workers. If an adapter or
execution environment cannot dispatch a required worker, the skill should
report a clear error and stop instead of falling back to inline execution.

The workflow is commit-heavy by design. Workers that edit repo files should
commit their own completed slice before reporting. Later workers may amend the
state with follow-up commits, revert a bad worker commit, or make corrective
commits. The orchestrator records commit hashes and verifies the final observed
state; the user can squash local history later if desired.

Editing is serial by default because concurrent commits race the git index. The
orchestrator runs at most one editing worker at a time on the shared working
tree, and that worker commits its slice before the next editing worker starts.
Read-only workers (planning investigation, review, verification) can still run
in parallel at any time. When parallel editing is worth the cost, give each
editing worker its own git worktree and integrate the results afterward; for
maximum fan-out, the orchestrator can instead have workers return patches and
apply and commit them itself. File-ownership fences alone do not make
concurrent commits safe.

## Placement Tests

Put each rule at the lowest durable layer that owns it:

| Content type | Owner |
|---|---|
| Every skill must do it before knowing the task | `v1/rules/skill-contracts.md` |
| Workflow control, phase choice, dispatch, evidence, and human stops | `v1/rules/orchestrator/` |
| How to perform one assigned worker role | `v1/rules/subagent/` |
| One command's routing surface, local context needs, and closeout shape | `v1/skills/<name>/SKILL.md` |
| Current durable system shape | `docs/architecture/workflow-kit.md` |
| Why the model was chosen | `docs/decisions/agent-docs.md` |
| Per-skill migration matrix while this work is active | `docs/plans/subagent-first-skill-breakdown.md` |

## Rule Organization

Keep `v1/rules/skill-contracts.md` as the universal contract for all
agent-docs skills, but reshape it around the subagent-first model. It should
own only the behavior every user-facing skill needs at startup: standard
intake, human stops, verification fallback, review/cost dials, model policy,
modes, registry expectations, and the fact that user-facing skills are
orchestrator entry points.

Split workflow rules by agent class:

```text
v1/rules/
  skill-contracts.md          # universal skill startup contract
  repo-rules.md               # universal git/destructive-command discipline
  authoring-rules.md          # universal doc maintenance rules
  coding-style.md             # universal code quality principles
  orchestrator/
    lifecycle.md              # request classification and phase routing
    dispatch.md               # worker packet shape and evidence accounting
    run-docs.md               # stateful run folder policy
  subagent/
    planning.md               # planning-worker rules
    implementation.md         # implementation-worker rules
    review.md                 # review-worker rules
    docs-maintenance.md       # doc drift/shape/repair worker rules
    plan-maintenance.md       # plan hygiene, migration, cleanup worker rules
    verification.md           # gate/check worker rules
    capture.md                # only if multiple capture flows need it
```

The exact filenames can change during implementation, but the directory split
is a requirement: orchestrator docs teach workflow control; subagent docs
teach assigned work. `v1/plan-lifecycle.md` continues to own plan metadata,
state transitions, and the disposable-plan model unless the implementation
chooses to move it under `v1/rules/subagent/plan-maintenance.md` with a
compatibility path.

## User-Facing Skills

User-facing skills should be orchestrator commands. Their bodies should focus
on:

- what request type they own
- what lifecycle phases are valid
- which worker role to spawn for each phase
- which rule files to pass to each worker
- how to track worker reports
- when to ask the human
- what closeout evidence to return

They should not contain detailed implementation, review, or cleanup procedure
except as a concise dispatch summary.

Proposed skill interpretation:

| Skill family | Orchestrator behavior |
|---|---|
| `start-session` | Inspect local git/plan/run-doc state, summarize in-flight work and cleanup candidates, then route to the owning workflow skill. |
| `fresh-chat` | Bootstrap router context, then route the user's task to the right orchestrator skill or launch a small context worker. |
| `plan` | Orchestrate planning workers and discussion loops; write or update planning docs only through a planning-worker-shaped phase unless the edit is purely coordination state. |
| `orchestrate` | General lifecycle orchestrator for broad work; always subagent-first. |
| `quick-fix` | Orchestrate a single bounded implementation worker plus optional review/verification worker. |
| `ship-plans` | Orchestrate implementation workers over named plans, with planning/review workers where the plan is broad or risky. |
| `ship-current-work` | Orchestrate finalization of the current diff: inspection, docs migration, gates, and commit through worker phases. |
| Review skills | Orchestrate review workers over named plans/docs/work; optionally dispatch fix workers when authorized. |
| Maintenance skills | Orchestrate maintenance workers over disk/git state; often one worker is enough. |
| Small utilities | `list-skills` and `feedback-agent-docs` remain small, but still use the orchestrator/worker shape with one narrow worker phase. |

This intentionally removes "should this agent delegate?" as a central
question. The question becomes "which worker role should this orchestrator
spawn, and how much fan-out is appropriate?"

The companion breakdown
[`subagent-first-skill-breakdown.md`](subagent-first-skill-breakdown.md) owns
the per-skill migration detail: each skill's orchestration overview,
orchestrator reads, likely worker phases, rule files passed to workers, and
closeout evidence. It is temporary migration scaffolding, not a permanent
canonical operating manual; after shipping, durable facts should live in the
rules, skill bodies, registry, architecture docs, and decisions docs.

## Dispatch Contract

Orchestrators should pass exact rule-file links to workers. They should not
copy full rules into prompts, and they should not tell workers to discover the
workflow system.

Each dispatch should include:

```text
Role:
Task:
Input docs/plans/context:
Read these exact rules:
- <rule file>
- <rule file>
Expected output:
Expected checks/evidence:
Report back with:
```

The orchestrator should usually avoid detailed file ownership fences unless
parallel workers are likely to collide. Planning and implementation workers
are better positioned to identify likely files, actual touched files, and
detailed local scope after reading the task context. Fences address read and
analysis overlap, not commit safety; concurrent editing uses the serial-commit
or worktree rule from the Core Model.

Worker reports should always include:

- concise outcome
- files/docs touched or inspected
- checks run and result
- durable facts or decisions that need migration
- blockers, assumptions, and residual risk
- commit hash for edited work, or a clear no-change report for read-only work

## Cost And Review Dials

`cost-*` and `review-*` remain useful, but they should not decide whether
subagents are used. They tune the orchestrated workflow:

- `cost-low` means fewer workers, cheaper models, less fan-out, and tighter
  phase selection.
- `cost-medium` means normal worker use with bounded fan-out.
- `cost-high` / `cost-max` means broader investigation, more parallel workers,
  stronger planning/review, and more second opinions where valuable.
- `review-none` skips human-review checkpoints only; it does not skip needed
  worker review, verification, or the original questioning needed to make the
  work clear.
- `review-high` / `review-max` adds stronger review workers and red-team
  passes when risk justifies them.

## Workstreams

### 1. Model Decision

Outcome: the repo records the orchestrator/worker split as the intended
workflow model.

Tasks:

- Update `docs/decisions/agent-docs.md` with the rationale for
  subagent-first orchestration and the rejection of a direct/delegated boolean
  as the primary model.
- Update `docs/architecture/workflow-kit.md` to describe user-facing skills as
  orchestrator entry points and role rule files as worker-facing instructions.
- State that missing worker-dispatch support is an error, not a reason to run
  the task inline.
- Record the commit-heavy policy: editing workers commit their own slices,
  follow-up workers can repair or revert through additional commits, editing is
  serial by default, and parallel editing uses worktree isolation or
  orchestrator-applied patches.

### 2. Shared Contract Rewrite

Outcome: `skill-contracts.md` reflects the new workflow contract.

Tasks:

- Remove or avoid `delegate-on` / `delegate-off` vocabulary.
- State that user-facing mutating/planning/review skills orchestrate worker
  phases.
- Remove the no-intake/direct-execution split from the shared skill taxonomy.
  Skills may infer obvious context from disk, but that is ordinary intake
  behavior, not a separate command class.
- Preserve the *behavior* the current `direct` / "context-free skills"
  exception encodes even as the label goes away: skills that operate on
  existing disk/git state still skip the two intake questions and run without
  blocking. Dropping the taxonomy term must not turn these skills into ones
  that now stop to ask. The shared contract should state non-blocking intake
  as the default for state-driven skills, expressed as ordinary intake rather
  than a named class.
- Keep intake, human stops, verification fallbacks, dials, model policy, and
  modes concise.
- Clarify that `cost-*` controls fan-out/model spend and `review-*` controls
  human and worker review intensity.

### 3. Rule Folder Split

Outcome: orchestrator and subagent rules live in separate folders with clear
responsibilities.

Tasks:

- Create `v1/rules/orchestrator/`.
- Create `v1/rules/subagent/`.
- Move or replace the current `v1/rules/orchestrating.md` with
  orchestrator-facing files, keeping a compatibility pointer if useful.
- Decide whether `v1/plan-lifecycle.md` stays at the kit root or gains a
  worker-facing companion under `v1/rules/subagent/`.
- Update docs and verifier checks for the new paths. `v1/verify-agent-docs.sh`
  currently greps `v1/rules/orchestrating.md` for the `cost-*`/`review-*` dial
  tokens, so moving that file means repointing those grep anchors at wherever
  the dial vocabulary lands.

### 4. Worker Rule Files

Outcome: workers have obvious role-specific rules to read.

Tasks:

- Create or reshape `v1/rules/subagent/planning.md`.
- Create `v1/rules/subagent/implementation.md`.
- Create `v1/rules/subagent/review.md`.
- Create `v1/rules/subagent/docs-maintenance.md`.
- Create `v1/rules/subagent/plan-maintenance.md`.
- Create `v1/rules/subagent/verification.md`.
- Defer `v1/rules/subagent/capture.md` unless implementation finds more than
  one capture workflow that needs the same reusable contract; otherwise route
  `feedback-agent-docs` through a narrow shared maintenance worker.
- Keep worker rules executable and role-focused, not a full copy of the
  orchestrator lifecycle.
- Ensure each worker rule states what evidence it must report back to the
  orchestrator.

### 5. Orchestrator Rules

Outcome: orchestration rules teach routing, dispatch, phase control, and human
communication rather than implementation details.

Tasks:

- Create `v1/rules/orchestrator/lifecycle.md`,
  `v1/rules/orchestrator/dispatch.md`, and
  `v1/rules/orchestrator/run-docs.md` or equivalent files.
- Rewrite the current orchestration policy around orchestrator
  responsibilities.
- Remove assumptions that orchestration applies only to large multi-stream
  work.
- Define single-worker orchestration as valid for small tasks.
- Define standard dispatch packet fields and expected worker report shape.
- Define the dispatch failure behavior: clear error and stop when a worker
  cannot be spawned.
- Define commit concurrency: editing is serial by default, and parallel editing
  uses worktree isolation or orchestrator-applied patches so commits do not
  race the git index.
- Keep run-doc behavior for long-running or resume-risk work.

### 6. Skill Suite Migration

Outcome: user-facing skills consistently behave as orchestrator entry points.

Tasks:

- Update `plan`, `quick-fix`, `ship-plans`, `ship-current-work`,
  `review-*`, `clear-plans`, `fix-docs-drift`, and other affected skills to
  dispatch worker roles instead of doing all work inline.
- Preserve skill-specific routing and classification logic.
- Ensure each skill names the exact worker rule files it passes for each
  phase.
- Use
  [`subagent-first-skill-breakdown.md`](subagent-first-skill-breakdown.md) as
  the required starting point for per-skill migration.
- Update `v1/skills/registry.md`: add a `Worker roles` column, drop the
  `Intake` column's `direct` taxonomy, and reconcile the `Commits` column with
  the commit-heavy worker policy. Do not add a direct-vs-delegated `Execution`
  column.

### 7. Verification And Adapter Freshness

Outcome: the new structure is mechanically checked where practical.

Tasks:

- Extend `v1/verify-agent-docs.sh` for cheap static checks such as missing
  referenced rule files, stale skill registry rows, or worker-rule references
  that point nowhere.
- Avoid brittle prose linting unless a repeated failure needs a guard.
- Run `bash v1/copy-skills.sh ~/agent-docs` and
  `bash v1/copy-skills.sh --check ~/agent-docs` after skill edits.

## Exit Gate

- `docs/architecture/workflow-kit.md` describes the orchestrator/worker
  architecture.
- `docs/decisions/agent-docs.md` records why the kit moved to subagent-first
  orchestration.
- `v1/rules/skill-contracts.md` no longer frames delegation as an optional
  mode.
- `v1/rules/orchestrator/` exists and owns orchestrator-facing policy.
- `v1/rules/subagent/` exists and owns worker-facing policy.
- Worker-facing rules exist for the major work roles selected during
  implementation.
- User-facing skills pass exact rule-file routes to workers.
- [subagent-first-skill-breakdown.md](subagent-first-skill-breakdown.md)
  covers every current skill in `v1/skills/registry.md`.
- Skills retain enough local routing context to be executable.
- Editing workers commit their own completed slices, and worker reports include
  commit hashes or an explicit no-change result.
- `bash v1/verify-agent-docs.sh` passes.
- If skills change, `bash v1/copy-skills.sh ~/agent-docs` and
  `bash v1/copy-skills.sh --check ~/agent-docs` pass or any adapter limitation
  is reported.

## Discipline Rules

- Do not preserve inline/direct execution as an equal peer to orchestration.
- Do not keep no-intake as a registry or skill class. A skill can use obvious
  disk state as task context, but it still follows the same orchestrator/worker
  contract.
- Do not add migration phases that defer the model change indefinitely. Plan
  the work tightly enough for implementation, then migrate the suite in one
  coordinated pass.
- Do not make orchestrators decide detailed touched files unless collision
  risk requires it.
- Do not make workers discover the rule graph; dispatchers provide exact rule
  files.
- Keep orchestrator docs about workflow control.
- Keep worker docs about doing assigned work.
- Put new class-specific rules under `v1/rules/orchestrator/` or
  `v1/rules/subagent/`; keep only truly universal policy at `v1/rules/`.
- Extract rules because they clarify the two-class model, not merely because a
  file is long.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts into:

- `architecture/workflow-kit.md` — orchestrator/worker model, rule file
  folder layout, skill responsibility, dispatch contracts, and
  verifier/adapter impact.
- `decisions/agent-docs.md` — rationale for subagent-first orchestration,
  exact rule-file routing, and the rejection of direct/delegated mode as a
  first-class split. State this rationale once here; the drafts repeat it
  across many sections, but the durable doc should not.
- `_meta/ownership.json` — only if a new concept needs an explicit owner.

## See also

- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/rules/skill-contracts.md`](../../v1/rules/skill-contracts.md)
- [`../../v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
