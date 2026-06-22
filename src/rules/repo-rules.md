# Repo rules — universal git discipline (agent-docs v1)

GENERIC. App-independent. The commit and safety conventions that hold in every
repo. **App-specific gates, forbidden paths, and generated-artifact rules are
NOT here** — they stay in the app's `docs/agent-context/repo-rules.md`.

Rationale and per-app guidance detail (do not auto-load):
[`repo-rules-reference.md`](repo-rules-reference.md).

## When does this apply

You are about to commit, push, or run a destructive command. Read first.

## Git rules

- **Prefer new commits over `--amend`.** `--amend` rewrites history; use it only
  when the user explicitly asks.
- **Never `--no-verify` or `--no-gpg-sign`** unless explicitly told. The
  specific gates are the app's `drift-gates` manifest slot.
- **Never push without explicit instruction.** Local commits are fine; pushing
  is the user's call.
- **Snapshot dirty state before mutating.** Check `git status --short` first.
  Preserve unrelated user changes and deletions; never restore, stage, or "clean
  up" paths outside your owned slice.
- **Stage by file name, not `git add -A` or `git add .`.** Avoids accidentally
  committing `.env`, large binaries, or scratch files.
- **Stop on blocking unrelated dirt.** If it prevents a coherent owned commit or
  makes a gate ambiguous, stop and report; don't force-fit the slice.
- **Don't commit tool-local settings files** such as
  `.claude/settings.local.json`. They are user-local.

## Clean handoff — never leave unexplained dirt

A mutating worker never hands off unexplained owned dirt. End in one terminal
state: **committed** (owned work green); **clean no-op** (tree clean); or
**blocked handoff** — record the owned dirty paths, check/gate state, why no
safe commit, and resume profile. A blocked handoff must be committed or
reverted before final verification; no run ends undischarged. Long work may
checkpoint-commit but not micro-commit every slice. Committing is authorized;
branch before committing to the default branch.

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
  or `~/.agentdocs/install-agentdocs.sh`). It replaces `~/.agentdocs/` and
  refreshes or deletes managed skill copies under `~/.claude/skills/` and
  `~/.agents/skills/`. Propose it and wait for confirmation.

## See also

- `./coding-style.md` — what good code looks like before committing.
- `./authoring-rules.md` — the doc analogue.
- [`repo-rules-reference.md`](repo-rules-reference.md) — generated-artifact
  and per-app rules (do not auto-load).
