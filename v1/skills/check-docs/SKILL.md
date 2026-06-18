---
name: check-docs
description: Check named docs for code drift and house-rule issues, then report findings.
---

You are the orchestrator for a **read-only mechanical drift check** over one or
more named docs in `docs/`. You coordinate the check by dispatching one or more
docs-maintenance workers — one per doc or doc cluster — with a drift lens, then
aggregate their concise reports. This is **report-only**: you edit nothing and
commit nothing. If findings should be applied, that is a follow-up edit pass or
the `fix-docs-drift` whole-tree sweep.

This is the mechanical lane of the three doc-maintenance skills: it asks whether
each named doc still matches the code and the house authoring rules. The
editorial "is this the right doc, in the right shape?" question belongs to
`review-docs-shape`; the heavyweight tree-wide fix-and-commit sweep belongs to
`fix-docs-drift`. The codebase is authoritative for behavior; the docs are
authoritative for what's-where and why.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`) → `index.md` → `overview.md` → stop. The doc paths to check
are the task; if none are named, run the two-question intake (which doc(s) to
check, plus dials) and wait before the deeper reads.

Once the doc paths are known, read
`~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
`~/agent-docs/v1/rules/orchestrator/dispatch.md` to plan worker fan-out and
dispatch. Read `docs/_meta/ownership.json` when a finding turns on ownership, and
read the named doc paths only enough to scope the work into per-doc or per-subtree
worker slices — the workers do the reading-across.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape follows
`orchestrator/dispatch.md`. Drift checks are read-only, so worker slices
parallelize freely — one doc-maintenance worker per doc, or one per doc cluster
when several docs share a subtree.

- **Docs-maintenance worker** per doc/cluster, with a **drift lens** and
  **read-only** dispatch. Pass the Docs-maintenance worker bundle:
  `~/agent-docs/v1/rules/subagent/docs-maintenance.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`. Tell it to check accuracy vs code
  (resolve `path → symbol` pointers and code anchors by name not line, check
  literal constants, flag contradictions and possible code bugs) and clarity vs
  the authoring rules (altitude, what-IS framing, no transcription or ungated
  counts, ownership), and to **report findings without editing or committing**.
  Point it at the `drift-verification` slot for app-specific high-risk surfaces.
- **Verification worker** only when a named drift gate is cheap and directly
  relevant to a literal count or contract the docs assert. Pass
  `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`, naming the exact gate to run. Skip it
  when no gate bears directly on the check.

A single named doc still goes through a docs-maintenance worker — the
cross-file read and the house-rule judgment are the dispatch boundary in
`orchestrator/lifecycle.md`, not an inline exception.

## Closeout

Aggregate from worker reports — no edits, no commits:

- one short report per checked doc
- drift findings (stale pointer, wrong value, contradicts code, possible code
  bug) as `location → issue`, or "none"
- house-rule findings (altitude / transcription / ownership / readability) as
  `location → issue`, or "none"
- recommended next action — e.g. "minor, fix inline", "run `fix-docs-drift`",
  "needs an editorial `review-docs-shape` pass", or "escalate the possible code
  bug at X"

$ARGUMENTS
