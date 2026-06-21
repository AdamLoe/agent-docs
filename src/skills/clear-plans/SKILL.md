---
name: clear-plans
description: Sweep docs/plans/ to delete flagged plans and flag shipped ones after migration.
---

You are the orchestrator for plan cleanup over the repository's disk and git
state. You coordinate the sweep through a plan-maintenance worker that buckets
plans and run folders, migrates durable context into owning docs, flags freshly
migrated plans, and deletes only already-verified cleanup candidates — you do not
hand-edit plans or migrate facts in your own context.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`, plus `change-to-doc`
and `drift-gates`/`drift-verification` for any migration follow-up.

This skill is **state-driven**: it runs directly off `docs/plans/` and git state,
so there is no two-question intake. Honor any dials passed in `$ARGUMENTS` where
they affect fan-out or model spend. Read `docs/plans/index.md`,
`~/.agentdocs/plan-lifecycle.md`, and the manifest for lifecycle and ownership
context inline; query `docs/_meta/ownership.json` for migration targets rather
than bulk-loading it. Then read `~/.agentdocs/rules/orchestrator/lifecycle.md`
and `~/.agentdocs/rules/orchestrator/dispatch.md` to dispatch.

A plan is working coordination, not canonical knowledge: once its work has
shipped **and** its durable context has been migrated into
`architecture/`/`decisions/`, the plan should be deleted. Start from what is on
disk and in git, not from this conversation's history. Reading and summarizing
the plan set, run-folder `hub.md` frontmatter, and `git status` is inline routing
work; the sweep itself — bucketing, migration, flagging, and deletion — is worker
work.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape, rule bundles,
and commit concurrency follow `orchestrator/dispatch.md`. Each phase below names
the exact rule files to pass in the dispatch packet.

- **Plan-maintenance worker** (the sweep and migration — the main job). Pass
  `~/.agentdocs/rules/subagent/plan-maintenance.md`,
  `~/.agentdocs/plan-lifecycle.md`,
  `~/.agentdocs/rules/authoring-rules.md`, and
  `~/.agentdocs/rules/repo-rules.md`. It sweeps top-level plan files
  (skipping `index.md` and `template.md`) and run folders, buckets each one
  (in-flight, ready-to-migrate, ready-to-delete, needs-human, long-lived),
  migrates durable facts and rationale into the owning docs **before** any status
  change, then:
  - **`okay_to_delete: true`** — sanity-checks that the owning docs carry the key
    facts, confirms the latest plan/run-doc version is tracked in local git with
    no staged/unstaged/renamed/deleted/untracked changes, and only then deletes
    (tracked files stay recoverable through git history). If a candidate is dirty
    or untracked it is **not** deleted this pass — report that the latest version
    must be committed first, or route to `ship-current-work`. If migration looks
    incomplete despite the flag, treat it as ready-to-migrate and note the
    mislabel.
  - **shipped/abandoned but `okay_to_delete: false`** — confirm the work really
    shipped/was dropped against git log and code, migrate every durable fact, set
    `okay_to_delete: true` and bump `last_updated` (or record the same closeout
    state in a run folder's `hub.md`), then **stop without deleting**. Freshly
    migrated material is left on disk so the user can eyeball the migration diff;
    the *next* sweep removes it. Record it as migrated → flagged.
  - **active/draft** — leave in flight. **`long_lived: true`** — leave, with a
    one-line note on why it cannot migrate. Run folders with no `hub.md`, no
    lifecycle frontmatter, or no clear closeout state — leave and flag as
    needs-human.

  It commits its slice before reporting.
- **Docs-maintenance worker** only when the migration targets need real
  architecture/decision edits beyond what the plan-maintenance worker handles
  cleanly. Pass `~/.agentdocs/rules/subagent/docs-maintenance.md` and
  `~/.agentdocs/rules/authoring-rules.md`, and
  `~/.agentdocs/rules/repo-rules.md`. Architecture is rewritten in place;
  decisions get the mandatory fields. Code paths in docs are relative to the
  manifest's `code_root`.
- **Verification worker** only when files changed and a final drift gate is
  better isolated. Pass `~/.agentdocs/rules/subagent/verification.md` and
  `~/.agentdocs/rules/repo-rules.md`.

Never delete a plan or run-doc whose latest version is not already in local git
history, and never delete a freshly migrated plan in the same pass — flagging it
lets the user review before the next sweep removes it.

## Closeout

Record from worker reports, one line per entry:

- **deleted** — plans/run folders removed this pass
- **migrated → flagged** — with which architecture/decisions docs got updates
- **left** — in flight and long-lived
- **needs human** — couldn't confirm shipped, or migration needs a judgment call
- commit hash when changes were made

$ARGUMENTS
