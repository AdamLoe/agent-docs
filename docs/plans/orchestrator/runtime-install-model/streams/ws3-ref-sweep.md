# Stream WS3 — Global runtime reference sweep

Owner: implementation worker (phase 6, runs last among edits). Compact notes.

Scope: rewrite `~/agent-docs/v1/...` → `~/.agentdocs/...` across `src/skills/**`,
`src/rules/**`, `src/template/**`, `docs/**`, historical plans, and **sibling
repos under `../`** (commit per-repo, preserve unrelated dirt). All sibling refs
are runtime → `~/.agentdocs/...`. In-repo: runtime refs → `~/.agentdocs/...`,
source-path refs about this checkout → `src/...`. Leave generated artifacts
(e.g. `quoridor-ml-studio/audit-2026-06-19.raw-completion.json`) unless trivial.

## Worker notes

**Completed 2026-06-20.**

### This-repo sweep (branch: overhaul-agent-docs-install-workflow)

Files changed (29 source files + 1 plan):
- `src/agent-docs-guide.md` — 6 occurrences replaced (including 2 label-form `agent-docs/v1/` without `~/`)
- `src/rules/authoring-rules.md` — 2 occurrences
- `src/skills/*/SKILL.md` — all 21 skill files swept
- `src/skills/list-skills/list-skills.sh` — 1 `$HOME/agent-docs/v1/skills` path replaced
- `src/template/docs/{agent-context,architecture,decisions,plans}/index.md` — 4 template files
- `docs/plans/agent-docs-hardening.md` — 1 occurrence

Acceptance gate: `bash src/verify-agent-docs.sh` → exit 0, `ALL AGENT-DOCS GATES PASS`
grep gate: `git grep -nE "agent-docs/v1" -- ':!docs/plans/orchestrator' ':!docs/plans/agentdocs-runtime-install-model.md'` → empty
src gate: `git grep -nE "agent-docs/src" -- ':!docs/plans/orchestrator'` → only `README.md:34` (source-checkout install command, not a runtime ref — correctly left)

Skipped (DO-NOT list):
- `docs/plans/orchestrator/**` — migration history, kept as-is
- `docs/plans/agentdocs-runtime-install-model.md` — the plan specifying this transform, kept as-is

### Sibling-repo commits

| Repo | Branch | Files changed | Commit hash |
|---|---|---|---|
| brain_visualizer | ship-visual-polish-and-plan-sweep | 9 docs files | fdaf512 |
| evosim | feat/v2.0.0 | 21 docs files | 26619a3 |
| fluid-simulation | agent-docs-workspace-proof | 10 docs files | a54afae |
| incremental | main | 13 docs files | 944db00 |
| llmrpg | master | 7 docs files | 6a096c6 |
| quoridor-ml-studio | codex/implement-threaded-plans | 10 docs files | c262d1f |
| traffic | grid-road-game-rewrite | 16 docs files | 70170d4 |
| adamloe.com | (any) | — | SKIPPED — already clean (0 refs) |

### Generated artifacts skipped

- `quoridor-ml-studio/audit-2026-06-19.raw-completion.json` — root-level raw completion JSON containing a `~/agent-docs/v1/rules/repo-rules.md` reference in a quoted string; untracked, left untouched
- `quoridor-ml-studio/audit-2026-06-19.raw-wave1.json` — raw artifact, untracked, skipped

### Residual `agent-docs/v1` left

Only the two excluded migration docs as expected:
- `docs/plans/orchestrator/runtime-install-model/` (run docs — migration history)
- `docs/plans/agentdocs-runtime-install-model.md` (the plan specifying before→after)

No other residual refs remain in this repo or any sibling repo.
