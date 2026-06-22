---
name: review-plans-health
description: Review docs/plans/ for stale, oversized, duplicate, blocked, or poorly migrated plans and report cleanup recommendations.
---

You are the orchestrator for a hygiene review over `docs/plans/` in the current
repository. You coordinate a read-only pass on plan status, staleness,
duplication, blocked work, and cleanup readiness — normally one inspection
worker, plus a review worker when the lens is broader than hygiene. This is
**report-only**: you do not implement plan work, edit plans, migrate docs, or
delete files unless the user explicitly asks you to apply the cleanup.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`, `change-to-doc`. This
skill is **state-driven** — it runs off the plan tree on disk, so there is no
two-question intake; honor any dials passed in `$ARGUMENTS`.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Read inline (this is coordination reading, not worker dispatch):

- `docs/plans/index.md` for the plan inventory.
- `~/.agentdocs/plan-lifecycle.md` and `~/.agentdocs/plan-template.md` for
  the lifecycle states and the shape a plan should hold.
- `docs/_meta/ownership.json` when judging whether a plan's `owning_docs` and
  migration targets are plausible.

Listing the plan tree and reading frontmatter to scope the review is inline
routing. Dispatch a worker once a phase reads across the plan/run bodies, judges
lifecycle health, or fans out by status. See References for pointers.

## Worker Phases

Workers resolve their context via
`bash src/verify-agent-docs.sh --resolve <profile-id>`.

- **Inspection worker** (the hygiene pass). Profile: `plans.inspect` (read-only)
  plus `docs/plans/index.md`, the plans and run folders in scope, and the
  ownership data. It inspects plan/run-folder health and buckets by lifecycle
  state and reports findings. For large plan sets, sample first, then fan out by
  status or subsystem.
- **Review worker** only when the requested lens is broader than hygiene — a
  planning-shape critique of whether plans are coherent, well-scoped, and headed
  the right way. Profile: `review.generic` plus the plans under review.

The worker applies this **health lens** to each plan, and the same lens to each
orchestration run folder (hub, observed state, open questions, blockers, next
action, stream status) as plan material:

- **Status truth** — whether `draft`, `active`, `shipped`, `abandoned`,
  `okay_to_delete`, and `long_lived` look credible from the plan text, git
  history, and obvious code/doc state.
- **Staleness** — old `last_updated`, unclear owner, blocked questions with no
  next action, or plans superseded by newer work.
- **Shape** — too detailed for a high-level plan, too vague to hand off, missing
  verification gates, unclear owning docs, or mixed unrelated workstreams.
- **Duplication** — plans that overlap, should merge, or are stale shadows of
  architecture/decisions docs.
- **Migration readiness** — shipped or abandoned plans whose durable facts and
  tradeoffs are ready for `clear-plans`, plus plans already flagged
  `okay_to_delete` that deserve a migration sanity check.
- **Risk** — plans likely to mislead implementers because they contradict
  current architecture, code state, or active direction.

A closed run that lacks a hub, lifecycle frontmatter, closeout, or migration
state is a cleanup risk — report it rather than inferring status from scattered
stream files.

## Closeout

Record from the worker report into one concise memo:

- overall plan health and the most important cleanup
- actionable findings (status drift, staleness, shape, duplication, risk)
- ready-for-cleanup list (ready for `clear-plans`, deletion after a migration
  sanity check, merge, or abandonment)
- needs-human list (plans blocked on product, architecture, or ownership)
- the recommended next cleanup action — the smallest batch worth doing

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver
- `~/.agentdocs/plan-lifecycle.md` — load only as coordination reading before dispatch

$ARGUMENTS
