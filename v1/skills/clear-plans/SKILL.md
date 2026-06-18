---
name: clear-plans
description: Sweep docs/plans/ to delete flagged plans and flag shipped ones after migration.
---

You are sweeping `docs/plans/` to keep it lean. A plan is working coordination, not canonical knowledge: once its work has shipped **and** its durable context has been migrated into `architecture/`/`decisions/`, the plan should be deleted. Start from what's on disk and in git, not from this conversation's history.

This skill runs directly on disk state — no intake questions. Read `~/agent-docs/v1/rules/skill-contracts.md` for the shared dials and model policy, and honor any dials passed in `$ARGUMENTS`.

Read the lifecycle rules first: `docs/plans/index.md` and `~/agent-docs/v1/rules/authoring-rules.md`. Architecture is rewritten **in place**; decisions get the three mandatory fields.

## The sweep

`ls docs/plans/`. Sweep top-level plan files (skip `index.md` and
`template.md`) and immediate run folders under `docs/plans/orchestrator/`.
Run folders are temporary orchestration coordination history; read `hub.md`
first and use its frontmatter (`status`, `okay_to_delete`, `long_lived`, and
`owning_docs`) plus closeout/migration notes as the status source. If a run
folder has no `hub.md`, no lifecycle frontmatter, or no clear
closeout/migration state, leave it and report it under bucket 4.

For every plan file or run folder, sort it into one bucket:

**1. `okay_to_delete: true` → delete it.**
First do a 10-second sanity check: open the `owning_docs` or hub migration
targets and confirm they actually carry the plan or run's key facts/decisions.
Before deleting, confirm the latest plan or run-doc content is recoverable in
local git history: all candidate files must be tracked and have no staged,
unstaged, renamed, deleted, or untracked changes. If any candidate file is
dirty or untracked, do **not** delete it in this pass; report that the latest
plan/run-doc version needs to be committed first, or route to
`ship-current-work` when the dirty tree is coherent. If migration looks
genuinely complete and the candidate is clean, delete the plan file or run
folder (tracked files are recoverable through git) and record it under
*deleted*. If migration looks **incomplete** despite the flag, do **not**
delete — treat it as bucket 2 instead and note the mislabel.

**2. `status: shipped` or `abandoned`, but `okay_to_delete: false` → the main job.**
- Confirm the work really shipped/was-dropped: check the git log and the code the plan claims to have produced. If you can't confirm, leave it and report why (bucket 4).
- Migrate every durable fact, decision, and trade-off into the owning `docs/architecture/<doc>.md` / `docs/decisions/<domain>.md`. Same bar as `wrap-up-current-chat`: only what would be **bad to lose** or is **needed to understand the current state**. Skip transient prose. Code paths in docs are relative to the manifest's `code_root`.
- Once migration is complete, set `okay_to_delete: true` and bump
  `last_updated` for a plan file, or record the same closeout state in a run
  folder's `hub.md` frontmatter and migration notes. **Then stop — do not
  delete it this pass.** Freshly migrated plan material is left on disk so the
  user can eyeball the migration diff; the *next* `clear-plans` run removes it
  via bucket 1. Record it under *migrated → flagged*.

**3. `status: active` or `draft` → leave it.** Work is in flight. Record it under *left (in flight)*, one line, so the user sees the live set.

**4. `long_lived: true` → leave it.** Record it under *left (long-lived)* with a one-line note on why it can't be migrated (if the frontmatter doesn't already say).

## Don'ts

- Don't delete anything you haven't confirmed is **both** shipped **and** fully migrated.
- Don't delete plan or run-doc files whose latest version is not already in
  local git history.
- Don't delete a freshly-migrated plan in the same pass — flag it and let the user review before the next sweep removes it.
- Don't invent decisions to record. If the rationale is already in `docs/decisions/`, just confirm and move on.
- Don't migrate transient prose. The git history of the plan keeps it.

## Finish

Report four short lists: **deleted**, **migrated → flagged** (with which docs got updates), **left (in flight / long-lived)**, and **needs human** (couldn't confirm shipped, or migration needs a judgment call you shouldn't make alone). Keep each entry to one line.

$ARGUMENTS
