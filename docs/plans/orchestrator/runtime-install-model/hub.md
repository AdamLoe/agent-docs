---
status:        active
owner:         orchestrator
last_updated:  2026-06-20
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/install-and-adapters.md
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Run hub — Agentdocs Runtime Install Model

Orchestration run for [`../../agentdocs-runtime-install-model.md`](../../agentdocs-runtime-install-model.md).
Separate the editable source checkout (`v1/` → `src/`) from a global runtime at
`~/.agentdocs/`, rewrite the installer flow, migrate all runtime references,
split the verifier, and migrate docs/decisions.

## Lifecycle & dials

- **Lifecycle:** tracked-plan (broad, cross-cutting, multi-stream, destructive).
- **Dials:** `review-medium`, `cost-medium` (defaults; user set none).
- **Classification rationale:** renames the running kit, mutates live `$HOME`,
  commits to sibling repos → high blast radius and high resume risk → committed
  run docs.

## Decisions log

| # | Decision | Source |
|---|---|---|
| D1 | **Full live install in this run** — a worker runs `install-agentdocs-local.sh` for real after edits + validation pass (mutates `~/.agentdocs/`, `~/.claude/skills/`, `~/.agents/skills/`, deletes stale managed skills). | user intake |
| D2 | **Edit + commit sibling repos** — workers rewrite refs in sibling repos under `../` and commit per-repo. | user intake |
| D3 | **Committed run-doc hub** — this folder. | user intake |
| D4 | In-repo refs split: source-path files → `src/...`; runtime refs in skill/rule/template bodies + consuming docs → `~/.agentdocs/...`. All **sibling-repo** refs are runtime → `~/.agentdocs/...`. | plan §Reference Migration |
| D5 | Codex skill destination = `~/.agents/skills/` (already the path in manifest drift-verification); installer may override only if it verifies a newer correct path. | plan + manifest |
| D6 | Open Decisions in the plan (GitHub latest-version resolution, verifier-split location, force-flag) are delegated to implementation ("simplest reliable option first"), not user stops. | plan §Open Decisions |

## Sequencing hazard (carry forward every phase)

This run does `git mv v1 src`. **After WS1, every dispatch route changes from
`v1/...` to `src/...`** and the manifest drift gate becomes
`bash src/verify-agent-docs.sh`. The installed `~/.claude/skills/*` copies still
point at `~/agent-docs/v1/...` until the final live install refreshes them — the
orchestrator already holds all needed rules in context and routes workers by
explicit path, so this is safe for the run. Do not re-bootstrap from installed
skill copies mid-run.

## Observed scope (recon at HEAD a7ad962)

- This repo: **39** files contain `~/agent-docs/v1` refs.
- Sibling repos: **87** files across **7** repos
  (`brain_visualizer`, `evosim`, `fluid-simulation`, `incremental`, `llmrpg`,
  `quoridor-ml-studio`, `traffic`); `adamloe.com` is clean. File list cached at
  `/tmp/sibling-stale.txt` (regenerate; do not trust across reboots).
- Edge cases for the sweep: `quoridor-ml-studio/audit-2026-06-19.raw-completion.json`
  (generated artifact), `quoridor-ml-studio/docs/loop/PROMPT.md`.
- Source scripts present: `v1/install.sh`, `v1/copy-skills.sh`,
  `v1/verify-agent-docs.sh`, `v1/export-chatgpt-context.sh`.

## Phase tracker

| Phase | Role / profile | Status | Last observed fact | Commit |
|---|---|---|---|---|
| 0 Coordination setup | orchestrator inline | active | hub created | — |
| 1 Plan review | review.plan (read-only) | pending | — | — |
| 2 WS1 rename + metadata | implementation.code-docs | pending | — | — |
| 3 WS2 installer rewrite | implementation.code | pending | — | — |
| 4 WS4 verifier split | implementation.code-docs | pending | — | — |
| 5 WS5 docs & decisions | implementation.code-docs | pending | — | — |
| 6 WS3 global ref sweep | implementation.code-docs | pending | — | — |
| 7 Shipped review | review.generic (read-only) | pending | — | — |
| 8 Live install + verify | implementation (mutates $HOME) | pending | — | — |
| 9 Closeout (plan + hub ship) | maintenance.plan | pending | — | — |
| 10 Final drift gate + report | verification.readonly | pending | — | — |

Editing is serial on the shared tree; phases 2→6 run one at a time, each
committing before the next. Phases 1 and 7 are read-only.

## Streams

- [`streams/ws1-rename.md`](streams/ws1-rename.md)
- [`streams/ws2-installer.md`](streams/ws2-installer.md)
- [`streams/ws3-ref-sweep.md`](streams/ws3-ref-sweep.md)
- [`streams/ws4-verifier.md`](streams/ws4-verifier.md)
- [`streams/ws5-docs.md`](streams/ws5-docs.md)

## Open questions / blockers

- None open. Plan §Open Decisions are delegated (D6).

## Closeout / migration status

- Not started. Before `okay_to_delete: true`: durable facts migrated into
  `architecture/install-and-adapters.md`, `architecture/workflow-kit.md`,
  `decisions/agent-docs.md`; plan migration notes filled; plan + hub set
  `status: shipped`.
