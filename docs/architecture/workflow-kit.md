# Workflow kit

`v1/` is the stable and active kit version. The workflow lowers context by
routing work to focused roles, not by generating per-run context workspaces.
The fixed startup runtime-card is `v1/rules/skill-contracts.md`; it stays short
and points to lifecycle, dispatch, and registry owner docs for deeper policy.

## Orchestrator/worker model

The kit is **subagent-first**. Every user-facing skill is an orchestrator entry
point: it classifies the request, chooses lifecycle phases, dispatches workers
with exact rule-file routes, tracks observed evidence, and reports to the human.
Workers do the planning, implementation, review, maintenance, or verification.

An orchestrator only does a step inline when it is pure routing or IO under the
reads-vs-dispatch test: read across no more than a couple of files, no
defensible judgment call, no mutation, and no gate. Worker dispatch is expected
of the runtime; an adapter that cannot spawn a required worker reports an error.

Rules live at the layer that owns them:

- **Universal** (`v1/rules/*.md`) - what every skill needs regardless of role.
- **Orchestrator** (`v1/rules/orchestrator/`) - lifecycle choice, dispatch
  packet shape, worker report shape, rule bundles, commit concurrency, and
  opt-in run docs.
- **Subagent** (`v1/rules/subagent/`) - one role's job card.
- **Skill body** (`v1/skills/<name>/SKILL.md`) - one command's routing surface,
  local context needs, worker phases, and closeout shape.

## Focused handoffs

The orchestrator is a knowledge intermediary, not the author of every
implementation detail. It passes each worker a minimal dispatch: role, task,
exact rule links, starting inputs, observed facts to preserve, expected
checks/evidence, and report shape.

When work is ambiguous or medium-sized, a planning worker spends the context to
investigate and return an implementation brief. That brief is plain Markdown,
not a generated packet or helper output. The standard brief shape is:

```text
Goal:
Non-goals:
Authoritative docs:
Likely source areas:
Expected behavior:
Implementation notes:
Cheapest sufficient checks:
Stop and report if:
Open decisions:
```

Implementation workers receive either a bounded task or the planner's brief.
They discover source files and tests inside that slice, run the cheapest
sufficient gate, update durable docs when required, commit, and report. They do
not switch into planning, review, or lifecycle closeout work on their own.

Between workers, the orchestrator carries forward a concise observed summary:
decisions made, facts proven, files or docs touched, gates and outputs, commits,
blockers, and assumptions. The next worker gets that summary instead of the full
prior transcript.

## Main surfaces

| Surface | Owns |
|---|---|
| `v1/skills/*/` | Runnable workflow commands; `SKILL.md` is the prompt entry point and skill-local helper scripts may live beside it. |
| `v1/skills/registry.md` | Skill inventory and mode/action metadata. |
| `v1/copy-skills.sh` | Refreshes copied agent-docs skills in Claude and Codex user skill directories after skill changes. |
| `v1/verify-agent-docs.sh` | Non-mutating kit drift gate; `--scaffold <repo-root>` checks a target repo's docs scaffold. |
| `v1/rules/*.md` | Universal rules shared by every consuming repo: `skill-contracts.md`, `repo-rules.md`, `authoring-rules.md`, `coding-style.md`. |
| `v1/rules/orchestrator/` | Orchestrator-facing workflow control: `lifecycle.md`, `dispatch.md`, and `run-docs.md`. |
| `v1/rules/subagent/` | Worker-facing role rules: `planning.md`, `implementation.md`, `review.md`, `docs-maintenance.md`, `plan-maintenance.md`, `verification.md`. |
| `v1/template/docs/` | Scaffold copied by `/rebuild-agent-docs`. |
| `v1/agent-docs-guide.md` | Narrative guide for adopting the doc system. |
| `v1/plan-lifecycle.md`, `v1/plan-template.md` | Plan metadata and plan skeleton. |

The workflow is commit-heavy: editing workers commit their own slice before
reporting, follow-up workers repair or revert with further commits, editing is
serial per working tree, and parallel editing uses worktree isolation or
orchestrator-applied patches. The orchestrator records commit hashes and verifies
the final observed state.

## Workflow commands

After adding, renaming, or deleting a skill, run:

```sh
bash ~/agent-docs/v1/copy-skills.sh ~/agent-docs
bash ~/agent-docs/v1/copy-skills.sh --check ~/agent-docs
```

Before shipping agent-docs kit changes, run:

```sh
bash ~/agent-docs/v1/verify-agent-docs.sh
```

With no arguments, the verifier validates the `agent-docs` checkout that
contains the script: this repo's docs, manifest, ownership data, skill registry,
template scaffold, stale references, executable bits, and local copied adapter
freshness. Its output labels the kit-repo checks, scaffold-template checks, and
local adapter freshness check separately.

For a consuming repo, run the target-aware scaffold check from that repo root or
pass an explicit target:

```sh
bash ~/agent-docs/v1/verify-agent-docs.sh --scaffold .
```

That mode checks the target `docs/` scaffold, manifest slots, ownership paths,
top-level routes, and unresolved seed placeholders. It does not validate the
agent-docs kit checkout or copied local adapters. Copied adapter freshness stays
owned by `v1/copy-skills.sh --check`.

- `/start-session` checks local git state, active plans, shipped cleanup
  candidates, and orchestration run docs, then routes into the owning skill.
- `/fresh-chat` starts ordinary work from the docs router.
- `/doctor` validates scaffold, manifest, ownership, skill registry, and stale
  reference health; consuming-repo scaffold checks use
  `v1/verify-agent-docs.sh --scaffold <repo-root>`.
- `/orchestrate` coordinates the quick-fix or plan/review/implement/review
  lifecycle through specialist workers. Medium or unclear work goes through a
  planning-worker brief before implementation.
- `/plan` shapes rough intent into discussion, implementer briefs, tracked
  plans, docs, or further questions.
- `/quick-fix` dispatches implementation only for already bounded fixes; unclear
  small work is first shaped by a planning worker or routed to `/plan`.
- `/ship-plans` implements named plans through verification, docs migration,
  plan shipping, and commit.
- `/review-shipped-work` reviews completed or in-progress work against named
  plans.
- `/review-plans` reviews named plans with a high-level or custom lens.
- `/review-plans-health` reviews the health of `docs/plans/`, including
  orchestration run folders under `docs/plans/orchestrator/`.
- `/review-skills` reviews this kit's skill suite for drift and lifecycle gaps.
- `/ship-current-work` finishes ordinary work and commits if gates pass.
- `/rebuild-agent-docs` adopts or repairs a repo's docs tree, then verifies the
  target scaffold with `v1/verify-agent-docs.sh --scaffold <repo-root>`.
- `/wrap-up-current-chat` captures chat-only durable context.
- `/clear-plans` cleans shipped or abandoned plans and orchestration run docs
  after migration.
- `/feedback-agent-docs` records a kit-level comment or request from a consuming
  repo into the upstream inbox at `~/agent-docs/feedback/inbox.jsonl`.

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
- [`../../v1/rules/orchestrator/`](../../v1/rules/orchestrator/)
- [`../../v1/rules/subagent/`](../../v1/rules/subagent/)
- [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md)
