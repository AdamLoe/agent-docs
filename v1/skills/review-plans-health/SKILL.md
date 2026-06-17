---
name: review-plans-health
description: Review docs/plans/ for stale, oversized, duplicate, blocked, or poorly migrated plans and report cleanup recommendations.
---

You are reviewing the health of `docs/plans/` in the current repository. This
is a report-only planning hygiene pass. It does not implement plan work, edit
plans, migrate docs, or delete files unless the user explicitly asks you to
apply the cleanup.

## Bootstrap

This skill runs directly on disk state — no intake questions. Read
`~/agent-docs/v1/rules/skill-contracts.md` for the shared dials and model
policy, and honor any dials passed in `$ARGUMENTS`.

1. Read `docs/_meta/manifest.md` for `repo_name`, `code_root`, and
   `change-to-doc`.
2. Read `docs/plans/index.md`, `~/agent-docs/v1/plan-lifecycle.md`, and
   `~/agent-docs/v1/plan-template.md`.
3. Read `docs/_meta/ownership.json` when judging whether a plan's
   `owning_docs` and migration targets are plausible.
4. List `docs/plans/` and read every top-level plan except `index.md` and
   `template.md`. Also read immediate run folders under
   `docs/plans/orchestrator/`; start with each `hub.md`, then sample stream
   or findings files only when the hub does not answer the health question.
   For large plan sets, sample first and then fan out by status or subsystem.

## Health Lens

For each plan, check:

- Status truth: whether `draft`, `active`, `shipped`, `abandoned`,
  `okay_to_delete`, and `long_lived` look credible from the plan text, git
  history, and obvious code/doc state.
- Staleness: old `last_updated`, unclear owner, blocked questions with no
  next action, or plans that appear superseded by newer work.
- Shape: too detailed for a high-level plan, too vague to hand off, missing
  verification gates, unclear owning docs, or mixed unrelated workstreams.
- Duplication: plans that overlap, should merge, or are stale shadows of
  architecture/decisions docs.
- Migration readiness: shipped or abandoned plans whose durable facts,
  decisions, and tradeoffs appear ready for `clear-plans`, plus plans already
  flagged `okay_to_delete` that deserve a quick migration sanity check.
- Risk: plans likely to mislead implementers because they contradict current
  architecture, code state, or active direction.

For orchestration run folders, apply the same lens to the run as plan
material. A healthy in-flight run has a coherent `hub.md` with plan-style
frontmatter (`status`, `owner`, `last_updated`, `okay_to_delete`,
`long_lived`, `owning_docs`), observed state, open questions, blockers, next
action, and current stream status. A closed run should name its durable
migration targets and whether it is ready for `clear-plans`; if it lacks a hub,
lifecycle frontmatter, closeout, or migration state, report it as a cleanup
risk rather than trying to infer status from scattered stream files.

## Report Format

Write one concise memo:

1. **Take** - the overall health of `docs/plans/` and the most important
   cleanup.
2. **Needs Human Decision** - plans blocked on product, architecture, or
   ownership judgment.
3. **Ready For Cleanup** - plans ready for `clear-plans`, deletion after
   migration sanity check, merge, or abandonment.
4. **Stale / Risky Plans** - plans likely to mislead implementers and why.
5. **Plan Quality Issues** - recurring structure or handoff problems.
6. **Leave Alone** - healthy active or long-lived plans.
7. **Suggested Next Step** - the smallest cleanup batch worth doing.

$ARGUMENTS
