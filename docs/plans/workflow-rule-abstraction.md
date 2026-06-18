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

# Subagent-first workflow architecture

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
- Remove the previous "delegate-on/delegate-off" model from this plan; the
  new default is subagent-first orchestration.
- Keep `cost-*` and `review-*` as intensity dials inside the orchestrated
  workflow, not as delegation switches.
- Update workflow architecture, decisions, skill contracts, orchestration
  rules, skill bodies, and registry metadata to reflect the new model.

Out of scope:

- Keeping a direct-worker mode as a first-class workflow goal.
- Creating separate command names for orchestrated vs direct execution.
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
- reporting concise evidence back to the orchestrator

This split should simplify docs because orchestrator docs no longer need to
teach an agent how to implement code, and worker docs no longer need to teach
an agent how to run the whole lifecycle.

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
    capture.md                # out-of-repo capture worker rules, if needed
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
| `fresh-chat` | Bootstrap router context, then route the user's task to the right orchestrator skill or wait for the task. |
| `plan` | Orchestrate planning workers and discussion loops; write or update planning docs only through a planning-worker-shaped phase unless the edit is purely coordination state. |
| `orchestrate` | General lifecycle orchestrator for broad work; always subagent-first. |
| `quick-fix` | Orchestrate a single bounded implementation worker plus optional review/verification worker. |
| `ship-plans` | Orchestrate implementation workers over named plans, with planning/review workers where the plan is broad or risky. |
| `ship-current-work` | Orchestrate finalization of the current diff: inspection, docs migration, gates, and commit through worker phases. |
| Review skills | Orchestrate review workers over named plans/docs/work; optionally dispatch fix workers when authorized. |
| Maintenance skills | Orchestrate maintenance workers over disk/git state; often one worker is enough. |

This intentionally removes "should this agent delegate?" as a central
question. The question becomes "which worker role should this orchestrator
spawn, and how much fan-out is appropriate?"

The companion breakdown
[`subagent-first-skill-breakdown.md`](subagent-first-skill-breakdown.md) owns
the per-skill migration detail: each skill's orchestration overview,
orchestrator reads, likely worker phases, rule files passed to workers, and
closeout evidence.

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
detailed local scope after reading the task context.

Worker reports should always include:

- concise outcome
- files/docs touched or inspected
- checks run and result
- durable facts or decisions that need migration
- blockers, assumptions, and residual risk
- commit hash when the worker committed

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
- Decide whether any direct path remains as an emergency/local fallback, and
  document it as an exception rather than a normal mode.

### 2. Shared Contract Rewrite

Outcome: `skill-contracts.md` reflects the new workflow contract.

Tasks:

- Remove or avoid `delegate-on` / `delegate-off` vocabulary.
- State that user-facing mutating/planning/review skills orchestrate worker
  phases.
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
- Update docs and verifier checks for the new paths.

### 4. Worker Rule Files

Outcome: workers have obvious role-specific rules to read.

Tasks:

- Create or reshape `v1/rules/subagent/planning.md`.
- Create `v1/rules/subagent/implementation.md`.
- Create `v1/rules/subagent/review.md`.
- Create `v1/rules/subagent/docs-maintenance.md`.
- Create `v1/rules/subagent/plan-maintenance.md`.
- Create `v1/rules/subagent/verification.md`.
- Create `v1/rules/subagent/capture.md` only if capture workflows need a
  reusable worker contract.
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
- Update `v1/skills/registry.md` if a new metadata column is useful, e.g.
  `Worker roles` or `Execution`.

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
- `bash v1/verify-agent-docs.sh` passes.
- If skills change, `bash v1/copy-skills.sh ~/agent-docs` and
  `bash v1/copy-skills.sh --check ~/agent-docs` pass or any adapter limitation
  is reported.

## Discipline Rules

- Do not preserve inline/direct execution as an equal peer to orchestration.
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
  first-class split.
- `_meta/ownership.json` — only if a new concept needs an explicit owner.

## See also

- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/rules/skill-contracts.md`](../../v1/rules/skill-contracts.md)
- [`../../v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
