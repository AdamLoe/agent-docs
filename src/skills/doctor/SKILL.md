---
name: doctor
description: Validate an agent-docs tree for required scaffold files, manifest slots, ownership data, skill registry coverage, and stale v1 references, reporting failures and spawning fix workers only when asked to repair.
---

You are the orchestrator for scaffold and registry health validation in the
current repository. This is a mechanical structural check, not an editorial docs
review and not a drift-repair sweep. You are **report-only by default**: dispatch
a verification worker, record what it found, and report. Only when the user asks
you to repair failures do you spawn fix workers, and then you finish through the
shared shipping shape.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`, `drift-gates`. doctor
is **state-driven**: it runs off existing disk and git state, so it skips both
intake questions and does not stop to ask for a task. It still honors dials
passed in `$ARGUMENTS`. Do NOT pre-load `context-profiles.md`, `dispatch.md`, or
`lifecycle.md` at startup.

Read the coordination state inline: `docs/_meta/manifest.md`,
`docs/_meta/ownership.json`, `~/.agentdocs/skills/registry.md`,
`~/.agentdocs/rules/skill-contracts.md`, and the static gate commands recorded in
the manifest `drift-gates` slot.

## What gets validated

The verification worker confirms:

- Required scaffold files exist: `docs/index.md`, `docs/overview.md`,
  `docs/repository-layout.md`, `docs/_meta/manifest.md`,
  `docs/_meta/ownership.json`, and the four doc roots `architecture/`,
  `decisions/`, `agent-context/`, `plans/`.
- Manifest slots exist: `repo_name`, `agent_docs_version`, `code_root`,
  `change-to-doc`, `drift-gates`, `drift-verification`, `decisions-domains`.
- `docs/index.md` visibly routes app bindings and ownership questions to
  `_meta/manifest.md` and `_meta/ownership.json`.
- Ownership data is parseable JSON and every owner path points at an existing
  file or directory.
- Every `~/.agentdocs/skills/*/SKILL.md` frontmatter `name:` matches its directory and has
  a row in `~/.agentdocs/skills/registry.md`.
- No stale live references remain to retired entry points or prose ownership
  guides.
- The manifest `drift-gates` pass. `~/.agentdocs/verify-agent-docs.sh` with no arguments
  is the standard static gate for this kit; consuming-repo scaffold validation
  uses `~/.agentdocs/verify-agent-docs.sh --scaffold <repo-root>`. Failures
  name the exact gate.

## Worker Phases

Workers resolve context via `bash src/verify-agent-docs.sh --resolve <profile-id>`.
Run the verification worker first, every invocation; fix workers run only when
the user asks to repair failures.

- **Verification worker** (the health check). Profile: `verification.readonly`.
  It runs the scaffold, manifest, registry, and stale-reference checks above. In
  this kit repo, that typically means `~/.agentdocs/verify-agent-docs.sh` plus the
  manifest `drift-gates`; in a consuming repo, the scaffold portion is
  `~/.agentdocs/verify-agent-docs.sh --scaffold <repo-root>` plus the target
  manifest `drift-gates`. It reports each failure with the exact file, path, or
  gate that failed. It stays read-only.
- **Docs-maintenance worker** only when authorized to repair doc-scaffold
  failures (missing required files, manifest-slot or routing gaps, dead ownership
  paths). Profile: `maintenance.docs`. It makes the smallest repair and commits
  its slice.
- **Implementation worker** only when authorized to repair a failing verifier or
  gate script. Profile: `implementation.code-docs`. It fixes the script, re-runs
  the gate, and commits.

Repair work follows the shared shipping shape: a fix worker commits its slice,
then re-run the verification worker to confirm green before closeout.

## Closeout

Record from worker reports:

- **Critical failures** — missing scaffold, broken manifest, unparseable
  ownership: the tree is not a valid agent-docs v1 kit until fixed.
- **Repairable failures** — registry gaps, dead ownership paths, stale
  references a fix worker can close.
- **Warnings** — non-blocking issues that could become drift.
- **Gates run** — the exact commands and their pasted results.
- **Next step** — fix now (and which worker), run a deeper drift sweep, or leave
  clean.

## References (do not auto-load)

- `~/.agentdocs/rules/orchestrator/dispatch.md` — dispatch and commit contract
- `~/.agentdocs/rules/context-profiles.md` — profile IDs and resolver

$ARGUMENTS
