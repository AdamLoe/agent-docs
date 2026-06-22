# Pack — Auth / Security (agent-docs v1)

GENERIC. App-independent. A task-routed quality overlay, NOT auto-loaded. The
resolver is the sole loader: this pack activates only when
`(path-routes ∪ scoper-tags) ∩ execution-allowlist` selects it. Activation
grants no new role or mutation authority — and never the authority to relax a
security control.

## When it activates

The diff touches authentication, authorization, sessions, secrets, or another
security-sensitive path the repo routed to this pack, or the scope brief tags
the slice `auth`/`security`.

## Extra standards

- Authorize every protected path on the server; never trust a client-side check
  alone. Deny by default.
- Keep secrets out of the diff, logs, and error messages; read them from the
  app's `secrets` provisioning, not from literals.
- Validate and encode all untrusted input/output against the relevant injection
  and XSS/SSRF classes.
- Do not weaken an existing control (token lifetime, scope, rate limit, CSRF,
  TLS) to make a feature pass — flag the tension instead.

## Evidence required before the slice counts as DONE

- the positive path AND the denial path both exercised (an unauthorized actor is
  actually refused);
- no secret present in the diff, logs, or output;
- the relevant injection/encoding class checked for the changed surface.

**Missing tooling is RESIDUAL RISK, not green.** Unverified authorization is an
open vulnerability — report it as residual risk, never as done.

## See also

- [`backend-api.md`](backend-api.md) — when the surface is an API.
