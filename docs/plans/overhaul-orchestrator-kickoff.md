You are orchestrating the agent-docs overhaul, working inside the repo at the
current working directory. This is a standard/deep multi-stream effort. The
plan is ALREADY fully written — your job is to EXECUTE it, not re-plan or
re-litigate it. Read all paths repo-relative (e.g. v1/rules/orchestrating.md),
not through ~/.claude or ~/agent-docs — the self-reference paths are mid-migration
and Phase 1 is what fixes them.

ORIENT — read in this order, do not skim:
1. docs/plans/overhaul-agent-docs.md — the HUB. Authoritative. Holds the
   mission, target decisions, the streams table, the Sequencing (Phases 1–5),
   the "This repo dogfoods the kit" section, the target doc skeletons, the
   discipline rules, and the real exit-gate assertions.
2. The six stream files it links: overhaul-B-install.md, overhaul-C-skill-metadata.md,
   overhaul-D-orchestration.md, overhaul-E-ship-current-work.md,
   overhaul-F-rebuild-agent-docs.md, overhaul-H-authoring-adapter.md. Each has
   its owned files, approach, exit gate, and a ready-to-paste dispatch prompt —
   use those dispatch prompts verbatim when you spawn the stream agents.
3. v1/rules/orchestrating.md — your operating manual (hold the map, not the
   territory; cheapest sufficient gate; consolidated end gate).
4. v1/rules/repo-rules.md — commit discipline: branch off main first, stage by
   filename, no `git add -A`, no --no-verify, NO push.

EXECUTE the phases in order (full detail in the hub's Sequencing section):

- PHASE 1 (you, serial, first). (a) Confirm recon:
  grep -RIn '~/.claude/agent-docs/v1' v1 README.md — expect ~25 hits across
  README.md, v1/README.md, and all 8 skills. (b) Substitute
  ~/.claude/agent-docs/v1 → ~/agent-docs/v1 everywhere; in runnable shell
  snippets prefer "$HOME/agent-docs/v1/…"; leave the ~/.claude/skills adapter
  alone (B/C own it). (c) Create the dogfood docs/_meta/manifest.md +
  ownership.json with the EXACT locked slot keys — code_root (= v1/),
  change-to-doc, drift-gates, drift-verification, decisions-domains — because
  Stream E's /ship-current-work reads them by name. Do Phase 1 yourself; it
  de-conflicts every downstream stream.

- PHASE 2 (parallel wave on disjoint files). Dispatch D, E, F, H concurrently
  (orchestrating.md / authoring-rules.md / three disjoint skill subsets + two
  NEW skills / one rule edit). Also dispatch B: it WRITES v1/install.sh (the
  only file it writes) and RETURNS README/v1-README slot content keyed to the
  hub skeleton — it must NOT write the README files. Batch by concern; do not
  spawn one agent per file.

- PHASE 3 (after Phase 2). Dispatch C: one metadata+length pass over ALL
  v1/skills/*/SKILL.md (add name:, tighten descriptions, trim hot-path bodies,
  make /list-skills adapter-aware). C VERIFIES (does not rewrite) E's and F's
  new skills, and provably preserves D's effort-resolution lines.

- PHASE 4 (you). Reconcile README.md, v1/README.md, v1/agent-docs-guide.md
  against the hub's "Target shape of the reconciled docs" skeletons, dropping
  each stream's returned slot content into the named headings. Apply B's
  install rewrite + install.sh pointer, E's lifecycle section, F's rebuild
  pointer, H's authoring cross-ref, C's cross-tool-contract table edit. Enforce
  terminology: ~/agent-docs, per-skill ~/.claude/skills/<name>, the
  ~/.codex/skills/agent-docs bucket, ship-current-work, rebuild-agent-docs,
  clear-plans (kept), router-only AGENTS.md, inline/light/standard/deep/max.

- PHASE 5 (you). Run the hub's Exit-gate assertions — they are REAL now (each
  fails non-zero on a miss; first failure aborts). Fix any failure before
  committing. Then commit locally by filename on a branch off main; suggested
  message "Refactor agent-docs install and workflow model". DO NOT PUSH. The
  installer-resolution checks that mutate $HOME are out of the automated gate —
  run them by hand only if you deliberately want to install.

HARD DISCIPLINE (from the hub — violating these is how this effort breaks):
- Parallel agents NEVER write README.md / v1/README.md / v1/agent-docs-guide.md.
  They return slot content; YOU apply it in Phase 4.
- Skill files are edited in PASSES: Phase 1 (paths) → D/E/F (disjoint subsets) →
  C (final sweep). Never two agents on the same skill at once.
- Discovery model is asymmetric and must never clobber a user's skills: Codex
  uses the ~/.codex/skills/agent-docs bucket (Codex recurses); Claude links
  per-skill into ~/.claude/skills/<name> (Claude does NOT recurse — verified
  against the binary). Keep the name clear-plans; do not introduce clean-plans.
- Hold the map, not the territory: spend your context on sequencing and
  judgment, not on file reads and build output. Each stream agent reports back;
  you reconcile.

DONE WHEN every assertion in the hub's Exit gate passes and the work is
committed locally (not pushed).

Begin: read the hub now, then confirm the Phase-1 recon counts, then proceed
through the phases. If anything in the plan is genuinely ambiguous or a gate
won't go green, stop and surface it rather than guessing.