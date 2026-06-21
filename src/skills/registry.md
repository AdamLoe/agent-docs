# agent-docs skill registry

This is the shared inventory for `~/.agentdocs/skills/*/SKILL.md`. It keeps workflow facts
out of individual skills when they apply to the suite as a whole. Every skill is
an orchestrator entry point; see `~/.agentdocs/rules/skill-contracts.md`,
`~/.agentdocs/rules/context-profiles.md`, and `~/.agentdocs/rules/orchestrator/`.

**Worker roles** names the subagent roles a skill normally dispatches
(`planning`, `implementation`, `review`, `docs-maintenance`, `plan-maintenance`,
`verification`), or `routes` when the skill mainly hands off to another skill, or
`none (inline)` for pure routing/IO utilities. **Commits** records whether the
workflow produces commits, which happen through editing workers, not an inline
top-level commit. **Intake**: `asks` skills run the two-question intake when
launched without context; `no-prompt` skills operate on existing disk/git state
and run directly (honoring any dials passed in). **Launch tier** is the
recommended model to launch the skill on: `cheap`, `mid`, `strong`, or
`strongest`. All are defined in `~/.agentdocs/rules/skill-contracts.md`.
Context profile IDs and mutation capability are defined only in
`~/.agentdocs/rules/context-profiles.md`; registry rows remain inventory metadata.

## Start and plan

| Skill | Mode | Action | Worker roles | Commits | Intake | Launch | Normal Input |
|---|---|---|---|---|---|---|---|
| `start-session` | bootstrap | inspect local repo and plan state, then route to the owning workflow skill | routes; plan-maintenance, review, verification | only through routed skills | no-prompt | mid | optional task or dials |
| `fresh-chat` | bootstrap | load docs router and route ordinary work | routes; optional review/docs-maintenance | no | asks | mid | user's first task |
| `plan` | planning | shape app-state thoughts into briefs, plans, or discussion | planning, review, docs-maintenance | only if it edits tracked docs/plans (via workers) | asks | strong | planning context |
| `orchestrate` | lifecycle orchestration | orchestrate quick-fix through plan/review/implement/review lifecycle | planning, review, implementation, verification, plan-maintenance | yes, via workers | asks | strong | change request |

## Implement and finish

| Skill | Mode | Action | Worker roles | Commits | Intake | Launch | Normal Input |
|---|---|---|---|---|---|---|---|
| `quick-fix` | mutating | fix one bounded problem | implementation, verification, review | yes, via worker | asks | mid | problem statement |
| `ship-plans` | mutating | implement named plans end to end | implementation, planning, review, verification, plan-maintenance | yes, via workers | asks | mid | plan paths |
| `ship-current-work` | mutating | finish current repo work | review, docs-maintenance, plan-maintenance, verification, implementation | yes, via workers | no-prompt | mid | current diff |
| `clear-plans` | mutating | migrate/delete shipped or abandoned plans | plan-maintenance, docs-maintenance, verification | yes, via plan-maintenance worker | no-prompt | mid | optional scope |
| `rebuild-agent-docs` | mutating | adopt or repair the docs scaffold | docs-maintenance, implementation, verification, plan-maintenance | yes, via workers | no-prompt | mid | docs path / dial hints |
| `wrap-up-current-chat` | mutating | migrate this chat's durable knowledge | docs-maintenance, plan-maintenance, verification | yes, via docs-maintenance worker | no-prompt | mid | optional notes |

## Review and maintain

| Skill | Mode | Action | Worker roles | Commits | Intake | Launch | Normal Input |
|---|---|---|---|---|---|---|---|
| `review-app` | review with approved planning | run a configured app audit, report findings, then create approved cleanup plans | review, planning, plan-maintenance, verification | yes, via plan-maintenance worker for opted-in run docs and approved plans | asks | strong | app scope, lenses, run-doc choice, plan approval |
| `review-shipped-work` | review with optional fixes | review work against named plans | review, implementation, docs-maintenance, plan-maintenance, verification | yes, only if a fix worker runs | asks | strong | plan paths |
| `review-plans` | report-only by default | critique named plans with a high-level or custom lens | review, planning | only if user asks to apply edits | asks | strong | plan paths and optional custom lens |
| `review-plans-health` | report-only | review `docs/plans/` hygiene | plan-maintenance, review | no | no-prompt | mid | optional scope |
| `review-docs-shape` | report-only | editorial review of docs shape and direction | docs-maintenance, review | no | no-prompt | strong | doc/subtree scope |
| `review-skills` | report-only | review this skill suite for drift and gaps | review, docs-maintenance, verification | no | no-prompt | strong | optional lens |
| `check-docs` | report-only | check named docs for mechanical drift | docs-maintenance, verification | no | asks | mid | doc paths |
| `fix-docs-drift` | mutating | repair docs drift across the tree | docs-maintenance, review, verification, implementation | yes, via workers | no-prompt | mid | optional scope/dials |
| `doctor` | report-only by default | validate scaffold, manifest, ownership, registry, and stale references | verification, docs-maintenance, implementation | only if user asks to fix failures | no-prompt | mid | optional scope |
| `list-skills` | report-only | list source skills and adapter freshness | none (inline); optional verification | no | no-prompt | mid | optional filter |
| `feedback-agent-docs` | capture | record kit feedback into the upstream inbox | none (inline); optional docs-maintenance | no (writes the gitignored kit inbox) | no-prompt | mid | optional feedback content |

Suite-wide policy lives in `~/.agentdocs/rules/skill-contracts.md`; orchestrator policy in
`~/.agentdocs/rules/orchestrator/`; worker-role rules in `~/.agentdocs/rules/subagent/`; repo/git
policy in `~/.agentdocs/rules/repo-rules.md`.
