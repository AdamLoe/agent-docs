# Pack — DB Migration / Data Safety (agent-docs v1)

GENERIC. App-independent. A task-routed quality overlay, NOT auto-loaded. The
resolver is the sole loader: this pack activates only when
`(path-routes ∪ scoper-tags) ∩ execution-allowlist` selects it. Activation
grants no new role or mutation authority.

## When it activates

The diff touches a schema/migration/data path the repo routed to this pack, or
the scope brief tags the slice `db-migration`/`data-safety`.

## Extra standards

- Migrations are forward-only and reversible by design: pair every change with a
  rollback (or a documented forward-fix) and a stated data-loss assessment.
- Prefer expand/contract over destructive in-place changes; never drop or rename
  a column the running app still reads.
- Make migrations idempotent/re-runnable and safe under the app's deploy
  ordering (old and new code coexisting).
- Use the app's named migration tooling (`database.migrate`/`seed`/`reset`),
  never hand-edited live data.

## Evidence required before the slice counts as DONE

- the migration applied AND rolled back cleanly against a real (non-production)
  database using the repo's `database` commands;
- a re-run proves idempotency;
- the data-loss / backfill impact stated explicitly (zero, or the plan).

**Missing tooling is RESIDUAL RISK, not green.** If no database is reachable
here, an unrun migration is residual risk, not a finished slice.

## See also

- [`backend-api.md`](backend-api.md) — when the schema backs an API contract.
