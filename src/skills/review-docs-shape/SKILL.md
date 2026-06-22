---
name: review-docs-shape
description: Editorial review of docs/ for fit, shape, and direction; report-only.
---

You are the orchestrator for an editorial and structural review of `docs/`. The
input is a doc, a subtree, or the whole tree. You coordinate review workers that
form a point of view — is this the **right** doc, in the **right shape**, heading
the **right way**? — and report findings and recommendations. You are
**report-only**: you do not edit or commit. Structural moves belong in a plan or
in a later skill the human invokes. As a broad review this defaults to
`cost-high`; scale fan-out down for a single doc and up only when scope needs it.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `decisions-domains`, plus
`change-to-doc` when direction/debt is in scope. This skill runs directly off
disk and git state with no two-question intake. Honor any dials passed in
`$ARGUMENTS`.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Orient inline (this is coordination reading, not worker dispatch):

- `docs/_meta/ownership.json` — query it to judge whether concepts sit with the
  right owner.
- The relevant index docs (`docs/architecture/index.md`,
  `docs/decisions/index.md`, `docs/agent-context/index.md`) for whichever layers
  are in scope — to judge routing and fit.
- `docs/overview.md` when the review covers first-screen orientation or
  whole-tree coverage.
- The target docs or subtree (skim, don't deep-read — that is worker work).
- Active plans in `docs/plans/` when direction matters — to judge what's coming
  that the docs will need to serve.

**If `$ARGUMENTS` is empty, default to the whole `docs/` tree** at `cost-high`;
do not stop to ask. See References for pointers.

## Worker Phases

Editorial judgment is strong-model work. Both phases are read-only, so they
parallelize freely. Workers resolve their context via
`bash src/verify-agent-docs.sh --resolve <profile-id>`.

- **Docs-maintenance worker** — architecture/decision **shape** and ownership
  review: is the material in the right layer (architecture = what IS, decisions =
  why, agent-context = procedure), is each concept owned cleanly, is
  `decisions-domains` coverage complete? Report-only, not a repair pass. Profile:
  `review.docs`, plus the target docs and the ownership/manifest slots it needs.
- **Review worker** — broad editorial and product fit through a docs-shape lens:
  coverage and gaps (under- and over-documentation both count), routing and
  fresh-chat fit (trace the path a fresh chat takes to answer a real question),
  altitude and framing, and direction against the active plans. Be opinionated —
  a hedged editorial is useless. Profile: `review.generic` plus the target
  docs/subtree under review. For a large tree, fan out one review worker per doc
  cluster and synthesize **one** point of view.

This review judges docs *as docs* — workers do not re-verify every code claim,
but ground coverage claims in `docs/overview.md` and the system's real shape.

## Closeout

Record from worker reports, synthesized into one opinionated editorial:

- **Findings by severity** — each as `area → the problem → what you'd do`,
  ordered by impact, covering gaps, structure, routing, altitude, and direction
  as they apply. Be concrete.
- **Structural recommendations** — splits, merges, relocations, new homes for
  homeless concepts, and what to leave alone so it isn't churned.
- **Suggested next skill** — `fix-docs-drift` or `check-docs-drift` for the mechanical
  cleanup this surfaced, a new plan for structural moves (offer to draft it into
  `docs/plans/`), or "leave clean" when nothing needs doing.

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver

$ARGUMENTS
