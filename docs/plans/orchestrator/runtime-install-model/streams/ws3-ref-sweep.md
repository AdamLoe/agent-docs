# Stream WS3 — Global runtime reference sweep

Owner: implementation worker (phase 6, runs last among edits). Compact notes.

Scope: rewrite `~/agent-docs/v1/...` → `~/.agentdocs/...` across `src/skills/**`,
`src/rules/**`, `src/template/**`, `docs/**`, historical plans, and **sibling
repos under `../`** (commit per-repo, preserve unrelated dirt). All sibling refs
are runtime → `~/.agentdocs/...`. In-repo: runtime refs → `~/.agentdocs/...`,
source-path refs about this checkout → `src/...`. Leave generated artifacts
(e.g. `quoridor-ml-studio/audit-2026-06-19.raw-completion.json`) unless trivial.

## Worker notes

(empty — worker fills on completion)
