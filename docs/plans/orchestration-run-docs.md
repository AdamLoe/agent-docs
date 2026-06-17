---
status:        draft
owner:         codex
last_updated:  2026-06-17
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
  - ../v1/agent-docs-guide.md
  - ../v1/plan-lifecycle.md
  - ../v1/rules/orchestrating.md
  - ../v1/skills/orchestrate/SKILL.md
---

# Opt-in orchestration run docs

## Mission

Define a lightweight, plan-native state format for long orchestration runs so
orchestrators and subagents can persist observed state without inventing a new
handoff flow every time. The work is done when `/orchestrate` can use committed
run docs under `docs/plans/orchestrator/<run>/` only after user permission, and
those run docs remain disposable through the normal plan cleanup lifecycle.

## Scope

In scope:

- Add a standard run-doc layout under `docs/plans/orchestrator/<run>/`.
- Define when run docs are allowed: the user explicitly asks for them, or the
  orchestrator asks and receives permission before creating them.
- Allow subagents to update run docs when dispatched into a stateful run.
- Keep the orchestrator responsible for hub consistency, closeout, and
  migration of durable facts.
- Commit run docs as part of orchestration history, while still treating them
  as temporary coordination surfaces that can be cleaned up like shipped plans.

Out of scope:

- Reintroducing retired orchestration command names.
- Making every `/orchestrate` run create persistent coordination files.
- Creating a hidden `docs/.orchestration/` state area.
- Building a rigid workflow engine or requiring agents to follow detailed
  task-by-task state transitions.

## Current direction

Use the existing `/orchestrate` command with an explicit run-doc mode instead
of adding a new command. The trigger should be user wording such as "use run
docs", "stateful orchestration", or "create an orchestration run folder".
If the user has not asked for run docs, the orchestrator may ask for permission
when resume risk is high, but it must not create the folder on its own.

Standard layout:

```text
docs/plans/orchestrator/<run-slug>/
  hub.md
  streams/
    <stream-id>.md
  findings/
    <topic-or-agent>.md
```

`hub.md` is the main coordination surface. It should hold the phase/status
tracker, decisions, open questions, blockers, verification evidence, and
closeout notes. Stream and findings files are compact subagent-owned notes
with observed state, touched files, verification, and handoff notes.

## Approach

Implement this as one coordinated documentation/workflow update:

- Update `v1/rules/orchestrating.md` with the run-doc permission rule, folder
  shape, authorship rules, and closeout expectations.
- Update `v1/skills/orchestrate/SKILL.md` so `/orchestrate` treats run docs as
  opt-in stateful mode, not default behavior.
- Update `v1/plan-lifecycle.md` and `v1/agent-docs-guide.md` to clarify that
  orchestration run docs are committed coordination history but remain
  disposable after durable facts migrate.
- Update `docs/architecture/workflow-kit.md` and
  `docs/decisions/agent-docs.md` with the current-state description and
  rationale.
- Add only lightweight verifier coverage if needed to prevent drift in the
  documented command surface. Do not add heavy structural validation for run
  folder contents unless implementation reveals a concrete drift risk.

## Exit gate

The implementation is complete when:

- `/orchestrate` documentation says run docs require explicit user request or
  permission before creation.
- The standard `docs/plans/orchestrator/<run>/` layout is documented.
- Subagent write permissions and orchestrator closeout ownership are clear.
- The docs explain that committed run docs are disposable plan material, not
  canonical architecture or decisions.
- Retired command names remain retired unless a separate decision explicitly
  reverses the command-surface cleanup.
- The repo drift gate passes:

```sh
bash v1/verify-agent-docs.sh
```

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts and rationale into:

- `architecture/workflow-kit.md` — current behavior of `/orchestrate` and run
  docs.
- `decisions/agent-docs.md` — rationale for opt-in stateful run docs and for
  not reviving retired orchestration command names.
- `../v1/rules/orchestrating.md` — generic orchestration discipline.
- `../v1/skills/orchestrate/SKILL.md` — skill-specific trigger and behavior.
- `../v1/plan-lifecycle.md` and `../v1/agent-docs-guide.md` — lifecycle and
  guide wording for committed-but-disposable run docs.

## See also

- [`../agent-context/orchestrating.md`](../agent-context/orchestrating.md)
- [`../../v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md)
- [`../../v1/skills/orchestrate/SKILL.md`](../../v1/skills/orchestrate/SKILL.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
