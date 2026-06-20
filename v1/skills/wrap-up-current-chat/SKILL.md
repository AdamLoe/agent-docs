---
name: wrap-up-current-chat
description: Capture this chat's durable knowledge into docs/architecture and docs/decisions.
---

You are the orchestrator for making **this chat** safe to delete. You coordinate
capture of the durable knowledge this session produced — facts, rationale, and
any plan it wrapped — into the owning architecture/decision docs by dispatching a
docs-maintenance worker that decides what is durable and where it belongs. You do
not transcribe the chat into docs yourself.

This is **not** the default finish command — `/ship-current-work` finalizes a
dirty tree. This skill captures chat-only durable knowledge that is not already
recoverable from docs, code, or git history; it does not ship a diff. Scope is
**this session only**: use `clear-plans` for a sweep of all plans on disk and
`fix-docs-drift` for a codebase-wide drift sweep.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`repo_name`, `code_root`, `decisions-domains`) → `index.md`
→ `overview.md` → stop.

This skill is **state-driven**: it runs directly off this session's history, with
no two-question intake. Read `docs/_meta/ownership.json` and the
architecture/decision docs named by the chat or pointed to by that ownership data
inline — that is coordination routing, not worker dispatch. If this chat wrapped
a plan, also read `docs/plans/index.md` and
`~/agent-docs/v1/plan-lifecycle.md`. Honor any dials passed in `$ARGUMENTS`.

Once you know what the chat produced, read
`~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
`~/agent-docs/v1/rules/orchestrator/dispatch.md` to choose worker phases and
dispatch.

## Capture Policy

The bar for migration is **"bad to lose" or "needed to understand the current
state,"** not "true" or "interesting." For each thing the chat learned, built, or
decided, the test is: if this chat vanished, would a fresh chat be worse off, and
is the fact *not* already recoverable from docs, code, or git? Only knowledge that
passes goes down.

- A fact about **what the system currently IS** → the owning
  `docs/architecture/<doc>.md`, rewritten in place.
- A choice about **why it's shaped this way** → the matching
  `docs/decisions/<domain>.md`, with the three mandatory fields.
- Add the minimum that keeps the docs true. Don't narrate edits (git has them),
  don't duplicate code (link by `code_root`-relative path), don't record
  transient details (debugging, dead ends, scratch numbers).
- If nothing from this chat clears the bar, change nothing and say so. Adding
  noise is worse than adding nothing.

## Worker Phases

Dials and model policy follow `skill-contracts.md`; dispatch shape, bundles, and
commit concurrency follow `orchestrator/dispatch.md`. Editing workers are serial
on the shared tree. Use only the phases the chat needs.

- **Docs-maintenance worker** (the durable-context migration). Pass
  `~/agent-docs/v1/rules/subagent/docs-maintenance.md` and
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md`, plus the candidate facts/rationale and
  the owning docs from `ownership.json`. It decides what is durable, updates the
  owning architecture/decisions docs in place, and commits its slice.
- **Plan-maintenance worker** only when this chat wrapped a plan and its status
  should change. Pass `~/agent-docs/v1/rules/subagent/plan-maintenance.md`,
  `~/agent-docs/v1/plan-lifecycle.md`, and
  `~/agent-docs/v1/rules/authoring-rules.md`, and
  `~/agent-docs/v1/rules/repo-rules.md`. It migrates the plan's durable context
  first, then sets `status`, `last_updated`, and `okay_to_delete` truthfully per
  `docs/plans/index.md`.
- **Verification worker** only if repo files changed and a gate is warranted.
  Pass `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`.

Editing workers stage by filename and commit their own slice before reporting;
record the hashes and verify the final state. Never push unless explicitly told.

## Closeout

Record from worker reports, in a line or two the user can confirm against:

- durable facts/rationale migrated, or that nothing cleared the bar
- docs changed
- plan status changes, if any
- checks run and result
- commit hash for edited work, or an explicit no-change result

$ARGUMENTS
