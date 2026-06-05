---
description: Sweep docs/plans/ to keep it lean — delete plans already flagged okay_to_delete, and for shipped/abandoned plans not yet flagged, migrate their durable context into docs/architecture and docs/decisions then flip okay_to_delete. Leaves active/draft/long_lived plans alone. Independent of the current chat's history.
---

You are sweeping `docs/plans/` to keep it lean. A plan is a working coordination doc, not canonical knowledge: once its work has shipped **and** its durable context has been migrated into `architecture/`/`decisions/`, the plan should be deleted. This sweep is **independent of the current chat** — start from what's on disk and in git, not from this conversation's history.

Read the lifecycle rules first: `docs/plans/index.md` (the meaning of `status`, `okay_to_delete`, `long_lived`) and the migration rules in `${CLAUDE_PLUGIN_ROOT}/rules/authoring-rules.md` (architecture rewritten **in place**; decisions get the three mandatory fields). This skill restates neither.

## The sweep

`ls docs/plans/`. For every plan file (skip `index.md` and `template.md`), read its frontmatter and sort it into one bucket:

**1. `okay_to_delete: true` → delete it.**
First do a 10-second sanity check: open the `owning_docs` and confirm they actually carry the plan's key facts/decisions. If migration looks genuinely complete, `rm` the plan (it's tracked — git can recover it) and record it under *deleted*. If migration looks **incomplete** despite the flag, do **not** delete — treat it as bucket 2 instead and note the mislabel.

**2. `status: shipped` or `abandoned`, but `okay_to_delete: false` → the main job.**
- Confirm the work really shipped/was-dropped: check the git log and the code the plan claims to have produced. If you can't confirm, leave it and report why (bucket 4).
- Migrate every durable fact, decision, and trade-off into the owning `docs/architecture/<doc>.md` / `docs/decisions/<domain>.md`. Same bar as `wrap-up-current-chat`: only what would be **bad to lose** or is **needed to understand the current state**. Skip transient prose (debug logs, dead ends, "tried X then Y"). Code paths in docs are relative to `src/`.
- Once migration is complete, set `okay_to_delete: true` and bump `last_updated`. **Then stop — do not delete it this pass.** A freshly-migrated plan is left on disk so the user can eyeball the migration diff; the *next* `clear-plans` run removes it via bucket 1. Record it under *migrated → flagged*.

**3. `status: active` or `draft` → leave it.** Work is in flight. Record it under *left (in flight)*, one line, so the user sees the live set.

**4. `long_lived: true` → leave it.** Record it under *left (long-lived)* with a one-line note on why it can't be migrated (if the frontmatter doesn't already say).

## Don'ts

- Don't delete anything you haven't confirmed is **both** shipped **and** fully migrated.
- Don't delete a freshly-migrated plan in the same pass — flag it and let the user review before the next sweep removes it.
- Don't invent decisions to record. If the rationale is already in `docs/decisions/`, just confirm and move on.
- Don't migrate transient prose. The git history of the plan keeps it.

## Finish

Report four short lists: **deleted**, **migrated → flagged** (with which docs got updates), **left (in flight / long-lived)**, and **needs human** (couldn't confirm shipped, or migration needs a judgment call you shouldn't make alone). Keep each entry to one line.

$ARGUMENTS
