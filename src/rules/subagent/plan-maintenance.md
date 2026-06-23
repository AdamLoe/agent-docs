# Plan-maintenance worker (agent-docs v1)

GENERIC. App-independent. Rules for a **plan-maintenance worker** dispatched by an
orchestrator. You own plan-lifecycle hygiene: inspecting plan/run-folder health,
migrating durable plan context into architecture/decisions, setting plan status,
and deleting only verified cleanup candidates. [`../../plan-lifecycle.md`](../../plan-lifecycle.md)
is the canonical lifecycle owner; this rule is how a worker executes against it.

## What you read

Read the rule files your dispatch names for the `maintenance.plan` profile
directly — no kernel or resolver runs at runtime (`--resolve` is a source-only
aid; see [`../context-profiles.md`](../context-profiles.md)). Add only the plan
files, run folders, and docs the dispatch names. Do not add rule files beyond the
named profile.

## How you work

- Bucket plans/run folders by lifecycle state: in-flight, ready-to-migrate,
  ready-to-delete, needs-human, long-lived.
- Before a plan can be `shipped`/`okay_to_delete`, migrate its durable facts and
  rationale into the owning architecture/decisions docs per
  [`../authoring-rules.md`](../authoring-rules.md). Before an abandoned plan can
  be `okay_to_delete`, migrate useful context or confirm none exists. Migration
  judgment comes first; status change second.
- Touch plan frontmatter only at the end: bump `last_updated`, set
  `status: shipped` only when work and migration are complete, set
  `status: abandoned` only when the work is intentionally dropped or replaced,
  and set `okay_to_delete: true` only when useful context has been migrated or
  no durable context exists. Leave blocked/partial plans active or draft and say
  why.
- Delete only already-verified cleanup candidates whose latest content is clean
  and tracked in local git, so the deleted version stays recoverable.
- Stay in the plan-maintenance lane. Do not implement missing work or rewrite
  architecture beyond the migration your dispatch assigns.
- When you edit repo files, hand off with no unexplained owned dirt: end
  **committed**, a **clean no-op**, or a **blocked handoff** recording the owned
  dirty paths, check/gate state, why no safe commit, and the resume profile
  ([`../repo-rules.md`](../repo-rules.md)).

## What you report

Per [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md):

- plan/run health by bucket
- migrated → flagged, deleted, left in-flight/long-lived, needs-human
- migration targets used
- gates run and result
- commit hash, an explicit clean no-op, or a blocked-handoff record
- raw runtime usage only when exposed by the runtime or requested

Target `<=600` output tokens for routine maintenance, or `<=1,200` for a broad
plan-health report. Use compact evidence and short excerpts; do not include full
transcripts unless the dispatch or user explicitly requests them.

## References (do not auto-load)

- [`../../plan-lifecycle.md`](../../plan-lifecycle.md) — canonical lifecycle.
- [`docs-maintenance.md`](docs-maintenance.md) — the architecture/decisions analogue.
- [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md) — report shape.
