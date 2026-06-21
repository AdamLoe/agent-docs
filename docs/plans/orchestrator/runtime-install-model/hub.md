---
status:        shipped
owner:         orchestrator
last_updated:  2026-06-20
okay_to_delete: true
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
| D8 | **Verifier split = LANDED** as ONE guarded script (no top-level `scripts/`): default mode = source-repo self-consistency gate, guarded by source-repo detection (`src/skills/registry.md` present + manifest `repo_name: agent-docs`); `--scaffold <target>` = consuming-repo runtime mode; `--context-report`. Ships in bundle; degrades to a `--scaffold` directive (exit 0) outside the source repo. | phase 3 |
| D9 | **GitHub install** = codeload tarball: default `archive/refs/heads/main.tar.gz`, tag arg `archive/refs/tags/<tag>.tar.gz`. No GitHub API, no published release needed. Slug `AdamLoe/agent-docs`. `--dry-run` fully offline. | phase 3 |
| D10 | **No force flag.** Unmanaged same-name skill collision STOPS with error; skill-root symlinks refused. Refresh logic INLINED into both installers (self-contained). | phase 3 |
| D11 | **Leave `~/agent-docs/feedback/inbox.jsonl` unchanged** — it's a source-checkout maintainer inbox, NOT a `v1` runtime ref, and `~/.agentdocs/` is wiped on every install so it's an unsuitable home. Out of this plan's scope (exit gate targets `~/agent-docs/v1` only). Recorded as a follow-up: "feedback inbox location under the new model" is a separate future decision. WS3 must NOT rewrite it. | phase 4 |

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
| 3 Install+Verify machinery (WS2+WS4) | implementation.code-docs (strong) | done | both installers + verifier split landed; `bash src/verify-agent-docs.sh` exit 0 (orch-confirmed at committed state) | c02e2af |
| 4 WS5 docs & decisions | implementation.code-docs (mid) | done | 6 owned docs + overview.md rewritten; committed a022d2a was RED (stream-note tripped sweep), fixed by 4b | a022d2a |
| 4b Verifier hardening | implementation.code (mid) | done | retired-name sweep now skips `docs/plans/orchestrator/**`; gate exit 0 (orch-confirmed) | b2c5c5e |
| 5 WS3 global ref sweep + siblings | implementation.code-docs (mid) | done | 30 files this repo (725eb01) + 7 sibling repos committed; orch-verified ZERO active stale refs anywhere | 725eb01 + 7 siblings |
| 6 Shipped review | review.generic (read-only, strong) | done | VERDICT safe-with-fixes; live install confirmed SAFE (deletion + dry-run + atomic-replace traced); 1 real miss: bare `v1/` refs | fe20142 (read) |
| 6b Bare-v1 active-files cleanup | maintenance.docs (strong) | done | 29 refs fixed across 13 files (docs→src/, src bodies→~/.agentdocs/); verifier:1007 tightened; gate exit 0 | c3712af |
| 7 Live install + verify | implementation (mutates $HOME) | done | ~/.agentdocs created (manifest kind=local); 21/21 skills refreshed both tools, markers→~/.agentdocs path; adapter-freshness now RUNS + passes; github --dry-run ok | no repo commit |
| 8 Closeout (plan + hub ship) | maintenance.plan | done | plan + hub shipped/okay_to_delete; migration notes filled; gate exit 0 | (this commit) |
| 9 Final drift gate + report | verification.readonly | done | FULLY GREEN at cd3fb9e: source gate + adapter-freshness pass, zero active stale refs (this repo + 8 siblings), runtime resolves 21/21, both installers parse + dry-run; only dirt = 11 preserved deletions | read-only |

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
  — owned by the Install+Verify phase (3). ✅ done in c02e2af.
- **Residual risk — brittle retired-name sweep.** The verifier flags any tracked
  file mentioning retired names (e.g. `new-project-prompt`, possibly
  `copy-skills.sh`/`install.sh`) unless allowlisted. WS1's stream notes already
  tripped it once (phase 3 extended `allow_retired_reference`). WS5/WS3/closeout
  workers that write prose mentioning retired scripts may re-trip it — each must
  run the gate and extend the allowlist for its own owned lines, or avoid the
  exact token. Final gate (phase 9) is the backstop.
- **Adapter-freshness check skips until runtime installed.** `~/.agentdocs/skills`
  does not exist yet, so "installed skills match runtime" is unobservable until
  phase 7 live install. ⇒ the FINAL consolidated gate (phase 9) MUST run AFTER
  phase 7 so this check actually executes.
- `docs/_meta/ownership.json` install/adapter `paths` already updated to the two
  new installers (phase 3 forced cross-file fix).
- **Sibling-repo commits (WS3)** — each on its own branch: brain_visualizer
  fdaf512 (ship-visual-polish-and-plan-sweep), evosim 26619a3 (feat/v2.0.0),
  fluid-simulation a54afae (agent-docs-workspace-proof), incremental 944db00
  (main), llmrpg 6a096c6 (master), quoridor-ml-studio c262d1f
  (codex/implement-threaded-plans), traffic 70170d4 (grid-road-game-rewrite).
  None pushed. quoridor untracked `audit-2026-06-19.raw-*.json` artifacts skipped
  (contain old path in quoted strings; untracked).

## Shipped-review findings (phase 6)

- **VERDICT: safe-with-fixes.** `bash install-agentdocs-local.sh` is SAFE to run
  live: reviewer traced deletion path against the real `$HOME` (all 21 managed
  dirs carry the marker, none symlinks, zero unmanaged conflicts), confirmed
  dry-run mutates nothing in both installers, and confirmed atomic temp-dir+mv
  replace with bundle-shape validation BEFORE touching the live runtime. No
  blocking installer defect.
- **Real miss (→ phase 6b): bare `v1/` source-path refs** in ~21 files. Active
  kit/doc files MUST be fixed (they are copied into the runtime by the live
  install): `src/rules/skill-contracts.md`, `src/rules/authoring-rules.md`,
  `src/rules/orchestrator/dispatch.md`, `src/skills/registry.md`,
  `src/skills/{fresh-chat,feedback-agent-docs,doctor}/SKILL.md`,
  `docs/agent-context/{index,orchestrating,collaboration-style}.md`,
  `docs/architecture/{index,workflow-kit}.md`, `docs/plans/index.md`.
- **Verifier finding (#2, optional):** `src/verify-agent-docs.sh:1007` still
  strips a `~/agent-docs/` prefix; harmless now, tighten to `~/.agentdocs/` so a
  stray old ref fails. Folded into 6b as optional.
- **Benign (#3):** existing `.agent-docs-managed` markers hold the old
  `…/agent-docs/v1/skills/<name>` path; overwritten on the next install (phase 7
  self-heals). No action.
- **Confirmed dry-run-only:** GitHub-tag install exit bullet stays dry-run-only
  (D7d). Retired-name run-doc skip (b2c5c5e) hid nothing real.

## Follow-ups (out of scope this run — surface in final report)

- **Disposable historical plans still hold bare `v1/` refs**:
  `docs/plans/{agent-docs-hardening,token-economy,review-app-skill,agent-docs-context-simplification-plan-revised,agent-docs-new-system-pitch}.md`.
  Not loaded as guidance; deletion candidates (11 siblings already deleted by the
  user). Scoped OUT of 6b. Recommend deletion or a low-priority sweep.
- **Feedback inbox location** — `~/agent-docs/feedback/inbox.jsonl` stays (D11);
  needs a stable, install-survivable home in a future decision.
- **Retired-name sweep vs run-doc prose** — resolved (b2c5c5e); review confirmed
  the narrow exclusion hid nothing.

## Open questions / blockers

- None open. Plan §Open Decisions are delegated (D6).

## Closeout / migration status

Phase 8 complete. All durable facts migrated and verified present in canonical
docs. Plan migration notes filled. Plan + hub set `status: shipped`,
`okay_to_delete: true`.

### Migrated facts and targets

| Fact | Target |
|---|---|
| Source/runtime split; `v1` retired | `docs/decisions/agent-docs.md` §"Source/runtime split" + `docs/architecture/install-and-adapters.md` intro + `docs/architecture/workflow-kit.md` opening |
| Two-installer model, install == update | `docs/decisions/agent-docs.md` §"Two-installer model" + `docs/architecture/install-and-adapters.md` §"Installers" |
| `.agentdocs-install-manifest` provenance-only (not deletion authority) | `docs/decisions/agent-docs.md` §"Install manifest is provenance only" + `docs/architecture/install-and-adapters.md` |
| Managed-skill deletion policy (`.agent-docs-managed` marker authority; no force flag; collision stops with error; symlinks refused) | `docs/decisions/agent-docs.md` §"Managed-skill deletion policy" + §"Tool paths are adapters" + `docs/architecture/install-and-adapters.md` §"Managed skill adapter refresh" |
| `copy-skills.sh`/`install.sh` retired; refresh inlined | `docs/decisions/agent-docs.md` §"Skill refresh is embedded in installers" + `docs/architecture/install-and-adapters.md` |
| Verifier: one bundled script, guarded source-repo default, `--scaffold`, `--context-report` | `docs/decisions/agent-docs.md` §"Verifier modes are explicit" + `docs/architecture/workflow-kit.md` §"Main surfaces" |
| Ownership: install/adapter + runtime-path concepts | `docs/_meta/ownership.json` `install-and-relocation` + `tool-adapters` surfaces |

### Phase tracker update

| Phase | Status |
|---|---|
| 8 Closeout (plan + hub ship) | done — plan + hub shipped/okay_to_delete, migration notes filled, gate exit 0 |
| 9 Final drift gate + report | pending — gate run by phase 8 (see plan migration notes); formal verification.readonly sign-off still pending |
