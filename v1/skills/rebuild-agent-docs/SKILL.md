---
name: rebuild-agent-docs
description: Rebuild or repair an app's docs/ tree into the agent-docs v1 scaffold. Seed missing files from ~/agent-docs/v1/template/docs/, adapt them to the repo, and retire the old one-off new-project prompt.
---

You are the orchestrator for adopting or repairing a repo's agent-docs v1 docs
scaffold. This is a **mutating maintenance workflow**: seed missing scaffold
files from the shared template, adapt them to the repo, repair manifest and
ownership state, and ship. You coordinate maintenance and verification workers —
you do not seed templates or hand-edit docs in your own context.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**. This skill is **state-driven**: it operates on the target repo's
existing docs path and scaffold rather than a user-described task, so it skips
the two-question intake and runs directly off that state. Honor any dials passed
in `$ARGUMENTS`; default `cost-medium`.

Read the orchestration state inline (this is routing, not worker dispatch):

- `~/agent-docs/v1/agent-docs-guide.md` — the v1 scaffold and routing model you
  are rebuilding toward.
- the `~/agent-docs/v1/template/docs/` inventory — the canonical seed set:
  `index.md`, `overview.md`, `repository-layout.md`, `architecture/index.md`,
  `decisions/index.md`, `agent-context/index.md`, `plans/index.md`,
  `_meta/manifest.md`, `_meta/ownership.json`.
- the current docs path (default `docs/`) and any existing `_meta/manifest.md`
  and `_meta/ownership.json` — to inventory what is present, partial, or stale.
- `~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
  `~/agent-docs/v1/rules/orchestrator/dispatch.md` to classify and dispatch.

## Scope Policy

- `$ARGUMENTS` may name a current docs path (default `docs/`), an example docs
  path used only as a shape reference, dials, and a rebuild-vs-patch preference.
- If the source docs path is not `docs/`, the rebuild migrates the scaffold
  toward `docs/` rather than preserving a custom docs root.
- Keep the output app-agnostic. An example docs path is a shape reference only —
  never copy its app-specific facts or hardcode its path into the result.
- `docs/_meta/manifest.md` binds repo-specific facts; `docs/_meta/ownership.json`
  is the tie-breaker when two docs could own the same fact. Both must stay
  visible from `docs/index.md` and `docs/overview.md`.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape, rule
bundles, and commit concurrency follow `orchestrator/dispatch.md`. Use only the
phases the repo's state needs.

- **Docs-maintenance worker** (scaffold inventory + migration — the core
  phase). Pass `~/agent-docs/v1/rules/subagent/docs-maintenance.md` and
  `~/agent-docs/v1/rules/authoring-rules.md`. It inventories the current docs
  against the v1 scaffold, **seeds each missing file from
  `~/agent-docs/v1/template/docs/` before adapting it** to the repo, applies the
  recoverability test (keep map/why/routing; collapse recoverable transcription
  to pointers), and repairs manifest and ownership state. If a stale prose
  ownership guide exists, it migrates durable routing facts into
  `docs/_meta/ownership.json` and removes the prose file once it owns nothing
  unique. Larger rebuilds fan this worker out by subtree at `cost-high`/`max`,
  serial on the shared tree.
- **Implementation worker** only when the rebuild needs a script or template
  repair (not just doc edits). Pass `~/agent-docs/v1/rules/subagent/implementation.md`,
  `~/agent-docs/v1/rules/coding-style.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`,
  `~/agent-docs/v1/rules/repo-rules.md`.
- **Verification worker** for the scaffold gate. Pass
  `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`; have it run
  `~/agent-docs/v1/verify-agent-docs.sh --scaffold <target-repo-root>` against
  the rebuilt tree plus any target manifest `drift-gates`, and paste the
  result. The verifier without `--scaffold` checks the shared kit checkout, not
  the consuming repo.
- **Plan-maintenance worker** only when the rebuild creates or retires plan
  material under `docs/plans/`. Pass
  `~/agent-docs/v1/rules/subagent/plan-maintenance.md`,
  `~/agent-docs/v1/plan-lifecycle.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`.

## Closeout

Record from worker reports:

- scaffold files created or updated (seeded vs. adapted)
- manifest and ownership state after repair, and any stale prose guide retired
- gates run (`verify-agent-docs.sh --scaffold <target-repo-root>` plus target
  manifest drift gates) and result
- commit hash(es)
- assumptions made and any follow-up that remains

$ARGUMENTS
