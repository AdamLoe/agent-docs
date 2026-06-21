# Stream WS2 — Installer rewrite

Owner: implementation worker (phase 3). Compact worker notes only.

Scope: new `install-agentdocs-local.sh` (top level) + `src/install-agentdocs.sh`
(GitHub install); remove old `src/install.sh` + `src/copy-skills.sh`; shared
skill-refresh + stale managed-skill deletion + `.agentdocs-install-manifest`
tracking. Codex dest `~/.agents/skills/`. Stop with error on unmanaged
same-name skill collision (no silent delete of unowned skills).

## Worker notes

Done. Basis: HEAD ab6e254, branch overhaul-agent-docs-install-workflow; dirty
tree was the 11 unrelated docs/plans deletions only (preserved).

Created `install-agentdocs-local.sh` (top level) and `src/install-agentdocs.sh`;
removed `src/install.sh` and `src/copy-skills.sh`.

Decisions:

- Latest-version resolution: default-branch codeload tarball
  (`archive/refs/heads/main.tar.gz`); a tag arg uses
  `archive/refs/tags/<tag>.tar.gz`. Simplest reliable option — no GitHub API and
  no published release needed. `--dry-run` is fully offline (prints the resolved
  URL + planned actions, downloads nothing).
- Force flag: none. Unmanaged same-name skill collision STOPS with a clear error
  (no silent delete of unowned skills). Refuses destination skill-root symlinks.
- Refresh structure: skill refresh + stale-prune logic INLINED into both
  installers so the GitHub installer is self-contained at
  `~/.agentdocs/install-agentdocs.sh`. Ported the `.agent-docs-managed` marker,
  stale-managed deletion, and unmanaged-conflict preflight from the old
  copy-skills.sh.
- Runtime path `~/.agentdocs/`; Codex dest `~/.agents/skills/`, Claude dest
  `~/.claude/skills/`. `.agentdocs-install-manifest` records provenance only
  (kind/path-or-tag/timestamp), not deletion authority.

Gates: `bash -n` both = 0; both `--dry-run` = 0 (proved mutation-free against the
real $HOME and offline for GitHub). Live path exercised against a throwaway fake
$HOME: bundle published, manifest written, markers correct, stale skill pruned,
unmanaged collision stopped.
