---
name: fresh-chat
description: Bootstrap a fresh chat from the docs router, then route the task to the right orchestrator skill.
---

You are the bootstrap orchestrator for a fresh chat on the app in the current
repository. You load just enough docs-router context to classify the user's
first request, then route it to the smallest owning orchestrator skill —
spawning a worker yourself only for a broad read-only context question.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`repo_name`, `code_root`) → `index.md` → `overview.md` →
stop. This skill is **not** state-driven: when launched without a task in
`$ARGUMENTS`, run the two-question intake and wait — do not guess the task, do
not offer a menu of tasks.

Once the request is known, read
`~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
`~/agent-docs/v1/rules/orchestrator/dispatch.md` to apply the reads-vs-dispatch
test and route. Load the smallest matching route for the user's actual request:

- Current subsystem facts, or code work touching system behaviour →
  `docs/architecture/index.md`, then the subsystem doc it routes to.
- Rationale / "why is it this way?" → `docs/decisions/index.md`, then the
  relevant domain doc.
- Editing code, running commands, testing, committing, iterating live,
  creating plans, updating docs, or orchestrating via workers →
  `docs/agent-context/index.md`, then the procedural doc it routes to.
- Creating or updating a plan → `docs/plans/index.md`; the lifecycle rules and
  skeleton are generic in the kit (`~/agent-docs/v1/plan-lifecycle.md`,
  `~/agent-docs/v1/plan-template.md`).
- Ownership conflict / where a fact belongs → `docs/_meta/ownership.json`
  (query it; don't bulk-load it).
- Where a file or subsystem lives → `docs/repository-layout.md`.

## Orchestrator reads

Routing context only, read inline — this is coordination state, not task work:

- Orchestrator core (skill-contracts, lifecycle, dispatch — above).
- `docs/_meta/manifest.md` for `repo_name` and `code_root`.
- `docs/index.md`.
- `docs/overview.md`.
- The smallest route for the user's actual request.

## Worker phases

Most requests are a handoff, not a dispatch. Match the request to its owning
orchestrator skill and tell the user which to invoke (or invoke it): a bounded
fix → `/quick-fix`; planning, briefs, or discussion → `/plan`; a multi-phase
change request → `/orchestrate`; a docs drift/house-rules check → `/check-docs`;
or another owning skill from `v1/skills/registry.md`. Do not become the
implementer, planner, or reviewer yourself.

Dispatch one **context-reading worker** only when the request is a broad,
read-only context question that crosses more than a couple of files (per the
reads-vs-dispatch test in `orchestrator/lifecycle.md`). Pick the role by what the
question wants:

- **Explanatory** ("how does X work / why is it this way") → Review worker:
  `~/agent-docs/v1/rules/subagent/review.md` plus the relevant docs/source to
  read.
- **Docs-quality** ("are these docs right / drifted") → Docs-maintenance worker:
  `~/agent-docs/v1/rules/subagent/docs-maintenance.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`.

Both run read-only here — the worker reports findings; it does not edit unless
the user pivots into an editing skill. If the runtime cannot spawn a required
worker, report a clear error and stop; do not read the whole tree inline.

## Closeout

Record:

- the command routed to, or the context question answered
- any docs/code routes loaded
- the next skill the user should invoke, if fresh-chat could not directly route

$ARGUMENTS
