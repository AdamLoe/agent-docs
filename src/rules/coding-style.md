# Coding style — universal principles (agent-docs v1)

GENERIC. App-independent. The conventions that hold in every codebase
regardless of language or stack. **Language- and tool-specific rules
(editions, libraries, framework choices, lint baselines) are NOT here** —
they stay in the app's own `docs/agent-context/coding-style.md`.

Language-specific idioms are in per-language overlay files loaded only when
the task involves that language:
- Rust/async: [`coding-style-rust.md`](coding-style-rust.md)
- Python: [`coding-style-python.md`](coding-style-python.md)
- Frontend (React/TS): [`coding-style-frontend.md`](coding-style-frontend.md)

## Universal principles

- **Small focused files.** One concept per file. No catch-all
  `utils`/`types`/`helpers` modules. If a file grows past a few hundred
  lines, split it by responsibility.

- **No comments unless the WHY is non-obvious.** Well-named identifiers
  document the WHAT. Comments are for hidden constraints, subtle invariants,
  workarounds for specific bugs, and behaviour that would surprise a reader.

- **No historical references in code or commits.** No "Phase X" / "Slice N" /
  ticket IDs / "ported from the prior stack" comments. No "removed because…"
  comments — the git log carries the diff. Delete the code; the diff is the
  record.

- **Code anchors in docs use `path → symbol_name`, not `path:line`.**
  Line numbers drift on every refactor; symbol names are grep-stable.

- **Match the surrounding code.** New code should read like the code around it
  — its comment density, naming, and idioms. Consistency beats personal
  preference.

- **Reuse before adding.** Don't introduce a new dependency without checking
  whether the workspace already provides it. The app's dependency manifest is
  the canonical list (named per-app).

- **Respect the gates.** Don't skip pre-commit hooks / drift gates
  (`--no-verify` and friends) unless explicitly told. The specific gates are
  the app's `drift-gates` manifest slot.

## What stays per-app (in `docs/agent-context/coding-style.md`)

Only the *values and local paths* — not the idioms above:
- Language editions / runtime versions (and "don't bump" rules).
- Lint commands and any allowed baseline lints (named).
- The app's named "follow this" patterns and the one-true-seam paths.
- Frozen / off-limits modules and the canonical dependency manifest.

## See also

- `./authoring-rules.md` — the doc analogue (`path → symbol`, no historical
  framing, recoverability test).
- Language overlays above — loaded conditionally by implementation profiles.
