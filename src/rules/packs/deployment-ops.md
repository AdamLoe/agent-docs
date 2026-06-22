# Pack — Deployment / Ops (agent-docs v1)

GENERIC. App-independent. A task-routed quality overlay, NOT auto-loaded. The
resolver is the sole loader: this pack activates only when
`(path-routes ∪ scoper-tags) ∩ execution-allowlist` selects it. Activation
grants no new role or mutation authority.

## When it activates

The diff touches install/deploy/CI/runtime-config/release surfaces the repo
routed to this pack (for this repo, the installers and bundles), or the scope
brief tags the slice `deployment`/`ops`.

## Extra standards

- Changes must be safe to roll forward AND back: name the rollback, and keep the
  step idempotent so a re-run does not corrupt state.
- Never destructively replace a managed target without the user's explicit
  go-ahead (installers that rewrite `$HOME`/runtime dirs are gated — see
  [`../repo-rules.md`](../repo-rules.md) destructive-command checklist).
- Keep config/secrets out of the artifact; read them from the environment's
  provisioning, not from committed literals.
- Preserve the source/runtime split: build from source, do not hand-edit the
  deployed copy.

## Evidence required before the slice counts as DONE

- the change previewed without mutating the live target (the repo's `--dry-run`
  / plan / smoke command), output reported;
- the rollback path named and shown to be available;
- a live apply only when the dispatch or user explicitly authorizes it, then the
  post-apply state confirmed.

**Missing tooling is RESIDUAL RISK, not green.** An unverified deploy step is
residual risk; do not call it done on an un-previewed change.

## See also

- [`../repo-rules.md`](../repo-rules.md) — destructive-command checklist.
