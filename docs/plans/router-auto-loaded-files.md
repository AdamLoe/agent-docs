---
status:        shipped
owner:         codex
last_updated:  2026-06-17
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/install-and-adapters.md
  - decisions/agent-docs.md
  - repository-layout.md
---

# Router-only auto-loaded files

## Mission

Add root `AGENTS.md` and `CLAUDE.md` files that point agents into the existing
docs router without becoming new fact owners. The change is done when both
files are present, their router-only role is documented, and the verifier
checks the surface.

## Scope

In scope:

- Root `AGENTS.md` and `CLAUDE.md` as short router-only adapters.
- Documentation updates for layout, adapter/current-state facts, and rationale.
- Verifier checks that the router files exist and point at the docs entry
  points.

Out of scope:

- Audience segmentation for skills or commands.
- A rebuild-agent-docs smoke test or fixture adoption flow.

## Approach

Implement this directly as one small docs/tooling change. Keep root files
minimal so agents do not treat them as app facts. Migrate the durable context
into architecture, decisions, and repository layout before marking shipped.

## Exit gate

Run:

```sh
bash v1/verify-agent-docs.sh
```

## Migration notes (filled in at ship time)

- Added `AGENTS.md` and `CLAUDE.md` as router-only root files.
- Migrated current-state facts into `docs/architecture/install-and-adapters.md`,
  `docs/overview.md`, `docs/repository-layout.md`, and `README.md`.
- Migrated rationale into `docs/decisions/agent-docs.md`.
- Added manifest, ownership, and verifier coverage for the router files.

## See also

- [`index.md`](index.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
