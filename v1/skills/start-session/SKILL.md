---
name: start-session
description: Begin a coding day or new agent session by checking local repo state, active plans, shipped cleanup candidates, orchestration run docs, and routing into the right agent-docs skill.
---

You are starting a work session in the current repository. Inspect local state,
summarize what is in flight, and continue through the smallest existing
agent-docs skill that owns the next action. Do not inspect GitHub, remotes,
issues, pull requests, or external services.

This skill runs directly on disk state — no intake questions. Read
`~/agent-docs/v1/rules/skill-contracts.md` for shared dials and model policy,
and honor any dials passed in `$ARGUMENTS`.

## Bootstrap

1. Read `docs/_meta/manifest.md` for `repo_name`, `code_root`,
   `change-to-doc`, and `drift-gates`.
2. Read `docs/index.md` and `docs/overview.md`.
3. Read `docs/plans/index.md` and `~/agent-docs/v1/plan-lifecycle.md`.
4. List `docs/plans/`. Read every top-level plan file except `index.md` and
   `template.md`. For each immediate folder under `docs/plans/orchestrator/`,
   read `hub.md` first and treat that hub frontmatter as the run status
   source.
5. Inspect local git state with `git status --short --branch`. Use
   `git diff --name-only` and `git diff --cached --name-only` only when the
   status output needs clarification. Use recent local commit history only
   when recoverability of plan material is unclear.

## Classify State

Bucket the repo state before acting:

- **Local git.** Clean, dirty coherent work, or dirty unclear work. Name
  staged, unstaged, untracked, renamed, or deleted files when they affect the
  next route.
- **In flight.** Top-level plans or orchestration runs with `draft` or
  `active` status, plus any `long_lived: true` material.
- **Cleanup candidates.** Plans or run folders with `status: shipped` or
  `abandoned`, especially `okay_to_delete: true`.
- **Plan history risk.** Cleanup candidates whose files are modified, staged,
  renamed, deleted, or untracked. Their latest version is not recoverable from
  local git history yet.
- **Next workflow.** The smallest skill that owns the next action.

For orchestration run folders, leave in-progress runs alone. Treat shipped or
abandoned runs as disposable plan material only when the hub has lifecycle
frontmatter and closeout or migration state.

## Routing

Use existing skills; do not copy their procedures.

- If there are cleanup candidates and local git is clean, continue with
  `clear-plans`. Tell the user this route is being taken and then follow
  `~/agent-docs/v1/skills/clear-plans/SKILL.md`.
- If cleanup candidates exist but any candidate plan or run-doc file is dirty
  or untracked, do not delete it. If the dirty tree is coherent and ready to
  preserve, continue with `ship-current-work`; otherwise report the files and
  ask for the one decision needed to proceed.
- If the repo has a dirty coherent diff unrelated to cleanup, continue with
  `ship-current-work` before starting new work.
- If active plans are ready to implement, continue with `ship-plans` and name
  the plan paths.
- If active or recently shipped work needs checking, continue with
  `review-shipped-work` and name the plan paths.
- If the user supplied a small bounded task in `$ARGUMENTS`, continue with
  `quick-fix`.
- If the user supplied broad or ambiguous work in `$ARGUMENTS`, continue with
  `plan` or `orchestrate` based on scope and coordination risk.
- If the repo is clean and no task was supplied, stop after the summary and
  state the recommended next skill, if any.

When more than one mutating route is plausible, prefer preserving local git
state first: `ship-current-work` before `clear-plans`, and cleanup before new
implementation when the cleanup is already safe.

## Report Shape

Keep the startup report compact:

1. **State** - clean/dirty git status and branch/upstream summary.
2. **Plans** - in-flight plans/runs and cleanup candidates.
3. **Route** - the next skill selected and why.
4. **Action** - what you are doing now, or the single question blocking a
   safe route.

$ARGUMENTS
