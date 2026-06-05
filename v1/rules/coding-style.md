# Coding style — universal principles (agent-docs v1)

GENERIC. App-independent. The conventions that hold in every codebase
regardless of language or stack. **Language- and tool-specific rules
(editions, libraries, framework choices, lint baselines) are NOT here** —
they stay in the app's own `docs/agent-context/coding-style.md`, which
should open by linking back to this doc and then list only what's
specific to that app.

> Why the split: "small focused files" and "no historical comments"
> transfer to any project unchanged. "Rust edition is 1.83" or "API
> calls go through `client.ts`" do not. The first kind lives here once;
> the second kind lives per-app.

## Universal principles

- **Small focused files.** One concept per file. No catch-all
  `utils`/`types`/`helpers` modules. If a file grows past a few hundred
  lines, split it by responsibility.

- **No comments unless the WHY is non-obvious.** Well-named identifiers
  document the WHAT. Comments are for hidden constraints, subtle
  invariants, workarounds for specific bugs, and behaviour that would
  surprise a reader. (Test-file naming is the conventional exception.)

- **No historical references in code or commits.** No "Phase X" /
  "Slice N" / ticket IDs / "ported from the prior stack" comments. No
  "removed because…" comments — the git log carries the diff. Delete the
  code; the diff is the record.

- **Code anchors in docs use `path → symbol_name`, not `path:line`.**
  Line numbers drift on every refactor; symbol names are grep-stable and
  surface meaningful refactors. (Same rule the authoring-rules apply to
  docs — it holds for code comments that point at other code too.)

- **Match the surrounding code.** New code should read like the code
  around it — its comment density, naming, and idioms. Consistency beats
  personal preference.

- **Reuse before adding.** Don't introduce a new dependency without
  checking whether the workspace already provides it. The app's
  dependency manifest is the canonical list (named per-app).

- **Respect the gates.** Don't skip pre-commit hooks / drift gates
  (`--no-verify` and friends) unless explicitly told. They run for a
  reason; the specific gates are the app's `drift-gates` manifest slot.

## Language idioms (apply wherever the language is present)

These are language-level conventions, not app choices — they hold in any
codebase using the language. The app layer only adds versions, lint
baselines, and local module paths.

**Rust / async**
- Prefer `tokio::spawn` over hand-rolled future polling.
- Hold a `std::sync::Mutex` only for brief writes, never across an
  `.await`; reach for `tokio::sync::Mutex` only when a lock must span an
  await (e.g. owning a `JoinHandle`).
- Pick the channel by shape: `oneshot` = per-request reply, `mpsc` =
  fan-in queue, `watch` = single-latest-value broadcast, `Notify` =
  explicit wake.
- `Arc<AtomicBool>` / `Arc<AtomicU*>` for flags and counters; default to
  `SeqCst` unless a comment justifies a weaker ordering.

**Python**
- Type-hint public functions.
- `from __future__ import annotations` so forward references work
  unquoted.
- No global mutable state across long-lived loops; pass dependencies in.

**Frontend (React/TS or similar)**
- Route all API calls through a single client module; no inline `fetch()`
  in components.
- Component-scoped styles (CSS Modules or equivalent); no global
  stylesheet dumping ground.
- Response/DTO types declared in one place and kept in sync with the
  server contract.

## What stays per-app (in `docs/agent-context/coding-style.md`)

Only the *values and local paths* — not the idioms above:
- Language editions / runtime versions (and "don't bump" rules).
- Lint commands and any allowed baseline lints (named).
- The app's named "follow this" patterns and the one-true-seam paths
  (e.g. which file is *the* API client).
- Frozen / off-limits modules and the canonical dependency manifest.

## See also

- `./authoring-rules.md` — the doc analogue of these rules
  (`path → symbol`, no historical framing, recoverability test).
