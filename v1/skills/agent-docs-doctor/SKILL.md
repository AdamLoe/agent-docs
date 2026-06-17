---
name: agent-docs-doctor
description: Validate an agent-docs tree for required scaffold files, manifest slots, ownership data, skill registry coverage, and stale v1 references.
---

You are running a structural validator for an agent-docs v1 tree. This is a
mechanical health check, not an editorial docs review and not a drift repair
sweep. Default to report-only: run checks and report failures. If the user
asks you to fix failures, make the smallest repairs and finish through
`/ship-current-work` semantics.

## Bootstrap

1. Read `docs/_meta/manifest.md`.
2. Read `docs/_meta/ownership.json`.
3. Read `v1/skills/registry.md` and `v1/rules/skill-contracts.md` when
   validating this kit repo.
4. Read the manifest `drift-gates` slot and run the narrow static gates that
   do not mutate `$HOME` or external state.

## Checks

Validate:

- Required scaffold files exist: `docs/index.md`, `docs/overview.md`,
  `docs/_meta/manifest.md`, `docs/_meta/ownership.json`, and the four doc
  roots `architecture/`, `decisions/`, `agent-context/`, `plans/`.
- Manifest slots exist: `repo_name`, `agent_docs_version`, `code_root`,
  `change-to-doc`, `drift-gates`, `drift-verification`, and
  `decisions-domains`.
- `docs/index.md` visibly routes app bindings and ownership questions to
  `_meta/manifest.md` and `_meta/ownership.json`.
- Ownership data is parseable JSON and every owner path points at an existing
  file or directory.
- Skills are registered: every `v1/skills/*/SKILL.md` frontmatter `name:`
  matches its directory and has a row in `v1/skills/registry.md`.
- No stale live references remain to retired entry points or prose ownership
  guides.
- Manifest `drift-gates` pass, or failures are reported with the exact gate
  that failed.

## Report Format

1. **Verdict** - pass/fail and the highest-impact failure.
2. **Failures** - exact file/path/gate and why it matters.
3. **Warnings** - non-blocking issues that could become drift.
4. **Checks Run** - commands or manual checks performed.
5. **Next Step** - fix now, run a deeper drift sweep, or leave clean.

$ARGUMENTS
