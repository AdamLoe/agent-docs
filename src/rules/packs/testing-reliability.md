# Pack — Testing / Reliability (agent-docs v1)

GENERIC. App-independent. A task-routed quality overlay, NOT auto-loaded. The
resolver is the sole loader: this pack activates only when
`(path-routes ∪ scoper-tags) ∩ execution-allowlist` selects it. Activation
grants no new role or mutation authority.

## When it activates

The diff touches a path the repo routed to this pack (the core logic, the
verifier, or another reliability-critical surface), or the scope brief tags the
slice `testing`/`reliability`.

## Extra standards

- Cover the behaviour you changed: the happy path plus the boundary and failure
  cases a real caller hits, not only the line you touched.
- New tests go in their own per-feature file, never appended to a shared one.
- No flaky or order-dependent tests; assert on observable behaviour, not
  incidental internals.
- Run against the authoritative source of truth named in the dispatch, never a
  mock that re-states the thing under test.

## Evidence required before the slice counts as DONE

- the repo's `targeted_test` (and `full_test` when the dispatch says so) run
  green, with the command, exit code, and the shortest proof reported;
- the new failure/boundary case demonstrably fails before the fix and passes
  after (or the equivalent assertion);
- no pre-existing test silently disabled or weakened.

**Missing tooling is RESIDUAL RISK, not green.** If the suite cannot run here,
report the untested behaviour as residual risk.

## See also

- [`../subagent/verification.md`](../subagent/verification.md) — the verification role.
