# Coding style — Python idioms (agent-docs v1)

GENERIC. App-independent. Language-level Python conventions — not app choices.
The app layer adds runtime versions, lint baselines, and local module paths.
Load this overlay only when the task involves Python code.

Parent: [`coding-style.md`](coding-style.md).

## Python idioms

- Type-hint public functions.
- `from __future__ import annotations` so forward references work unquoted.
- No global mutable state across long-lived loops; pass dependencies in.
