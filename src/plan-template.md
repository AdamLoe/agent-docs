---
status:        draft
owner:         unassigned
last_updated:  YYYY-MM-DD
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/<doc>.md
  - decisions/<domain>.md
---

# Plan title

## Mission

One paragraph. What's the goal? Why does it matter now? What constitutes
done?

## Scope

What's in scope. What's deliberately out of scope (and where the cut
line is).

## Approach

Decomposition into independent units of work. Identify what can run in
parallel and what serializes. If the work is going to be done by
subagents, name the streams and their owned-file sets.

## Exit gate

The named commands or assertions that prove this plan is done. Specific.
For implementation work this is usually a test or a manual smoke; for
design work it's "the relevant architecture doc reflects the new shape
and decisions/<domain>.md has the entry."

## Discipline rules

Anything specific to this plan that overrides the defaults. Most plans
need none of this; delete the section if unused.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, walk through this plan and route every
fact / decision / trade-off into:

- `architecture/<doc>.md` — for current-state facts.
- `decisions/<domain>.md` — for design choices and trade-offs.
- `_meta/ownership.json` — for any new concept-to-doc routing.

List what was migrated and where, so a reviewer can confirm
`okay_to_delete: true` is honest.

## See also

- The app's `docs/plans/index.md` — where live plans land.
- [`plan-lifecycle.md`](plan-lifecycle.md) — status metadata and the
  ship-time migration workflow.
- The owning docs listed in the frontmatter.
