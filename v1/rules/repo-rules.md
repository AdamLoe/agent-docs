# Repo rules — universal git discipline (agent-docs v1)

GENERIC. App-independent. The commit and safety conventions that hold
in every repo. **App-specific gates, forbidden paths, and generated-artifact
rules are NOT here** — they stay in the app's own
`docs/agent-context/repo-rules.md`, which should open by linking back to
this doc.

> Why the split: "never `--no-verify`" and "stage by filename" apply
> everywhere unchanged. "Regenerate `crates/engine/contracts/` before
> committing" does not. The first kind lives here once; the second kind
> lives per-app.

## When does this apply

You are about to commit, push, or run a destructive command. Read first.

## Git rules

- **Prefer new commits over `--amend`.** `--amend` rewrites history;
  use it only when the user explicitly asks. New commits are easier to
  review.
- **Never `--no-verify` or `--no-gpg-sign`** unless explicitly told.
  The hooks exist for a reason; the specific gates they enforce are the
  app's `drift-gates` manifest slot.
- **Never push without explicit instruction.** Local commits are fine;
  pushing is the user's call.
- **Stage by file name, not `git add -A` or `git add .`.** Avoids
  accidentally committing `.env`, large binaries, or in-progress scratch
  files.
- **Don't commit `.claude/settings.local.json`.** It's user-local.

## Commit cadence

**Commit proactively — don't hand back a dirty tree for the user to
clean up.** The standing preference is to commit finished work yourself,
often, without waiting to be asked:

- Commit as you go, the moment a chunk of work builds and its gates are
  green. Don't park changes in the working tree.
- **Batch freely.** Grouping related changes into one commit is
  encouraged when it's faster than crafting a tidy series. **Speed beats
  commit hygiene** — a coarse commit now is better than a perfect history
  later. Don't agonize over splitting or message polish.
- This authorizes *committing* only. **Pushing still needs explicit
  instruction**, and if you're on the default branch, branch first.
- Gates are not optional: commits still go through the app's drift gates
  — "faster over cleaner" never means committing a red tree or using
  `--no-verify`.

## Commit-message conventions

- Brief but specific. Focus on the **why**, since `git diff` already
  shows the what.
- No "Phase X" / "Slice N" / ticket-ID prefixes in source comments.
  Commit messages may reference them for archaeology but the codebase
  itself stays version-less.
- Co-author tag if generated with help, using the tool's standard identity.
  Include the model name only when the tool convention calls for it.

## Generated artifacts & what never to commit (universal)

- **Never hand-edit a generated artifact.** Run the app's regenerator so
  paired outputs (e.g. a binary fixture and its JSON sidecar) stay in
  sync. The regenerator command is the app's, but "don't hand-edit
  generated files" is universal.
- **Never commit build output or dependency dirs** — `target/`, `dist/`,
  `.venv/`, `node_modules/`, and the like. They're gitignored for a
  reason; double-check staging before you commit.
- **Never commit local run/data artifacts** — scratch databases, run
  directories, anything written to a working artifact root. They're for
  inspection, not the repo.

## Destructive command checklist

Before running any of these, confirm with the user:

- `rm -rf` on any path outside `/tmp/`.
- `git reset --hard`, `git checkout .`, `git clean -fd`, `git branch -D`.
- `git push --force` (and **never** `--force` to `main`).

## What stays per-app (in `docs/agent-context/repo-rules.md`)

- Drift gates that block commits: what must regenerate, what lint
  baseline is allowed, which test suites must be green.
- Forbidden or restricted source paths (frozen modules, generated
  artifacts that must not be hand-edited).
- Build artifacts / runtime data dirs to never commit.
- App-specific destructive commands (e.g. `cargo clean` cost, dropping a
  local database).
- The `drift-gates` manifest slot in `docs/_meta/manifest.md` is the
  canonical machine-readable gate list for that repo.

## See also

- `./coding-style.md` — what good code looks like before you commit it.
- `./authoring-rules.md` — the doc analogue (no historical framing,
  recoverability test).
