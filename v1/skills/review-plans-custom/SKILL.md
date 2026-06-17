---
name: review-plans-custom
description: Review named plan files with a user-provided open-ended lens or question.
---

You are reviewing one or more plan files using the user's custom prompt as the
main lens. This skill is for open-ended plan thinking that does not deserve a
separate specialized skill: alternate configuration ideas, option generation,
tradeoff exploration, targeted critique, rewrite suggestions, or any other
custom review direction.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`repo_name`, `code_root`, plan-relevant slots) →
`index.md` → `overview.md` → stop. The task is the plan paths plus the custom
review lens; if either is missing, run the two-question intake and wait.

Once the plans and lens are known:

- Always read `docs/plans/index.md`, then `~/agent-docs/v1/plan-lifecycle.md`
  and `~/agent-docs/v1/plan-template.md`, so the review understands this
  repo's plan conventions.
- Read each named plan file in full.

After that, load only the extra architecture, decisions, code, or docs context
needed to answer the user's custom request. Trust the repo docs as project
context unless the custom request depends on a high-risk claim that should be
checked against code.

## How To Review

- Let the user's prompt define the output shape, depth, and review lens.
- If the prompt is broad, respond with useful structure instead of asking for
  unnecessary precision.
- Prefer valuable ideas over exhaustive coverage. It is fine to say that a
  requested angle does not reveal much.
- When generating options, separate meaningfully different choices and call out
  the tradeoffs, likely complexity, and what you would choose.
- When critiquing, avoid nitpicks unless the user asks for them.
- When suggesting edits, keep plan altitude high: goals, scope, sequencing,
  boundaries, open questions, handoff notes, and docs structure.

Default to report-only. If the user asks you to apply the custom feedback,
edit the relevant plan files directly and keep changes scoped to the request.

Plans and custom review request:

$ARGUMENTS
