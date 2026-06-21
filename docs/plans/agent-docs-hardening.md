---
status:        shipped
owner:         codex
last_updated:  2026-06-20
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - architecture/install-and-adapters.md
  - decisions/agent-docs.md
  - repository-layout.md
---

# Agent-docs hardening plan

## Mission

Turn the repo-wide review findings into a safer, more enforceable v1 workflow
kit. The goal is not a conceptual redesign: keep router-only startup files,
tool-neutral adapters, subagent-first orchestration, disposable plans, and the
reusable `v1/` kit. Done means the scripts, verifier, rule bundles, lifecycle
docs, metadata, and skill registry enforce those promises consistently.

## Scope

In scope:

- Install and skill-copy safety.
- Kit verifier vs consuming-repo scaffold verification.
- Orchestrator dispatch bundles and mutation authority.
- Canonical shipping order and tracked-plan persistence.
- Metadata ownership, command ownership, registry validation, and layout checks.
- Skill body/registry drift cleanup.
- Reader-path docs that explain the working model without bloating routers.
- Token-economy policy folded from `token-economy.md`: cache-stable startup,
  source-first dispatch, compact output, static doc/skill budgets, and optional
  telemetry.

Out of scope:

- A new v2 format or wholesale rewrite of the v1 docs tree.
- Changing the router-only contract for `AGENTS.md` or `CLAUDE.md`.
- Implementing unrelated plan cleanup from the pre-existing deleted
  `docs/plans/` files.
- Moving durable architecture facts before the implementation proves the final
  shape.

## Accepted Scope And Deferrals

Accepted scope for this lifecycle is the work already listed in this plan's six
streams plus the five token-economy streams in `token-economy.md`. Implementation
workers should use the combined waves below as the serial source of truth; do not
treat `agent-docs-new-system-pitch.md` as a third implementation plan.

Defaults and deferred scope:

- Keep `docs/overview.md` mandatory during startup until the startup/skill wave
  completes a route audit proving every skill can classify without it. Only then
  make `docs/overview.md` task-routed.
- Run copy/install safety before any skill-body normalization or copied-adapter
  refresh. `copy-skills.sh` safety is a prerequisite, not cleanup after the
  skill rewrite.
- Static doc, rule, and skill size caps become hard verifier checks once
  documented. Per-run output caps remain review heuristics until telemetry
  exists.
- Defer per-skill budget/profile registry columns until baseline usage data
  exists.
- Keep `/list-skills`, feedback capture, and `AGENT_DOCS_SKILLS_DEST` aligned
  with source and docs after implementation workers inspect their current
  behavior; this plan does not choose those defaults from prose alone.
- Migrate useful pitch material during the reader-path closeout. Only after that
  migration may `agent-docs-new-system-pitch.md` be marked shipped and
  `okay_to_delete: true`.

## Approach

### Stream 1: Install And Adapter Safety

Owned surfaces:

- `v1/copy-skills.sh`
- `v1/install.sh`
- `README.md`
- `docs/architecture/install-and-adapters.md`
- `docs/decisions/agent-docs.md`

Work:

- Treat symlinked `~/.agents/skills` and `~/.claude/skills` roots as conflicts
  by default unless an explicit force/ownership mode is added.
- Preflight all unmanaged skill-name conflicts before deleting stale managed
  entries or copying updated skills.
- Inspect source and docs for `AGENT_DOCS_SKILLS_DEST`, then make behavior and
  documentation agree. If it remains public testing behavior, document it; if
  not, clear or ignore it from `install.sh`.
- Consider `--dry-run` for copy/install so users can inspect mutations before
  touching tool skill roots.
- Clarify the three path concepts in prose: physical checkout, canonical
  `~/agent-docs` self-reference, and copied tool skill adapters.
- Finish this stream before skill normalization or copied-adapter refresh.

Acceptance:

- `bash -n v1/install.sh`
- `bash -n v1/copy-skills.sh`
- Targeted temporary-directory checks for conflict preflight and symlink-root
  handling.
- `bash v1/verify-agent-docs.sh`

### Stream 2: Verifier And Scaffold Contract

Owned surfaces:

- `v1/verify-agent-docs.sh`
- `v1/skills/rebuild-agent-docs/SKILL.md`
- `v1/skills/doctor/SKILL.md`
- `v1/template/docs/`
- `v1/agent-docs-guide.md`
- `docs/architecture/workflow-kit.md`
- `docs/_meta/manifest.md`
- `docs/_meta/ownership.json`

Work:

- Split the verifier contract into kit-repo checks and consuming-repo scaffold
  checks, or make the scaffold checks target the current working tree through
  `/doctor`.
- Remove any implication that `~/.agentdocs/verify-agent-docs.sh` validates a
  rebuilt consuming repo when it actually validates the kit checkout.
- Add a placeholder gate for scaffold output: no `<!-- fill -->`, `"fill"`,
  empty repo name, or empty `code_root` in rebuilt docs.
- Strengthen `v1/template/docs/index.md` so seeded docs route to `overview.md`,
  `architecture/index.md`, `decisions/index.md`, `agent-context/index.md`,
  `plans/index.md`, repository layout, and `_meta`.
- Add manifest and ownership coverage for `v1/template/docs/`.

Acceptance:

- A consuming-repo scaffold can be checked without falsely validating only the
  kit checkout.
- Template placeholder checks fail on unresolved placeholders.
- `bash v1/verify-agent-docs.sh`

### Stream 3: Rules And Lifecycle Hardening

Owned surfaces:

- `v1/rules/orchestrator/dispatch.md`
- `v1/rules/orchestrator/lifecycle.md`
- `v1/rules/skill-contracts.md`
- `v1/rules/subagent/`
- `v1/rules/repo-rules.md`
- `v1/rules/authoring-rules.md`
- `v1/plan-lifecycle.md`
- `v1/skills/orchestrate/SKILL.md`
- `v1/skills/ship-current-work/SKILL.md`
- `v1/skills/ship-plans/SKILL.md`

Work:

- Make mutating bundles self-contained:
  - docs-maintenance and plan-maintenance get `repo-rules.md`;
  - review/verification only get fix authority when also given
    `implementation.md` and `repo-rules.md`, or fixes route to implementation
    workers instead.
- Pick one canonical ship order:
  - finish all code/doc/plan/run-doc mutations;
  - run the final consolidated drift gate;
  - report closeout from the verified final state.
- Document that the ship order is a set of outcome checkpoints, not a one-to-one
  subagent list. Add a durable skill-to-worker map that names which skills spawn
  planning, implementation, review, docs-maintenance, plan-maintenance, and
  verification workers, and which ship-order checkpoints each worker role owns.
- Add an explicit tracked-plan persistence actor between planning and review:
  write-capable planning worker, plan-maintenance worker, or orchestrator-owned
  persistence.
- Redefine `okay_to_delete` so it covers shipped or abandoned plans once durable
  context has been migrated or no durable context exists.
- Add a universal dirty-tree invariant: snapshot status, preserve unrelated
  user changes/deletions, stage only owned paths, and stop if unrelated dirty
  state blocks a clean slice.
- Fix stale relative links and adapter-specific wording in generic rules.

Acceptance:

- Rule bundles match the behavior they authorize.
- No workflow doc allows "green" to predate final frontmatter/run-doc edits.
- Durable workflow docs explain subagent spawn order and ship-order ownership
  clearly enough that a fresh orchestrator does not infer "one subagent per
  numbered step."
- Plan persistence is explicit enough for a fresh orchestrator to resume.
- `bash v1/verify-agent-docs.sh`

### Stream 4: Metadata And Mechanical Drift Coverage

Owned surfaces:

- `docs/_meta/manifest.md`
- `docs/_meta/ownership.json`
- `docs/repository-layout.md`
- `v1/verify-agent-docs.sh`
- `v1/skills/registry.md`

Work:

- Add inverse registry checks: no stale registry rows, duplicate rows, malformed
  rows, invalid launch tiers, or mismatched mode/action/commit metadata.
- Add curated repository-layout coverage for stable tracked surfaces such as
  `.gitattributes`, `v1/agent-docs-guide.md`, `v1/plan-lifecycle.md`, and
  `v1/plan-template.md`.
- Broaden command ownership to cover the full command surface or command
  families, aligned with `v1/skills/registry.md`.
- Separate or label repo-only checks vs local adapter freshness checks in the
  verifier output.

Acceptance:

- Registry/body drift that the review found would fail mechanically.
- Stable layout omissions are either covered by a parent row or fail the layout
  check.
- `python3 -m json.tool docs/_meta/ownership.json`
- `bash v1/verify-agent-docs.sh`

### Stream 5: Skill Suite Cleanup

Owned surfaces:

- `v1/skills/registry.md`
- `v1/skills/review-plans-health/SKILL.md`
- `v1/skills/review-skills/SKILL.md`
- `v1/skills/fix-docs-drift/SKILL.md`
- `v1/skills/feedback-agent-docs/SKILL.md`
- `v1/skills/list-skills/SKILL.md`
- `v1/skills/list-skills/list-skills.sh`
- `v1/skills/fresh-chat/SKILL.md`

Work:

- Make optional mutation explicit in registry rows, or make the affected review
  skills strictly report-only.
- Rewrite `fix-docs-drift` so cross-file judgment goes to workers; remove
  retired `Update when` / `Living notes` concepts if they are no longer part of
  the doc model.
- Inspect source and docs for feedback capture when dogfooding inside
  `agent-docs`, then align behavior with one documented destination.
- Inspect source and docs for `/list-skills`, then make the command and docs
  agree on whether it reports canonical source inventory, installed adapter
  inventory, or both with freshness state.
- Replace the undefined `fresh-chat` launch tier with a registry-valid value or
  document `any` as valid and verify it.

Acceptance:

- Registry rows honestly describe mutation/commit behavior.
- Skill inventory checks pass against source and registry.
- `bash v1/skills/list-skills/list-skills.sh`
- `bash v1/verify-agent-docs.sh`

### Stream 6: Reader Path And Pitch Docs

Owned surfaces:

- `docs/overview.md`
- `docs/plans/index.md`
- `README.md`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`

Work:

- Add a compact working-model section to `docs/overview.md`:
  subagent-first orchestration, reads-vs-dispatch, commit-heavy shipping, and
  drift gates.
- Clarify in `docs/plans/index.md` that ordinary plans and orchestrator run
  folders are temporary coordination surfaces governed by `v1/plan-lifecycle.md`.
- Keep `AGENTS.md`, `CLAUDE.md`, and `README.md` thin; do not solve
  recoverability by moving workflow facts into auto-loaded files.
- After implementation, migrate the pitch from
  `docs/plans/agent-docs-new-system-pitch.md` into architecture and decisions
  if it still reflects the system. The pitch is migration evidence only; do not
  dispatch implementation from it.

Acceptance:

- A fresh reader gets the operating model from the overview before branching.
- Router files remain facts-free.
- `bash v1/verify-agent-docs.sh`

## Combined Implementation Waves

Run editing serially on the shared working tree. Read-only planning or review can
fan out only when it does not create competing edit instructions.

1. **Install/copy safety.** Complete Stream 1 before any skill-body
   normalization or adapter refresh. This wave owns `copy-skills.sh`,
   `install.sh`, install docs, path terminology, conflict preflight,
   symlink-root handling, and the `AGENT_DOCS_SKILLS_DEST` source/docs decision.
2. **Verifier/scaffold boundary.** Complete Stream 2 so workers know whether a
   check validates the kit checkout, a consuming-repo scaffold, or local adapter
   freshness before tightening downstream gates.
3. **Combined lifecycle/dispatch policy.** Merge Stream 3 with token-economy
   Streams 2 and 3. This wave owns dispatch bundles, mutation authority, ship
   order, tracked-plan persistence, dirty-tree discipline, source-doc vs summary
   policy, compact reports, gate excerpts, and cost-dial output heuristics.
4. **Startup/skill normalization after overview audit.** Merge Stream 5 with
   token-economy Stream 1 only after Wave 1 is done. Keep `docs/overview.md`
   mandatory until this wave proves every skill can classify without it; if the
   audit passes, make it task-routed and normalize skill bodies/registry rows.
   Refresh copied adapters only through the now-safe copy path.
5. **Metadata/budgets/telemetry/enforcement.** Merge Stream 4 with the remaining
   skill-suite cleanup plus token-economy Streams 4 and 5. This wave owns
   registry/body drift checks, ownership/manifest coverage, repository-layout
   coverage, static doc/skill budget checks, optional token-usage report shape,
   and telemetry validation when data exists.
6. **Reader-path and migration closeout.** Finish Stream 6 last. Rewrite the
   overview, README, plan index, architecture, and decisions from the implemented
   state; migrate useful pitch material; then update plan statuses only after
   durable context has landed.

## Exit Gate

The plan is done when:

- The accepted scope in this plan and `token-economy.md` has shipped, and any
  deferral named in "Accepted Scope And Deferrals" is explicitly preserved in
  the final report or follow-up plan.
- Findings from
  `docs/plans/orchestrator/repo-wide-review-2026-06-19/findings/synthesis.md`
  are resolved to one of those accepted or deferred buckets.
- Durable current-state facts are migrated into:
  - `docs/architecture/install-and-adapters.md`
  - `docs/architecture/workflow-kit.md`
  - `docs/repository-layout.md`
- Durable rationale is migrated into `docs/decisions/agent-docs.md`.
- New or changed ownership mappings are in `docs/_meta/ownership.json`.
- Token-economy defaults are represented truthfully: static doc/skill caps are
  hard checks, per-run output caps are review heuristics until telemetry exists,
  and per-skill budget/profile registry columns remain deferred until baseline
  usage exists.
- Useful pitch material is migrated into architecture/decisions, and the pitch
  file is closed only after that migration.
- The final mutation is followed by:

  ```sh
  bash v1/verify-agent-docs.sh
  ```

- The final git state preserves unrelated pre-existing user changes.

## Discipline Rules

- Treat `docs/plans/orchestrator/repo-wide-review-2026-06-19/` as evidence, not
  canonical architecture.
- Do not stage or restore unrelated deleted plan files.
- Keep implementation commits grouped by stream where practical.
- Do not push without explicit user instruction.
- Do not make `AGENTS.md` or `CLAUDE.md` carry durable workflow facts.

## Migration Notes

Closeout migration targets:

- `docs/architecture/install-and-adapters.md` carries installer/copy behavior,
  adapter path ownership, conflict handling, dry-run/check behavior, and
  `AGENT_DOCS_SKILLS_DEST` scope.
- `docs/architecture/workflow-kit.md` carries the current workflow lifecycle,
  subagent-first orchestration, reads-vs-dispatch, source-first handoffs,
  ship order, commit-heavy worker model, verifier/scaffold boundary, static
  budgets, and optional usage reporting.
- `docs/overview.md` carries the compact reader-path working model.
- `docs/plans/index.md` carries temporary plan and run-folder lifecycle routing.
- `docs/repository-layout.md` carries stable path inventory.
- `docs/decisions/agent-docs.md` carries rationale for adapter ownership,
  verifier modes, overview route gating, mutation authority, source-first
  handoffs, static budgets before usage gates, final-state shipping order,
  and focused v1 handoffs over generated context.
- `docs/_meta/manifest.md` and `docs/_meta/ownership.json` carry the current
  routing and ownership coverage for the shipped surfaces.

Useful pitch material was already migrated into those targets without
historical framing; this plan no longer owns durable current-state context.

## See Also

- [`agent-docs-new-system-pitch.md`](agent-docs-new-system-pitch.md)
- [`token-economy.md`](token-economy.md)
- [`orchestrator/repo-wide-review-2026-06-19/findings/synthesis.md`](orchestrator/repo-wide-review-2026-06-19/findings/synthesis.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../../v1/plan-template.md`](../../v1/plan-template.md)
