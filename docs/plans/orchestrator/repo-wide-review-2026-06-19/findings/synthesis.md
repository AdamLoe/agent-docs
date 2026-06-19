# Repo-wide Review Synthesis

## Executive Summary

The repo is coherent in its core direction: router-only startup files,
tool-neutral docs, subagent-first orchestration, disposable plans, and a reusable
`v1/` kit. The strongest findings are not about the concept. They are about
contract enforcement: several important promises are stated in docs or rules but
are not mechanically guaranteed by scripts, verifier checks, dispatch bundles, or
metadata ownership.

The best next move is not a broad rewrite. It is a focused hardening pass over
the exact surfaces that make the kit safe to trust: installer safety, verifier
scope, rule bundle self-containment, lifecycle ordering, and ownership coverage.

## Biggest Pitches

1. **Make install/copy behavior transactional and path-safe.**
   `copy-skills.sh` can replace symlinked tool skill roots even though docs
   promise only managed child skills are touched. It also mutates before all
   conflicts are known. Treat symlinked skill roots as conflicts unless forced,
   preflight all unmanaged-name conflicts before deleting/copying, and decide
   whether `AGENT_DOCS_SKILLS_DEST` is a documented testing hook or ignored by
   `install.sh`.

2. **Split the verifier contract: kit repo gate vs consumer scaffold gate.**
   `v1/verify-agent-docs.sh` validates the `agent-docs` checkout because it
   derives root from its own location. `rebuild-agent-docs` currently presents
   it as if it validates a rebuilt consuming repo. Add a targetable current-tree
   scaffold verifier, or move those checks into `/doctor`, so adopting repos can
   validate their own `docs/` without vendoring `v1/`.

3. **Make dispatch bundles self-contained for any role allowed to mutate.**
   Docs-maintenance and plan-maintenance can commit but their bundle omits
   `repo-rules.md`; review/verification can be authorized to fix but their
   bundles omit `implementation.md`. If a role can edit, the exact rule bundle
   should include commit discipline. If review workers should never fix, remove
   that authority and route fixes to implementation workers.

4. **Define one canonical ship order: last mutation, final verifier, closeout.**
   Some docs run final gates before plan/frontmatter/run-doc closeout edits,
   while others run docs maintenance before gates. Pick one rule: all mutations
   including doc migration and plan status updates happen before the final
   consolidated gate, then the orchestrator reports the verified final state.

5. **Make tracked-plan persistence explicit.**
   The lifecycle says planners may draft tracked plans and reviewers review plan
   files, but it is unclear who writes and commits the plan between those phases
   when the planner is read-only. Add a named persistence actor/subphase, either
   write-capable planning workers or a plan-maintenance handoff.

6. **Treat metadata as an enforcement layer, not just helpful context.**
   Add explicit manifest and ownership coverage for `v1/template/docs/`, broaden
   command ownership to match the registry, and strengthen verifier checks for
   inverse registry rows, duplicate rows, row shape, and curated repository
   layout coverage.

7. **Clean up skill registry/body drift.**
   `review-plans-health` and `review-skills` are registered as non-committing
   report-only commands but allow optional fixes. `fix-docs-drift` still assigns
   cross-file lead-only judgment that conflicts with subagent-first routing.
   `feedback-agent-docs` claims out-of-repo capture while writing under this
   repo when dogfooded. `list-skills` mixes source inventory with installed
   adapter inventory. Resolve these so command behavior is predictable.

8. **Tighten the reader path without bloating routers.**
   Keep `AGENTS.md`, `CLAUDE.md`, and `README.md` thin, but add a compact
   working-model section to `docs/overview.md`: subagent-first orchestration,
   reads-vs-dispatch, commit-heavy shipping, and the verifier gate. Also clarify
   plan/run-folder cleanup semantics in `docs/plans/index.md`.

## Add

- A targetable scaffold verifier for consuming repos, or equivalent `/doctor`
  checks that validate the current working tree.
- Preflight/dry-run behavior for `copy-skills.sh` and install/copy conflict
  reporting.
- Manifest and ownership entries for `v1/template/docs/`.
- Verifier checks for registry inverse rows, duplicate rows, launch-tier values,
  registry row shape, stale rows, and placeholder tokens in scaffold output.
- Dirty-tree preservation language in universal repo rules: snapshot status,
  preserve unrelated user changes/deletions, and stage only owned paths.
- A named "persist planner output" lifecycle subphase.

## Change

- Update `copy-skills.sh` so symlinked skill roots are conflicts by default and
  copy operations do not partially refresh managed skills after a later conflict.
- Change dispatch bundles so any editing authority carries `repo-rules.md` and,
  when following implementation discipline, `implementation.md`.
- Normalize final gate ordering across `skill-contracts`, `authoring-rules`,
  `/ship-current-work`, `/ship-plans`, and orchestrator lifecycle docs.
- Clarify canonical path language: physical checkout, `~/agent-docs`
  self-reference/symlink, and copied adapter skills are distinct concepts.
- Redefine `okay_to_delete` to cover abandoned plans as well as shipped plans
  once useful context is migrated or absent.
- Decide whether review workers may fix; if yes, make the rule bundle explicit;
  if no, route every fix through implementation.

## Remove

- Stale path references such as `./plan-lifecycle.md` from `v1/rules/`.
- Tool-specific generic wording that mentions only `~/.claude/skills/` where
  the adapter model includes both Claude and Codex paths.
- Retired `fix-docs-drift` concepts like `Update when` and `Living notes` if
  they are no longer part of the doc model.
- Any claim that feedback capture is outside the repo unless the inbox is moved
  or ignored when this repo is the current checkout.

## Suggested Sequence

1. Installer/copy safety: symlink-root conflict, all-conflicts preflight,
   `AGENT_DOCS_SKILLS_DEST` decision, dry-run/check clarity.
2. Verifier/scaffold split: target current repo scaffold checks, placeholder
   gate, registry inverse/shape checks.
3. Rules/lifecycle hardening: self-contained bundles, final gate ordering,
   planner-output persistence, dirty-tree invariant.
4. Metadata/docs alignment: template ownership, command ownership, overview
   working-model section, install terminology cleanup.
5. Skill cleanup: registry optional-mutation fields, `fix-docs-drift`,
   `feedback-agent-docs`, `list-skills`, `fresh-chat` launch tier.
