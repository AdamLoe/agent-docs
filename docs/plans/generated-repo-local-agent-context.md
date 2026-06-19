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

# Generated repo-local agent context

## Status

This plan is abandoned. It is superseded by
[`v1-focused-subagent-handoffs.md`](v1-focused-subagent-handoffs.md), which keeps
the active kit on v1 and lowers context through sharper worker roles instead of
generated workspaces.

The useful lesson migrated into durable docs is that context reduction should be
role-specific, deterministic, and source-backed. The rejected part is treating
handoff quality as a generated-workspace problem with per-run folders, source
trace files, or launcher infrastructure.

## Migration

Durable current-state facts live in
[`../architecture/workflow-kit.md`](../architecture/workflow-kit.md). Durable
rationale lives in [`../decisions/agent-docs.md`](../decisions/agent-docs.md).
The v2 proof path was removed after checking live references; no active v1
workflow required it.

## See also

- [`v1-focused-subagent-handoffs.md`](v1-focused-subagent-handoffs.md)
