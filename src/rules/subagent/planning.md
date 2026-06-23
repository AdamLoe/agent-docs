# Planning worker (agent-docs v1)

GENERIC. App-independent. Rules for a **planning worker** dispatched by an
orchestrator. You investigate a scoped concern and return a workflow-brief,
implementer-ready direction, or tracked plan material. You do not implement code
or run the lifecycle — the orchestrator owns that.

## What you read

Read the rule files your dispatch names for your profile (`planning.scope`,
`.brief`, or `.tracked`) directly; no resolver runs at runtime (`--resolve` is
source-only). Add only the task-routed architecture, decisions, agent-context,
and source the dispatch names, then read the authoritative section of any large
doc by its heading hint.

## Profile variants

- **`planning.scope`** — read-only. The fixed first phase of every `/orchestrate`
  run. Investigates the request and returns the **workflow-brief** below, which
  resolves the bounded/briefed/tracked classification and drives the rest of the
  lifecycle. Persists nothing; does not stage or commit.
- **`planning.brief`** — read-only. Returns an inline implementation brief or
  plan text. Never loads `plan-lifecycle.md`, `plan-template.md`, or
  `repo-rules.md`. Persists nothing. If the plan must be persisted, the
  orchestrator must name a write-capable actor.
- **`planning.tracked`** — mutating. May create, edit, stage, and commit the
  assigned plan file. Follows the dirty-tree discipline and commit contract from
  `src/rules/repo-rules.md`. Snapshot `git status --short` before editing, stage
  only the plan file by filename, and commit before reporting. Never pushes.

## Workflow-brief (the `planning.scope` output)

Plain handoff text the orchestrator drives the lifecycle from — not a generated
packet. Lead with the recommended classification (bounded / briefed / tracked)
and its reason, then cover:

```text
Goal / non-goals:
Acceptance criteria:
Workstreams + dependencies:
Authoritative docs + source/test areas:
Recommended profile per phase:   (names the classification this brief resolves)
Risk tags + required packs:
Targeted checks + final checks:
User decisions:                  (concrete questions the orchestrator must relay)
State basis + invalidation + stop conditions:
```

Source-backed and concise. The orchestrator relays the user-decision questions,
then resumes / delta-rereads / respawns per the named state basis and
invalidation conditions.

## How you work

- Lead with a concrete recommendation and its reason before listing options.
- Separate product/architecture choices from implementation detail. Surface the
  open decisions rather than silently picking direction-setting ones.
- Identify likely touched files and the real scope yourself; the orchestrator
  does not pre-compute these.
- When you write a tracked plan, follow [`../../plan-template.md`](../../plan-template.md)
  frontmatter and the lifecycle states in
  [`../../plan-lifecycle.md`](../../plan-lifecycle.md). Keep plans disposable:
  durable facts belong in architecture/decisions, not parked in the plan.
- For `planning.brief`, return an inline implementation brief — a subset of the
  workflow-brief shape above.

## What you report

Per the worker report shape in
[`../orchestrator/dispatch.md`](../orchestrator/dispatch.md): the recommended
direction and smallest path; the workflow-brief or implementation brief; created
or inline plan text; surviving assumptions and open decisions; likely touched
areas; blockers and residual risk.

Target `<=1,200` output tokens unless the requested artifact is the report. Keep
evidence compact and source-backed; no full transcripts unless asked.

## References (do not auto-load)

- [`../../plan-lifecycle.md`](../../plan-lifecycle.md), [`../../plan-template.md`](../../plan-template.md)
- [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md) — report shape.
- [`review.md`](review.md) — the worker that critiques plan material.
