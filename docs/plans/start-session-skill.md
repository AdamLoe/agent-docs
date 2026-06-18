---
status:        shipped
owner:         codex
last_updated:  2026-06-18
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
  - ../v1/skills/registry.md
  - ../v1/rules/skill-contracts.md
---

# Start-session skill

## Mission

Add a `start-session` skill that gives an agent a reliable beginning-of-day or
new-coding-session check. The work is done when the skill can inspect local
repo state, summarize active work, clean disposable plan material through the
existing cleanup skill when appropriate, and route the user into the next
implementation or planning workflow without duplicating those workflows.

## Scope

In scope:

- Add `v1/skills/start-session/SKILL.md` as a direct-intake workflow skill.
- Add the skill to `v1/skills/registry.md` and any workflow command lists.
- Have the skill inspect local git state only: branch/status, dirty files,
  plan/run-doc lifecycle state, and recent local history only when it helps
  explain recoverability.
- Treat orchestration run docs under `docs/plans/orchestrator/` like plan
  material: leave in-progress runs alone; clean shipped or abandoned runs only
  after durable context is migrated and the latest run docs are recoverable
  through git history.
- Route done plan cleanup to `clear-plans` instead of reimplementing cleanup.
- Route a dirty but coherent current diff to `ship-current-work`.
- Route active named plans to `ship-plans` or `review-shipped-work` depending
  on whether they need implementation or review.
- Route ambiguous or broad next work to `plan` or `orchestrate`.
- Tighten `clear-plans` so it never deletes a plan file or orchestration run
  folder whose latest version is not recoverable in local git history.
- Refresh copied skill adapters and verifier coverage if the existing drift
  gates require the new command surface to be discoverable.

Out of scope:

- Any GitHub API, PR, issue, or remote repository cleanup.
- Hidden session state outside git and `docs/plans/`.
- A new orchestration state format.
- Replacing `fresh-chat`, `doctor`, `review-plans-health`, `clear-plans`, or
  `ship-current-work`.
- Deleting active/draft plans or in-progress orchestration run folders.

## Approach

Implement this as one workflow-kit update.

The new skill should run directly from disk state, like `doctor`,
`review-plans-health`, and `clear-plans`. It should read the shared skill
contracts, then bootstrap from the manifest, docs router, and overview. After
that it should inspect only the narrow state needed for a startup summary:
`git status --short`, the current branch/upstream status when available, and
the plan/run-doc lifecycle frontmatter under `docs/plans/`.

The skill should produce a short state summary with buckets:

- Clean/dirty local git state.
- Active or draft plan files and in-progress orchestration runs.
- Shipped or abandoned plan files and run folders that are cleanup candidates.
- Current diff that should be shipped before more work starts.
- Recommended next skill, with the reason for that route.

The skill may invoke `clear-plans` when it finds shipped or abandoned plans or
run folders that are already eligible for cleanup. It may invoke
`ship-current-work` when the tree is dirty and the diff appears to be coherent
work that should be committed before cleanup or new implementation. It should
ask only when multiple mutating routes are plausible or when a dirty diff
would make cleanup unsafe.

Update `clear-plans` with a deletion guard at the point it handles
`okay_to_delete: true` candidates:

- If the candidate plan file or run folder is tracked and has no staged or
  unstaged changes, deletion is allowed after the existing migration sanity
  check.
- If any candidate file is modified, staged, deleted, renamed, or untracked,
  do not delete it in that pass. Report that the latest plan/run-doc version
  must be committed first, or route the user through `ship-current-work` when
  the dirty tree is coherent.
- If `clear-plans` itself migrates durable context or flags a plan/run folder,
  keep the existing two-pass behavior: commit the migration/flagging work, and
  leave deletion for a later cleanup run.

Update architecture and decisions docs only with durable current-state facts
and rationale: `start-session` is the local session entrypoint, it delegates
mutation to existing skills, and cleanup preserves git recoverability for
deleted plan material.

## Exit gate

The implementation is complete when:

- `v1/skills/start-session/SKILL.md` exists with concise frontmatter and a
  direct startup workflow.
- `v1/skills/registry.md` lists `start-session` with mode, action, commit
  behavior, intake style, launch tier, and normal input.
- Workflow docs mention `start-session` as the beginning-of-day/new-session
  state check without making it the default auto-loaded router.
- `clear-plans` refuses to delete dirty or untracked plan/run-doc material
  whose latest version is not in git history.
- The skill routes to existing skills rather than copying their procedures.
- Copied skill adapters are refreshed and checked.
- The repo drift gate passes:

```sh
bash v1/copy-skills.sh ~/agent-docs
bash v1/copy-skills.sh --check ~/agent-docs
bash v1/verify-agent-docs.sh
```

## Migration notes (filled in at ship time)

Before marking shipped, migrate durable facts and rationale into:

- `architecture/workflow-kit.md` for the current command surface and
  `start-session` routing role.
- `decisions/agent-docs.md` for the rationale behind a local startup
  coordinator and the git-history deletion guard.
- `../v1/skills/registry.md` for the new skill inventory row.
- `../v1/rules/skill-contracts.md` for the direct-intake exception list.

## See also

- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/skills/registry.md`](../../v1/skills/registry.md)
- [`../../v1/skills/clear-plans/SKILL.md`](../../v1/skills/clear-plans/SKILL.md)
- [`../../v1/skills/ship-current-work/SKILL.md`](../../v1/skills/ship-current-work/SKILL.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
