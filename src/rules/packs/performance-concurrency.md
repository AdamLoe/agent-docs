# Pack — Performance / Concurrency (agent-docs v1)

GENERIC. App-independent. A task-routed quality overlay, NOT auto-loaded. The
resolver is the sole loader: this pack activates only when
`(path-routes ∪ scoper-tags) ∩ execution-allowlist` selects it. Activation
grants no new role or mutation authority.

## When it activates

The diff touches a hot path, a shared-state/concurrent path, or another
performance-critical surface the repo routed to this pack, or the scope brief
tags the slice `performance`/`concurrency`.

## Extra standards

- Know the complexity and allocation profile of the path you change; avoid
  accidental N+1s, unbounded growth, and per-item work that belongs in a batch.
- Guard shared mutable state: no data races, no lock-order inversions, bounded
  queues/pools, and explicit cancellation/timeout on every await/blocking call.
- Set and respect the resource budget for the path; do not regress a measured
  baseline without saying so.
- Serialize on the app's `scarce_resources` rather than contending blindly.

## Evidence required before the slice counts as DONE

- a measurement of the changed path (latency/throughput/allocations or the
  repo's named metric) against the prior baseline, not a guess;
- for concurrent changes, the contended path exercised under realistic load (or
  a race/sanitizer pass where the toolchain offers one);
- any regression stated explicitly with its tradeoff.

**Missing tooling is RESIDUAL RISK, not green.** An unmeasured perf or
concurrency claim is residual risk, not a finished slice.

## See also

- [`../coding-style.md`](../coding-style.md) — universal principles.
