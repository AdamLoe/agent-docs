# Plan lifecycle (agent-docs v1)

GENERIC. App-independent. Plans are **working coordination docs** for
multi-step work. They are **not** canonical architecture: once work ships,
the relevant architecture and decisions docs get updated and the plan is
deleted. Per-app, plans live in that repo's `docs/plans/`; this file owns
the lifecycle rules every app shares.

## Lifecycle states

Every plan starts from [`plan-template.md`](plan-template.md) with YAML
frontmatter:

```yaml
---
status:        draft | active | shipped | abandoned
owner:         <name or "unassigned">
last_updated:  YYYY-MM-DD
okay_to_delete: false | true
long_lived:    false | true
owning_docs:
  - architecture/<doc>.md
  - decisions/<domain>.md
---
```

Field meanings:

- **`status`.**
  - `draft` — plan is being written. Not actionable yet.
  - `active` — work is in flight. The plan is the coordination surface;
    check it before assuming code state.
  - `shipped` — the work is done and the relevant architecture/decisions
    docs reflect the new state. Set `okay_to_delete` truthfully.
  - `abandoned` — the work was scoped out or replaced. Set
    `okay_to_delete: true` and let the user delete it.
- **`owner`.** Who is driving. Used to know who to ping when status
  changes.
- **`last_updated`.** Bump on every edit. Helps spot stale plans.
- **`okay_to_delete`.** Set `true` when (a) the plan has shipped and (b)
  all useful context has been migrated into architecture/decisions. The
  user decides when to actually delete.
- **`long_lived`.** Default `false`. Set `true` only when the plan
  contains context that genuinely cannot be migrated elsewhere — e.g. a
  multi-month coordination doc that surfaces ongoing trade-offs. Most
  plans should reach `shipped + okay_to_delete: true`, not `long_lived`.
  **The default expectation is that shipped plans get deleted.**
- **`owning_docs`.** The architecture and decisions docs this plan most
  affects. Updated on every edit so the maintainer can cross-reference
  what's been migrated.

## Plan workflow

1. Create the plan from [`plan-template.md`](plan-template.md). Set
   `status: draft`.
2. When work starts: `status: active`.
3. Ship the work — code + tests + drift gates green.
4. **Migrate context.** Read through the plan; for every fact, decision,
   or trade-off in it, route it into the relevant architecture or
   decisions doc. Add an `_meta/ownership.json` entry if a new concept
   needs a canonical owner.
5. Set `status: shipped`. If migration was complete, set
   `okay_to_delete: true`. Leave it on disk for the user to delete on
   their next cleanup pass.
6. Only set `long_lived: true` if the migration in step 4 was truly
   impossible (escape hatch).

The goal this enforces: *a fresh chat should never need to read plan
history to understand the current system.* If it does, migration was
incomplete.

## What lives in `docs/plans/`

Active and recently-shipped plans, alongside the app's `docs/plans/index.md`
landing doc. Once `okay_to_delete: true` and the user has confirmed the
migration, the plan is removed. **The index does not maintain an inventory
of active plans** — that would rot the moment a plan is added without an
index edit. List the directory (`ls docs/plans/`) to see what's live.

`docs/plans/orchestrator/<run-slug>/` is reserved for opt-in orchestration run
docs. A run folder is committed coordination history, not canonical
architecture. It may contain a required `hub.md`, stream notes under
`streams/`, and optional read-only findings under `findings/`. The hub carries
the same lifecycle frontmatter as a plan file (`status`, `owner`,
`last_updated`, `okay_to_delete`, `long_lived`, `owning_docs`) and is the
status source for cleanup. Once the run's work ships, migrate durable facts and
rationale into architecture/decisions, record the migration targets in the hub,
and set `okay_to_delete: true` only when the run is disposable.

## See also (resolved relative to this kit)

- [`plan-template.md`](plan-template.md) — the skeleton.
- [`rules/authoring-rules.md`](rules/authoring-rules.md) — the doc-update
  rules a shipped plan must satisfy (§"Workflow when shipping a plan").
- [`agent-docs-guide.md`](agent-docs-guide.md) — why plans are disposable.
