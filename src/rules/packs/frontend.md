# Pack — Frontend / UI (agent-docs v1)

GENERIC. App-independent. A task-routed quality overlay, NOT auto-loaded. The
resolver is the sole loader: this pack activates only when
`(path-routes ∪ scoper-tags) ∩ execution-allowlist` selects it, never by a
worker reading it directly. Activation grants no new role or mutation authority.

## When it activates

The diff touches a frontend/UI path the repo routed to this pack
(`pack_routes` in `execution.yaml`), or the scope brief tags the slice
`frontend`/`ui`.

## Extra standards

- Route all data access through the app's one client seam; no ad-hoc fetches in
  components.
- Cover the four non-happy states for every changed view: loading, error,
  empty, and populated.
- Keep changes accessible and responsive — semantic markup, keyboard reach,
  visible focus, and layout that holds across the app's supported breakpoints.

## Evidence required before the slice counts as DONE

When the UI tooling named in `execution.yaml` (`browser.workflow`,
`browser.screenshot`, the dev/start command) is available, the resolution MUST
include all of:

- the app started and the changed view reached;
- the view exercised in a browser (the actual user path, not a unit test);
- screenshots of the changed view;
- the responsive layout confirmed at the supported breakpoints;
- an accessibility pass (keyboard + semantics/contrast);
- the loading, error, and empty states each shown, not just the happy path.

**Missing tooling is RESIDUAL RISK, not green.** If a browser/screenshot/start
command is absent, the slice is NOT done on the strength of code review — report
the gap as residual risk so the orchestrator decides, and never mark a UI slice
complete on unexercised code.

## See also

- [`../coding-style-frontend.md`](../coding-style-frontend.md) — frontend idioms.
- [`accessibility.md`](accessibility.md) — the deeper a11y overlay when routed.
