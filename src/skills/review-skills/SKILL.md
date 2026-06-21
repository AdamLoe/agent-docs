---
name: review-skills
description: Review the agent-docs skill set for drift, duplicate policy, adapter assumptions, and lifecycle gaps.
---

You are the orchestrator for a review of the agent-docs skill suite itself. You
coordinate review of the skill bodies, the registry, and the rule docs that
describe them — looking for drift, duplicated policy, adapter assumptions, and
lifecycle gaps. This is report-only: you route review and maintenance workers and
record their findings; you do not edit or commit unless the user explicitly asks
to apply fixes.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**. This skill is state-driven: it runs directly off the on-disk skill
suite, so **skip the two-question intake** and do not stop to ask for a task. It
still honors dials passed in `$ARGUMENTS`; broad-sweep default is `cost-high`.

Then read, inline, the coordination state this review spans:

- `~/agent-docs/v1/skills/registry.md` — the skill inventory.
- `~/agent-docs/v1/agent-docs-guide.md` — especially maintenance and lifecycle.
- `~/agent-docs/v1/rules/skill-contracts.md` and `~/agent-docs/v1/rules/repo-rules.md`.
- `~/agent-docs/v1/rules/orchestrator/` and `~/agent-docs/v1/rules/subagent/` —
  the orchestrator and worker-role rules the skills route to.
- Representative `~/agent-docs/v1/skills/*/SKILL.md` bodies, selected by risk
  (recently changed, mode-ambiguous, or carrying their own policy), plus
  `~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
  `~/agent-docs/v1/rules/orchestrator/dispatch.md` to check skills against the
  documented orchestrator model.

Reading and summarizing this coordination state is inline routing work. Dispatch
a worker once a phase reads across the skill bodies, makes a defensible judgment
call, or (when authorized) mutates the tree.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape and commit
concurrency follow `orchestrator/dispatch.md`.

- **Review worker** for registry/skill consistency: directory name vs.
  frontmatter `name:` vs. registry row, mode/action/commit metadata, missing or
  stale skills, lifecycle gaps and confusing overlap, `$ARGUMENTS` and
  missing-input behavior. Use profile `review.generic` plus
  `~/agent-docs/v1/skills/registry.md` and the skill bodies under review.
- **Docs-maintenance worker** for rule-doc shape and duplicated policy: bootstrap,
  shipping, commit, model-tier, or ownership instructions repeated across skills
  that should move into a shared rule, and rule-doc house-rule compliance. Pass
  `~/agent-docs/v1/rules/subagent/docs-maintenance.md` and
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md` only when fixes are authorized.
- **Verification worker** only when the user authorizes applying fixes and a
  static check (e.g. registry/skill cross-check) is better isolated. Pass
  `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`.

Default is read-only review. If the user asks to apply fixes, route them to a
docs-maintenance or implementation worker with an appropriate mutating profile.
Fix workers make only obvious non-debatable corrections, verify, and commit
their slice before reporting; substantial changes pivot to `/plan`.

## Closeout

Record from worker reports, findings first:

- registry drift — missing skills, stale names, wrong mode/action/commit metadata,
  guide text that lists an old command.
- duplicate policy that should be extracted into a shared rule.
- missing verification or commit semantics — report-only skill that edits, or a
  mutating skill that omits how it verifies.
- adapter / discovery risks — tool-specific roots, hardcoded vendor model names,
  one-platform assumptions, or skills the registry/guide cannot surface.
- proposed or applied fixes, with commit hashes for any applied, and whether the
  suite is coherent enough to trust or needs a follow-up plan.

$ARGUMENTS
