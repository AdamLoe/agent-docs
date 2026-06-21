# Skill contracts — expanded rationale + examples (do not auto-load)

GENERIC. App-independent. Reference companion to
[`skill-contracts.md`](skill-contracts.md). The terse startup contract lives
there; this leaf carries the rationale, worked examples, and the migration notes
for the two dials. **Never auto-loaded.** No skill, profile, or role card loads
it at startup. Read it only when you want the "why" behind a rule in
`skill-contracts.md`.

## Standard Intake Protocol — why cache-first

The fixed startup order (this file → manifest → `docs/index.md`, then stop) is a
cache-first order: it loads exactly the cache-stable layer and nothing else, so
the controlled launch budget stays measurable across every skill. The "stop"
step is the load-bearing one — without it, skills drift into eagerly loading
`docs/overview.md`, more rules, architecture/decisions, plans, templates, the
registry, ownership, or source before the task state proves any of those are
needed. Treat `docs/overview.md` as a normal task-routed doc reached from
`docs/index.md`: read it for system-shape orientation, docs-shape review,
scaffold repair, or another explicit task need — never as mandatory startup.
Query `docs/_meta/ownership.json` only for ownership questions; do not bulk-load
it.

## Intake branch — examples

- **Context present.** `$ARGUMENTS` or the user message already carries a
  substantive task, target paths, or a custom lens. Treat it as the first
  answer, parse any dials, and proceed — no questions. A supplied bounded
  `quick-fix` runs straight through with no dial round trip.
- **Context absent, `asks` skill.** Ask exactly two batched questions, then
  wait: one multiple-choice for the two dials (`review-medium`/`cost-medium`
  preselected) and one open-ended "what do you want to do?" Never guess the task
  or offer a task menu.
- **Context absent, `no-prompt`/state-driven skill.** Skip the generic intake
  questions and run from existing disk, git, or argument state. Honor dials where
  they affect the work; a pure utility may ignore inert dials. A capture skill
  may ask for missing payload content, but not for generic task/dial intake.

Use the skill body or `~/.agentdocs/skills/registry.md` Intake column to identify
`asks` vs. `no-prompt`.

## The two dials — rationale and old-tag migration

Two axes tune every skill; both default to `medium` unless the user names them.

- `review-*` controls human-review checkpoint intensity and how hard review
  workers work. Only `review-none` has a hard meaning: skip human-review
  checkpoints. It never skips automated verification, drift gates, or the
  original questioning needed to make work well-defined.
- `cost-*` controls worker fan-out, stronger-model spend, and worker-output
  budget. `cost-max` has no hard output cap, but every `cost-max` run records a
  budget-exception reason before spawning broad workers or accepting long
  reports.

Everything other than `review-none` is guidance, not a rulebook: higher asks a
bit more, fans out more, and reaches for stronger models when useful; lower
decides more locally and stays cheaper. Neither dial decides *whether* workers
are used — that is the reads-vs-dispatch test in
[`orchestrator/lifecycle.md`](orchestrator/lifecycle.md).

Old tags map in: `skip-review` → `review-none`; `heavy-review` →
`review-high`/`review-max`; `cheap-agents` → `cost-low`; `no-cost-limit` →
`cost-max`. A skill may declare a non-`medium` default.

## Model Policy — rationale

Role names (`cheap`, `mid-tier`, `strong`, `strongest`) let each adapter map to
its local models. Routine implementation, verification, mechanical docs, and
bounded investigation default to `mid-tier`. Escalate to `strong`/`strongest`
for security/auth, migrations, destructive behavior, public APIs, concurrency,
hard algorithms, conflicting sources, unclear acceptance, repeated failures, or
weak verification. `cost-low` pushes work down to `mid-tier`/`cheap`; `cost-max`
permits strong workers freely; `review-high`/`review-max` adds stronger
independent review where useful.

A skill's *launch* tier is recorded in `~/.agentdocs/skills/registry.md`
(`cheap`/`mid`/`strong`/`strongest`; `mid` maps to `mid-tier`). Dispatched
workers follow the role mapping above regardless of the launch tier.

## Human Stops — rationale

Stop for the user only when an answer changes what should be built, reviewed, or
shipped and cannot be resolved from code, docs, precedent, or the request.
Batching is the point: every stop states the decision needed, why it changes the
work, the fewest concrete questions, and a recommended default when one is
defensible. A vague blocker is not a stop — keep investigating, or run the
appropriate planning/review pass, until the question is concrete.

## Verification Fallbacks — rationale

Run relevant gates whenever practical. A skipped gate is never green: if a gate
cannot run, report the command attempted, why it failed or was unavailable, the
cheaper check you ran instead, and the residual risk.

## Owner pointers — why facts live elsewhere

This file is the small, always-loaded startup contract, so it carries no deep
policy. Deeper policy lives with its owner and is never copied back here or into
a skill body:

- **Orchestration** — reads-vs-dispatch, lifecycle choice, worker packets,
  dispatch-failure behavior, commit concurrency:
  [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md),
  [`orchestrator/dispatch.md`](orchestrator/dispatch.md).
- **Context profiles** — worker rule loads:
  [`context-profiles.md`](context-profiles.md). Skills name profile IDs and
  overlays, not rule lists.
- **Modes and registry** — inventory, mode/action names, worker roles, commit
  behavior, intake style, launch tier, normal inputs:
  [`../skills/registry.md`](../skills/registry.md).
- **Shipping** — confirm diff, migrate owning docs, run targeted + manifest
  gates, stage by filename, commit when green, never push unless told:
  [`orchestrator/dispatch.md`](orchestrator/dispatch.md),
  [`repo-rules.md`](repo-rules.md), [`subagent/`](subagent/).
- **Generated context** — dispatches stay plain text with exact rule links and
  concise observed summaries; no packet helpers, generated prompt artifacts, or
  per-run context workspaces unless a future owner doc changes that policy.
