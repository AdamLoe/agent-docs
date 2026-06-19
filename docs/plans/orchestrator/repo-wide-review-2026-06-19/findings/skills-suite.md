# Skills Suite Review

## Findings

1. Registry commit metadata understates optional mutation for review skills.
   `v1/skills/registry.md:46` marks `review-plans-health` as `report-only` with `Commits: no`, but the skill allows user-authorized cleanup at `v1/skills/review-plans-health/SKILL.md:10` and `v1/skills/review-plans-health/SKILL.md:47`. Its closeout at `v1/skills/review-plans-health/SKILL.md:80` only describes recommendations, not commits/gates for applied cleanup. `v1/skills/registry.md:48` similarly marks `review-skills` as `Commits: no`, while `v1/skills/review-skills/SKILL.md:58` allows applied fixes and commits. This makes the command suite look safer/read-only than some bodies permit.

2. `fix-docs-drift` breaks the shared reads-vs-dispatch model.
   The shared contract says to dispatch a worker when work reads across more than a couple files or makes a defensible judgment call (`v1/rules/skill-contracts.md:69`, `v1/rules/orchestrator/lifecycle.md:41`). But `v1/skills/fix-docs-drift/SKILL.md:74` tells the lead to reconcile renamed symbols across three docs and curate "Living notes" inline as "lead-only judgment." That is exactly the kind of cross-file judgment the model says should go to a worker. The same skill also references `Update when` and `Living notes` at `v1/skills/fix-docs-drift/SKILL.md:55` and `v1/skills/fix-docs-drift/SKILL.md:75`; `rg` found no other occurrences in `docs/` or `v1/`, so these look like retired doc conventions.

3. `feedback-agent-docs` can violate its no-repo-change capture contract when dogfooded in this repo.
   The capture mode says these skills write out-of-repo and do not edit the current repo (`v1/rules/skill-contracts.md:155`). The registry repeats that `feedback-agent-docs` does not commit because it "writes the kit inbox, not the repo" (`v1/skills/registry.md:53`). But the skill appends to `~/agent-docs/feedback/inbox.jsonl` (`v1/skills/feedback-agent-docs/SKILL.md:83`, `v1/skills/feedback-agent-docs/SKILL.md:94`) while also saying no repo change at `v1/skills/feedback-agent-docs/SKILL.md:106`. In this checkout, `git rev-parse --show-toplevel` is `/home/adamg/agent-docs`, so that path is inside the current repo.

4. `list-skills` mixes canonical inventory and installed-copy inventory.
   The skill says to read the registry and source frontmatter (`v1/skills/list-skills/SKILL.md:22`), but the helper scans only copied adapter paths and project skill paths (`v1/skills/list-skills/list-skills.sh:101`). It then prints that the source of truth is `~/agent-docs/v1/skills/` (`v1/skills/list-skills/list-skills.sh:109`). Today the installed helper returned all 20 skills, but stale adapter copies could make `/list-skills` hide source/registry drift.

5. `fresh-chat` uses an undefined launch-tier value.
   The registry describes launch tier as the recommended model tier (`v1/skills/registry.md:15`) and `skill-contracts.md` defines role-based tiers around `cheap`, `mid-tier`, `strong`, and `strongest` (`v1/rules/skill-contracts.md:126`). All registry rows use `mid` or `strong` except `fresh-chat`, which uses `any` at `v1/skills/registry.md:25`. That is small schema drift that makes validation and model-choice guidance less crisp.

## What Works

- No missing discoverable skills found: 20 `v1/skills/*/SKILL.md` files, 20 registry rows, and matching frontmatter names.
- The main intake split is coherent: `asks` rows generally run two-question intake, and state-driven `no-prompt` rows skip it.
- Most mutating skills route edits through implementation, docs-maintenance, or plan-maintenance workers and ask for verification plus commit hashes.
- The command surface is mostly understandable: `check-docs`, `review-docs-shape`, and `fix-docs-drift` have distinct lanes; `start-session` routes instead of duplicating lifecycle work.

## Biggest Pitches

- Make optional mutation explicit in the registry: either change `review-plans-health` and `review-skills` to "review with optional fixes" with commit behavior, or make them strictly report-only and route applies to `clear-plans` or a fix skill.
- Rewrite the `fix-docs-drift` inline reconciliation clause so cross-file judgment goes to review/docs-maintenance workers; delete or re-home the stale `Update when` / `Living notes` policy.
- Decide whether `list-skills` means canonical source inventory or currently installed skills. If both matter, report both plus adapter freshness.
- Decide where the feedback inbox lives when the current repo is `agent-docs`; either make it ignored/out-of-repo or admit it is a repo mutation.

## Open Questions

- Should `review-plans-health` ever apply cleanup directly, or should `/clear-plans` own all plan cleanup mutation?
- Is `fresh-chat` intentionally launchable on "any" model, or should the registry only use defined launch tiers?
- Are `Update when` bullets and `Living notes` retired conventions?
- Should feedback inbox entries be committed, ignored, or stored outside the kit checkout?

## Checks

Files/docs inspected: `docs/index.md`, `docs/overview.md`, `docs/_meta/manifest.md`, `docs/architecture/workflow-kit.md`, `docs/architecture/install-and-adapters.md`, `docs/decisions/agent-docs.md`, `README.md`, `v1/agent-docs-guide.md`, `v1/skills/registry.md`, all 20 `v1/skills/*/SKILL.md`, `v1/skills/list-skills/list-skills.sh`, `v1/rules/skill-contracts.md`, `v1/rules/repo-rules.md`, `v1/rules/orchestrator/*`, and `v1/rules/subagent/*`.

Checks run: `rg --files v1/skills`, `wc -l v1/skills/*/SKILL.md`, two `diff -u` checks comparing skill directories to registry rows and frontmatter names, targeted `rg` checks for intake/commit/adapter/stale terms, `bash v1/skills/list-skills/list-skills.sh`, `git status --short`, `git rev-parse --show-toplevel`.

Result: static checks found no missing registry rows or frontmatter mismatches. The full verifier was not run per instruction. No files were edited, staged, restored, or committed. Existing deleted `docs/plans/` files and the untracked orchestrator folder were left untouched. Residual risk: this was a cheap read-only review, not a full verifier or adapter freshness gate.
