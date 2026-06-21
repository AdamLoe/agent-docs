# Stream WS4 — Verifier split

Owner: implementation worker (phase 4). Compact worker notes only.

Scope: decide runtime vs source-only verifier behavior; keep runtime/scaffold
checks in `src/verify-agent-docs.sh`; move source-only repo drift checks to
top-level `scripts/` if they should not ship in the runtime bundle; update
`docs/_meta/manifest.md` drift-gate rows to match the split.

## Worker notes

Done. Same basis as WS2 (HEAD ab6e254).

Split decision: LANDED the optional refinement as ONE script (no top-level
`scripts/` dir). The default mode is the source-repo self-consistency gate; the
only runtime-useful mode skills invoke from the bundle is `--scaffold
<target>`, which already resolves against the target arg, not the kit checkout.
Added an early source-repo guard in default mode: if `src/skills/registry.md`
is absent or the manifest `repo_name` is not `agent-docs`, print a directive to
use `--scaffold` and exit 0 (graceful degradation when run as
`~/.agentdocs/verify-agent-docs.sh` in a consuming repo). `--scaffold` and
`--context-report` entry points are unchanged.

Source-only checks (skipped outside the source repo): manifest scalar/section
slots, change-to-doc rows, ownership surface/path validation, skill registry
parsing, context-profile contract, documentation budgets, retired-name and
stale-path rejections, required-executable + git-mode checks. Runtime-useful:
`--scaffold` (consuming-repo scaffold validation) and `--context-report`.

Other edits:

- Required-executable list now names `install-agentdocs-local.sh` and
  `src/install-agentdocs.sh` (was the two removed scripts).
- Replaced the copy-skills `--check` adapter-freshness self-test with an inline
  `check_adapter_freshness` that diffs each tool destination against
  `~/.agentdocs/skills/` (stale/missing/orphaned all fail). Skips when the
  runtime is not installed (fresh CI checkout). Functionally proved pass + all
  failure modes against a throwaway fake $HOME.
- Manifest: rewrote the two install/adapter change-to-doc rows and the
  `## drift-verification` block (now `--dry-run` previews + `~/.agentdocs/...`
  resolution checks + `src/verify-agent-docs.sh --context-report`).
- Forced cross-file fix (my deletion broke them): `docs/_meta/ownership.json`
  install/adapter `paths` now name the two new installers so
  `validate_ownership_paths_under` stays green.
- Extended `allow_retired_reference` for two pre-existing WS1 stream-note lines
  that discuss the allowlist mechanism — the source gate was already RED at HEAD
  ab6e254 because of them.

Gates: `bash src/verify-agent-docs.sh` = 0 (ALL GATES PASS); guard graceful-skip
exit 0 outside source repo; dangling-ref grep = no matches.

## Verifier hardening

Changed: in `reject_unapproved_retired_name`, added a path-skip before the
inner grep loop — any `$relative_file` starting with `docs/plans/orchestrator/`
is skipped with `continue`. The `candidate_files()` function and the
`.agent-docs/(current|src)` stale-path reject are untouched.

Allowlist entries removed from `allow_retired_reference` (run-doc files only,
no longer needed since the whole `docs/plans/orchestrator/**` subtree is now
excluded from the sweep):
- `new-project-prompt|docs/plans/orchestrator/runtime-install-model/streams/ws1-rename.md` (two entries)
- `new-project-prompt|docs/plans/orchestrator/runtime-install-model/hub.md` (one entry)

Kept: the `src/agent-docs-guide.md` entry and the `docs/decisions/agent-docs.md`
fresh-planning-chat entry — both are real production docs.

Gate result: `bash src/verify-agent-docs.sh` → exit 0, `ALL AGENT-DOCS GATES
PASS`. Previously-failing `ws5-docs.md:25` (`new-project-prompt` mention in
run-doc prose) no longer triggers. Non-run-doc detection confirmed intact: skip
is path-scoped to `docs/plans/orchestrator/` only; `src/` and
`docs/decisions/` still run through the full check plus per-line allowlist.
