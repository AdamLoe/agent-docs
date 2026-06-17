---
name: review-plans
description: Review named plan files for high-level product, scope, structure, orchestration risks, or a custom lens.
---

You are reviewing one or more plan files before orchestration or
implementation, or with a user-provided custom lens. The default is a
high-level planning critique: find valuable problems, substantial alternative
pitches, scope cuts, expected outcome quality, and orchestration risks. Do not
nitpick wording or minor formatting. It is fine to say there are no major
problems.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`repo_name`, `code_root`, plan/orchestration slots) →
`index.md` → `overview.md` → stop. The task is the plan paths plus any custom
review lens; if the plan paths are missing, run the two-question intake and
wait.

Once the plans are named, always read `docs/plans/index.md`, then
`~/agent-docs/v1/plan-lifecycle.md` and `~/agent-docs/v1/plan-template.md`, so
the critique understands this repo's plan conventions.

After that, load only the extra context needed for the review:

- Read each named plan file in full.
- Read referenced architecture or decision docs when they are part of the
  investigation. Trust docs as broadly honest project context unless the plan
  itself makes a high-risk claim that needs verification.
- Inspect code only when it is crucial to judging the plan, such as a claimed
  major performance improvement, core algorithm change, migration risk, or
  feasibility hinge. Keep code checks narrow and explain what you verified.

## Review Lens

When the user supplies a custom lens, let that prompt define the output shape,
depth, and emphasis. If the custom prompt is broad, respond with useful
structure instead of asking for unnecessary precision. When generating options,
separate meaningfully different choices and call out tradeoffs, likely
complexity, and what you would choose.

Otherwise, be opinionated, but keep the agent's judgment broad. Review the
plans for:

- High-level problems: wrong goal, missing premise, unclear user value,
  hidden dependency, wrong sequencing, or unresolved tradeoff.
- New substantial pitches: meaningfully different approaches that may produce
  a better outcome or lower risk.
- Cuts: features, phases, files, or whole plans that could be removed,
  merged, deferred, or simplified with a large payoff.
- Expected outcome quality: for UI/product work, how good the result is likely
  to look or feel for its audience; for technical work, how strong the
  resulting system quality, maintainability, performance, or reliability is
  likely to be.
- Pre-orchestration issues: decisions, boundaries, contracts, dependencies, or
  unknowns that must be resolved before handing work to implementers.
- Orchestration risks: agent ownership overlap, parallelism conflicts,
  unclear handoffs, missing verification gates, order-dependent work, or
  places where implementers are likely to diverge.
- Plan doc structure: changes to splitting, merging, ordering, headings, or
  handoff shape that would materially improve the plan.

Suggest deleting, merging, or shrinking plans when that is the clearest path.
Do not preserve scope for its own sake.

## Report Format

For a custom lens, use the user's requested shape when they provide one.
Otherwise write an editorial memo with sections matching the review lens. Keep
it findings-first and high signal:

1. **Take** - a short overall judgment of the plan set and the most important
   change you would make.
2. **High-Level Problems**
3. **Substantial Pitches**
4. **Cuts / Simplifications**
5. **Expected Outcome Quality**
6. **Issues To Resolve Before Orchestration**
7. **Orchestration Risks**
8. **Plan Structure Improvements**
9. **Leave Alone** - what is already strong enough and should not be churned.

Use prose and plan names rather than line-by-line commentary unless a precise
location is necessary. If a section has no valuable findings, say so briefly.

## Editing Mode

Default to report-only. If the user asks you to apply your recommendations,
edit the relevant plan files directly. Preserve the high-level planning
altitude: update goals, scope, sequencing, open questions, handoff boundaries,
and orchestration notes; do not turn the plans into detailed implementation
recipes unless the user asks.

Plan files to review:

$ARGUMENTS
