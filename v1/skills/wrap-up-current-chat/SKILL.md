---
name: wrap-up-current-chat
description: Capture this chat's durable knowledge into docs/architecture and docs/decisions.
---

You are wrapping up **this chat** only. This is **not** the default finish
command; use `/ship-current-work` for normal completion. Keep this skill for
chat-specific durable knowledge that is not already recoverable from docs,
code, or git history.

The goal: make this chat's history **safe to delete** without losing
knowledge. A new chat should be able to understand what the app does, how
it's architected, and why by reading `docs/`, never by replaying this chat's
edits or plans.

Scope is **this session only**. For a sweep of *all* plans on disk use
`clear-plans`; for a full codebase-wide drift sweep use `fix-docs-drift`.

This skill runs directly on this session's state — no intake questions. Read
`~/agent-docs/v1/rules/skill-contracts.md` for the shared dials and model
policy, and honor any dials passed in `$ARGUMENTS`.

Walk back through the session. For each thing you learned, built, or decided, ask:

> If this chat vanished right now, would a fresh chat be worse off — and is the fact *not* already recoverable from the docs, the code, or the git log?

Only knowledge that passes that test gets written down. The bar is **"bad to
lose" or "needed to understand the current state,"** not "true" or
"interesting."

## Where it goes

- A fact about **what the system currently IS** → the owning `docs/architecture/<doc>.md`.
- A choice about **why it's shaped this way** → the matching `docs/decisions/<domain>.md`.

Find the canonical owner in `docs/_meta/ownership.json` and follow the
authoring rules in `~/agent-docs/v1/rules/authoring-rules.md`: architecture is
rewritten **in place** and decisions use the three mandatory fields.

If **this chat** wrapped up a plan, migrate its durable context into
architecture/decisions first, then set that plan's `okay_to_delete`
truthfully per `docs/plans/index.md`.

## Restraint — add little

These docs are a **current-state snapshot**, not a changelog or a diary. Add
the minimum that keeps them true and complete:

- Don't narrate the edits you made — the git log already has them.
- Don't duplicate what the code already says — link to it by path (relative to the manifest's `code_root`).
- Don't record transient details (debugging steps, dead ends, scratch numbers, "we tried X then Y") — those should die with the chat.
- Prefer rewriting an existing sentence over appending a new paragraph.
- If nothing from this chat clears the bar, say so and change nothing. Adding noise is worse than adding nothing.

Finish by naming, in one or two lines, exactly what you changed (or that you
changed nothing) so the user can confirm the history is safe to drop.

$ARGUMENTS
