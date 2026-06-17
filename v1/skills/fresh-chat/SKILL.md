---
name: fresh-chat
description: Bootstrap a fresh chat from the docs router, then wait for the task.
---

You are bootstrapping a fresh chat on the app in the current working
directory. Its documentation lives under `docs/` and follows agent-docs v1.

Normal work finishes with `/ship-current-work`.

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`repo_name`, `code_root`) → `index.md` → `overview.md`
→ stop. If the user has not yet described their task, run the two-question
intake and wait — do not guess the task or offer a menu.

Once the user describes what they want, load the smallest matching route:

- Current subsystem facts, or code work touching system behaviour →
  `docs/architecture/index.md`, then the subsystem doc it routes to.
- Rationale / "why is it this way?" → `docs/decisions/index.md`, then the
  relevant domain doc.
- Editing code, running commands, testing, committing, iterating live,
  creating plans, updating docs, or orchestrating via sub-agents →
  `docs/agent-context/index.md`, then the procedural doc it routes to.
- Creating or updating a plan → `docs/plans/index.md`; the lifecycle rules
  and skeleton are generic in the kit
  (`~/agent-docs/v1/plan-lifecycle.md`, `~/agent-docs/v1/plan-template.md`).
- Ownership conflict / where a fact belongs → `docs/_meta/ownership.json`
  (query it; don't bulk-load it).
- Where a file or subsystem lives → `docs/repository-layout.md`.

The doc-authoring and maintenance rules are global (agent-docs v1) — load
`~/agent-docs/v1/rules/authoring-rules.md` only when you ship a change and
need to update docs.

The user's first message:

$ARGUMENTS
