# Pack — Accessibility (agent-docs v1)

GENERIC. App-independent. A task-routed quality overlay, NOT auto-loaded. The
resolver is the sole loader: this pack activates only when
`(path-routes ∪ scoper-tags) ∩ execution-allowlist` selects it. Activation
grants no new role or mutation authority.

## When it activates

The diff touches a user-facing surface the repo routed to this pack, or the
scope brief tags the slice `accessibility`/`a11y`.

## Extra standards

- Semantic structure first: correct landmarks, headings, labels, and roles
  before ARIA patches.
- Full keyboard operability — every interactive element reachable and operable
  without a pointer, with a visible focus order that matches reading order.
- Meet the app's stated contrast and text-sizing target; respect reduced-motion
  and other user preferences.
- Name images, icons, and controls for assistive tech; announce dynamic changes.

## Evidence required before the slice counts as DONE

- a keyboard-only walkthrough of the changed surface (tab order + focus visible);
- the app's accessibility checker (axe/lighthouse or the repo's named tool) run
  on the changed view with results reported;
- contrast/labeling confirmed for new or changed elements.

**Missing tooling is RESIDUAL RISK, not green.** If no a11y checker is wired,
report it as a gap rather than asserting the surface is accessible.

## See also

- [`frontend.md`](frontend.md) — the broader UI overlay this complements.
