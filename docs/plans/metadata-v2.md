---
status:        abandoned
owner:         unassigned
last_updated:  2026-06-19
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Metadata v2

## Status

This plan is abandoned. It is superseded by
[`v1-focused-subagent-handoffs.md`](v1-focused-subagent-handoffs.md), which keeps
the current kit on the Markdown manifest and v1 ownership model.

The useful lesson migrated into durable docs is that handoffs need structured,
source-backed inputs and explicit ownership of what the next worker should read.
The rejected part is a breaking metadata model with a YAML manifest, ownership
v2, parser work, and generated-workspace conventions.

## Migration

Durable current-state facts live in
[`../architecture/workflow-kit.md`](../architecture/workflow-kit.md). Durable
rationale lives in [`../decisions/agent-docs.md`](../decisions/agent-docs.md).
The v1 verifier continues to validate `docs/_meta/manifest.md` and
`docs/_meta/ownership.json`.

## See also

- [`v1-focused-subagent-handoffs.md`](v1-focused-subagent-handoffs.md)
