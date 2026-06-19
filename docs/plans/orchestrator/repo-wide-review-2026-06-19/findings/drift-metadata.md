# Drift and Metadata Review

## Findings

1. **High - `v1/template/docs/` is a first-class repo surface without explicit metadata ownership.**
   The layout and workflow docs list the scaffold template as an important surface, but `docs/_meta/manifest.md` has no specific change-to-doc row for template scaffold changes, and `docs/_meta/ownership.json` has no owner path for `v1/template/docs/`. The verifier only checks that some template files exist and that the template has its own minimal internal layout route; it does not prove this repo has an owner for changing the template itself. Evidence: `docs/repository-layout.md:23`, `docs/architecture/workflow-kit.md:72`, `docs/_meta/manifest.md:9`, `docs/_meta/ownership.json:29`, `v1/verify-agent-docs.sh:135`, `v1/verify-agent-docs.sh:191`.

2. **Medium - the registry gate is one-way and shallow.**
   The contract says each discoverable skill has one registry row, but the verifier only loops over `v1/skills/*/SKILL.md` and greps for a matching row. It would catch a missing row for an existing skill, but not a stale registry row after a skill directory is removed, duplicate rows, malformed columns, or wrong mode/action/intake/launch metadata. Current registry contents match the directories today; the issue is mechanical coverage. Evidence: `v1/rules/skill-contracts.md:184`, `v1/skills/registry.md:8`, `v1/verify-agent-docs.sh:258`, `v1/verify-agent-docs.sh:272`.

3. **Medium - `docs/repository-layout.md` is not mechanically checked against the tracked tree.**
   The tracked tree includes `.gitattributes`, `v1/agent-docs-guide.md`, `v1/plan-lifecycle.md`, and `v1/plan-template.md`; the layout doc lists `v1/` broadly and several child surfaces, but omits those stable files as explicit inventory rows. That may be intentional compression, but there is no verifier check distinguishing "covered by parent row" from accidental omission. The gate only requires the layout doc to exist and a manifest row to name it. Evidence: `.gitattributes:1`, `docs/repository-layout.md:8`, `docs/architecture/workflow-kit.md:73`, `v1/verify-agent-docs.sh:128`, `v1/verify-agent-docs.sh:166`.

4. **Medium - the main drift gate is green, but not fully repo-wide or hermetic.**
   Stale-reference scanning is hard-coded to `README.md`, `AGENTS.md`, `CLAUDE.md`, `docs`, and `v1`; future top-level tracked files or version directories would be missed unless the script is updated. The same gate also depends on `$HOME` adapter state via `v1/copy-skills.sh --check`, so it is partly a local install freshness check rather than a pure repository drift check. Evidence: `v1/verify-agent-docs.sh:327`, `v1/verify-agent-docs.sh:402`, `v1/copy-skills.sh:102`.

## What Works

- Required manifest slots are present: `repo_name`, `agent_docs_version`, `code_root`, `change-to-doc`, `drift-gates`, `drift-verification`, and `decisions-domains`.
- `docs/_meta/ownership.json` parses with `python3 -m json.tool`.
- All current ownership paths resolve.
- Skill directories, `SKILL.md` frontmatter names, and current registry rows agree today.
- `bash v1/verify-agent-docs.sh` passes:
  `agent-docs skills are fresh...` and `ALL AGENT-DOCS GATES PASS`.

## Biggest Pitches

- Add verifier coverage checks for registry inverse rows and row shape.
- Add a lightweight layout coverage check, probably based on curated stable surfaces plus `git ls-files`, not every temporary plan.
- Add explicit manifest/ownership coverage for `v1/template/docs/`.
- Split or label the gate's repo-only checks versus local adapter freshness checks.

## Open Questions

- Should `v1/template/docs/` be owned by a new "docs scaffold template" surface, or folded explicitly into the existing workflow/adoption surface?
- Should `.gitattributes` be listed in repository layout as stable repo config?
- The actual workspace has empty untracked `v2/` directories. Should those be deleted as local residue, ignored, or documented as an intentional future placeholder?

## Checks

Files/docs inspected: `docs/_meta/manifest.md`, `docs/_meta/ownership.json`, `docs/repository-layout.md`, `v1/verify-agent-docs.sh`, `v1/skills/registry.md`, `v1/rules/subagent/review.md`, router docs, skill contract/orchestrator rules, template metadata, workflow/install docs, and actual tree listings.

Commands run: `git status --short --untracked-files=all`; `python3 -m json.tool docs/_meta/ownership.json`; `find`/`git ls-files` tree checks; skill registry/frontmatter comparisons; `bash v1/verify-agent-docs.sh`.

Result: read-only review complete. No files edited, staged, restored, or committed. Pre-existing deleted files under `docs/plans/` were not touched. Residual risk: this was a cheap static review, not a full semantic docs drift sweep.
