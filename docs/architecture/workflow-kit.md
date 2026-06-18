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

- `/start-session` checks local git state, active plans, shipped cleanup
  candidates, and orchestration run docs at the start of a day or coding
  session. It routes into the owning skill instead of duplicating workflow
  logic: `clear-plans` for safe disposable plan material,
  `ship-current-work` for dirty coherent work, `ship-plans` or
  `review-shipped-work` for active plan work, and `plan`, `quick-fix`, or
  `orchestrate` for a supplied next task.
- `/fresh-chat` starts ordinary work from the docs router.
- `/doctor` validates scaffold, manifest, ownership, skill
  registry, and stale reference health.
- `/orchestrate` asks for a change request, then coordinates the
  quick-fix or plan/review/implement/review lifecycle through specialist
  agents. Its default state lives in chat, subagent reports, and ordinary
  plans already in play. When the user asks for run docs or grants permission
  after a resume-risk prompt, it may create
  `docs/plans/orchestrator/<run-slug>/` with a required `hub.md`, stream
  notes, and optional findings. The hub carries plan-style lifecycle metadata
  so cleanup tools can treat the run folder as disposable plan material after
  durable facts migrate.
- `/plan` shapes app-state thoughts into implementer briefs, tracked plans,
  docs, or further discussion.
- `/quick-fix` fixes a small problem directly and commits when green.
- `/ship-plans` implements named plans through verification, docs
  migration, plan shipping, and commit.
- `/review-shipped-work` reviews completed or in-progress work against named plans.
- `/review-plans` reviews named plans with a high-level or custom lens.
- `/review-plans-health` reviews the health of `docs/plans/`, including
  orchestration run folders under `docs/plans/orchestrator/`.
- `/review-skills` reviews this kit's skill suite for drift and
  lifecycle gaps.
- `/ship-current-work` finishes ordinary work and commits if gates pass.
- `/rebuild-agent-docs` adopts or repairs a repo's docs tree.
- `/wrap-up-current-chat` captures chat-only durable context.
- `/clear-plans` cleans shipped or abandoned plans and orchestration run
  folders after migration. It deletes only clean tracked plan/run-doc material
  so the latest deleted content remains recoverable from local git history.
- `/feedback-agent-docs` records a kit-level comment or request from a
  consuming repo into the upstream inbox at `~/agent-docs/feedback/inbox.jsonl`.

## Command routing

Use the smallest command that owns the current job:

| Job | Command |
|---|---|
| Start a day/session by checking local git, plans, and cleanup candidates | `/start-session` |
| Start a normal chat and wait for the task | `/fresh-chat` |
| Fix one bounded issue now | `/quick-fix` |
| Shape rough direction into implementer-ready material | `/plan` |
| Coordinate a broad change across planning, implementation, and review | `/orchestrate` |
| Implement existing plan files | `/ship-plans` |
| Verify shipped or in-progress plan work | `/review-shipped-work` |
| Finish the current dirty tree | `/ship-current-work` |
| Check scaffolding and mechanical drift | `/doctor`, `/check-docs`, `/fix-docs-drift` |
| Review doc or plan quality | `/review-docs-shape`, `/review-plans`, `/review-plans-health` |

## See also

- [`../../v1/agent-docs-guide.md`](../../v1/agent-docs-guide.md)
- [`install-and-adapters.md`](install-and-adapters.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../../v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md)
- [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md)
