# Coding style — Rust / async idioms (agent-docs v1)

GENERIC. App-independent. Language-level Rust conventions — not app choices.
The app layer adds editions, lint baselines, and local module paths. Load this
overlay only when the task involves Rust code.

Parent: [`coding-style.md`](coding-style.md).

## Rust / async idioms

- Prefer `tokio::spawn` over hand-rolled future polling.
- Hold a `std::sync::Mutex` only for brief writes, never across an `.await`;
  reach for `tokio::sync::Mutex` only when a lock must span an await (e.g.
  owning a `JoinHandle`).
- Pick the channel by shape: `oneshot` = per-request reply, `mpsc` = fan-in
  queue, `watch` = single-latest-value broadcast, `Notify` = explicit wake.
- `Arc<AtomicBool>` / `Arc<AtomicU*>` for flags and counters; default to
  `SeqCst` unless a comment justifies a weaker ordering.
