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
| D7 | **Plan review = yes-with-changes.** Adopted fixes below. | phase 1 review |
| D7a | `verify-agent-docs.sh` hardcodes ~77 `v1/` literals, depends on `install.sh`/`copy-skills.sh` existing, AND hardcodes the manifest change-to-doc rows → install↔verify are circularly coupled. **Merge installer (WS2) + verifier (WS4) into one "Install+Verify machinery" phase.** | B1/B2/B3 |
| D7b | WS1 must also rewrite the mechanical `v1/`→`src/` path literals **inside** `verify-agent-docs.sh` (incl its hardcoded manifest expectations) and `manifest.md`, keeping script names `install.sh`/`copy-skills.sh` (still exist post-rename), so `bash src/verify-agent-docs.sh` stays green right after the rename. | B1 |
| D7c | Stale-skill deletion authority = the existing per-skill `.agent-docs-managed` marker logic in `copy-skills.sh` (reuse it). The new `.agentdocs-install-manifest` records bundle provenance (source kind/tag) only — it is NOT the deletion authority. Same-name unmanaged collision → stop with error. | A1 |
| D7d | **GitHub install path is `bash -n` + `--dry-run` only this run** (no published tag; tag-push out of scope per Discipline Rules). Exit-gate bullet "installs from GitHub tag/latest" is accepted as dry-run-only — recorded limitation, not a silent descope. Live install (phase 7) exercises the LOCAL path only (matches D1). | A2 |
| D7e | WS3 sweeps SOURCE (`src/**`, `docs/**`, plans) + sibling repos only — NOT the installed `~/.claude/skills`/`~/.agents/skills` copies (phase 7 live install refreshes those from swept `src/`). Don't weaken the verifier's `[.]agent-docs/(current\|src)` reject regex; `~/.agentdocs/` (no hyphen) is safe. Preserve an adapter-freshness check in the runtime verifier. | A3 + gaps |

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
| 0 Coordination setup | orchestrator inline | done | hub created | 310f764 |
| 1 Plan review | review.plan (read-only) | done | yes-with-changes; D7a–e adopted | — |
| 2 WS1 rename + mechanical v1→src | implementation.code-docs (mid) | done | git mv done; `bash src/verify-agent-docs.sh` exit 0; profile table now routes to `src/rules/...` | c54fe23 |
| 3 Install+Verify machinery (WS2+WS4) | implementation.code-docs (strong) | pending | — | — |
| 4 WS5 docs & decisions | implementation.code-docs (mid) | pending | — | — |
| 5 WS3 global ref sweep + siblings | implementation.code-docs (mid) | pending | — | — |
| 6 Shipped review | review.generic (read-only) | pending | — | — |
| 7 Live install + verify | implementation (mutates $HOME) | pending | — | — |
| 8 Closeout (plan + hub ship) | maintenance.plan | pending | — | — |
| 9 Final drift gate + report | verification.readonly | pending | — | — |

Editing is serial on the shared tree; phases 2→5 run one at a time, each
committing before the next. Phases 1 and 6 are read-only. WS2+WS4 merged per
D7a (install↔verify circular coupling).

## Streams

- [`streams/ws1-rename.md`](streams/ws1-rename.md)
- [`streams/ws2-installer.md`](streams/ws2-installer.md)
- [`streams/ws3-ref-sweep.md`](streams/ws3-ref-sweep.md)
- [`streams/ws4-verifier.md`](streams/ws4-verifier.md)
- [`streams/ws5-docs.md`](streams/ws5-docs.md)

## Carry-forward facts (observed)

- After c54fe23, dispatch routes are `src/...` (not `v1/...`). The
  `src/rules/context-profiles.md` table already reflects this.
- **WS1 artifact to catch:** `docs/overview.md:26,28` now read
  `~/agent-docs/src/skills/<name>` (WS1 rewrote `v1`→`src` inside a
  `~/agent-docs/` path). WS3's `~/agent-docs/v1` pattern will NOT match this.
  Correct end state = `~/.agentdocs/skills/<name>` copied by the new installer.
  Explicitly routed to WS5 (copy-model prose) + WS3 (catch residual
  `~/agent-docs/src`). Also re-grep `~/agent-docs/src` in shipped review.
- `manifest.md` `## drift-verification` block still has old install commands
  (`bash v1/install.sh`, `bash v1/copy-skills.sh`, `~/agent-docs/v1` readlinks)
  — owned by the Install+Verify phase (3).

## Open questions / blockers

- None open. Plan §Open Decisions are delegated (D6).

## Closeout / migration status

- Not started. Before `okay_to_delete: true`: durable facts migrated into
  `architecture/install-and-adapters.md`, `architecture/workflow-kit.md`,
  `decisions/agent-docs.md`; plan migration notes filled; plan + hub set
  `status: shipped`.
