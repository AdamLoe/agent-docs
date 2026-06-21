# Skill contracts (agent-docs v1)

GENERIC. App-independent. The short startup contract read by every
`~/.agentdocs/skills/*/SKILL.md`. Keep only fixed startup behavior and
adapter-neutral defaults here; deeper orchestration, mode, shipping, and registry
policy lives with the owners linked under Owner Pointers — do not copy it back.

Expanded rationale + examples (do not auto-load):
[`skill-contracts-reference.md`](skill-contracts-reference.md).

## Standard Intake Protocol

Run this exact cache-first startup order:

1. Read this file.
2. Read `docs/_meta/manifest.md` for `repo_name`, `code_root`, and any task slots
   needed (`change-to-doc`, `drift-gates`, `drift-verification`,
   `decisions-domains`).
3. Read `docs/index.md`.
4. **Stop.** Do not load `docs/overview.md`, more rules,
   architecture/decisions/agent-context, plans, templates, registry, ownership,
   or source until the task state says they are needed.

Then branch:

- **Context present** — `$ARGUMENTS` or the user message already carries a
  substantive task, paths, or lens. Treat it as the first answer, parse any
  dials, proceed.
- **Context absent, `asks` skill** — ask exactly two batched questions, then
  wait: one multiple-choice for the two dials (`review-medium`/`cost-medium`
  preselected) and one open-ended "what do you want to do?" Never guess the task
  or offer a menu.
- **Context absent, `no-prompt`/state-driven skill** — skip generic intake
  questions; run from disk, git, or argument state. Honor dials that affect the
  work; pure utilities may ignore inert dials. A capture skill may ask for
  missing payload, not for generic intake.

Use the skill body or `~/.agentdocs/skills/registry.md` Intake column to identify
`asks` vs. `no-prompt`. Query `docs/_meta/ownership.json` only for ownership
questions. Treat `docs/overview.md` as a task-routed doc from `docs/index.md`,
not mandatory startup.

## Dials

Two axes tune every skill; both default to `medium` unless the user names them.

- **`review-[none|low|medium|high|max]`** — how much the skill stops for human
  review and how hard review workers work.
- **`cost-[low|medium|high|max]`** — how freely to spend on worker fan-out,
  stronger models, and worker-output budget.

Only `review-none` has a hard meaning: skip human-review checkpoints — never
automated verification, drift gates, or the questioning that makes work
well-defined. Everything else is guidance: higher asks/fans-out/escalates more;
lower decides locally and stays cheaper. `cost-*` controls fan-out and model
spend; `review-*` controls human and review-worker intensity. Neither dial
decides *whether* workers are used. `cost-max` has no hard output cap but records
a budget-exception reason before broad fan-out. Old tags: `skip-review` →
`review-none`, `heavy-review` → `review-high`/`max`, `cheap-agents` →
`cost-low`, `no-cost-limit` → `cost-max`.

## Model Policy

Use role names so adapters map locally: `cheap`, `mid-tier`, `strong`,
`strongest`. Routine implementation, verification, mechanical docs, and bounded
investigation default to `mid-tier`. Escalate to `strong`/`strongest` for
security/auth, migrations, destructive behavior, public APIs, concurrency, hard
algorithms, conflicting sources, unclear acceptance, repeated failures, or weak
verification. A skill's launch tier is recorded in
`~/.agentdocs/skills/registry.md` (`mid` maps to `mid-tier`); dispatched workers
follow the role mapping above regardless of launch tier.

## Human Stops

Stop for the user only when an answer changes what should be built, reviewed, or
shipped and cannot be resolved from code, docs, precedent, or the request. Every
stop states the decision needed, why it changes the work, the fewest concrete
questions, and a recommended default when one is defensible. A vague blocker is
not a stop — keep investigating until the question is concrete.

## Verification Fallbacks

Run relevant gates whenever practical. A skipped gate is not green. If a gate
cannot run, report the command attempted, why it failed or was unavailable, the
cheaper check you ran instead, and the residual risk.

## Owner Pointers

- **Orchestration** — [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md),
  [`orchestrator/dispatch.md`](orchestrator/dispatch.md).
- **Context profiles** — [`context-profiles.md`](context-profiles.md). Name
  profile IDs and overlays, not rule lists.
- **Modes and registry** — [`../skills/registry.md`](../skills/registry.md).
- **Shipping** — [`orchestrator/dispatch.md`](orchestrator/dispatch.md),
  [`repo-rules.md`](repo-rules.md), [`subagent/`](subagent/).
- **Generated context** — dispatches stay plain text with exact rule links and
  concise observed summaries; no packet helpers, prompt artifacts, or per-run
  context workspaces unless a future owner doc changes that policy.

## See also

- [`skill-contracts-reference.md`](skill-contracts-reference.md) — rationale (do not auto-load).
- [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md)
- [`orchestrator/dispatch.md`](orchestrator/dispatch.md)
- [`context-profiles.md`](context-profiles.md)
- [`../skills/registry.md`](../skills/registry.md)
