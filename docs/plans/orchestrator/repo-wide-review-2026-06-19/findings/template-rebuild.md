# Template and Rebuild Review

Outcome: read-only review completed. No files edited, staged, restored, or committed.

## Findings

1. High: `rebuild-agent-docs` tells verification to run the kit verifier "against the rebuilt tree," but the verifier resolves and checks the `agent-docs` checkout, not the consuming repo.
   `v1/skills/rebuild-agent-docs/SKILL.md:67-71` dispatches `~/agent-docs/v1/verify-agent-docs.sh` for the rebuilt tree. `v1/verify-agent-docs.sh:9-21` derives `repo_root` from the script location/git checkout, then validates `docs/`, `AGENTS.md`, `CLAUDE.md`, and `v1/` under that root at `v1/verify-agent-docs.sh:125-142`. In a consuming repo, that can falsely validate the kit checkout while leaving the target `docs/` unvalidated.

2. Medium: the seed scaffold can produce an unrouted docs tree.
   The guide's routing model expects descent from the top router to `architecture/`, `decisions/`, `agent-context/`, and `plans/` (`v1/agent-docs-guide.md:149-157`), but `v1/template/docs/index.md:5-9` only routes repository layout, `_meta`, and a placeholder row. `doctor` only requires visible `_meta` routing (`v1/skills/doctor/SKILL.md:38-39`), and the verifier only requires a route to `repository-layout.md` (`v1/verify-agent-docs.sh:157`, `191`). A consumer can therefore get all required directories but no reliable router path to the main doc roots.

3. Medium: placeholders are not guarded by the scaffold contract.
   `rg` found unresolved `<!-- fill -->` placeholders across the template plus `"surface": "fill"` / `"paths": ["fill"]` in `v1/template/docs/_meta/ownership.json:9-11`. The ownership contract says owner paths must point at existing files (`v1/skills/doctor/SKILL.md:40-41`; enforced for live ownership at `v1/verify-agent-docs.sh:245-254`), but the template verifier check only confirms the `repository-layout` owner path (`v1/verify-agent-docs.sh:197-201`). The rebuild skill says "adapt" and "repair manifest and ownership state" (`v1/skills/rebuild-agent-docs/SKILL.md:54-59`), but its closeout does not require "no placeholders remain."

## What Works

The canonical seed inventory is explicit and matches disk: nine files under `v1/template/docs/`, including the four doc roots and `_meta` files (`v1/skills/rebuild-agent-docs/SKILL.md:24-27`).

The guide correctly centers `docs/_meta/manifest.md` and `docs/_meta/ownership.json` as app bindings (`v1/agent-docs-guide.md:133-140`) and tells adopters not to create a prose ownership guide (`v1/agent-docs-guide.md:398-400`).

The rebuild flow has the right high-level shape: seed missing files, apply the recoverability test, migrate durable facts, repair manifest/ownership, verify, and close out (`v1/skills/rebuild-agent-docs/SKILL.md:51-86`).

## Biggest Pitches

Make the consumer scaffold verifier targetable, or split it from the kit verifier. A consuming repo needs a read-only command that validates `docs/` in the current working tree without requiring `v1/` to exist locally.

Strengthen the seed/router contract: top-level `docs/index.md` should route to `overview.md`, `architecture/index.md`, `decisions/index.md`, `agent-context/index.md`, `plans/index.md`, repository layout, and `_meta`.

Add a cheap placeholder gate for rebuild closeout: fail if `<!-- fill -->`, `"fill"`, `repo_name: <!-- fill -->`, or `code_root: <!-- fill -->` remains in generated consumer docs.

## Open Questions

Should consuming repos be expected to vendor any verifier script, or should `/doctor` contain the generic current-working-tree scaffold checks itself?

Should the template be intentionally skeletal, or should it be a valid minimal tree after replacing only repo name/code root/gates?

Durable fact that may need migration: the current verifier is this repo's drift gate, not a consumer-repo scaffold verifier, despite rebuild docs presenting it that way.

## Checks

Files/docs inspected: `docs/index.md`, `docs/overview.md`, `docs/_meta/manifest.md`, `docs/_meta/ownership.json`, `docs/repository-layout.md`, `docs/architecture/workflow-kit.md`, `docs/architecture/install-and-adapters.md`, `docs/decisions/agent-docs.md`, `v1/template/docs/**`, `v1/agent-docs-guide.md`, `v1/skills/rebuild-agent-docs/SKILL.md`, `v1/skills/doctor/SKILL.md`, `v1/rules/subagent/review.md`, `v1/rules/authoring-rules.md`, `v1/rules/subagent/docs-maintenance.md`, `v1/verify-agent-docs.sh`, `README.md`.

Checks run: `find v1/template -maxdepth 4 -type f`, `find v1/template/docs -type d -print`, `rg` for scaffold/adoption/repair/verifier/placeholder/ownership references, `nl -ba` for cited files, and `git status --short`.

Result: read-only checks completed. Full verifier intentionally not run. Pre-existing deleted files under `docs/plans/` were observed in git status and left untouched. Residual risk: no dynamic rebuild simulation was run, so findings are based on static contract review only.
