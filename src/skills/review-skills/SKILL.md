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

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol**. This skill is state-driven: it runs directly off the on-disk skill
suite, so **skip the two-question intake** and do not stop to ask for a task. It
still honors dials passed in `$ARGUMENTS`; broad-sweep default is `cost-high`.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Read inline (this is coordination reading, not worker dispatch):

- `~/.agentdocs/skills/registry.md` — the skill inventory.
- `~/.agentdocs/agent-docs-guide.md` — especially maintenance and lifecycle.
- `~/.agentdocs/rules/skill-contracts.md` and `~/.agentdocs/rules/repo-rules.md`.
- Representative `~/.agentdocs/skills/*/SKILL.md` bodies, selected by risk
  (recently changed, mode-ambiguous, or carrying their own policy).

Reading and summarizing this coordination state is inline routing work. Dispatch
a worker once a phase reads across the skill bodies, makes a defensible judgment
call, or (when authorized) mutates the tree. See References for pointers.

## Worker Phases

This skill's kernel workflow is `review-skills`; `src/kernel/workflows.json` is
the machine authority for its phase sequence and allowed profiles. Each
dispatch names that profile's exact rule files directly; `--resolve` is a
source-only authoring aid, not a runtime worker step.

- **Review worker** for registry/skill consistency: directory name vs.
  frontmatter `name:` vs. registry row, mode/action/commit metadata, missing or
  stale skills, lifecycle gaps and confusing overlap, `$ARGUMENTS` and
  missing-input behavior. Profile: `review.generic` plus
  `~/.agentdocs/skills/registry.md` and the skill bodies under review.
- **Docs-maintenance worker** for rule-doc shape and duplicated policy: bootstrap,
  shipping, commit, model-tier, or ownership instructions repeated across skills
  that should move into a shared rule, and rule-doc house-rule compliance. Profile:
  `review.docs` plus `~/.agentdocs/rules/repo-rules.md` only when fixes are
  authorized.
- **Verification worker** only when the user authorizes applying fixes and a
  static check (e.g. registry/skill cross-check) is better isolated. Profile:
  `verification.readonly`.

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

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver
- `~/.agentdocs/rules/orchestrator/` — orchestrator and worker-role rules (load only when checking skills against the orchestrator model)

$ARGUMENTS
