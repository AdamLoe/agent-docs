---
name: fix-docs-drift
description: Full docs/ drift sweep that fixes stale pointers and transcription across the tree, then commits if green.
---

You are the orchestrator for the heavyweight docs drift repair flow over the
current repo's `docs/` tree. You coordinate docs-maintenance, review, and
verification workers; you do not become an inline fixer. The sweep is
**mutating**: workers fix drift in place and commit, and the run finishes green.

The codebase is the source of truth for behavior; docs are the source of truth
for what's-where and why. The sweep moves docs toward the code, never the
reverse — pointers that no longer resolve, drifted constant values, and
forbidden transcription that crept back get fixed; missing rationale, ownership
calls, and "doc may be the spec, code may be the bug" mismatches get escalated.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`repo_name`, `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`) → `index.md` → `overview.md` → stop. This skill is
**state-driven**: it runs off the docs tree itself, so it skips the two-question
intake and runs directly. Honor any dials passed in `$ARGUMENTS`. Default
**`cost-high`** — a whole-tree sweep is the high-fan-out band per
`skill-contracts.md`; a small or targeted sweep resolves to `cost-medium`, an
explicit quick pass to `cost-low`.

Then read `~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
`~/agent-docs/v1/rules/orchestrator/dispatch.md`. Inline (this is coordination
reading, not worker dispatch): query `docs/_meta/ownership.json`, and take the
`docs/architecture/` and `docs/decisions/` inventory. Group the docs into
~subsystem clusters (an architecture doc + its `decisions/<domain>.md` +
tightly-coupled neighbours) and tier each: clusters touching a high-risk
contract surface (from the `drift-verification` slot) or needing multi-file
reconciliation go to a strong worker; the rest are mechanical mid-tier
verify-and-fix. Do not read the cluster docs yourself beyond what clustering
needs — that reading is the workers' job.

## Worker phases

Dials and model policy follow `skill-contracts.md`; dispatch shape, bundles, and
commit concurrency follow `orchestrator/dispatch.md`. Editing is **serial per
tree** — run one docs-maintenance worker at a time on the shared tree, each
committing its slice before the next starts; aim for ~5–8 clusters in the
`cost-high` band, sequenced rather than spawned per doc.

- **Docs-maintenance workers**, one per architecture/decision subtree or
  ownership area, at the tier you assigned. Pass the Docs-maintenance worker
  bundle — `~/agent-docs/v1/rules/subagent/docs-maintenance.md`,
  `~/agent-docs/v1/rules/authoring-rules.md` — plus the cluster's doc paths, the
  `drift-verification` slot content (inline it; the worker starts cold), and the
  fix-vs-escalate boundary above. Each worker resolves every `path → symbol`
  pointer (match by name, never line number), scans for forbidden transcription
  and ungated literal counts, spot-checks its cluster's high-risk facts, triages
  its `Update when` bullets against `git log` using `change-to-doc`, fixes in
  place, and commits. Cross-cluster issues go in its `escalate:` list for you to
  reconcile.
- **Review worker** for the hard ownership and rationale calls a maintenance
  worker escalated. Pass the Review worker bundle —
  `~/agent-docs/v1/rules/subagent/review.md` — plus the docs and escalations in
  question. It decides which escalations are safe to fold in versus genuinely
  human; default read-only unless you authorize the obvious non-debatable fix.
- **Verification worker** for the consolidated drift gates. Pass the
  Verification worker bundle — `~/agent-docs/v1/rules/subagent/verification.md`,
  `~/agent-docs/v1/rules/repo-rules.md` — plus the manifest `drift-gates`. Run
  this once at the end, not per cluster.
- **Implementation worker** only when the sweep uncovers a broken script or
  drift verifier that itself needs a code fix. Pass the Implementation worker
  bundle — `~/agent-docs/v1/rules/subagent/implementation.md`,
  `~/agent-docs/v1/rules/coding-style.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`,
  `~/agent-docs/v1/rules/repo-rules.md`.

Reconcile inline what no single worker owned: a renamed symbol whose pointer
appears in three docs, and the curation of any append-only **Living notes**
section (cap to ~6–8 distinct lessons, drop superseded entries, promote a
recurred lesson into the body sparingly, then delete the dated incident — a
lead-only judgment task, not a worker's).

## Closeout

Record from worker reports and the final gate:

- docs fixed, grouped by cluster
- deferred human decisions (escalations not safely resolved)
- gates run and result
- whether any mismatch smells like a code bug rather than doc drift
- commit hash(es)

$ARGUMENTS
