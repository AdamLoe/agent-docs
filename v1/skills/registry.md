# agent-docs skill registry

This is the shared inventory for `v1/skills/*/SKILL.md`. It keeps workflow
facts out of individual skills when they apply to the suite as a whole.

**Intake**: `two-question` skills run the Standard Intake Protocol and, when
launched without context, ask the dial + task questions and wait. `direct`
skills operate on existing disk/git state and skip the questions (honoring
any dials passed in). **Launch tier** is the recommended model to launch the
skill on, per the kit Model Policy (planning/review → strong; implementation
and mechanical work → mid). Both are defined in `v1/rules/skill-contracts.md`.

## Start and plan

| Skill | Mode | Action | Commits | Intake | Launch | Normal Input |
|---|---|---|---|---|---|---|
| `start-session` | bootstrap | inspect local repo and plan state, then route to the owning workflow skill | only through routed skills | direct | mid | optional task or dials |
| `fresh-chat` | bootstrap | load docs router for ordinary work | no | two-question | any | user's first task |
| `plan` | planning | shape app-state thoughts into briefs, plans, or discussion | only if it edits tracked docs/plans | two-question | strong | planning context |
| `orchestrate` | lifecycle orchestration | orchestrate quick-fix through plan/review/implement/review lifecycle | yes, through implementer/reviewer shipping | two-question | strong | change request |

## Implement and finish

| Skill | Mode | Action | Commits | Intake | Launch | Normal Input |
|---|---|---|---|---|---|---|
| `quick-fix` | mutating | fix one bounded problem | yes | two-question | mid | problem statement |
| `ship-plans` | mutating | implement named plans end to end | yes | two-question | mid | plan paths |
| `ship-current-work` | mutating | finish current repo work | yes | direct | mid | current diff |
| `clear-plans` | mutating | migrate/delete shipped or abandoned plans | yes, through green shipping semantics | direct | mid | optional scope |
| `rebuild-agent-docs` | mutating | adopt or repair the docs scaffold | yes, through green shipping semantics | direct | mid | docs path / dial hints |
| `wrap-up-current-chat` | mutating | migrate this chat's durable knowledge | yes, through green shipping semantics | direct | mid | optional notes |

## Review and maintain

| Skill | Mode | Action | Commits | Intake | Launch | Normal Input |
|---|---|---|---|---|---|---|
| `review-shipped-work` | review with optional fixes | review work against named plans | yes, only if it makes fixes | two-question | strong | plan paths |
| `review-plans` | report-only by default | critique named plans with a high-level or custom lens | only if user asks to apply edits | two-question | strong | plan paths and optional custom lens |
| `review-plans-health` | report-only | review `docs/plans/` hygiene | no | direct | mid | optional scope |
| `review-docs-shape` | report-only | editorial review of docs shape and direction | no | direct | strong | doc/subtree scope |
| `review-skills` | report-only | review this skill suite for drift and gaps | no | direct | strong | optional lens |
| `check-docs` | report-only | check named docs for mechanical drift | no | two-question | mid | doc paths |
| `fix-docs-drift` | mutating | repair docs drift across the tree | yes | direct | mid | optional scope/dials |
| `doctor` | report-only by default | validate scaffold, manifest, ownership, registry, and stale references | only if user asks to fix failures | direct | mid | optional scope |
| `list-skills` | report-only | list discoverable skills | no | direct | mid | optional filter |
| `feedback-agent-docs` | capture | record kit feedback into the upstream inbox | no (writes the kit inbox, not the repo) | direct | mid | optional feedback content |

Suite-wide policy lives in `v1/rules/skill-contracts.md`; repo/git policy
lives in `v1/rules/repo-rules.md`.
