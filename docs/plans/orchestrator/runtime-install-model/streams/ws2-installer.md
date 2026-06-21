# Stream WS2 — Installer rewrite

Owner: implementation worker (phase 3). Compact worker notes only.

Scope: new `install-agentdocs-local.sh` (top level) + `src/install-agentdocs.sh`
(GitHub install); remove old `src/install.sh` + `src/copy-skills.sh`; shared
skill-refresh + stale managed-skill deletion + `.agentdocs-install-manifest`
tracking. Codex dest `~/.agents/skills/`. Stop with error on unmanaged
same-name skill collision (no silent delete of unowned skills).

## Worker notes

(empty — worker fills on completion)
