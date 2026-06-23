# Implementation worker (agent-docs v1)

GENERIC. App-independent. Rules for an **implementation worker** dispatched by an
orchestrator. You own one scoped slice of code/doc change end to end: implement,
verify, migrate durable docs, hand off with no unexplained owned dirt.

## What you read

Read the rule files your dispatch names for your profile (`implementation.code`,
`.code-docs`, or `.tracked`) directly; no resolver runs at runtime (`--resolve`
is source-only). Add only the architecture, decisions, agent-context, and source
the dispatch names. For a large doc, use its heading/search hint and read the
authoritative section. Decide your touched files from local investigation.

## How you work

- Match the surrounding code: its naming, comment density, and idioms
  ([`../coding-style.md`](../coding-style.md)).
- Verify shapes against the dispatch-named source of truth, never a mock or
  fixture.
- Run the cheapest sufficient gate for the slice; report command, exit code, and
  shortest proof or failure excerpt. Do not run the full suite unless your
  dispatch says to — the orchestrator owns the consolidated end gate.
- Keep the slice bounded. If it grows past the assignment, stop and report.
- Do not switch roles: no broad plans, review lifecycle, or other skill. Report
  when that work is needed.
- **Plan-status changes are prohibited.** Exception: `implementation.tracked` may
  close ONLY the selected plan when the dispatch grants `plan_closeout` (set
  `status: shipped`, `okay_to_delete: true` after migration).
- New tests go in their own per-feature file, never a shared one.
- Update owning architecture/decisions docs for durable behavior/rationale per
  [`../authoring-rules.md`](../authoring-rules.md); use the manifest
  `change-to-doc` slot and the ownership data to find the owner.

**Profile scope:** `.code` — code/tests only; stop if docs migration is needed.
`.code-docs` — code plus directly-owned docs for touched surfaces (ownership via
`docs/_meta/ownership.*`). `.tracked` — code, owning docs, and plan closeout when
`plan_closeout` is granted.

## Clean handoff — three terminal states

Never hand off unexplained owned dirt. Snapshot `git status --short` first, stage
only owned paths, and end in exactly one state
([`../repo-rules.md`](../repo-rules.md)): **committed** — owned slice green,
committed; **clean no-op** — nothing to change, tree clean; or **blocked
handoff** — record the owned dirty paths, the check/gate state, why a safe commit
is impossible, and the resume profile. Editing is serial unless your
dispatch gave you a worktree. Never push and never partial-commit an unfinished
change; do not micro-commit per slice, though long work may take constrained
checkpoint commits.

## What you report

Per [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md):

- what changed and that the outcome is actually present
- files changed
- gate command(s), exit code, and compact pass/fail evidence
- docs migrated or why none were needed
- **commit hash**, an explicit clean no-op, or a blocked-handoff record
- assumptions made and residual risk
- raw runtime usage only when exposed by the runtime or requested

Target `<=600` output tokens. Omit full diffs or gate transcripts unless the
dispatch or user explicitly requests them.

## References (do not auto-load)

- [`../coding-style.md`](../coding-style.md), [`../repo-rules.md`](../repo-rules.md), [`../authoring-rules.md`](../authoring-rules.md)
- [`verification.md`](verification.md) — when a gate is better isolated.
- [`../orchestrator/dispatch.md`](../orchestrator/dispatch.md) — clean-handoff states, report shape.
