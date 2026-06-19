# Rules System Review

## Findings

1. High - Mutating worker bundles are not self-contained enough for the behavior they authorize. `v1/rules/orchestrator/dispatch.md:10` says to pass exact rule-file links and not make workers discover the workflow system, and `v1/rules/orchestrator/dispatch.md:87` defines the bundle table. But docs-maintenance may repair and commit (`v1/rules/subagent/docs-maintenance.md:24`, `v1/rules/subagent/docs-maintenance.md:28`) while its bundle omits `repo-rules.md` (`v1/rules/orchestrator/dispatch.md:94`). Plan-maintenance may delete/edit/commit (`v1/rules/subagent/plan-maintenance.md:29`, `v1/rules/subagent/plan-maintenance.md:33`) while its bundle also omits `repo-rules.md` (`v1/rules/orchestrator/dispatch.md:95`). Review and verification can be authorized to fix and then follow `implementation.md` (`v1/rules/subagent/review.md:22`, `v1/rules/subagent/verification.md:25`), but their bundles do not include `implementation.md` (`v1/rules/orchestrator/dispatch.md:93`, `v1/rules/orchestrator/dispatch.md:96`). That leaves commit safety, staging, gates, and doc-migration behavior dependent on link-chasing or skill-specific compensation instead of the exact dispatch contract.

2. Medium - The review worker is under-specified for docs/rules/system reviews. The review bundle is only `v1/rules/subagent/review.md` plus the source under review (`v1/rules/orchestrator/dispatch.md:93`). But the review card says docs reviews check ownership, recoverability, and house rules (`v1/rules/subagent/review.md:18`) and reports per dispatch (`v1/rules/subagent/review.md:34`). It does not require `authoring-rules.md`, `skill-contracts.md`, or `dispatch.md` unless the orchestrator manually adds them. A worker can therefore satisfy the role card while missing the actual rule authority behind "house rules."

3. Medium - Core orchestration policy is duplicated across authority layers. `skill-contracts.md` restates subagent-first orchestration, reads-vs-dispatch, and dispatch failure behavior (`v1/rules/skill-contracts.md:58` through `v1/rules/skill-contracts.md:78`) that `lifecycle.md` also owns in more detail (`v1/rules/orchestrator/lifecycle.md:16` through `v1/rules/orchestrator/lifecycle.md:60`). Dials are also split: `skill-contracts.md` says only `review-none` is hard and the rest is "vibes, not a rulebook" (`v1/rules/skill-contracts.md:108`), while `lifecycle.md` gives numeric fan-out bands (`v1/rules/orchestrator/lifecycle.md:87`). The caveat at `v1/rules/orchestrator/lifecycle.md:82` helps, but the same policy now has two edit sites.

4. Medium - The commit-heavy rules lack a dirty-tree preservation invariant. The system strongly prefers worker commits (`v1/rules/repo-rules.md:35`, `v1/rules/orchestrator/dispatch.md:136`, `v1/rules/subagent/implementation.md:36`) and says to stage by filename (`v1/rules/repo-rules.md:28`), but it never explicitly says to snapshot `git status`, preserve unrelated user changes/deletions, avoid restoring unrelated files, or stop if unrelated dirty state blocks a clean slice. The current run hub records pre-existing deleted plan files (`docs/plans/orchestrator/repo-wide-review-2026-06-19/hub.md:41`), but that safeguard comes from run context, not the generic rules.

5. Low - `authoring-rules.md` has stale or tool-specific path references. Its See also uses `./plan-lifecycle.md` and `./agent-docs-guide.md` (`v1/rules/authoring-rules.md:161`), but from `v1/rules/` those files do not exist; the real files are `v1/plan-lifecycle.md` and `v1/agent-docs-guide.md`. It also says maintenance skills live under `~/.claude/skills/` (`v1/rules/authoring-rules.md:158`), while the repo overview documents both Claude and Codex copied skill paths (`docs/overview.md:26`, `docs/overview.md:28`).

## What Works

- The layer model is clear: universal rules, orchestrator rules, subagent role cards, and skill bodies are explicitly separated in `docs/architecture/workflow-kit.md:18`.
- The dispatch packet shape is concrete and useful (`v1/rules/orchestrator/dispatch.md:8`).
- Worker role files are short enough to load without burying workers; the whole rule tree is about 1,292 lines.
- The authoring rules give strong, actionable invariants around ownership, recoverability, and no transcription (`v1/rules/authoring-rules.md:23`, `v1/rules/authoring-rules.md:37`).
- Commit concurrency is well stated: editing is serial by default, with worktrees or patches for parallel editing (`v1/rules/orchestrator/dispatch.md:142`).

## Biggest Pitches

- Make the bundle table self-contained: if a role can edit, include `repo-rules.md`; if it can follow implementation discipline, include `implementation.md`; if it reviews docs/rules, include the rule owners for that lens.
- Pick one owner for reads-vs-dispatch and dial semantics. Let `skill-contracts.md` summarize and point to `lifecycle.md`, or keep only non-numeric startup policy there.
- Add two explicit invariants: "preserve unrelated dirty work" and "dispatch rule-file paths are repo-root paths; code anchors are `code_root`-relative."
- Add a cheap static check for rule links and bundle prerequisites so stale paths and missing role dependencies fail before review.

## Open Questions

- Should review workers ever apply fixes, or should optional fixes always route to a separate implementation worker?
- Is `skill-contracts.md` a skill-only startup contract, or should workers also receive it as part of every bundle?
- Should generic rule docs mention both `~/.claude/skills` and `~/.agents/skills` whenever they mention installed skills?
- Should docs/rules reviews have a named bundle separate from generic "Review worker"?

## Checks

Outcome: read-only review completed. No files edited, staged, restored, or committed.

Inspected: `docs/index.md`, `docs/overview.md`, `docs/_meta/manifest.md`, `docs/architecture/workflow-kit.md`, `docs/decisions/agent-docs.md`, `v1/agent-docs-guide.md`, `v1/skills/registry.md`, the run hub, and all files under `v1/rules/`.

Checks run: `find v1/rules -maxdepth 3 -type f | sort`; `nl -ba`/`sed` reads of rule and context files; `rg` scans for duplicated policy, path references, bundle/report terms, and dirty-tree language; `wc -l` on rule files; `ls` checks for the suspect relative links; `git status --short`.

Results: cheap checks only, per request. Full verifier `bash v1/verify-agent-docs.sh` was not run. `ls v1/rules/plan-lifecycle.md` and `ls v1/rules/agent-docs-guide.md` failed; `ls v1/plan-lifecycle.md` and `ls v1/agent-docs-guide.md` passed. `git status --short` showed the pre-existing deleted `docs/plans/` files and the untracked orchestrator run folder; this review did not modify them.

Durable migration candidates: bundle self-containment, dirty-tree preservation, adapter-neutral installed-skill paths, path-kind semantics, and single-owner dial/orchestration policy.

Blockers/residual risk: no blocker. Residual risk is that individual skill bodies may compensate for bundle gaps in practice; this review treated `v1/rules/orchestrator/dispatch.md` as the authoritative reusable rules surface.
