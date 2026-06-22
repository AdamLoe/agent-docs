# Workflow kit

`src/` is the source kit; `~/.agentdocs/` is the installed runtime that skills,
rules, and consuming-repo docs self-reference. The workflow lowers context by
routing work to focused roles, not by generating per-run context workspaces.
The fixed startup runtime-card is `~/.agentdocs/rules/skill-contracts.md`. The
**machine authority** for profiles, scenarios, per-skill workflows, and packs is
the kernel under `src/kernel/*.json`; `~/.agentdocs/rules/context-profiles.md` is
the **human contract** that names those facts in prose but no longer owns them.
Generic classification lives in lifecycle, dispatch shape in dispatch, command
inventory in the registry. Mandatory startup is cache-first: read the runtime
card, needed manifest slots, and `docs/index.md`, then stop. `docs/overview.md`
is routed by task.

## Context layers

Cache-stable inputs are the router-only adapters,
`~/.agentdocs/rules/skill-contracts.md`, manifest startup slots, docs indexes,
and stable worker role cards. The task-specific layer is the smallest owning
slice: one architecture leaf, one decisions domain, one agent-context
procedure, selected plan/run docs, and needed source/tests. Ownership JSON and
repository layout are queried only for ownership or location questions. Never
auto-load architecture leaves, decisions, plans, run docs,
`~/.agentdocs/agent-docs-guide.md`, the kernel JSON, full ownership JSON, source
files, verifier output, or pitch material. Class word budgets live in
`~/.agentdocs/rules/authoring-rules.md`. Worker context profiles are owned by the
kernel (`src/kernel/profiles.json`), described in prose by
`~/.agentdocs/rules/context-profiles.md`, and reported by
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
- **Kernel** (`src/kernel/{profiles,scenarios,workflows,packs}.json`) - the sole
  machine authority for profiles (paths/overlays/mutation/budgets), scenario rows,
  per-skill workflow IDs, and pack triggers, read by `src/verify-agent-docs.sh`.
- **Context profiles** (`src/rules/context-profiles.md`) - the human contract;
  the kernel owns the facts.
- **Skill body** (`src/skills/<name>/SKILL.md`) - one command's routing surface,
  profile IDs, worker phases, and closeout shape.

## Focused handoffs

The orchestrator is a knowledge intermediary, not the author of every
implementation detail. It passes each worker a minimal dispatch: role, task,
exact rule links, starting inputs, path plus heading/search hints for large docs,
observed facts to preserve, expected checks/evidence, and report shape. Packets
stay compact: no copied rules, generated artifacts, or full transcripts.

Every `/orchestrate` run opens with a read-only `planning.scope` worker (the
fixed first phase) that investigates and returns a **workflow-brief**; lighter
work uses a `planning.brief` worker for an inline implementation brief. Both
briefs are plain Markdown, not generated packets. The canonical field shape is
owned by
[`../../src/rules/subagent/planning.md`](../../src/rules/subagent/planning.md)
(`## Workflow-brief`) and not duplicated here.

Implementation workers receive either a bounded task or the planner's brief.
They discover source files and tests inside that slice, run the cheapest
sufficient gate, update durable docs when required, commit, and report. They do
not switch into planning, review, or lifecycle closeout work on their own.

Between workers, the orchestrator carries forward a concise observed summary
(decisions, proven facts, touched files/docs, gates, commits, blockers,
assumptions) instead of the full prior transcript. Worker reports are compact and
self-contained; the report fields are owned by
[`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md).
Runtime usage counts appear only when the runtime exposes raw counts or the
caller explicitly asks.

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
snapshot dirty state, preserve unrelated changes and deletions, and stage only
owned paths by filename. They end under the **clean-handoff invariant** (no
unexplained owned dirt) in one of three terminal states: **committed**, **clean
no-op**, or **blocked handoff** (recording the dirty paths, gate state, why no
safe commit, and the resume profile). A **discharge gate** binds every
blocked-handoff record to its resolution — committed or reverted — before final
verification. Long work may take constrained checkpoint commits but never the
per-slice micro-commit cadence this replaces. Review and verification workers are
read-only; misses route back to implementation, docs-maintenance, or
plan-maintenance.

## Main surfaces

| Surface | Owns |
|---|---|
| `src/skills/*/` | Runnable workflow commands; `SKILL.md` is the prompt entry point and skill-local helper scripts may live beside it. |
| `src/skills/registry.md` | Skill inventory, mode/action metadata, intake style, and launch tier. |
| `src/verify-agent-docs.sh` | Kit drift gate; modes: `--context-report`, `--resolve` (profile, or `--skill/--phase/--repo/--risk` merge), `--equivalence`, `--measure-launch`, `--contract-check`, `--scaffold`. No-arg is the consolidated gate. |
| `src/kernel/` | Machine authority (JSON): `profiles`, `scenarios`, `workflows`, `packs`. Never auto-loaded; read by the verifier/resolver. |
| `src/rules/*.md` | Universal rules shared by every consuming repo: `skill-contracts.md`, `context-profiles.md`, `repo-rules.md`, `authoring-rules.md`, `coding-style.md`. |
| `src/rules/orchestrator/` | Orchestrator-facing workflow control: `lifecycle.md`, `dispatch.md`, and `run-docs.md`. |
| `src/rules/subagent/` | Worker-facing role rules: `planning.md`, `implementation.md`, `review.md`, `docs-maintenance.md`, `plan-maintenance.md`, `verification.md`. |
| `src/rules/packs/` | Eight task-routed quality overlays (frontend, backend-api, auth-security, db-migration, accessibility, testing-reliability, performance-concurrency, deployment-ops); resolver-activated, never auto-loaded. |
| `src/rules/coding-style-{rust,python,frontend}.md` | Language-idiom overlays (never auto-loaded). |
| `src/verify-fixtures/` | Verifier-only baseline snapshots (`baseline.md`). The scenario matrix moved to `src/kernel/scenarios.json`. |
| `docs/_meta/execution.yaml` | Per-repo execution binding (operational + Q9 fields); the resolver and gate read it. |
| `src/template/docs/` | Scaffold copied by `/rebuild-agent-docs`. |
| `src/agent-docs-guide.md` | Narrative guide for adopting the doc system. |
| `src/plan-lifecycle.md`, `src/plan-template.md` | Plan metadata and plan skeleton. |

Editing workers end under the clean-handoff invariant (committed, clean no-op, or
discharged blocked handoff); later workers repair with further commits. Editing
is serial per working tree, and the orchestrator verifies the final observed
state after docs, plan-status, and run-doc mutations.

## Workflow commands

After adding, renaming, or deleting a skill in `src/`, re-publish then verify
(`bash install-agentdocs-local.sh` then `bash src/verify-agent-docs.sh`); before
shipping any kit change, run `bash src/verify-agent-docs.sh`.

With no arguments, the verifier validates the source checkout: docs, manifest,
ownership, skill registry, template scaffold, the kernel, `execution.yaml`
schema, pack triggers/non-activation, the source-bound contract checks, the
single-authority and clean-handoff/cost-regression scenario gates, stale
references, executable bits, and adapter freshness. `--equivalence` is the
standalone single-authority proof. Run from outside the source repo, it prints a
`--scaffold` directive and exits 0.

For profile inspection use `--context-report [--profile <id>]`. A consuming repo
runs the target-aware scaffold check `bash ~/.agentdocs/verify-agent-docs.sh
--scaffold <repo-root>`, which checks that repo's scaffold, manifest slots,
ownership paths, routes, and unresolved placeholders — not the source checkout.

The full command inventory with one-line purposes lives in
[`../../src/skills/registry.md`](../../src/skills/registry.md); the routing table
below picks the smallest owner. The load-bearing workflow facts not obvious from
a command name:

- `/orchestrate` always begins with a `planning.scope` worker as its fixed first
  phase (the uniform scope brief resolving bounded/briefed/tracked); the accepted
  cost regression is bounded by a cost-regression budget guard.
- `/quick-fix` dispatches implementation only for already bounded fixes; unclear
  small work is first shaped by a planning worker or routed to `/plan`.
- `/start-session` checks local git, plans, cleanup candidates, and run docs,
  then routes into the owning skill; `/fresh-chat` starts ordinary work from the
  docs router.
- `/ship-current-work` finishes ordinary work and commits if gates pass;
  `/wrap-up-current-chat` captures chat-only durable context.
- `/feedback-agent-docs` appends to the runtime inbox
  `~/.agentdocs/feedback.jsonl`, preserved across installer runs.

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
