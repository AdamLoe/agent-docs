# Workflow kit

`v1/` is the current kit version.

## Main surfaces

| Surface | Owns |
|---|---|
| `v1/skills/*/SKILL.md` | Runnable workflow commands. |
| `v1/skills/registry.md` | Skill inventory and mode/action metadata. |
| `v1/copy-skills.sh` | Refreshes copied agent-docs skills in Claude and Codex user skill directories after skill changes. |
| `v1/verify-agent-docs.sh` | Non-mutating drift gate for scaffold, manifest, ownership, registry, adapter, and stale-reference checks. |
| `v1/rules/*.md` | Generic rules shared by every consuming repo. |
| `v1/rules/skill-contracts.md` | Shared contracts for skill modes, bootstrap, shipping, registry, and model language. |
| `v1/template/docs/` | Scaffold copied by `/rebuild-agent-docs`. |
| `v1/agent-docs-guide.md` | Narrative guide for adopting the doc system. |
| `v1/plan-lifecycle.md`, `v1/plan-template.md` | Plan metadata and plan skeleton. |

## Workflow commands

After adding, renaming, or deleting a skill, run
`bash ~/agent-docs/v1/copy-skills.sh ~/agent-docs`, then
`bash ~/agent-docs/v1/copy-skills.sh --check ~/agent-docs`, so Claude and
Codex can discover the updated skill set from their copied user skill
directories.

Before shipping repo changes, run `bash ~/agent-docs/v1/verify-agent-docs.sh`
from any working directory. The verifier owns this repo's non-mutating drift
gate and delegates copied-adapter freshness to `v1/copy-skills.sh --check`.

- `/fresh-chat` starts ordinary work from the docs router.
- `/agent-docs-doctor` validates scaffold, manifest, ownership, skill
  registry, and stale reference health.
- `/orchestrate` asks for a change request, then coordinates the
  quick-fix or plan/review/implement/review lifecycle through specialist
  agents.
- `/plan` shapes app-state thoughts into implementer briefs, tracked plans,
  docs, or further discussion.
- `/quick-fix` fixes a small problem directly and commits when green.
- `/implement-plans` implements named plans through verification, docs
  migration, plan shipping, and commit.
- `/review-work` reviews completed or in-progress work against named plans.
- `/review-plans-health` reviews the health of `docs/plans/`.
- `/review-plans-custom` reviews named plans with a custom user-provided lens.
- `/review-agent-docs-skills` reviews this kit's skill suite for drift and
  lifecycle gaps.
- `/ship-current-work` finishes ordinary work and commits if gates pass.
- `/rebuild-agent-docs` adopts or repairs a repo's docs tree.
- `/wrap-up-current-chat` captures chat-only durable context.
- `/clear-plans` cleans shipped or abandoned plans after migration.
- `/lodge-agent-docs-feedback` records a kit-level comment or request from a
  consuming repo into the upstream inbox at `~/agent-docs/feedback/inbox.jsonl`.

## Command routing

Use the smallest command that owns the current job:

| Job | Command |
|---|---|
| Start a normal chat and wait for the task | `/fresh-chat` |
| Fix one bounded issue now | `/quick-fix` |
| Shape rough direction into implementer-ready material | `/plan` |
| Coordinate a broad change across planning, implementation, and review | `/orchestrate` |
| Implement existing plan files | `/implement-plans` |
| Verify shipped or in-progress plan work | `/review-work` |
| Finish the current dirty tree | `/ship-current-work` |
| Check scaffolding and mechanical drift | `/agent-docs-doctor`, `/check-docs-consistency-some`, `/fix-docs-drift-all` |
| Review doc or plan quality | `/review-docs`, `/review-plans-high-level`, `/review-plans-custom`, `/review-plans-health` |

## See also

- [`../../v1/agent-docs-guide.md`](../../v1/agent-docs-guide.md)
- [`install-and-adapters.md`](install-and-adapters.md)
- [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md)
