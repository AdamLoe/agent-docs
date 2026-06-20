---
name: review-plans-health
description: Review docs/plans/ for stale, oversized, duplicate, blocked, or poorly migrated plans and report cleanup recommendations.
---

You are the orchestrator for a hygiene review over `docs/plans/` in the current
repository. You coordinate a read-only pass on plan status, staleness,
duplication, blocked work, and cleanup readiness — normally one plan-maintenance
worker, plus a review worker when the lens is broader than hygiene. This is
**report-only**: you do not implement plan work, edit plans, migrate docs, or
delete files unless the user explicitly asks you to apply the cleanup.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`, `change-to-doc`. This
skill is **state-driven** — it runs off the plan tree on disk, so there is no
two-question intake; honor any dials passed in `$ARGUMENTS`.

Then read, inline, the coordination state this review judges against:

- `docs/plans/index.md` for the plan inventory.
- `~/agent-docs/v1/plan-lifecycle.md` and `~/agent-docs/v1/plan-template.md` for
  the lifecycle states and the shape a plan should hold.
- `docs/_meta/ownership.json` when judging whether a plan's `owning_docs` and
  migration targets are plausible.
- `~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
  `~/agent-docs/v1/rules/orchestrator/dispatch.md` to choose phases and dispatch.

Listing the plan tree and reading frontmatter to scope the review is inline
routing. Dispatch a worker once the pass reads across the plan/run bodies, judges
lifecycle health, or fans out by status — per the reads-vs-dispatch test in
`orchestrator/lifecycle.md`.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape and report
fields follow `orchestrator/dispatch.md`. The health lens below is what the
worker checks.

- **Plan-maintenance worker** (the hygiene pass, read-only). Pass the
  Plan-maintenance worker bundle: `~/agent-docs/v1/rules/subagent/plan-maintenance.md`,
  `~/agent-docs/v1/plan-lifecycle.md`, `~/agent-docs/v1/rules/authoring-rules.md`,
  plus `docs/plans/index.md`, the plans and run folders in scope, and the
  ownership data. It inspects plan/run-folder health and buckets by lifecycle
  state, but **reports only** — no migration, status changes, or deletion unless
  the user asked to apply cleanup. For large plan sets, sample first, then fan
  out by status or subsystem.
- **Review worker** only when the requested lens is broader than hygiene — a
  planning-shape critique of whether plans are coherent, well-scoped, and headed
  the right way. Pass `~/agent-docs/v1/rules/subagent/review.md` plus the plans
  under review.

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

$ARGUMENTS
