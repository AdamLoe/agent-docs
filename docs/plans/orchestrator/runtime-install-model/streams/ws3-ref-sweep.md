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

## Bare-v1 cleanup (phase 6b)

Earlier sweeps converted the explicit `~/agent-docs/v1/...` runtime form but
missed bare `v1/...` source-path refs. This phase fixed those in the owned set,
applying the source-vs-runtime split (`docs/**` kit links → `src/...`; `src/`
runtime bodies → `~/.agentdocs/...`), prioritizing in-file consistency.

### Files touched (13) + refs fixed (29 total)

- `src/rules/skill-contracts.md` — 3 refs → `~/.agentdocs/...` (runtime body)
- `src/rules/authoring-rules.md` — 2 refs → `~/.agentdocs/...` (runtime body)
- `src/rules/orchestrator/dispatch.md` — 2 refs (`--context-report` command) → `~/.agentdocs/verify-agent-docs.sh`
- `src/skills/registry.md` — 8 refs → `~/.agentdocs/...` (runtime body)
- `src/skills/fresh-chat/SKILL.md` — 1 ref → `~/.agentdocs/skills/registry.md`
- `src/skills/feedback-agent-docs/SKILL.md` — 1 ref (`surface` example) → `~/.agentdocs/rules/...`
- `src/skills/doctor/SKILL.md` — 6 refs → `~/.agentdocs/...` (matches file's existing convention)
- `docs/agent-context/index.md` — 2 links → `../../src/...`
- `docs/agent-context/orchestrating.md` — 3 refs → `src/...`/`../../src/...`
- `docs/agent-context/collaboration-style.md` — 1 link → `../../src/...`
- `docs/architecture/index.md` — 1 link → `../../src/...`
- `docs/architecture/workflow-kit.md` — 1 ref (line ~179) → `~/.agentdocs/...` (see judgment below)
- `docs/plans/index.md` — 3 links → `../../src/...`

### Source-vs-runtime judgment calls

- `docs/architecture/workflow-kit.md:179` — bare `v1/verify-agent-docs.sh --scaffold <repo-root>`
  describes a CONSUMING-repo scaffold check. Per the in-file exception it matched
  the runtime form (line 168 already uses `~/.agentdocs/verify-agent-docs.sh
  --scaffold .`), so → `~/.agentdocs/...`, NOT `src/...`. The source-checkout
  gate commands elsewhere in the file (`bash src/verify-agent-docs.sh`) were
  already correct and left as-is.
- `src/rules/orchestrator/dispatch.md:44-45` — the `--context-report` command is
  in a body that becomes `~/.agentdocs/rules/orchestrator/dispatch.md`; migrated
  sibling bodies (doctor, rebuild SKILLs) write `~/.agentdocs/verify-agent-docs.sh`,
  so matched that → `~/.agentdocs/...`.
- `src/skills/doctor/SKILL.md` — file had already standardized on `~/.agentdocs/...`
  (e.g. line 48), so all six stragglers (registry, skill-contracts, the `v1/skills/*`
  glob, the `v1/verify-agent-docs.sh` self-refs) matched that convention.
- `src/skills/feedback-agent-docs/SKILL.md:74` — the `surface` field example names
  a kit rule file by path; as a runtime self-reference → `~/.agentdocs/rules/...`.

### Optional verifier tighten — DONE

`src/verify-agent-docs.sh:1007` prefix-strip tightened `~/agent-docs/` →
`~/.agentdocs/`. Functionally dead either way (line 1011 grep only captures
`src/rules/...` substrings, never runtime-form refs), so zero gate risk; applied
for vocabulary alignment.

### Gate result

`bash src/verify-agent-docs.sh` → see commit; `git grep` confirms only intentional
leftovers remain (retirement-prose mentions, the two excluded migration docs).

### Left deliberately

None in the owned set. Intentional out-of-scope refs (retirement prose in
`docs/decisions/agent-docs.md:8`, `src/agent-docs-guide.md:349`, the verifier
allowlist `new-project-prompt` entry, the migration-history docs) untouched.
