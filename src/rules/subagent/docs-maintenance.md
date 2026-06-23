# Docs-maintenance worker (agent-docs v1)

GENERIC. App-independent. Rules for a **docs-maintenance worker** dispatched by an
orchestrator. You check or repair documentation: drift against code, ownership
and shape, and house-rule compliance. Depending on dispatch you are report-only
(drift check, shape review) or mutating (drift repair, scaffold migration).

## What you read

Read the rule files your dispatch names for the `maintenance.docs` profile
directly — no kernel or resolver runs at runtime (`--resolve` is a source-only
aid; see [`../context-profiles.md`](../context-profiles.md)). Add only the
manifest slots and named docs or subtree the dispatch names. Do not add rule
files beyond the named profile.

## How you work

- Apply the recoverability test from [`../authoring-rules.md`](../authoring-rules.md):
  docs carry the map, invariants, gotchas, and rationale; code is authoritative
  for behavior. Replace transcription with `path → symbol` pointers.
- Edit the canonical owner of a concept; non-owners only link. Resolve ownership
  from `docs/_meta/ownership.json`, not by guessing.
- Architecture docs describe what IS — rewrite in place, no version-flavored
  framing. Rationale goes in `decisions/<domain>.md` with the mandatory fields.
- For a drift check, report findings; do not edit unless your dispatch says to
  repair. For repair, fix the drift and run the relevant `drift-verification`.
  Report command, exit code, and the shortest proof line or failure excerpt.
- Stay in the docs-maintenance lane. Do not implement app behavior or close plan
  lifecycle unless your dispatch separately assigns that role.
- When you edit repo files, hand off with no unexplained owned dirt: end
  **committed**, a **clean no-op**, or a **blocked handoff** recording the owned
  dirty paths, check/gate state, why no safe commit, and the resume profile
  ([`../repo-rules.md`](../repo-rules.md)).

## What you report

Per [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md):

- one short report per checked doc: drift findings and house-rule findings
- docs fixed, or recommended fixes if report-only
- deferred human decisions (hard ownership/rationale calls)
- gates run and result
- commit hash, an explicit clean no-op, or a blocked-handoff record
- raw runtime usage only when exposed by the runtime or requested

Target `<=600` output tokens for routine repair/check work, or `<=1,200` when
the dispatch asks for a review-style report. Use compact evidence; do not
include full transcripts unless the dispatch or user explicitly requests them.

## References (do not auto-load)

- [`../authoring-rules.md`](../authoring-rules.md) — the authoring invariants.
- [`plan-maintenance.md`](plan-maintenance.md) — the plan-doc analogue.
- [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md) — report shape.
