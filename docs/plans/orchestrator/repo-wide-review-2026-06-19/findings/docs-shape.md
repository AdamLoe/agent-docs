# Docs Shape Review

## Findings

1. **Install/adapter docs conflate canonical path, physical checkout, and copied skill adapters.**
   `README.md:11-24` says the repo can be cloned anywhere and passed to the installer, but `README.md:31-35`, `docs/architecture/install-and-adapters.md:3`, and `docs/decisions/agent-docs.md:5-6` say the real checkout lives at `~/agent-docs`. Meanwhile route text still says "symlinks" or "symlink contract" at `docs/index.md:9`, `docs/architecture/index.md:5`, and `README.md:84`, while the active adapter model is copied skills in `README.md:39-47`, `docs/overview.md:26-29`, `docs/architecture/install-and-adapters.md:12-13`, and `docs/decisions/agent-docs.md:15-18`.

   What I would do: split the language into three explicit concepts: canonical self-reference path `~/agent-docs`, optional installer-created symlink when the physical checkout is elsewhere, and copied tool skill adapters.

2. **The "system shape in one screen" route is too thin for current working rules.**
   `docs/index.md:7` routes system-shape readers to `docs/overview.md`, but the overview only covers layout and discovery adapters (`docs/overview.md:7-29`). The actual working model - subagent-first orchestration, inline-vs-worker boundary, commit-heavy worker shipping, and drift gate - lives elsewhere (`docs/architecture/workflow-kit.md:8-16`, `docs/architecture/workflow-kit.md:76-80`, `docs/architecture/workflow-kit.md:91-98`, `docs/agent-context/repo-rules.md:8-11`).

   What I would do: add a short "Working model" section to `docs/overview.md` with the current orchestration, shipping, and gate rules.

3. **Ownership metadata does not cover the documented command surface cleanly.**
   `docs/_meta/ownership.json:29-31` names only a subset of workflows under `workflow-lifecycle`, while `docs/architecture/workflow-kit.md:100-126` documents the full command surface and `docs/architecture/workflow-kit.md:130-143` routes by job. A fresh agent querying ownership for `/quick-fix`, `/ship-plans`, `/clear-plans`, `/doctor`, `/check-docs`, or review commands will not get a complete owner signal.

   What I would do: broaden ownership to command families or enumerate all workflow commands, aligned with `v1/skills/registry.md`.

4. **Plans routing is recoverable but under-explained.**
   `docs/index.md:13` advertises "Active and shipped plans," while `docs/plans/index.md:6-7` says not to maintain a live inventory and to list the directory. That is directionally correct, but it leaves orchestration run docs and cleanup semantics to deeper routes (`docs/architecture/workflow-kit.md:117-124`, `docs/decisions/agent-docs.md:177-187`).

   What I would do: add two sentences to `docs/plans/index.md` explaining that plan files and run folders are temporary coordination surfaces governed by `v1/plan-lifecycle.md` and cleanup skills.

## What Works

- `AGENTS.md` and `CLAUDE.md` are clean router-only files with no fact dump.
- `docs/index.md` gives a compact route map and points to manifest and ownership data.
- Architecture vs decisions are mostly well separated: current behavior in `docs/architecture/`, rationale in `docs/decisions/`.
- Manifest basics are clear: `code_root: v1/` at `docs/_meta/manifest.md:5` and drift gate `bash v1/verify-agent-docs.sh` at `docs/_meta/manifest.md:23-29`.
- Historical terms are mostly contained in `docs/decisions/agent-docs.md`, not spread through the startup routers.

## Biggest Pitches

- Make install wording precise first; it is the main recoverability hazard.
- Promote the current workflow contract into `docs/overview.md` so a fresh agent gets the operating model before branching.
- Treat `ownership.json` as a real routing surface and make command ownership complete.
- Keep `README.md`, `AGENTS.md`, and `CLAUDE.md` thin; do not solve these by stuffing workflow facts into auto-loaded files.

## Open Questions

- Is non-`~/agent-docs` physical checkout support a long-term contract? `v1/install.sh` supports it, but the prose still says the real checkout is `~/agent-docs`.
- Should ownership metadata enumerate every skill, or should it own command families and rely on `v1/skills/registry.md` for the exact inventory?
- Should mature "alternatives considered" material in `docs/decisions/agent-docs.md` stay as-is, or be compressed once the current model is stable?

## Checks

Inspected: `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/` excluding `docs/plans/orchestrator/repo-wide-review-2026-06-19/`, plus `v1/rules/subagent/review.md`, manifest, ownership, and relevant `v1` installer/registry files for evidence.

Checks run: `rg --files`, `find ... -prune`, `nl -ba`, `sed -n`, targeted `rg` for stale terms, routing, command names, ownership, copy/symlink wording, and `git status --short`.

Result: read-only review only. No files edited, staged, restored, or committed. Full verifier was intentionally not run. `git status --short` shows the pre-existing deleted `docs/plans/` files and untracked excluded orchestrator folder; they were left untouched. Residual risk: the worker did not validate every Markdown link or inspect deleted plan contents.
