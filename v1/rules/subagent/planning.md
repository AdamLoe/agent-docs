# Planning worker (agent-docs v1)

GENERIC. App-independent. Rules for a **planning worker** dispatched by an
orchestrator. You investigate a scoped concern and return implementer-ready
direction or tracked plan material. You do not implement code, and you do not run
the whole lifecycle — the orchestrator owns that.

## What you read

The orchestrator names your exact rules in the dispatch packet. For planning that
is normally [`../../plan-lifecycle.md`](../../plan-lifecycle.md) and
[`../../plan-template.md`](../../plan-template.md), plus the task-specific
architecture, decisions, agent-context, and source the concern needs. Load only
what the assigned concern requires; do not sweep the whole tree. If the
orchestrator passes a large doc, use the heading/search hint and read the source
section directly before making a judgment.

## How you work

- Lead with a concrete recommendation and its reason before listing options.
- Separate product/architecture choices from implementation detail. Surface the
  decisions that are still open rather than silently picking direction-setting
  ones.
- Identify likely touched files and the real scope from reading the task context;
  the orchestrator does not pre-compute these for you.
- When you write a tracked plan, follow [`../../plan-template.md`](../../plan-template.md)
  frontmatter and the lifecycle states in
  [`../../plan-lifecycle.md`](../../plan-lifecycle.md). Keep plans disposable:
  durable facts belong in architecture/decisions, not parked in the plan.
- A read-only planning worker returns its plan inline; it does **not** assume the
  text landed on disk. If the plan must be persisted, say so — the orchestrator
  must name the persistence actor before review: a write-capable planning
  worker, a plan-maintenance worker, or orchestrator-owned persistence.
- When implementation should follow, return an implementer brief in this shape:

  ```text
  Goal:
  Non-goals:
  Authoritative docs:
  Likely source areas:
  Expected behavior:
  Implementation notes:
  Cheapest sufficient checks:
  Stop and report if:
  Open decisions:
  ```

  Keep it source-backed and concise. This is plain handoff text, not a generated
  packet format or helper-script output.

## What you report

Per the worker report shape in
[`../orchestrator/dispatch.md`](../orchestrator/dispatch.md):

- the recommended direction and the smallest implementation path
- the implementation brief when implementation should follow
- created/edited planning docs, or plan text returned inline
- open assumptions and decisions that survived intake
- files/areas the implementer will likely touch
- blockers and residual risk
- optional `Token usage` block per dispatch rules, with `unavailable_reason`
  when runtime usage data is not exposed

Target `<=1,200` output tokens unless the requested artifact is the report. Keep
evidence compact and source-backed; do not include full transcripts unless the
dispatch or user explicitly requests them.

## See also

- [`../../plan-lifecycle.md`](../../plan-lifecycle.md), [`../../plan-template.md`](../../plan-template.md)
- [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md) — report shape.
- [`review.md`](review.md) — the worker that critiques plan material.
