# Repo rules — universal git discipline (agent-docs v1)

GENERIC. App-independent. The commit and safety conventions that hold in every
repo. **App-specific gates, forbidden paths, and generated-artifact rules are
NOT here** — they stay in the app's `docs/agent-context/repo-rules.md`.

Rationale, generated-artifact rules, and per-app guidance detail (do not
auto-load): [`repo-rules-reference.md`](repo-rules-reference.md).

## When does this apply

You are about to commit, push, or run a destructive command. Read first.

## Git rules

- **Prefer new commits over `--amend`.** `--amend` rewrites history; use it
  only when the user explicitly asks.
- **Never `--no-verify` or `--no-gpg-sign`** unless explicitly told. The
  specific gates are the app's `drift-gates` manifest slot.
- **Never push without explicit instruction.** Local commits are fine; pushing
  is the user's call.
- **Snapshot dirty state before mutating.** Check `git status --short` before
  editing or committing. Preserve unrelated user changes and deletions; do not
  restore, stage, or "clean up" paths outside your owned slice.
- **Stage by file name, not `git add -A` or `git add .`.** Avoids accidentally
  committing `.env`, large binaries, or scratch files.
- **Stop on blocking unrelated dirt.** If unrelated dirty state prevents a
  coherent owned commit or makes a gate result ambiguous, stop and report
  instead of force-fitting the slice.
- **Don't commit tool-local settings files** such as
  `.claude/settings.local.json`. They are user-local.

## Commit cadence

Commit proactively — don't hand back a dirty tree for the user to clean up.
Commit as you go when a chunk of work builds and gates are green. Batch related
changes freely; speed beats commit hygiene. This authorizes *committing* only —
**pushing still needs explicit instruction**; branch before committing to the
default branch. Gates are not optional even when moving fast — never use
`--no-verify`.

## Commit-message conventions

- Brief but specific. Focus on the **why**, since `git diff` shows the what.
- No "Phase X" / "Slice N" / ticket-ID prefixes in source comments.
- Co-author tag if generated with help, using the tool's standard identity.

## Destructive command checklist

Before running any of these, confirm with the user:

- `rm -rf` on any path outside `/tmp/`.
- `git reset --hard`, `git checkout .`, `git clean -fd`, `git branch -D`.
- `git push --force` (and **never** `--force` to `main`).
- **Any agent-docs installer** (`install-agentdocs-local.sh`, `src/install-agentdocs.sh`,
  or `~/.agentdocs/install-agentdocs.sh`). Running an installer replaces
  `~/.agentdocs/` and refreshes or deletes managed skill copies under
  `~/.claude/skills/` and `~/.agents/skills/`. Propose it and wait for
  confirmation.

## See also

- `./coding-style.md` — what good code looks like before you commit it.
- `./authoring-rules.md` — the doc analogue.
- [`repo-rules-reference.md`](repo-rules-reference.md) — generated-artifact
  rules, per-app guidance (do not auto-load).
