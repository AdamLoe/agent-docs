# Install and Adapter Review

## Findings

1. **High: symlinked tool skill roots are replaced despite docs promising only managed skills are touched.**
   `v1/copy-skills.sh:34` removes `dest_root` when `~/.agents/skills` or `~/.claude/skills` is a symlink, then `v1/copy-skills.sh:40` recreates it as a real directory. That conflicts with `docs/architecture/install-and-adapters.md:47`, which says only `.agent-docs-managed` skills are replaced/removed and unrelated personal skills are left alone. User data is not deleted, but a symlinked personal skill root would stop being the tool discovery root.

2. **Medium: `AGENT_DOCS_SKILLS_DEST` can hijack installer/copy behavior but is undocumented.**
   `v1/install.sh:46` delegates to `copy-skills.sh` without clearing the environment. If `AGENT_DOCS_SKILLS_DEST` is set, `v1/copy-skills.sh:95` copies or checks only that path, not both documented tool roots. The installer then verifies `~/.claude` and `~/.agents` at `v1/install.sh:49`, likely failing after mutating the env-selected destination. README and architecture docs do not mention this override.

3. **Medium: copy failure is not preflighted, so a conflict can leave adapters partially refreshed.**
   `copy_into` removes stale managed entries before checking all unmanaged name conflicts (`v1/copy-skills.sh:42`, `v1/copy-skills.sh:55`). It also replaces each managed skill in place at `v1/copy-skills.sh:59`. If a later skill name conflicts with an unmanaged personal skill, the script exits with some prior managed skills already updated or removed.

## What Works

- Root `AGENTS.md` and `CLAUDE.md` are router-only and match the adapter policy.
- `install.sh` refuses to overwrite a non-symlink `~/agent-docs`.
- Per-skill collision handling is conservative: same-name unmanaged skills cause a failure instead of overwrite.
- By inspection, `copy-skills.sh --check` is read-only on its normal path and uses tests plus `diff -qr`.

## Biggest Pitches

- Treat symlinked `~/.agents/skills` and `~/.claude/skills` as conflicts unless an explicit force/ownership mechanism exists.
- Make `copy-skills.sh` preflight all destination conflicts before deleting or copying anything.
- Either document `AGENT_DOCS_SKILLS_DEST` as an advanced/testing hook or make `install.sh` ignore it.
- Consider adding `--dry-run` for copy/install, since the current safe mode is check-only and requires an existing install.

## Open Questions

- Should agent-docs own the tool skill root itself, or only child skill directories with `.agent-docs-managed`?
- Is `AGENT_DOCS_SKILLS_DEST` intended public behavior, or just an internal test hook?
- Should `install.sh` replace an existing `~/agent-docs` symlink that points somewhere else, or fail and ask for an explicit reinstall?

## Checks

- Inspected: `v1/install.sh`, `v1/copy-skills.sh`, `README.md`, `docs/architecture/install-and-adapters.md`, `AGENTS.md`, `CLAUDE.md`, plus required router/review rules.
- Ran: `bash -n v1/install.sh` and `bash -n v1/copy-skills.sh`; both passed.
- Ran read-only `nl`, `rg`, `wc`, `test -f`, and scoped `git status` checks.
- Did not run install, copy, `--check`, or the full verifier because the prompt ruled out mutating `$HOME` and full verification.
- No files edited, staged, or committed.
- Existing `docs/plans/` deletions and untracked `docs/plans/orchestrator/` were observed and left untouched.
- Durable facts likely needing migration: root skill-directory symlink policy, `AGENT_DOCS_SKILLS_DEST` status, and whether copy/install should guarantee all-or-nothing adapter refresh.
