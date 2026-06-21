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

# Build the focused execution kernel

> **Supersedes** `agent-docs-focused-execution-kernel-shipping-plan.md`. This is
> the revised, more-detailed build plan with the review verdict and all ten
> review-question dispositions baked in. The companion
> `agent-docs-focused-execution-kernel-review-plan.md` holds the design proposal
> and review lens and is left unchanged.

## Mission

Implement the focused execution kernel as a **consolidation of machine authority
that already exists**, not as new generated-context infrastructure. Three things
already hold normative facts independently: the Markdown profile table in
`src/rules/context-profiles.md` (declared "the canonical owner for worker context
profiles"), the 11-row trace matrix in `src/verify-fixtures/workflow-scenarios.json`,
and hardcoded budget constants inside `src/verify-agent-docs.sh` (`fixed_budget=2000`,
`classifier_budget=3300`, the per-profile budgets, the `classifier_allowlist`).
The kernel pulls these into one JSON authority under `src/kernel/`, queried by the
**existing** verifier (extending `--resolve`/`--contract-check`, not a new CLI).
Done means: one machine authority for workflows/profiles/packs/scenarios; every
`/orchestrate` run begins with a read-only `planning.scope` worker; read-only
skills never select mutating profiles; the resolver returns exact source-backed
references with no copied bodies; consuming repos expose `docs/_meta/execution.yaml`;
mutating workers leave no unexplained owned dirt; and deterministic gates prove
the Claude Code/Codex contract without routine model spend.

**Framing reconciles the prior "Focused handoffs over generated context"
decision.** That decision rejected generated workspaces, packet helpers, *YAML
metadata*, parser work, and launcher behavior — infrastructure that becomes a
second workflow surface. The kernel introduces none of that: it **validates
structured data the verifier already parses** and **generates no prompt bodies
and no per-run context**. The resolver emits exact references (paths + heading
hints + sizes), copies no rule/doc/source body, and writes no artifact. Wave 0
records this reconciliation explicitly so the kernel is not mistaken for a
revival of metadata-v2 / generated-repo-local-context.

## Scope

In scope (carried from the old plan, corrected per Review resolution):

- one JSON machine authority for workflow phase sequences, allowed profiles,
  profile capabilities, pack activation, and scenario expectations;
- a read-only resolver/validator that is an **extension of the existing
  verifier** (no parallel CLI), writing no persistent context and copying no
  rule/doc/source body;
- mandatory `planning.scope` as the fixed first phase of every `/orchestrate`
  run;
- task-oriented read-only profiles `docs.inspect` and `plans.inspect`;
- `docs/_meta/execution.yaml` in source/template/dogfood repo, **required
  immediately** (not lazy);
- conditional app-quality packs with frontend/browser/accessibility first-class,
  plus the Q9 bootstrap/secrets layers;
- the revised clean-handoff git invariant with a discharge gate;
- the two approved skill renames (`check-docs`→`check-docs-drift`,
  `review-plans-health`→`check-plans-health`);
- static scenario traces, budgets, docs migration, and — at the FINAL deliberate
  step only — installer bundle updates and Claude/Codex canaries.

Out of scope:

- inline implementation or a single-actor fast path;
- a general workflow engine, autonomous scheduler, generated prompt bodies, or
  committed per-run context bundles;
- telemetry infrastructure or routine multi-model benchmarks;
- adapters other than Claude Code and Codex;
- concurrent mutators on one shared tree as the normal path;
- a second parser, PyYAML, or any network-installed dependency for the kernel;
- broad redesign of plan lifecycle, docs ownership, or installer safety;
- migrating consuming repos other than the dogfood repo before the final step.

## Review resolution

**Verdict:** ready after named revisions — now resolved. The dispositions below
are settled inputs to this build plan.

- **Q1 — APPROVE.** Uniform `planning.scope` entry. The user **accepts the cost
  regression** on bounded `/orchestrate` runs as the price of a uniform entry
  phase. Recorded as an accepted risk; Wave 7 adds a budget row that **measures**
  the added scope-worker hop (a cost-regression budget guard), so the regression
  is bounded and visible rather than hidden.
- **Q2 — REVISE → resolved.** Single authority enforced via a **hard cutover**
  (Wave 1b), not a compatibility layer.
- **Q3 — APPROVE w/ named choice.** Kernel is **JSON**, parsed by the stdlib
  `json` the verifier already uses (`import json` appears at multiple points in
  `src/verify-agent-docs.sh`). **No YAML/PyYAML** (forbidden network dep) and
  **no second parser**. `execution.yaml` is the only YAML and MUST be parsed by
  something guaranteed-present on the runtime host; if no guaranteed YAML parser
  exists, store `execution.yaml`'s machine fields as JSON-compatible content the
  stdlib can read (flag under open questions).
- **Q4 — RESOLVED.** `execution.yaml` is **required immediately** in
  source/template/dogfood repo. The user **accepts breaking other consuming
  repos** because nothing is migrated until the final deliberate step (see the
  SOURCE-ONLY discipline rule). Drop the "lazy"/optional approach.
- **Q5 — APPROVE.** `planning.scope` / `docs.inspect` / `plans.inspect` are
  sufficient; no 4th profile.
- **Q6 — REVISE → resolved.** Single deterministic pack-merge rule:
  `(path-routes ∪ scoper-tags) ∩ execution-allowlist`. Worker additions require a
  logged grant. The resolver is the **sole loader** of packs.
- **Q7 — REVISE → resolved.** The blocked-handoff state gets a **discharge gate**:
  the blocked-handoff record must be committed or reverted before final
  verification. Checkpoint commits are **constrained** so they do not re-create
  the micro-commit cadence the new invariant replaces.
- **Q8 — APPROVE (low value).** Ship `check-docs`→`check-docs-drift` and
  `review-plans-health`→`check-plans-health`. No other true duplicates.
- **Q9 — REVISE → resolved.** `execution.yaml`/packs MUST add the bootstrap +
  secrets layers a real feature worker hits first: dependency/toolchain install,
  secrets/credentials provisioning, observability/log access, test-data/fixture
  seeding, and network/external-service boundaries.
- **Q10 — REVISE → resolved.** Smallest two-authority-free migration is the
  **shadow → atomic-cutover** sequence (Wave 1a/1b), not the old Wave 1's
  "introduce kernel + CLI, then migrate" two-step.

**Accepted risks.** (a) The bounded-`/orchestrate` cost regression from the
uniform scope phase. (b) Temporary breakage of un-migrated consuming repos until
the final migration step (neutralized for the dogfood/source surface by the
SOURCE-ONLY rule).

## Approach

Each wave names its owned files and ends with a per-wave green gate:
`bash src/verify-agent-docs.sh`. Only one mutating worker touches the shared tree
at a time; workers stage only their owned files by filename. **All gating runs
against `src/` only** until the final migration step (see Discipline rules).

### Wave 0 — Lock decisions & baseline (no model calls)

Record in `docs/decisions/agent-docs.md`:

- subagent-first execution (strengthen the existing decision; orchestrators do
  coordination IO and user communication only);
- the **kernel-as-consolidation** framing, explicitly superseding "Focused
  handoffs over generated context" (the kernel validates pre-existing structured
  data and generates no prompt bodies or per-run context);
- uniform `planning.scope` as the fixed `/orchestrate` entry, with the accepted
  cost regression;
- the **SOURCE-ONLY** discipline rule (see Discipline rules).

Freeze the baseline as fixtures (no model calls): record the current output of
`bash src/verify-agent-docs.sh`, `--context-report`, `--measure-launch orchestrate`,
`--measure-launch quick-fix`, plus the current 11-profile inventory, the
`classifier_allowlist`, and representative traces.

Owned: `docs/decisions/agent-docs.md`, `docs/architecture/workflow-kit.md`,
`src/verify-fixtures/` (baseline snapshots).

### Wave 1a — Kernel as shadow (JSON)

Add `src/kernel/*.json`: `workflows.json`, `profiles.json`, `packs.json`,
`scenarios.json`. Populate `scenarios.json` by **reusing the content** of
`src/verify-fixtures/workflow-scenarios.json` and `profiles.json` from the
`context-profiles.md` rows. Add a `verify-kernel --equivalence` check (a new mode
of the existing verifier) that proves the kernel resolves **byte-identical**
profile + scenario facts versus the current Markdown table and the JSON fixture.
Markdown remains the **only enforced authority**; the kernel is unproven shadow
data this wave. One authority at all times.

Owned: `src/kernel/*.json`, the `--equivalence` mode in `src/verify-agent-docs.sh`.

### Wave 1b — Atomic cutover (ONE commit)

In a single commit: repoint `validate_context_profiles` / `contract_check` /
scenario reads / the hardcoded budget constants (`fixed_budget`,
`classifier_budget`, per-profile budgets, `classifier_allowlist`) at the kernel,
**and in the same commit** delete the superseded Markdown profile/budget tables
and the JSON fixture, leaving human prose pointing at the kernel. The Wave 1a
`--equivalence` check is the rollback boundary. **Extend the existing verifier
and `--resolve`; do NOT build a parallel CLI.** Note: neither installer bundles
`verify-fixtures/` or a `kernel/` dir today (`bundle_dirs=(skills rules
template)`), and the verifier reads them from `src/` directly — so this cutover
needs no installer change, which is exactly what the SOURCE-ONLY rule relies on.

Owned: `src/verify-agent-docs.sh`, `src/rules/context-profiles.md` (tables
deleted, prose repointed), `src/verify-fixtures/workflow-scenarios.json`
(deleted), `src/kernel/*.json`.

### Wave 2 — `planning.scope` as the fixed `/orchestrate` entry

Add the read-only `planning.scope` profile (kernel + prose) and the
workflow-brief contract (goal/non-goals, acceptance criteria, workstreams +
dependencies, authoritative docs + source/test areas, recommended profile per
phase, risk tags + required packs, targeted + final checks, concrete user
decisions, state basis + invalidation + stop conditions). Rewrite
`/orchestrate` as a fixed controller that **always dispatches `planning.scope`
first** (no short-circuit — cost regression accepted), relays the worker's
questions, and resumes/delta-rereads/respawns per invalidation state. Remove the
bounded/briefed/tracked inline classification from the orchestrator. Keep
deterministic first phases for `/quick-fix` (implementation), `/plan` (planning),
doc/plan checks (inspection), and named reviews. Add a scenario row asserting
`planning.scope` is the **first** phase for `/orchestrate`.

Owned: `src/kernel/profiles.json`, `src/kernel/workflows.json`,
`src/kernel/scenarios.json`, `src/skills/orchestrate/SKILL.md`,
`src/rules/orchestrator/{lifecycle,dispatch}.md`, `src/rules/subagent/planning.md`.

### Wave 3 — Profiles + exact-context resolution

Add `docs.inspect` and `plans.inspect` (read-only). Remap read-only skills off
mutating maintenance profiles (`check-docs`/`check-docs-drift` and
`review-plans-health`/`check-plans-health` must not select `maintenance.docs`/
`maintenance.plan` and then subtract authority in prose). **Extend** `--resolve`
/ context resolution to accept `--skill` / `--phase` / `--repo` / `--risk` and
merge: kernel profile + manifest fields + `execution.yaml` fields + task-routed
docs (with heading hints) + source/test hints + allowed packs + checks + exact
resolved size. Enforce **no self-upgrade of write authority** (workers may
request an allowed pack post-discovery; they may not change role or gain
mutation).

Owned: `src/kernel/profiles.json`, `src/verify-agent-docs.sh` (`--resolve`
extension), `src/rules/context-profiles.md`, the affected read-only skill bodies,
`src/rules/orchestrator/dispatch.md`.

### Wave 4 — Repo execution bindings + quality packs

Add `docs/_meta/execution.yaml` to `src/template/docs/_meta/` and the dogfood
repo's `docs/_meta/` — **required immediately**. Schema MUST cover the
operational fields (language/roots, format/lint/typecheck/targeted-test/full-test/
build/smoke commands, path-to-check routing, services + startup + health + ports,
browser/screenshot workflows, db/migration commands, generated/protected/forbidden
paths, scarce resources, path/risk→pack routes) **AND the Q9 layers**
(dependency/toolchain bootstrap, secrets/credentials provisioning,
observability/log access, test-data/fixture seeding, network/external-service
boundaries). Add task-routed packs (frontend/UI, accessibility, backend/API,
auth/security, db-migration/data-safety, testing/reliability,
performance/concurrency, deployment/ops). Implement the single deterministic
pack-merge rule `(path-routes ∪ scoper-tags) ∩ execution-allowlist`; the resolver
is the sole loader. UI resolution must include app startup, browser exercise,
screenshots, responsive + accessibility + loading/error/empty states when
available; **missing tooling is residual risk, not green**. Update `doctor`,
`rebuild-agent-docs`, scaffold validation (`check_scaffold_tree`), manifest
routes, and ownership.

Owned: `src/template/docs/_meta/execution.yaml`, dogfood
`docs/_meta/execution.yaml`, `src/kernel/packs.json`, new pack rule leaves under
`src/rules/`, `src/verify-agent-docs.sh` (scaffold + execution.yaml schema
checks), `src/skills/{doctor,rebuild-agent-docs}/SKILL.md`,
`docs/_meta/{manifest.md,ownership.json}`, `docs/repository-layout.md`,
`src/agent-docs-guide.md`.

**Open question (decide at ship time):** do all eight packs ship now, or ship
UI/a11y first-class with the remaining six **stubbed** (kernel entry + trigger +
evidence requirement, leaf to be filled)? Stubs must still gate (a pack present
without a trigger fails).

### Wave 5 — Clean-handoff git invariant

Replace "commit every completed slice" with **"a mutating worker never hands off
unexplained owned dirt."** Three terminal states: committed / clean no-op /
explicit blocked handoff (exact owned dirty paths + check state + why a safe
commit is impossible + the resume profile). **Add a discharge gate** tying a
blocked-handoff record to its resolution (committed or reverted) before final
verification. **Constrain checkpoint commits** so long/resume-sensitive work does
not reintroduce the micro-commit cadence. Update `src/rules/repo-rules.md`, the
orchestrator dispatch/lifecycle, mutating role cards
(`src/rules/subagent/{implementation,docs-maintenance,plan-maintenance}.md`),
affected skills, `docs/decisions/agent-docs.md` (supersede "Commit-heavy worker
shipping"), and the verifier assertions.

Owned: `src/rules/repo-rules.md`, `src/rules/orchestrator/{lifecycle,dispatch}.md`,
`src/rules/subagent/*.md`, `docs/decisions/agent-docs.md`,
`src/verify-agent-docs.sh`, `src/kernel/scenarios.json`.

### Wave 6a — Skill renames + coupled surfaces (ONE commit)

`check-docs`→`check-docs-drift`; `review-plans-health`→`check-plans-health`. In
the **same commit** update: skill dirs + frontmatter, `src/skills/registry.md`,
`src/agent-docs-guide.md`, `docs/architecture/workflow-kit.md`,
`docs/decisions/agent-docs.md`, the verifier's scenario→skill `mapping` **code**
(the dict near line 1022 of `src/verify-agent-docs.sh`), the `classifier_allowlist`
if affected, and **add `reject_unapproved_retired_name` guards** for the two old
names (mirroring the existing guards for `fresh-planning-chat`, `new-project-prompt`,
etc., with `allow_retired_reference` exceptions for the decision-record lines).
**The installer `remove_stale_managed` / adapter-freshness coupling is DEFERRED
to the final migration** (SOURCE-ONLY rule) — do not run an installer to prune
the old skill dirs from `~/.agentdocs` or the adapter copies this wave.

Owned: `src/skills/check-docs-drift/`, `src/skills/check-plans-health/`,
`src/skills/registry.md`, `src/verify-agent-docs.sh`, `src/agent-docs-guide.md`,
`docs/architecture/workflow-kit.md`, `docs/decisions/agent-docs.md`.

### Wave 6b — Per-skill kernel-workflow-ID wiring

Each skill references exactly one kernel workflow ID plus only its unique intake /
approval / escalation / result behavior. Shared machine facts stay in the kernel.

Owned: `src/skills/*/SKILL.md`, `src/kernel/workflows.json`, `src/skills/registry.md`.

### Wave 7 — Verification + RELABELED exit gate

Static gates fail on the statically-decidable items (duplicate/missing kernel
authority, invalid kernel refs, a read-only skill selecting a mutating profile, a
pack present without a trigger, budgets below the measured floor, source/registry/
template parity, no resolver-written artifacts, `execution.yaml` schema validity).
Run the deterministic gate + the scenario traces. Migrate durable facts into
`architecture/workflow-kit.md`, `decisions/agent-docs.md`, `_meta/manifest.md`,
`_meta/ownership.json`, `agent-docs-guide.md`, and the template.

**The FINAL migration is a SEPARATE deliberate step gated on explicit user
permission.** Only after the overhaul is green end-to-end and the user authorizes
it: extend the installer bundles if the runtime needs `kernel/`, run the
installer, refresh `~/.agentdocs/`, update the Claude/Codex adapter skill copies
(including pruning the renamed skill dirs via `remove_stale_managed`), roll
`execution.yaml` out to other consuming repos, and run the two live canaries (an
ordinary feature + a UI feature) per adapter.

## Exit gate

Bucketed into three honest groups.

**Statically proven** (zero-dependency gate, `bash src/verify-agent-docs.sh`):

- single authority / no duplication (no profile, budget, or scenario fact lives
  in both the kernel and Markdown/bash);
- valid kernel references (every workflow/profile/pack ref resolves);
- read-only-vs-mutating consistency (no read-only skill selects a mutating
  profile);
- budgets at or above measured floors;
- source/registry/template parity;
- no resolver-written artifacts and no copied bodies in resolver output;
- `execution.yaml` schema validity (operational + Q9 fields).

**Scenario-contract asserted** (proven against fixtures, not live runs):

- `/orchestrate` starts with `planning.scope` (ordering row);
- final verification observes the state after the last mutation;
- pack non-activation (irrelevant packs stay unloaded);
- blocked-handoff discharge (record resolved before final verification);
- question relay (worker → orchestrator → user).

**Canary-observed only** (run at the final migration step):

- the two live feature/UI canaries per adapter (Claude Code, Codex).

**Acceptance tests to ADD:**

- a **dual-authority detector** — fail if any profile/budget/scenario lives in
  both the kernel and Markdown/bash;
- a **resolver output-snapshot test** — assert no copied rule/doc/source bodies,
  references only;
- the **`planning.scope`-first ordering** scenario row for `/orchestrate`;
- the **pack non-activation** test;
- the **blocked-handoff discharge** test;
- the **cost-regression budget guard** for the added scope-worker hop (measures
  and bounds the accepted Q1 regression).

## Discipline rules

- **SOURCE-ONLY UNTIL FINAL MIGRATION.** All work and all
  `bash src/verify-agent-docs.sh` gating runs against `src/`. Do NOT run either
  installer (`install-agentdocs-local.sh`, `src/install-agentdocs.sh`), refresh
  `~/.agentdocs/`, or update the Claude/Codex adapter skill copies until the
  overhaul is green end-to-end AND the user explicitly authorizes one deliberate
  migration that updates the runtime AND all consuming repos together. This
  neutralizes the adapter-freshness / `remove_stale_managed` coupling and the
  consuming-repo breakage during the build.
- Per-wave green gate (`bash src/verify-agent-docs.sh`) before handoff.
- One mutating worker at a time on the shared tree; stage only owned files by
  filename; preserve the unrelated dirty state (the deleted plan files).
- No YAML/PyYAML and no second parser for the kernel; the kernel is JSON read by
  the verifier's existing stdlib `json`.
- Never let Markdown and the kernel both own the same machine fact.
- No quality pack without a proven path/risk trigger.
- Do not weaken gates or inflate budgets to go green; budget changes need a
  documented correctness floor (Decision E3 pattern).

## Likely files

- `src/kernel/{workflows,profiles,packs,scenarios}.json`
- `src/verify-agent-docs.sh` (extend `--resolve`/`--contract-check`; add
  `--equivalence`; repoint budget constants + scenario `mapping`; add new guards)
- `src/rules/context-profiles.md` (tables deleted, prose repointed)
- `src/verify-fixtures/workflow-scenarios.json` (deleted in Wave 1b)
- `src/rules/orchestrator/{lifecycle,dispatch}.md`
- `src/rules/subagent/{planning,implementation,docs-maintenance,plan-maintenance}.md`
- `src/rules/repo-rules.md`; new task-routed pack leaves under `src/rules/`
- `src/skills/orchestrate/SKILL.md`; `src/skills/{check-docs-drift,check-plans-health}/`
- `src/skills/{doctor,rebuild-agent-docs}/SKILL.md`; `src/skills/registry.md`
- `src/template/docs/_meta/execution.yaml`; dogfood `docs/_meta/execution.yaml`
- `docs/architecture/workflow-kit.md`; `docs/decisions/agent-docs.md`
- `docs/_meta/{manifest.md,ownership.json}`; `docs/repository-layout.md`
- `src/agent-docs-guide.md`
- (FINAL step only) `install-agentdocs-local.sh`, `src/install-agentdocs.sh`

## Migration notes (filled in at ship time)

Before `status: shipped`, route every durable fact into:

- `docs/architecture/workflow-kit.md` — implemented kernel shape, resolver,
  execution binding, packs, and clean-handoff git shape;
- `docs/decisions/agent-docs.md` — kernel-as-consolidation (superseding "Focused
  handoffs over generated context"), uniform `planning.scope` + accepted cost
  regression, single-authority cutover, clean-handoff invariant superseding
  "Commit-heavy worker shipping", and the rejected alternatives;
- `docs/_meta/{manifest.md,ownership.json}` — new surfaces (`src/kernel/`,
  `execution.yaml`, packs, renamed skills) and their update triggers;
- `src/agent-docs-guide.md` and `src/template/docs/` — the consuming-repo
  contract including `execution.yaml`.

Record the final authority moves and any accepted deviations here so a reviewer
can confirm `okay_to_delete: true` is honest.

## See also

- `agent-docs-focused-execution-kernel-review-plan.md` — design proposal + review
  lens (unchanged).
- `agent-docs-focused-execution-kernel-shipping-plan.md` — the superseded
  shipping plan.
- [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
