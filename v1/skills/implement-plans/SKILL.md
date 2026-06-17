---
name: implement-plans
description: Implement named plan files end to end, including verification, docs migration, plan shipping, and commit.
---

You are implementing one or more plan files in the current repository. Your
job is to finish the named plans unless the user says otherwise: code changes,
targeted verification, durable docs, plan status, and a local commit when
green. Do not push unless explicitly told.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`) → `index.md` → `overview.md` → stop. The plan paths are
the task; if missing, run the two-question intake (ask which plans and the
expected outcome) and wait.

Once the plans are named:

- Read each named plan in full. Ignore whether it is `draft` or `active`;
  explicit user selection is enough.
- Read `~/agent-docs/v1/plan-lifecycle.md` and
  `~/agent-docs/v1/plan-template.md` for status and migration rules, and
  `docs/plans/index.md` if you need sibling-plan context.
- Read `~/agent-docs/v1/rules/coding-style.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md`.
- If the work is multi-stream or delegated, read
  `~/agent-docs/v1/rules/orchestrating.md` and
  `docs/agent-context/orchestrating.md` if it exists.

Then load only the architecture, decisions, agent-context, and source files
needed to implement and verify the plans.

## Execution Policy

Dials and model policy follow `skill-contracts.md`. Implementation specifics:

- Work through all named plans unless the user narrows scope.
- Default to a middle ground: use sub-agents when they materially reduce
  context, wall time, or cost without creating coordination risk; otherwise
  implement directly. At `cost-low`, push bounded investigation,
  implementation, and routine verification onto cheaper agents.
- At `review-none`, do not stop for human review unless truly blocked. Record
  anything the human should review later in a closeout note in the final
  response or, if substantial, a small closeout doc the user can inspect after
  the run.
- Stop and ask when a plan is stale, contradictory, infeasible, or missing a
  decision that changes what should be built. Batch those questions. At
  `review-none`, choose the best defensible path, document the assumption, and
  keep moving unless the risk is severe.
- Defer expensive tests as much as possible. Run the cheapest useful checks
  during implementation, and reserve manifest drift gates or broader tests for
  the final shipping pass unless the plan's core risk requires them earlier.
- For UI-facing work, perform visual verification when the app and tooling make
  it practical. Screenshots or browser checks are part of shipping when visual
  quality is central to the plan.

## Shipping Requirements

At the end of each completed plan or related batch:

1. Inspect the diff and verify the implementation matches the plan outcome,
   not just the first obvious task.
2. Run targeted tests plus the manifest gates needed to justify the commit.
3. Migrate durable plan context into the owning architecture and decisions
   docs, following the authoring rules. Use `change-to-doc`,
   `owning_docs`, and `docs/_meta/ownership.json` if needed.
4. Touch plan files only at the end: update `last_updated`, set
   `status: shipped` only when the work and doc migration are complete, and
   set `okay_to_delete: true` only when useful context has been migrated.
   Leave blocked or partial plans active/draft and explain why.
5. Stage by filename and commit when green. Prefer one commit per plan when
   implemented sequentially; combine commits when plans were implemented as a
   single parallel batch or share one coherent change.

If a plan cannot fully ship, commit only a coherent green checkpoint when that
helps the user, keep the plan unshipped, and explain the blocker and next
step. Never mark a plan shipped on optimism.

Plans to implement:

$ARGUMENTS
