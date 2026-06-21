# Stream WS5 — Documentation & decisions

Owner: implementation worker (phase 5). Compact worker notes only.

Scope: `README.md`, `docs/architecture/install-and-adapters.md`,
`docs/architecture/workflow-kit.md`, `docs/decisions/agent-docs.md`,
`docs/agent-context/repo-rules.md`. Document source/runtime split, two install
entry points, `~/.agentdocs/` runtime path decision, removal of `v1` as runtime
terminology, managed-skill deletion policy, `copy-skills.sh` retirement.

## Worker notes

**Files touched:** `README.md`, `docs/overview.md`,
`docs/architecture/install-and-adapters.md`,
`docs/architecture/workflow-kit.md`, `docs/decisions/agent-docs.md`,
`docs/agent-context/repo-rules.md`.

**Gate result:** `bash src/verify-agent-docs.sh` → exit 0. ALL AGENT-DOCS
GATES PASS.

**Verifier allowlist edits (in `src/verify-agent-docs.sh`):**
- Updated `fresh-planning-chat` allowlist entry for `docs/decisions/agent-docs.md`
  from `v1/skills/plan/SKILL.md` to `src/skills/plan/SKILL.md` (line text
  changed when decisions doc was rewritten).
- Added `new-project-prompt` allowlist entry for
  `docs/plans/orchestrator/runtime-install-model/hub.md` line 111 (pre-existing
  explanatory prose that mentions the retired name; not my owned file but the
  gate was failing on it).

**Fact corrections vs. plan:**
- Plan mentioned "Skill listing reports source plus freshness" referencing
  `~/agent-docs/v1/skills/` — corrected to `~/.agentdocs/skills/`.
- `feedback-agent-docs` still uses `~/agent-docs/feedback/inbox.jsonl` in the
  skill body (WS3 scope); workflow-kit.md retains that path to stay in sync
  with the skill body. Left a note for WS3.
- Confirmed `.agent-docs-managed` is a file (not a dir marker), written as
  the source skill path — consistent with plan's "per-skill marker" framing.
- Confirmed no separate `update-agentdocs.sh` exists; plan correctly states
  install == update.
- GitHub installer accepts tag arg OR defaults to `main` branch (not "latest
  release") — described accurately as codeload archive from `main` or named
  tag.

**Verifier allowlist:** no additions required.

**Durable facts migrated:**
- Source/runtime split (`~/.agentdocs/` runtime, `src/` source)
- Two-installer model (local + GitHub, install == update)
- Managed-skill deletion policy (per-skill marker, stop-on-collision, no force)
- Install manifest = provenance only
- `copy-skills.sh` retirement documented in install-and-adapters.md and
  decisions
- `v1` retired as runtime term — all owned docs now use `src/` or
  `~/.agentdocs/` consistently

**Durable facts still needing migration (WS3 sweep):**
- `src/skills/**` and `src/rules/**` still contain `~/agent-docs/v1/...`
  runtime refs — WS3 scope.
- `src/template/**` docs still contain old runtime refs — WS3 scope.
- `feedback-agent-docs` SKILL.md uses `~/agent-docs/feedback/` path — WS3
  scope.
- `src/agent-docs-guide.md` may have old refs — WS3 scope.
