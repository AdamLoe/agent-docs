# Plan lifecycle (agent-docs v1)

GENERIC. App-independent. Plans are **working coordination docs** for
multi-step work. They are **not** canonical architecture: once work ships,
the relevant architecture and decisions docs get updated and the plan is
deleted. Per-app, plans live in that repo's `docs/plans/`; this file owns
the lifecycle rules every app shares.

Expanded field rationale, workflow walk-through, and run-folder detail (do not
auto-load): [`plan-lifecycle-reference.md`](plan-lifecycle-reference.md).

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
- **`status`:** `draft` (not actionable), `active` (in flight — check it before
  assuming code state), `shipped` (done; set `okay_to_delete` truthfully),
  `abandoned` (scoped out or replaced; set `okay_to_delete` after migrating).
- **`owner`:** Who is driving.
- **`last_updated`:** Bump on every edit. Helps spot stale plans.
- **`okay_to_delete`:** `true` only when shipped/abandoned and all useful
  context has been migrated or is absent. The user decides when to actually
  delete.
- **`long_lived`:** Default `false`. Escape hatch for multi-month coordination
  docs with context that genuinely cannot be migrated. Most plans should reach
  `shipped + okay_to_delete: true`.
- **`owning_docs`:** The architecture and decisions docs this plan most affects.

## Plan workflow

1. Create from [`plan-template.md`](plan-template.md). Set `status: draft`.
2. When work starts: `status: active`.
3. Complete the implementation work and slice checks, keeping the plan open
   until migration and final verification finish.
4. **Migrate context.** Route every fact, decision, or trade-off into
   architecture or decisions docs. Add an `_meta/ownership.json` entry if a
   new concept needs a canonical owner.
5. Set `status: shipped`. If migration is complete or there was no durable
   context, set `okay_to_delete: true`.
6. Run the final drift gate after all code, docs, plan-status, and run-doc
   mutations before reporting the plan shipped.
7. Only set `long_lived: true` if the migration in step 4 was truly impossible.

The goal: *a fresh chat should never need to read plan history to understand
the current system.* If it does, migration was incomplete.

## What lives in `docs/plans/`

Active and recently-shipped plans, alongside the app's `docs/plans/index.md`
landing doc. The index is a router only — list the directory to see what's
live. `docs/plans/orchestrator/<run-slug>/` is reserved for opt-in run docs.
A run folder's lifecycle frontmatter is on its `hub.md`.

## See also

- [`plan-template.md`](plan-template.md) — the skeleton.
- [`rules/authoring-rules.md`](rules/authoring-rules.md) — the doc-update
  rules a shipped plan must satisfy.
- [`agent-docs-guide.md`](agent-docs-guide.md) — why plans are disposable.
- [`plan-lifecycle-reference.md`](plan-lifecycle-reference.md) — field
  rationale, workflow detail, run-folder structure (do not auto-load).
