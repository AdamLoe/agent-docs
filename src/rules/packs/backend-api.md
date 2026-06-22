# Pack — Backend / API (agent-docs v1)

GENERIC. App-independent. A task-routed quality overlay, NOT auto-loaded. The
resolver is the sole loader: this pack activates only when
`(path-routes ∪ scoper-tags) ∩ execution-allowlist` selects it. Activation
grants no new role or mutation authority.

## When it activates

The diff touches a backend/API/service path the repo routed to this pack, or the
scope brief tags the slice `backend`/`api`.

## Extra standards

- Treat the published contract as authoritative: a request/response or schema
  change is a contract change — version it or keep it backward-compatible, never
  silently break a consumer.
- Validate input at the boundary; return typed, documented errors rather than
  leaking internals.
- Preserve idempotency and error semantics for retried or duplicated calls.
- Keep the change observable: log/trace the new path through the app's named
  observability seam.

## Evidence required before the slice counts as DONE

- the contract verified against the authoritative source of truth (schema /
  spec / generated client), never a fixture;
- the new/changed endpoint exercised against a running instance (the app's
  `services` + `smoke`/`targeted_test` commands), happy path and at least the
  primary error path;
- backward-compatibility for existing consumers confirmed or the break called
  out explicitly.

**Missing tooling is RESIDUAL RISK, not green.** If the service cannot be run
here, report the unexercised path as residual risk.

## See also

- [`auth-security.md`](auth-security.md) — when the endpoint handles auth.
