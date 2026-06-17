---
name: quick-fix
description: Fix a small problem directly, verify it, update docs if needed, and commit when green.
---

You are making a quick fix in the current repository. The input is a problem,
not a plan. Keep the scope small, fix the issue directly, verify it, migrate
durable docs only if needed, and commit when green. Do not push unless
explicitly told.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`) → `index.md` → `overview.md` → stop. The problem to fix
is the task; if it is missing, run the two-question intake and wait.

Once the problem is known:

- Read `~/agent-docs/v1/rules/coding-style.md` and
  `~/agent-docs/v1/rules/repo-rules.md`.
- Load only the architecture, decisions, agent-context, and source files
  needed to understand and fix the problem.

Read `~/agent-docs/v1/rules/authoring-rules.md` before updating docs. Read
`docs/plans/index.md` and `~/agent-docs/v1/plan-lifecycle.md` only if the fix
needs to touch plan files.

## Scope Policy

- Quick fixes can affect any part of the app, but the change should stay
  bounded: one bug, one small behavior correction, one small feature, or one
  obvious cleanup.
- If the issue is too large, ambiguous, or direction-setting for a quick fix,
  pivot to planning: say that it needs `/plan`, summarize the
  concern, ask the batched high-level questions, and stop before implementing.
- Do not create partial commits for an unfinished quick fix. If the fix cannot
  be completed cleanly, leave the tree coherent, explain the blocker, and do
  not claim it is fixed.
- Ask before changing public behavior or APIs only when the problem statement
  does not already imply the desired behavior. At `review-none`, make the best
  defensible choice and note the assumption.

## Execution Policy

Dials and model policy follow `skill-contracts.md`. Notes specific to a quick
fix:

- Default to direct implementation. Use sub-agents only when they will likely
  save context, time, or model cost without slowing down a small fix; at
  `cost-low`, delegate routine investigation/verification to a cheaper agent
  when running on a stronger model.
- Run the cheapest meaningful verification first. Use manifest gates when they
  are needed to justify the commit or when the fix touches surfaces covered by
  those gates.
- For UI-facing fixes, do visual verification when practical. Ask for user
  confirmation when useful unless `review-none` is set.

## Shipping

Before finishing:

1. Inspect the diff and confirm the problem is actually fixed.
2. Run targeted tests or checks, plus any manifest gates needed for confidence.
3. Update architecture or decisions docs only for durable behavior/rationale
   changes, following the authoring rules.
4. Stage by filename and commit when green.

Final report can be brief, but include what changed, what verification ran,
the commit made, and any follow-up that remains.

Problem to fix:

$ARGUMENTS
