---
status:        draft
owner:         implementation
last_updated:  2026-06-21
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Ship the focused execution-kernel overhaul

> **Superseded by** `agent-docs-focused-execution-kernel-build-plan.md`. The
> review verdict (ready after named revisions) and the ten review-question
> dispositions are recorded there, along with the revised wave sequence. Use the
> build plan; this file is retained only for history.

## Preconditions

The companion review plan, `agent-docs-focused-execution-kernel-review-plan.md`, has received a **ready to ship** or **ready after named revisions** verdict. Before changing this plan to `active`, copy every approved revision into the relevant workstream and record any rejected proposal under “Review resolution.”

## Review resolution

Fill this section before implementation:

- Review verdict:
- Required revisions incorporated:
- Proposed skill renames approved/rejected:
- Kernel serialization/parser choice:
- `docs/_meta/execution.yaml` migration policy:
- Remaining accepted risks:

## Mission

Implement the approved focused execution kernel in place. Done means `/orchestrate` always begins with a read-only scoping worker, granular skills remain focused, named profiles and conditional quality packs resolve to exact source-backed context, consuming repos expose machine-readable execution bindings, worker git handoffs are clean and explainable, and deterministic gates prove the final Claude Code/Codex contract without routine model-call spending.

## Scope

In scope:

- machine-readable workflow, profile, quality-pack, and scenario authority;
- a read-only resolver/validator CLI with no persistent generated context;
- mandatory `planning.scope` for every new `/orchestrate` run;
- task-oriented `docs.inspect` and `plans.inspect` profiles;
- `docs/_meta/execution.yaml` and scaffold support;
- conditional app-quality packs, with frontend/browser/accessibility support first-class;
- revised mutator handoff and commit cadence;
- approved skill naming cleanup;
- static scenario traces, budgets, docs migration, installer bundle updates, and Claude/Codex canaries.

Out of scope:

- inline implementation or a single-actor fast path;
- a general workflow engine or autonomous task scheduler;
- generated prompt bodies or committed per-run context bundles;
- telemetry infrastructure or routine multi-model benchmarks;
- adapters other than Claude Code and Codex;
- concurrent mutators on one shared working tree as the normal path;
- broad redesign of plan lifecycle, docs ownership, or installer safety.

## Approach

### Wave 0 — Lock decisions and baseline

1. Add a durable decision strengthening subagent-first execution:
   - orchestrators perform coordination IO and user communication only;
   - substantive role work is always worker-owned;
   - inline task execution is a deferred experiment that must not be recommended without explicitly superseding the decision.
2. Record the approved decisions for mandatory `planning.scope`, orchestrator-relayed questions, granular skills, structured kernel, exact resolver output, `execution.yaml`, quality packs, task-oriented inspection profiles, and the new git handoff invariant.
3. Run and record the current deterministic baseline:

   ```sh
   bash src/verify-agent-docs.sh
   bash src/verify-agent-docs.sh --context-report
   bash src/verify-agent-docs.sh --measure-launch orchestrate
   bash src/verify-agent-docs.sh --measure-launch quick-fix
   ```

4. Freeze current skill/profile inventory and representative workflow traces as fixtures. Do not call models for this baseline.

Likely owners: `docs/decisions/agent-docs.md`, `docs/architecture/workflow-kit.md`, `src/verify-fixtures/`.

### Wave 1 — Introduce the structured kernel and CLI

1. Add the review-approved structured files under `src/kernel/` for:
   - workflows and phase sequences;
   - profile definitions, capabilities, grants, and reusable internal fragments;
   - quality packs and activation rules;
   - scenario traces and expected final ordering.
2. Add a small zero-network-dependency CLI. It must support equivalent operations to:

   ```text
   resolve-profile <id>
   resolve-context --skill <skill> --phase <phase> --profile <id> --repo <path> ...
   trace-workflow <skill-or-scenario>
   measure-context ...
   verify-kernel
   ```

3. Keep `src/verify-agent-docs.sh` as the stable top-level gate if useful, but delegate structured parsing and validation to one implementation. Do not maintain a second parser for the same kernel facts.
4. Migrate machine authority out of Markdown tables and the old scenario fixture. Markdown retains concise human explanation and pointers to the kernel.
5. Extend both installers and local bundle validation so `kernel/` and the CLI are shipped into `~/.agentdocs/`.
6. Prove the CLI writes no repo or runtime artifact and emits no copied rule/doc/source bodies.

### Wave 2 — Make scoping the fixed `/orchestrate` entry phase

1. Add enforced read-only profile `planning.scope` and define it as a variant of the planning worker unless review found a separate role card necessary.
2. Define the workflow-brief contract:

   ```text
   Goal and non-goals
   Acceptance criteria
   Workstreams/slices and dependencies
   Authoritative docs and likely source/test areas
   Recommended profiles by phase
   Risk tags and quality packs
   Targeted and final checks
   Concrete user decisions
   State basis, invalidation, and stop conditions
   ```

3. Rewrite `/orchestrate` as a fixed controller:
   - dispatch or validly resume `planning.scope` first;
   - relay the worker's concrete questions;
   - resume/delta-reread/respawn after answers according to invalidation state;
   - persist a tracked plan only when the scope brief says the work is broad, risky, multi-stream, or resume-sensitive;
   - dispatch implementation, review, maintenance, and final verification from the approved brief.
4. Remove bounded/briefed/tracked app investigation from the orchestrator's own context. It may select the next kernel-defined phase but may not deep-read source to invent worker limits.
5. Keep deterministic first phases for specific skills; do not force `planning.scope` into `/quick-fix`, `/plan`, doc checks, or named reviews.
6. Add static traces proving every new `/orchestrate` run begins with `planning.scope` and that user questions flow worker → orchestrator → user.

### Wave 3 — Complete profile and exact-context resolution

1. Add enforced read-only profiles:
   - `docs.inspect` for mechanical documentation drift checks;
   - `plans.inspect` for plan/run health inspection.
2. Remap read-only skills away from mutating maintenance profiles. A dispatch must never grant mutation and then revoke it only in prose.
3. Refactor stable profile IDs onto reusable internal fragments only where this removes duplication. Skills continue naming complete profile IDs; orchestrators do not assemble ad hoc permissions.
4. Implement `resolve-context` so it combines:
   - kernel profile and allowed grants;
   - requested manifest fields;
   - `docs/_meta/execution.yaml` fields needed by the phase;
   - task-routed docs with heading/search hints;
   - source/test hints from the scoper or deterministic path routes;
   - allowed quality packs;
   - named checks and evidence requirements;
   - exact static size.
5. Enforce that workers may request an allowed quality pack after discovery but cannot self-upgrade write authority or change role.
6. Update dispatch packets and worker reports to reference resolver results compactly while preserving direct reads of authoritative files.

### Wave 4 — Add repo execution bindings and quality packs

1. Add `docs/_meta/execution.yaml` to the dogfood repo and `src/template/docs/_meta/` using the approved schema. Keep it operational, not architectural.
2. Update `doctor`, `rebuild-agent-docs`, scaffold validation, manifest routes, ownership data, repository layout, and the guide to create and validate the file.
3. The minimal schema must support:
   - language/framework and root bindings;
   - format, lint, typecheck, test, build, smoke, and final commands;
   - path/change-to-check routing;
   - services, startup, health checks, and ports;
   - browser/screenshot/accessibility procedures;
   - database/migration procedures;
   - generated/protected paths;
   - scarce resources;
   - path/risk-to-pack routes.
4. Add task-routed quality rule leaves and kernel entries for:
   - frontend/UI;
   - accessibility;
   - backend/API;
   - auth/security;
   - database migration/data safety;
   - testing/reliability;
   - performance/concurrency;
   - deployment/operations.
5. UI feature resolution must include, when available and permitted: app startup, browser exercise, screenshot evidence, responsive states, accessibility checks, and loading/error/empty states. Missing tooling must be reported as residual risk, not treated as green.
6. Add schema and activation tests showing irrelevant packs remain unloaded.

### Wave 5 — Replace commit-heavy wording with clean handoffs

1. Change the universal invariant to: **a mutating worker never hands off unexplained owned dirt**.
2. Require one of three terminal states: committed, clean no-op, or explicit blocked handoff with exact dirty paths, check state, blocker, and required resume profile.
3. Commit coherent work at mutator handoff or assignment end. Use checkpoint commits for long/resume-sensitive work; do not require a commit after every tiny repair.
4. Preserve serial editing on a shared tree, staging by filename, unrelated-dirt protection, no autonomous push, and final verification after all mutations.
5. Update `repo-rules.md`, orchestrator dispatch/lifecycle, mutating role cards, affected skills, decisions, and verifier assertions. Remove stale “commit every completed slice” language where it contradicts the new cadence.
6. Add scenarios for blocked handoff, checkpoint resume, and final no-agent-owned-dirt state.

### Wave 6 — Reconcile the granular skill surface

1. Keep all materially distinct workflows as public skills.
2. Apply only naming changes approved in review. Default proposal:
   - `check-docs` → `check-docs-drift`;
   - `review-plans-health` → `check-plans-health`.
3. Preserve the three documentation lanes: mechanical check, mutating drift repair, and editorial shape review. Preserve named-plan critique separately from plan-tree health.
4. Update source directories, frontmatter, registry, guide, architecture, decisions, verifier allowlists, installer stale-managed cleanup expectations, and Claude/Codex copies as one atomic migration. Do not leave aliases or duplicate live recipes unless review explicitly requires them.
5. Ensure each skill references one kernel workflow ID and only its unique intake, approval, escalation, and result behavior. Shared machine facts remain in the kernel.

### Wave 7 — Verification, migration, and release proof

1. Extend static gates to fail on:
   - duplicate or missing kernel authority;
   - invalid workflow/profile/pack references;
   - `/orchestrate` not starting with `planning.scope`;
   - read-only skills selecting mutating profiles;
   - unauthorized pack or grant escalation;
   - resolver output containing copied bodies or writing artifacts;
   - missing/invalid `execution.yaml` bindings;
   - quality packs loading without a trigger;
   - stale commit-per-subslice policy;
   - final verification preceding any mutation;
   - source/registry/template/Claude/Codex drift;
   - context budgets above approved floors.
2. Run the complete deterministic gate and representative traces:

   ```sh
   bash src/verify-agent-docs.sh
   bash src/verify-agent-docs.sh --context-report
   bash src/verify-agent-docs.sh --contract-check
   # plus the approved kernel CLI verification and trace commands
   ```

3. Migrate durable facts into architecture, decisions, manifest, ownership, guide, and template docs. Remove superseded tables and rules rather than preserving two authorities.
4. Propose `bash install-agentdocs-local.sh` and wait for explicit user permission. After approval, refresh the runtime and verify Claude/Codex adapter parity.
5. Run only two live canary shapes in each supported adapter because this is a major kernel change:
   - an ordinary feature through `/orchestrate`, proving `planning.scope`, question relay, bounded implementation context, and final verification;
   - a UI feature, proving execution bindings and frontend/accessibility quality packs produce browser and screenshot evidence when available.

Static scenarios cover bounded quick fix, failed verification, dirty-tree handoff, and invalidated resume without additional model spending.

## Exit gate

The overhaul is done only when:

- every new `/orchestrate` run starts with `planning.scope`;
- the orchestrator performs no substantive planning, implementation, review, maintenance, or verification;
- concrete user questions are relayed by the orchestrator;
- granular skills remain and only approved naming cleanup occurred;
- the kernel is the sole machine authority for workflows, profiles, packs, and scenarios;
- profiles remain stable named contracts and `docs.inspect`/`plans.inspect` are read-only;
- resolver output is exact, source-backed, body-free, read-only, and budgeted;
- `docs/_meta/execution.yaml` is scaffolded, validated, and queried selectively;
- feature tasks load only triggered quality packs;
- UI feature work can produce browser, screenshot, responsive, and accessibility evidence when the repo supports it;
- mutating workers end committed, clean no-op, or explicitly blocked, and final shipping leaves no agent-owned dirt;
- final verification observes the state after the last mutation;
- all static gates and both Claude Code/Codex canary shapes pass or have an explicitly accepted residual risk;
- durable facts are migrated and this plan can truthfully become `shipped` and `okay_to_delete: true`.

## Discipline rules

- One mutating worker at a time on the shared tree.
- Preserve unrelated dirty paths and stage only owned files.
- Do not add inline execution as a fallback when dispatch is unavailable.
- Do not build a general workflow engine, background scheduler, telemetry system, or generated prompt workspace.
- Do not let Markdown and the kernel both own the same machine fact.
- Do not load quality packs without a proven path/risk trigger.
- Do not weaken gates or inflate budgets to make the migration green.
- Do not run an installer or push without explicit user instruction.

## Likely files

- `src/kernel/*`
- the review-approved kernel CLI and `src/verify-agent-docs.sh`
- `src/rules/context-profiles.md`
- `src/rules/orchestrator/{lifecycle,dispatch}.md`
- `src/rules/subagent/{planning,docs-maintenance,plan-maintenance,implementation}.md`
- new task-routed quality rule leaves under `src/rules/`
- `src/rules/repo-rules.md`
- `src/skills/orchestrate/SKILL.md`
- affected doc/plan inspection skills and `src/skills/registry.md`
- `src/template/docs/_meta/execution.yaml`
- consuming-repo `docs/_meta/execution.yaml`
- `src/install-agentdocs.sh`, `install-agentdocs-local.sh`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`
- `docs/_meta/{manifest.md,ownership.json}`
- `docs/repository-layout.md`
- `src/agent-docs-guide.md`

## Migration notes (filled in at ship time)

Record the final authority moves and any accepted deviations here. At minimum, confirm migration to:

- `docs/architecture/workflow-kit.md` — implemented workflow, resolver, execution binding, packs, and git shape;
- `docs/decisions/agent-docs.md` — worker-only execution, granular skills, kernel authority, repo boundary, and rejected alternatives;
- `docs/_meta/manifest.md` and `docs/_meta/ownership.json` — all new surfaces and update triggers;
- `src/agent-docs-guide.md` and `src/template/docs/` — consuming-repo contract.

## See also

- `agent-docs-focused-execution-kernel-review-plan.md`
- [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
