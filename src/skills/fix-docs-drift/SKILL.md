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

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`, `change-to-doc`,
`drift-gates`, `drift-verification`. This skill is **state-driven**: it runs off
the docs tree itself, so it skips the two-question intake and runs directly.
Honor any dials passed in `$ARGUMENTS`. Default
**`cost-high`** — a whole-tree sweep is the high-fan-out band per
`skill-contracts.md`; a small or targeted sweep resolves to `cost-medium`, an
explicit quick pass to `cost-low`.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Inline (this is coordination reading, not worker dispatch): query
`docs/_meta/ownership.json`, and take the `docs/architecture/` and
`docs/decisions/` inventory. Group the docs into ~subsystem clusters (an
architecture doc + its `decisions/<domain>.md` + tightly-coupled neighbours) and
tier each: clusters touching a high-risk contract surface (from the
`drift-verification` slot) or needing multi-file reconciliation go to a strong
worker; the rest are mechanical mid-tier verify-and-fix. Do not read the cluster
docs yourself beyond what clustering needs — that reading is the workers' job.
See References for pointers.

## Worker Phases

Editing is **serial per tree** — run one docs-maintenance worker at a time on
the shared tree, each committing its slice before the next starts; aim for ~5–8
clusters in the `cost-high` band, sequenced rather than spawned per doc.
Workers resolve their context via
`bash src/verify-agent-docs.sh --resolve <profile-id>`.

- **Docs-maintenance workers**, one per architecture/decision subtree or
  ownership area, at the tier you assigned. Profile: `maintenance.docs`. Pass
  the cluster's doc paths, the `drift-verification` slot content (inline it; the
  worker starts cold), and the fix-vs-escalate boundary above. Each worker
  resolves every `path → symbol` pointer (match by name, never line number),
  scans for forbidden transcription and ungated literal counts, spot-checks its
  cluster's high-risk facts, compares touched surfaces with the manifest
  `change-to-doc` owners when drift seems cross-cutting, fixes in place, and
  commits. Cross-cluster issues go in its `escalate:` list with the exact paths,
  evidence, and recommended follow-up role.
- **Review worker** for the hard ownership and rationale calls a maintenance
  worker escalated. Profile: `review.generic`. Pass the docs and escalations in
  question. It decides which escalations are safe to fold in versus genuinely
  human; default read-only unless you authorize the obvious non-debatable fix.
- **Verification worker** for the consolidated drift gates. Profile:
  `verification.readonly`. Pass the manifest `drift-gates`. Run this once at the
  end, not per cluster.
- **Implementation worker** only when the sweep uncovers a broken script or
  drift verifier that itself needs a code fix. Profile: `implementation.code-docs`.

Do not resolve cross-file judgment inline. When no single worker owned a
renamed symbol, ownership call, or rationale mismatch that spans clusters,
dispatch a follow-up docs-maintenance or review worker with the affected paths,
prior evidence, and a narrow fix-vs-escalate boundary. Keep only routing,
evidence tracking, and final gate coordination in the orchestrator context.

## Closeout

Record from worker reports and the final gate:

- docs fixed, grouped by cluster
- deferred human decisions (escalations not safely resolved)
- gates run and result
- whether any mismatch smells like a code bug rather than doc drift
- commit hash(es)

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver

$ARGUMENTS
