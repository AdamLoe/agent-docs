# Workflow kit

`src/` is the source kit; `~/.agentdocs/` is the installed runtime that skills,
rules, and consuming-repo docs self-reference. The workflow lowers context by
routing work to focused roles, not by generating per-run context workspaces.
The fixed startup runtime-card is `~/.agentdocs/rules/skill-contracts.md`;
profile policy lives in `~/.agentdocs/rules/context-profiles.md`, generic
classification in lifecycle, dispatch shape in dispatch, and command inventory
in the registry. Mandatory startup is cache-first: read the runtime card,
needed manifest slots, and `docs/index.md`, then stop. `docs/overview.md` is
routed by task.

## Context layers

Cache-stable inputs are the router-only adapters,
`~/.agentdocs/rules/skill-contracts.md`, manifest startup slots, docs indexes,
and stable worker role cards. The task-specific layer is the smallest owning
slice: one architecture leaf, one decisions domain, one agent-context
procedure, selected plan/run docs, and needed source/tests. Ownership JSON and
repository layout are queried only for ownership or location questions. Never
auto-load architecture leaves, decisions, plans, run docs,
`~/.agentdocs/agent-docs-guide.md`, full ownership JSON, source files,
verifier output, or pitch material. Class word budgets live in
`~/.agentdocs/rules/authoring-rules.md`. Worker context profiles live in
`~/.agentdocs/rules/context-profiles.md` and are reported by
`~/.agentdocs/verify-agent-docs.sh --context-report`.

## Orchestrator/worker model

The kit is **subagent-first**. Every user-facing skill is an orchestrator entry
point: it classifies the request, chooses phases, dispatches workers with exact
rule routes, tracks evidence, and reports. Workers do planning, implementation,
review, maintenance, or verification.

An orchestrator only does a step inline when it is pure routing or IO under the
reads-vs-dispatch test: no broad reads, judgment call, mutation, or gate. Worker
dispatch is expected of the runtime; adapters report an error when unavailable.
Workers read authoritative docs and source directly when exact details,
judgment, or evidence matter. The orchestrator carries observed facts between
workers; it does not rewrite authoritative docs into generated summaries.

Rules live at the layer that owns them:

- **Universal** (`src/rules/*.md`) - what every skill needs regardless of role.
- **Orchestrator** (`src/rules/orchestrator/`) - lifecycle choice, dispatch
  packet shape, worker report shape, context profiles, commit concurrency, and
  opt-in run docs.
- **Subagent** (`src/rules/subagent/`) - one role's job card.
- **Context profiles** (`src/rules/context-profiles.md`) - exact core rule
  files, conditional overlays, mutation capability, and enforced budgets.
- **Skill body** (`src/skills/<name>/SKILL.md`) - one command's routing surface,
  profile IDs, worker phases, and closeout shape.

## Focused handoffs

The orchestrator is a knowledge intermediary, not the author of every
implementation detail. It passes each worker a minimal dispatch: role, task,
exact rule links, starting inputs, path plus heading/search hints for large
docs, observed facts to preserve, expected checks/evidence, and report shape.
Dispatch packets stay compact: no copied rules, generated prompt artifacts, or full
prior transcripts by default.

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

Worker reports are compact and self-contained. Routine reports name outcome,
observed basis, inspected sources, files, concise gate evidence, migrations,
blockers/risk, and commit or no-change state. Planning and review reports can be
longer, but still use short excerpts rather than transcripts unless the user
asks for full output. Runtime usage counts appear only when the runtime exposes
raw counts or the caller explicitly asks.

## Ship order

Mutating workflows converge on one final-state order:

1. Classify the request and choose the smallest safe lifecycle.
2. Plan or brief when needed; tracked plans are persisted by an explicit actor
   before plan review.
3. Implement owned slices, serializing editing on the shared tree.
4. Review shipped outcomes when risk warrants and route fixes to mutating
   workers.
5. Finish all mutations, including architecture/decisions, ownership metadata,
   plan frontmatter, and run-doc status.
6. Run the final consolidated drift gate after the last mutation.
7. Report commits, gates, migrations, assumptions, blockers, and residual risk
   from the verified final state.

Ship order is checkpoints, not a one-worker-per-step template. Editing workers
snapshot dirty state, preserve unrelated user changes and deletions, stage only
owned paths by filename, and commit their completed slice before reporting.
Review and verification workers are read-only; misses route back to
implementation, docs-maintenance, or plan-maintenance.

## Main surfaces

| Surface | Owns |
|---|---|
| `src/skills/*/` | Runnable workflow commands; `SKILL.md` is the prompt entry point and skill-local helper scripts may live beside it. |
| `src/skills/registry.md` | Skill inventory, mode/action metadata, intake style, and launch tier. |
| `src/verify-agent-docs.sh` | Kit drift gate; modes: `--context-report`, `--resolve`, `--measure-launch`, `--contract-check` (gating), `--scaffold`. |
| `src/rules/*.md` | Universal rules shared by every consuming repo: `skill-contracts.md`, `context-profiles.md`, `repo-rules.md`, `authoring-rules.md`, `coding-style.md`. |
| `src/rules/orchestrator/` | Orchestrator-facing workflow control: `lifecycle.md`, `dispatch.md`, and `run-docs.md`. |
| `src/rules/subagent/` | Worker-facing role rules: `planning.md`, `implementation.md`, `review.md`, `docs-maintenance.md`, `plan-maintenance.md`, `verification.md`. |
| `src/rules/coding-style-{rust,python,frontend}.md` | Language-idiom overlays (never auto-loaded). |
| `src/verify-fixtures/` | Verifier-only: `workflow-scenarios.json`, `baseline.md`. |
| `src/template/docs/` | Scaffold copied by `/rebuild-agent-docs`. |
| `src/agent-docs-guide.md` | Narrative guide for adopting the doc system. |
| `src/plan-lifecycle.md`, `src/plan-template.md` | Plan metadata and plan skeleton. |

Editing workers commit their own slice before reporting; later workers repair
with further commits. Editing is serial per working tree, and the orchestrator
verifies the final observed state after docs, plan-status, and run-doc
mutations.

## Workflow commands

After adding, renaming, or deleting a skill in `src/`, re-publish and verify:

```sh
bash install-agentdocs-local.sh
bash src/verify-agent-docs.sh
```

Before shipping agent-docs kit changes, run:

```sh
bash src/verify-agent-docs.sh
```

With no arguments, the verifier validates the agent-docs source checkout:
docs, manifest, ownership data, skill registry, template scaffold, context
profile contract, stale references, executable bits, and local adapter
freshness. Run from outside the source repo, it prints a `--scaffold`
directive and exits 0.

For profile inspection:

```sh
bash src/verify-agent-docs.sh --context-report
bash src/verify-agent-docs.sh --context-report --profile implementation.code
```

For a consuming repo, run the target-aware scaffold check:

```sh
bash ~/.agentdocs/verify-agent-docs.sh --scaffold .
```

That mode checks the target scaffold, manifest slots, ownership paths, routes,
and unresolved placeholders. It does not validate the source checkout.

- `/start-session` checks local git state, active plans, shipped cleanup
  candidates, and orchestration run docs, then routes into the owning skill.
- `/fresh-chat` starts ordinary work from the docs router.
- `/doctor` validates scaffold, manifest, ownership, skill registry, and stale
  reference health; consuming-repo scaffold checks use
  `~/.agentdocs/verify-agent-docs.sh --scaffold <repo-root>`.
- `/orchestrate` coordinates the quick-fix or plan/review/implement/review
  lifecycle through specialist workers. Medium or unclear work goes through a
  planning-worker brief before implementation.
- `/review-app` runs a confirmed read-only app audit for cleanup discovery,
  ranks findings by severity and cleanup ROI, and creates only approved plans.
- `/plan` shapes rough intent into discussion, implementer briefs, tracked
  plans, docs, or further questions.
- `/quick-fix` dispatches implementation only for already bounded fixes; unclear
  small work is first shaped by a planning worker or routed to `/plan`.
- `/ship-plans` implements named plans through verification, docs migration,
  plan shipping, and commit.
- `/review-shipped-work` reviews completed or in-progress work against named
  plans.
- `/review-plans` reviews named plans with a high-level or custom lens.
- `/check-plans-health` reviews the health of `docs/plans/`, including
  orchestration run folders under `docs/plans/orchestrator/`.
- `/review-skills` reviews this kit's skill suite for drift and lifecycle gaps.
- `/ship-current-work` finishes ordinary work and commits if gates pass.
- `/rebuild-agent-docs` adopts or repairs a repo's docs tree, then runs the
  scaffold verifier.
- `/wrap-up-current-chat` captures chat-only durable context.
- `/clear-plans` cleans shipped or abandoned plans and orchestration run docs
  after migration.
- `/feedback-agent-docs` records a kit-level comment or request into the
  runtime inbox at `~/.agentdocs/feedback.jsonl`, which is preserved across
  installer runs.
- `/list-skills` reports the canonical source skill inventory, project-local
  skill directories, and Claude/Codex adapter freshness.

## Command routing

Use the smallest command that owns the current job:

| Job | Command |
|---|---|
| Start a day/session by checking local git, plans, and cleanup candidates | `/start-session` |
| Start a normal chat and wait for the task | `/fresh-chat` |
| Fix one bounded issue now | `/quick-fix` |
| Shape rough direction into implementer-ready material | `/plan` |
| Discover broad cleanup work through a configured app audit before planning fixes | `/review-app` |
| Coordinate a broad change across planning, implementation, and review | `/orchestrate` |
| Implement existing plan files | `/ship-plans` |
| Verify shipped or in-progress plan work | `/review-shipped-work` |
| Finish the current dirty tree | `/ship-current-work` |
| Check scaffolding and mechanical drift | `/doctor`, `/check-docs-drift`, `/fix-docs-drift` |
| Review doc or plan quality | `/review-docs-shape`, `/review-plans`, `/check-plans-health` |

## See also

- [`../../src/agent-docs-guide.md`](../../src/agent-docs-guide.md)
- [`install-and-adapters.md`](install-and-adapters.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md)
- [`../../src/rules/orchestrator/`](../../src/rules/orchestrator/)
- [`../../src/rules/subagent/`](../../src/rules/subagent/)
- [`../../src/rules/authoring-rules.md`](../../src/rules/authoring-rules.md)
