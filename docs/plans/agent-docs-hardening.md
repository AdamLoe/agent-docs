---
status:        draft
owner:         codex
last_updated:  2026-06-19
okay_to_delete: false
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

Out of scope:

- A new v2 format or wholesale rewrite of the v1 docs tree.
- Changing the router-only contract for `AGENTS.md` or `CLAUDE.md`.
- Implementing unrelated plan cleanup from the pre-existing deleted
  `docs/plans/` files.
- Moving durable architecture facts before the implementation proves the final
  shape.

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
- Decide whether `AGENT_DOCS_SKILLS_DEST` is public testing behavior. Document
  it if yes; clear or ignore it from `install.sh` if no.
- Consider `--dry-run` for copy/install so users can inspect mutations before
  touching tool skill roots.
- Clarify the three path concepts in prose: physical checkout, canonical
  `~/agent-docs` self-reference, and copied tool skill adapters.

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
- Remove any implication that `~/agent-docs/v1/verify-agent-docs.sh` validates a
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
- Decide where feedback capture lives when dogfooding inside `agent-docs`:
  ignored in-repo inbox, out-of-repo inbox, or committed feedback records.
- Decide whether `/list-skills` reports canonical source inventory, installed
  adapter inventory, or both with freshness state.
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
  if it still reflects the system.

Acceptance:

- A fresh reader gets the operating model from the overview before branching.
- Router files remain facts-free.
- `bash v1/verify-agent-docs.sh`

## Sequencing

1. **Install safety first.** This is the only finding with realistic user-data or
   tool-discovery risk.
2. **Verifier/scaffold second.** The kit needs to know what it is validating
   before tightening every downstream gate.
3. **Rules/lifecycle third.** Once verification boundaries are clear, align
   dispatch bundles, ship order, plan persistence, and dirty-tree discipline.
4. **Metadata fourth.** Add ownership and mechanical drift checks after the
   intended contracts are stable.
5. **Skill cleanup fifth.** Bring registry and skill bodies into the hardened
   contract.
6. **Reader path last.** Rewrite overview/README/architecture language after the
   implementation has settled.

Parallelism:

- Streams 1 and 2 should run serially if both touch verifier/install docs.
- Stream 3 should run mostly serially because the same central rule files
  define lifecycle semantics.
- Streams 4 and 5 can run in parallel after Streams 2 and 3 settle if they use
  disjoint files.
- Stream 6 should be final docs-maintenance work.

## Exit Gate

The plan is done when:

- All accepted findings from
  `docs/plans/orchestrator/repo-wide-review-2026-06-19/findings/synthesis.md`
  are fixed or explicitly deferred.
- Durable current-state facts are migrated into:
  - `docs/architecture/install-and-adapters.md`
  - `docs/architecture/workflow-kit.md`
  - `docs/repository-layout.md`
- Durable rationale is migrated into `docs/decisions/agent-docs.md`.
- New or changed ownership mappings are in `docs/_meta/ownership.json`.
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

At ship time, migrate:

- Installer/copy behavior and adapter path model to
  `docs/architecture/install-and-adapters.md`.
- Workflow lifecycle, dispatch bundles, ship order, and plan persistence to
  `docs/architecture/workflow-kit.md`.
- Repository inventory and stable layout coverage to
  `docs/repository-layout.md`.
- Rationale for verifier split, mutation authority, adapter ownership, and
  feedback/list-skills behavior to `docs/decisions/agent-docs.md`.
- Ownership changes to `docs/_meta/ownership.json`.

## See Also

- [`agent-docs-new-system-pitch.md`](agent-docs-new-system-pitch.md)
- [`orchestrator/repo-wide-review-2026-06-19/findings/synthesis.md`](orchestrator/repo-wide-review-2026-06-19/findings/synthesis.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../../v1/plan-template.md`](../../v1/plan-template.md)
