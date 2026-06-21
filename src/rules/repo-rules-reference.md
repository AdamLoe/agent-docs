# Repo rules — generated artifacts + per-app guidance (do not auto-load)

GENERIC. App-independent. Reference companion to
[`repo-rules.md`](repo-rules.md). The terse normative contract lives there; this
leaf carries the generated-artifact rules, per-app guidance detail, and rationale
for the commit-cadence policy. **Never auto-loaded.** Read it when you need the
"why" behind a rule or the per-app checklist guidance.

## Why new commits over --amend

`--amend` rewrites published history and makes rebase conflicts worse. New commits
are easier to review, easier to revert, and produce a cleaner bisect surface. Use
`--amend` only on a commit that has never been pushed, and only when the user
explicitly asks.

## Generated artifacts & what never to commit (universal)

- **Never hand-edit a generated artifact.** Run the app's regenerator so paired
  outputs (e.g. a binary fixture and its JSON sidecar) stay in sync. The
  regenerator command is the app's, but "don't hand-edit generated files" is
  universal.
- **Never commit build output or dependency dirs** — `target/`, `dist/`,
  `.venv/`, `node_modules/`, and the like. They're gitignored for a reason;
  double-check staging before you commit.
- **Never commit local run/data artifacts** — scratch databases, run
  directories, anything written to a working artifact root. They're for
  inspection, not the repo.

## What stays per-app (in `docs/agent-context/repo-rules.md`)

- Drift gates that block commits: what must regenerate, what lint baseline is
  allowed, which test suites must be green.
- Forbidden or restricted source paths (frozen modules, generated artifacts that
  must not be hand-edited).
- Build artifacts / runtime data dirs to never commit.
- App-specific destructive commands (e.g. `cargo clean` cost, dropping a local
  database).
- The `drift-gates` manifest slot in `docs/_meta/manifest.md` is the canonical
  machine-readable gate list for that repo.

## Commit-cadence rationale

The "speed beats commit hygiene" rule exists because the alternative — holding
changes in the working tree until a perfect history is crafted — creates merge
risk, makes it harder to bisect, and hands the user a dirty tree to interpret.
One coarse commit now is almost always better than a cleaned-up history later.
The exception: when the split genuinely aids archaeology (e.g., a refactor
followed by a behavioural change), prefer two commits.
