---
status:        active
owner:         implementation
last_updated:  2026-06-23
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Build the focused execution kernel

> **Supersedes** the shipping-plan and review-plan (both deleted). The
> revised build plan has the review verdict and all ten review-question
> dispositions baked in.

## Mission

Implement the focused execution kernel as a **consolidation of machine authority
that already exists**, not as new generated-context infrastructure. Three things
hold normative facts independently today: the Markdown profile table in
`src/rules/context-profiles.md` (declared "the canonical owner for worker context
profiles"), the 11-row trace matrix in `src/verify-fixtures/workflow-scenarios.json`,
and hardcoded budget constants in `src/verify-agent-docs.sh` (`fixed_budget=2000`,
`classifier_budget=3300`, per-profile budgets, `classifier_allowlist`).
The kernel pulls these into one JSON authority under `src/kernel/`, queried by the
**existing** verifier (extending `--resolve`/`--contract-check`, not a new CLI).
Done means one machine authority for workflows/profiles/packs/scenarios, a
`planning.scope`-first `/orchestrate`, read-only skills that never select mutating
profiles, a no-copied-bodies resolver, `docs/_meta/execution.yaml` in consuming
repos, mutating workers leaving no unexplained owned dirt, and deterministic gates
proving the Claude Code/Codex contract without routine spend.

This **reconciles the prior "Focused handoffs over generated context"
decision** (now migrated to the Kernel-as-consolidation decision in
`docs/decisions/agent-docs.md`): the kernel adds no generated workspaces, packet
helpers, YAML metadata, parser, or per-run context — it validates structured data
the verifier already parses, and its resolver emits exact references while copying
no body and writing no artifact.

## Scope

In scope (each item is detailed in its wave): one JSON machine authority for
workflow sequences, allowed
profiles, profile capabilities, pack activation, and scenario expectations; a
read-only resolver/validator that **extends the existing verifier** (no parallel
CLI), writing no persistent context and copying no rule/doc/source body; mandatory
`planning.scope` as the fixed first `/orchestrate` phase; read-only `docs.inspect`
and `plans.inspect` profiles; `docs/_meta/execution.yaml` in source/template/dogfood
repo, **required immediately** (not lazy); all eight conditional app-quality packs
as first-class leaves (frontend/browser/accessibility included) plus the Q9
bootstrap/secrets layers; the revised clean-handoff git invariant with a discharge
gate; the two approved skill renames (`check-docs`→`check-docs-drift`,
`review-plans-health`→`check-plans-health`); and static scenario traces, budgets,
docs migration, plus — at the FINAL deliberate step only — installer bundle updates
and Claude/Codex canaries.

Out of scope:

- inline implementation or a single-actor fast path;
- a general workflow engine, autonomous scheduler, generated prompt bodies, or
  committed per-run context bundles;
- telemetry infrastructure or routine multi-model benchmarks;
- adapters other than Claude Code and Codex;
- concurrent mutators on one shared tree as the normal path;
- a second parser, PyYAML, or any network-installed dependency **for the kernel**
  (PyYAML stays an *optional* `execution.yaml` parser only);
- broad redesign of plan lifecycle, docs ownership, or installer safety;
- migrating consuming repos other than the dogfood repo before the final step.

## Review resolution

**Verdict:** ready after named revisions — now resolved. The dispositions below
are settled inputs.

- **Q1 — APPROVE.** Uniform `planning.scope` entry. The user **accepts the cost
  regression** on bounded `/orchestrate` runs as the price of a uniform entry
  phase. Recorded as an accepted risk; Wave 7 adds a budget row that **measures**
  the added scope-worker hop, keeping the regression bounded and visible.
- **Q2 — REVISE → resolved.** Single authority via a **hard cutover** (Wave 1b),
  not a compatibility layer.
- **Q3 — APPROVE w/ named choice.** The **kernel** is **JSON**, parsed by the
  stdlib `json` the verifier already uses (`import json` appears throughout
  `src/verify-agent-docs.sh`) — firm, because the kernel is the gate's
  always-parsed machine authority and must read with zero external deps on every
  adapter host; YAML buys nothing for machine-authored data whose prose is in
  Markdown. **`execution.yaml` stays YAML** (human-authored per-repo binding where
  readability matters). PyYAML is an **optional, documented dependency, not a
  ban**: the verifier tries to import a YAML parser; present, it validates the
  full `execution.yaml` schema; absent, it degrades to a shallow presence/text
  check plus an "install pyyaml for full execution.yaml validation" remediation —
  so the core gate runs everywhere and an agent can fix a missing parser
  reactively. The original ban kept the deterministic gate runnable offline on any
  bash + stdlib-python host; that property is preserved absolutely for the kernel
  and made best-effort for `execution.yaml`.
- **Q4 — RESOLVED.** `execution.yaml` is **required immediately** in
  source/template/dogfood repo. The user **accepts breaking other consuming
  repos** since nothing migrates until final migration (SOURCE-ONLY rule). Drop
  the "lazy"/optional approach.
- **Q5 — APPROVE.** `planning.scope` / `docs.inspect` / `plans.inspect` suffice;
  no 4th profile.
- **Q6 — REVISE → resolved.** Single deterministic pack-merge rule
  `(path-routes ∪ scoper-tags) ∩ execution-allowlist`. Worker additions require a
  logged grant. The resolver is the **sole loader** of packs.
- **Q7 — REVISE → resolved.** The blocked-handoff state gets a **discharge gate**:
  the record must be committed or reverted before final verification. Checkpoint
  commits are **constrained** so they do not re-create the micro-commit cadence
  the invariant replaces.
- **Q8 — APPROVE (low value).** Ship `check-docs`→`check-docs-drift` and
  `review-plans-health`→`check-plans-health`. No other true duplicates.
- **Q9 — REVISE → resolved.** `execution.yaml`/packs MUST add the bootstrap +
  secrets layers a real feature worker hits first: dependency/toolchain install,
  secrets/credentials provisioning, observability/log access, test-data/fixture
  seeding, network/external-service boundaries.
- **Q10 — REVISE → resolved.** Smallest two-authority-free migration is the
  **shadow → atomic-cutover** sequence (Wave 1a/1b), not the old "kernel + CLI,
  then migrate" two-step.

**Accepted risks.** (a) The bounded-`/orchestrate` cost regression (Q1). (b)
Temporary breakage of un-migrated consuming repos until final migration
(neutralized for the dogfood/source surface by SOURCE-ONLY).

## Approach

Each wave names its owned files and ends with a green gate
(`bash src/verify-agent-docs.sh`); staging and SOURCE-ONLY gating follow the
Discipline rules.

### Wave 0 — Lock decisions & baseline (no model calls)

Record in `docs/decisions/agent-docs.md`:

- subagent-first execution (strengthen the existing decision; orchestrators do
  coordination IO and user communication only);
- the **kernel-as-consolidation** framing, explicitly superseding "Focused
  handoffs over generated context";
- uniform `planning.scope` as the fixed `/orchestrate` entry, with the accepted
  cost regression;
- the **SOURCE-ONLY** discipline rule.

Freeze the baseline as fixtures (no model calls): the current output of
`bash src/verify-agent-docs.sh`, `--context-report`, `--measure-launch orchestrate`,
`--measure-launch quick-fix`, plus the 11-profile inventory, `classifier_allowlist`,
and representative traces.

Owned: `docs/decisions/agent-docs.md`, `docs/architecture/workflow-kit.md`,
`src/verify-fixtures/` (baseline snapshots).

### Wave 1a — Kernel as shadow (JSON)

Add `src/kernel/*.json`: `workflows.json`, `profiles.json`, `packs.json`,
`scenarios.json`. Populate `scenarios.json` by **reusing**
`src/verify-fixtures/workflow-scenarios.json`, and `profiles.json` from the
`context-profiles.md` rows. Add a `verify-kernel --equivalence` check (a new mode
of the existing verifier) proving the kernel resolves **byte-identical** profile +
scenario facts versus the current Markdown table and the JSON fixture. Markdown
remains the **only enforced authority** this wave; the kernel is unproven shadow
data — one authority at all times.

Owned: `src/kernel/*.json`, the `--equivalence` mode in `src/verify-agent-docs.sh`.

### Wave 1b — Atomic cutover (ONE commit)

In one commit: repoint `validate_context_profiles` / `contract_check` /
scenario reads / the hardcoded budget constants (`fixed_budget`,
`classifier_budget`, per-profile budgets, `classifier_allowlist`) at the kernel,
**and in the same commit** delete the superseded Markdown profile/budget tables
and the JSON fixture, leaving prose pointing at the kernel. The Wave 1a
`--equivalence` check is the rollback boundary. **Extend the existing verifier
and `--resolve`; do NOT build a parallel CLI.** No installer change is needed:
neither installer bundles `verify-fixtures/` or `kernel/` today
(`bundle_dirs=(skills rules template)`) and the verifier reads them from `src/`
directly — which the SOURCE-ONLY rule relies on.

Owned: `src/verify-agent-docs.sh`, `src/rules/context-profiles.md` (tables
deleted, prose repointed), `src/verify-fixtures/workflow-scenarios.json`
(deleted), `src/kernel/*.json`.

### Wave 2 — `planning.scope` as the fixed `/orchestrate` entry

Add the read-only `planning.scope` profile (kernel + prose) and the
workflow-brief contract (goal/non-goals, acceptance criteria, workstreams +
dependencies, authoritative docs + source/test areas, recommended profile per
phase, risk tags + required packs, targeted + final checks, user decisions, state
basis + invalidation + stop conditions). Rewrite
`/orchestrate` as a fixed controller that **always dispatches `planning.scope`
first** (no short-circuit — cost regression accepted), relays worker questions, and
resumes/delta-rereads/respawns per invalidation state. Remove its
bounded/briefed/tracked inline classification. Keep deterministic first phases for
`/quick-fix` (implementation), `/plan` (planning), doc/plan checks (inspection),
and named reviews. Add a scenario row asserting `planning.scope` first for
`/orchestrate`.

Owned: `src/kernel/profiles.json`, `src/kernel/workflows.json`,
`src/kernel/scenarios.json`, `src/skills/orchestrate/SKILL.md`,
`src/rules/orchestrator/{lifecycle,dispatch}.md`, `src/rules/subagent/planning.md`.

### Wave 3 — Profiles + exact-context resolution

Add `docs.inspect` and `plans.inspect` (read-only). Remap read-only skills off
mutating maintenance profiles (`check-docs`/`check-docs-drift` and
`review-plans-health`/`check-plans-health` must not select `maintenance.docs`/
`maintenance.plan` then subtract authority in prose). **Extend** `--resolve` /
context resolution to accept `--skill` / `--phase` / `--repo` / `--risk`, merging
kernel profile + manifest fields + `execution.yaml` fields + task-routed
docs (with heading hints) + source/test hints + allowed packs + checks + exact
resolved size. Enforce **no self-upgrade of write authority** — workers may
request an allowed pack post-discovery but may not change role or gain mutation.

Owned: `src/kernel/profiles.json`, `src/verify-agent-docs.sh` (`--resolve`
extension), `src/rules/context-profiles.md`, the affected read-only skill bodies,
`src/rules/orchestrator/dispatch.md`.

### Wave 4 — Repo execution bindings + quality packs

Add `docs/_meta/execution.yaml` to `src/template/docs/_meta/` and the dogfood
`docs/_meta/` — **required immediately**. Schema MUST cover operational fields
(language/roots, format/lint/typecheck/targeted-test/full-test/build/smoke
commands, path-to-check routing, services + startup + health + ports,
browser/screenshot workflows, db/migration commands, generated/protected/forbidden
paths, scarce resources, path/risk→pack routes) **AND the Q9 layers**
(dependency/toolchain bootstrap, secrets/credentials provisioning,
observability/log access, test-data/fixture seeding, network/external boundaries).
Add task-routed packs (frontend/UI, accessibility, backend/API, auth/security,
db-migration/data-safety, testing/reliability, performance/concurrency,
deployment/ops) — **all eight as full leaves this wave**. Implement the single
deterministic pack-merge rule `(path-routes ∪ scoper-tags) ∩ execution-allowlist`;
the resolver is the sole loader. UI resolution must include app startup, browser
exercise, screenshots, and responsive + accessibility + loading/error/empty states
when available; **missing tooling is residual risk, not green**. Update `doctor`, `rebuild-agent-docs`,
scaffold validation (`check_scaffold_tree`), manifest routes, ownership.

Owned: `src/template/docs/_meta/execution.yaml`, dogfood
`docs/_meta/execution.yaml`, `src/kernel/packs.json`, new pack rule leaves under
`src/rules/`, `src/verify-agent-docs.sh` (scaffold + execution.yaml schema
checks), `src/skills/{doctor,rebuild-agent-docs}/SKILL.md`,
`docs/_meta/{manifest.md,ownership.json}`, `docs/repository-layout.md`,
`src/agent-docs-guide.md`.

**Decided (ship all eight).** Each pack ships as a **first-class leaf** — full
rule content, kernel entry, activation trigger, evidence requirement. No stubs.
Every pack must gate (a pack present without a trigger fails).

### Wave 5 — Clean-handoff git invariant

Replace "commit every completed slice" with **"a mutating worker never hands off
unexplained owned dirt."** Three terminal states: committed / clean no-op /
explicit blocked handoff (exact owned dirty paths + check state + why a safe
commit is impossible + resume profile). **Add a discharge gate** tying a
blocked-handoff record to its resolution (committed or reverted) before final
verification. **Constrain checkpoint commits** so long/resume-sensitive work does
not revive the micro-commit cadence. Update `src/rules/repo-rules.md`, the
orchestrator dispatch/lifecycle, mutating role cards
(`src/rules/subagent/{implementation,docs-maintenance,plan-maintenance}.md`),
affected skills, `docs/decisions/agent-docs.md` (supersede "Commit-heavy worker
shipping"), the verifier assertions.

Owned: `src/rules/repo-rules.md`, `src/rules/orchestrator/{lifecycle,dispatch}.md`,
`src/rules/subagent/*.md`, `docs/decisions/agent-docs.md`,
`src/verify-agent-docs.sh`, `src/kernel/scenarios.json`.

### Wave 6a — Skill renames + coupled surfaces (ONE commit)

`check-docs`→`check-docs-drift`; `review-plans-health`→`check-plans-health`. In
**one commit** update: skill dirs + frontmatter, `src/skills/registry.md`,
`src/agent-docs-guide.md`, `docs/architecture/workflow-kit.md`,
`docs/decisions/agent-docs.md`, the verifier's scenario→skill `mapping` **code**
(the `mapping` dict in `src/verify-agent-docs.sh`), the `classifier_allowlist` if
affected, and **add `reject_unapproved_retired_name` guards** for the two old
names (mirroring the existing retired-name guards already in the verifier, with
`allow_retired_reference` exceptions for the decision-record lines). **The
installer `remove_stale_managed` / adapter-freshness coupling is DEFERRED to the
final migration** (SOURCE-ONLY rule) — do not run an installer to prune the old
skill dirs or adapter copies this wave.

Owned: `src/skills/check-docs-drift/`, `src/skills/check-plans-health/`,
`src/skills/registry.md`, `src/verify-agent-docs.sh`, `src/agent-docs-guide.md`,
`docs/architecture/workflow-kit.md`, `docs/decisions/agent-docs.md`.

### Wave 6b — Per-skill kernel-workflow-ID wiring

Each skill references exactly one kernel workflow ID plus only its unique intake /
approval / escalation / result behavior; shared machine facts stay in the kernel.

Owned: `src/skills/*/SKILL.md`, `src/kernel/workflows.json`, `src/skills/registry.md`.

### Wave 7 — Verification + RELABELED exit gate

Wire the static gates and scenario traces to fail on every item in the Exit gate
buckets below, then run the deterministic gate. Migrate durable facts per the
Migration notes.

**The FINAL migration is a SEPARATE deliberate step gated on explicit user
permission** — its steps are listed under "Remaining" in the Migration notes
below. Run it only after the overhaul is green end-to-end and authorized.

## Exit gate

Three honest buckets.

**Statically proven** (zero-dependency gate, `bash src/verify-agent-docs.sh`):

- single authority / no duplication (no profile, budget, or scenario fact lives
  in both the kernel and Markdown/bash);
- valid kernel references (every workflow/profile/pack ref resolves);
- read-only-vs-mutating consistency (no read-only skill selects a mutating
  profile);
- budgets at or above measured floors;
- source/registry/template parity;
- no resolver-written artifacts and no copied bodies in resolver output;
- `execution.yaml` schema validity (operational + Q9 fields) — full check when a
  YAML parser is available, shallow presence check with a remediation notice
  otherwise.

**Scenario-contract asserted** (proven against fixtures, not live runs):

- `/orchestrate` starts with `planning.scope` (ordering row);
- final verification observes state after the last mutation;
- pack non-activation (irrelevant packs stay unloaded);
- blocked-handoff discharge (record resolved before final verification);
- question relay (worker → orchestrator → user).

**Canary-observed only** (run at the final migration step):

- the two live feature/UI canaries per adapter (Claude Code, Codex).

**Acceptance tests to ADD:**

- a **dual-authority detector** — fail if any profile/budget/scenario lives in
  both the kernel and Markdown/bash;
- a **resolver output-snapshot test** — references only, no copied bodies;
- the **`planning.scope`-first ordering** scenario row for `/orchestrate`;
- the **pack non-activation** test;
- the **blocked-handoff discharge** test;
- the **cost-regression budget guard** for the scope-worker hop (bounds the
  accepted Q1 regression).

## Discipline rules

- **SOURCE-ONLY UNTIL FINAL MIGRATION.** All work and all
  `bash src/verify-agent-docs.sh` gating runs against `src/`. Do NOT run either
  installer (`install-agentdocs-local.sh`, `src/install-agentdocs.sh`), refresh
  `~/.agentdocs/`, or update the Claude/Codex adapter skill copies until the
  overhaul is green end-to-end AND the user explicitly authorizes one deliberate
  migration updating the runtime AND all consuming repos together. This neutralizes
  the adapter-freshness / `remove_stale_managed` coupling and consuming-repo
  breakage during the build.
- Per-wave green gate (`bash src/verify-agent-docs.sh`) before handoff.
- One mutating worker at a time on the shared tree; stage only owned files by
  filename; preserve the unrelated dirty state (the deleted plan files).
- The **kernel** is JSON read by the verifier's existing stdlib `json` — no
  second parser. `execution.yaml` stays YAML with PyYAML *optional* and graceful
  gate degradation when absent.
- Never let Markdown and the kernel both own the same machine fact.
- No quality pack without a proven path/risk trigger.
- Do not weaken gates or inflate budgets to go green; budget changes need a
  documented correctness floor (Decision E3).

## Migration notes (done at ship time)

**State: SOURCE-COMPLETE, NOT fully shipped.** Green end-to-end at `src/` (Waves
0–7b). `status: active`, `okay_to_delete: false` because the user-gated FINAL
migration has not run. Do not mark `shipped` until it completes.

Durable facts are migrated into canonical docs (a fresh chat needs none of this
plan); targets used:

- `workflow-kit.md` — kernel as machine authority vs `context-profiles.md` human
  contract; clean-handoff three states + discharge gate; `--equivalence` + no-arg
  consolidated gate; `verify-fixtures/` = baseline only (scenarios →
  `scenarios.json`); surface rows for `kernel/`, `rules/packs/`, `execution.yaml`;
  `/orchestrate`'s fixed `planning.scope` phase; brief → `subagent/planning.md`.
- `decisions/agent-docs.md` — Waves 0+5 already record Kernel-as-consolidation
  (supersedes "Focused handoffs over generated context"), uniform `planning.scope`
  + accepted cost regression, single-authority cutover, Clean-handoff invariant
  (supersedes "Commit-heavy worker shipping"), Source-only. Verified in 7b; no edit.
- `_meta/{manifest.md,ownership.json}` — `kernel-machine-authority`,
  `execution-binding`, `quality-packs`, `verifier-modes`, `verifier-fixtures`
  routed across W1b/W4/W6; renamed skills covered by the `src/skills/` glob.
- `agent-docs-guide.md` + `template/docs/` — execution.yaml required binding
  (operational + Q9); kernel is worker-context authority; template ships it.

**Authority moves.** Profiles/scenarios/budgets/packs: Markdown+bash → kernel JSON,
enforced by the dual-authority detector. `workflow-scenarios.json` →
`scenarios.json` (deleted); per-skill facts → `workflows.json`. No machine fact
lives twice.

**Remaining ONLY for the user-gated FINAL migration:** run an installer; refresh
`~/.agentdocs/` + the Claude/Codex adapter copies (prune renamed
`check-docs`/`review-plans-health` dirs via `remove_stale_managed`); roll
`execution.yaml` to other consuming repos; run the two live canaries per adapter.
Then set `status: shipped`, `okay_to_delete: true`. **No `kernel/` bundle change is
needed** — a no-install layout sim (2026-06-23) showed the runtime only runs
`--scaffold` (never the kernel); `--resolve`/full gate are source-only. The canary
should confirm how consuming-repo dispatch resolves a profile's rules at runtime.

## See also

- [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md),
  [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md),
  [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
