# Skill contracts (agent-docs v1)

GENERIC. App-independent. This is the short startup contract read by every
`v1/skills/*/SKILL.md`. Keep only fixed startup behavior and adapter-neutral
defaults here. Deeper orchestration, mode, shipping, and registry policy lives
in the owner docs linked below; do not copy those sections back into this file or
individual skill bodies.

## Standard Intake Protocol

Run this exact cache-first startup order:

1. Read this file.
2. Read `docs/_meta/manifest.md` for `repo_name`, `code_root`, and any task
   slots needed (`change-to-doc`, `drift-gates`, `drift-verification`,
   `decisions-domains`).
3. Read `docs/index.md`.
4. Stop. Do not load `docs/overview.md`, more rules,
   architecture/decisions/agent-context docs, plans, templates, registry,
   ownership, or source until the task state says they are needed.

Then branch:

- **Context present** - `$ARGUMENTS` or the user message already contains a
  substantive task, target paths, or custom lens. Treat it as the first answer,
  parse any dials, and proceed.
- **Context absent, `asks` skill** - ask exactly two batched questions, then
  wait: one multiple-choice for the two dials with `review-medium` and
  `cost-medium` preselected, and one open-ended "what do you want to do?" Never
  guess the task or offer a task menu.
- **Context absent, `no-prompt` or state-driven skill** - skip the generic
  intake questions and run from existing disk, git, or argument state. Honor
  dials where they affect the work; pure utilities may ignore inert dials. A
  capture skill may ask for missing payload content, but not for generic
  task/dial intake.

Use the skill body or `v1/skills/registry.md` Intake column to identify
`asks` vs. `no-prompt`. Query `docs/_meta/ownership.json` only for ownership
questions; do not bulk-load it. Treat `docs/overview.md` as a normal
task-routed doc from `docs/index.md`: read it for system-shape orientation,
docs-shape review, scaffold repair, or another explicit task need, not as part
of mandatory startup.

## Human Stops

Stop for the user only when an answer changes what should be built, reviewed, or
shipped and cannot be resolved from code, docs, precedent, or the user's request.
Every stop states the decision needed, why it changes the work, the fewest
concrete questions needed, and a recommended default when one is defensible.

Do not stop with a vague blocker. If the question is not concrete yet, keep
investigating or run the appropriate planning/review pass until it is.

## Verification Fallbacks

Run relevant gates whenever practical. If a gate cannot run, report the command
attempted, why it failed or was unavailable, what cheaper check you ran instead,
and the residual risk. A skipped gate is not green.

## Usage Reporting

When a runtime exposes raw token counts, worker reports may include the optional
usage block defined in `orchestrator/dispatch.md`. When it does not, reports use
`unavailable_reason`. Do not invent counts, infer cache metrics, or translate
usage into vendor pricing.

## Dials

Two axes tune every skill. The user sets them by naming them; otherwise both
default to `medium`.

- **`review-[none|low|medium|high|max]`** - how much the skill stops for human
  review and how hard review workers work.
- **`cost-[low|medium|high|max]`** - how freely to spend on worker fan-out,
  stronger models, and worker-output budget.

Only `review-none` has a hard meaning: skip human-review checkpoints. It never
skips automated verification, drift gates, or the original questioning needed to
make work well-defined. Everything else is guidance: higher asks a bit more,
fans out more, and reaches for stronger models when useful; lower decides more
locally and stays cheaper. `cost-*` controls fan-out and model spend; `review-*`
controls human and review-worker intensity. Neither dial decides whether workers
are used.

`cost-max` has no hard output cap, but every `cost-max` run records a
budget-exception reason before spawning broad workers or accepting long reports.
Skills may declare a non-`medium` default. Old tags map in: `skip-review` ->
`review-none`, `heavy-review` -> `review-high`/`review-max`, `cheap-agents` ->
`cost-low`, `no-cost-limit` -> `cost-max`.

## Model Policy

Use role-based names so adapters can map them locally: `cheap`, `mid-tier`,
`strong`, `strongest`.

- Planning and review use `strong`.
- Implementation, bounded investigation, verification, mechanical docs, and
  routine work use `mid-tier` by default.
- `cost-low` pushes work down to `mid-tier`/`cheap`; `cost-max` permits strong
  workers freely; `review-high`/`review-max` adds a strong red-team or second
  opinion where useful.

A skill's launch tier is recorded in `v1/skills/registry.md` as `cheap`, `mid`,
`strong`, or `strongest`; `mid` maps to the `mid-tier` role above. Dispatched
workers follow the role mapping above regardless of launch tier.

## Owner Pointers

- **Orchestration.** User-facing skills are orchestrator entry points. The
  reads-vs-dispatch boundary, lifecycle choices, worker packets, dispatch
  failure behavior, and commit concurrency live in
  [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md) and
  [`orchestrator/dispatch.md`](orchestrator/dispatch.md).
- **Modes and registry.** The skill inventory, mode/action names, worker roles,
  commit behavior, intake style, launch tier, and normal inputs live in
  [`../skills/registry.md`](../skills/registry.md).
- **Shipping.** Mutating skills finish by confirming the diff, migrating owning
  docs when needed, running targeted and manifest gates, staging by filename,
  committing when green, and never pushing unless told. Details live in
  [`orchestrator/dispatch.md`](orchestrator/dispatch.md),
  [`repo-rules.md`](repo-rules.md), and [`subagent/`](subagent/).
- **Generated context.** Dispatches stay plain text with exact rule links and
  concise observed summaries; do not create packet helpers or generated context
  bundles unless a future owner doc changes that policy.

## See also

- [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md)
- [`orchestrator/dispatch.md`](orchestrator/dispatch.md)
- [`../skills/registry.md`](../skills/registry.md)
