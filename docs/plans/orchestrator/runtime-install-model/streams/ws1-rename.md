# Stream WS1 — Source tree rename + metadata

Owner: implementation worker (phase 2). Compact worker notes only.

Scope: `git mv v1 src`; update root routers, `docs/repository-layout.md`,
`docs/_meta/manifest.md` (`code_root`, drift-gates path, `v1/...` rows),
`docs/_meta/ownership.json`. Source-path refs → `src/...`. Do **not** do the
global `~/agent-docs/v1` → `~/.agentdocs/` content sweep (that is WS3/phase 6).

## Worker notes

Completed 2026-06-20. HEAD 44dd667, branch overhaul-agent-docs-install-workflow.

**Transform applied:** `git mv v1 src` + mechanical bare `v1/` → `src/` sweep
across owned metadata/script files.

**Files touched (beyond the tree rename itself):**

- `CLAUDE.md`, `AGENTS.md` — bare `v1/` mention in See also line.
- `docs/repository-layout.md` — all `v1/...` table rows; `See also` link.
- `docs/index.md` — `../v1/agent-docs-guide.md` link.
- `docs/overview.md` — layout diagram, discovery adapter descriptions.
- `docs/_meta/manifest.md` — `code_root`, drift-gates bash line, all
  change-to-doc rows, and decisions-domains rows. `drift-verification` block
  UNCHANGED per dispatch.
- `docs/_meta/ownership.json` — all `v1/...` paths rewritten.
- `src/verify-agent-docs.sh` — usage string, all internal `v1/` literals
  (require_file, word-budget globs, context-profile reader, Python validator
  path, manifest-self-check string, require_manifest_change_to_doc calls,
  require_ownership_surface_path calls, require_layout_path calls, require_text
  calls, check_scaffold_tree call, skill-dir loop, skill-name mismatch message,
  registry reader, require_file/dir for rules/skills, retired-path check,
  executable list, copy-skills.sh invocation, candidate_files/policy_candidate_files).
- `src/copy-skills.sh` — `source_root` variable (bare source-path literal).
- `src/rules/context-profiles.md` — profile table `core_rule_paths` cells
  (these are repo-root-relative paths the verifier resolves; not runtime refs).
- `src/export-chatgpt-context.sh` — usage string, group IDs/titles,
  classify_path cases.

**Gate result:** `bash src/verify-agent-docs.sh` → exit 0.
`ALL AGENT-DOCS GATES PASS`

**Safety check:** `rg -n "~/agent-docs/src|/home/adamg/agent-docs/src" .` →
zero hits except two correct descriptive lines in `docs/overview.md` (skill copy
source path now correctly shown as `~/agent-docs/src/skills/<name>`).

**Intentionally preserved `v1/` literals (not wrongly rewritten):**

- `docs/_meta/manifest.md` `## drift-verification` block: `bash v1/install.sh`,
  `bash v1/copy-skills.sh`, `bash v1/verify-agent-docs.sh --context-report`,
  `readlink -e ~/agent-docs/v1/rules/authoring-rules.md`. These belong to the
  install/verify phase (WS2/WS4).
- All `~/agent-docs/v1/...` runtime references in `docs/agent-context/`,
  `docs/architecture/`, `docs/decisions/`, and skill bodies — WS3 sweeps these
  to `~/.agentdocs/...` in a later phase.
- `src/agent-docs-guide.md` internal `~/agent-docs/v1/...` runtime references
  and the allowlisted `v1/new-project-prompt.md` retired-name mention.
- `allow_retired_reference` allowlist in verifier: `v1/new-project-prompt.md`
  and `v1/skills/plan/SKILL.md` references in their respective decision docs
  are historical mentions, correctly allowlisted.

**Durable facts for migration (WS3/later):**

- All `~/agent-docs/v1/...` runtime refs in docs/agent-context/, architecture/,
  decisions/, and skill bodies remain to be converted to `~/.agentdocs/...`.
- `docs/_meta/manifest.md` drift-verification block still shows old runtime
  install commands — a later phase updates those.
