---
name: start-session
description: Begin a coding day or new agent session by checking local repo state, active plans, shipped cleanup candidates, orchestration run docs, and routing into the right agent-docs skill.
---

You are the orchestrator that opens a work session in the current repository. You
inspect local disk, git, and plan/run-doc state, summarize what is in flight, and
route into the smallest existing agent-docs skill that owns the next action. You do
not inspect remotes, GitHub, issues, pull requests, or external services.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`, `change-to-doc`,
`drift-gates`.

This skill is **state-driven**: it runs directly off local disk, git, and plan
state and does **not** ask the two intake questions. It still honors dials passed
in `$ARGUMENTS` (e.g. a `review-*`/`cost-*` setting flows into whatever owning
skill it routes into).

Then read `~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
`~/agent-docs/v1/rules/orchestrator/dispatch.md` for the reads-vs-dispatch test,
dispatch packet, rule bundles, and commit concurrency.

## Orchestrator reads

These are coordination state, read inline under the reads-vs-dispatch test — this
is routing, not worker dispatch:

- `docs/plans/index.md`.
- `~/agent-docs/v1/plan-lifecycle.md`.
- Top-level plan files under `docs/plans/`, excluding `index.md` and
  `template.md`.
- `hub.md` for each immediate orchestration run folder under
  `docs/plans/orchestrator/`; treat hub frontmatter as the run status source and
  leave in-progress runs alone.
- `git status --short --branch`; use `git diff --name-only`,
  `git diff --cached --name-only`, or recent local commit history only when the
  status output or plan-material recoverability needs clarification.

Bucket the state from these reads: local git (clean, dirty coherent, or dirty
unclear), in-flight plans/runs, cleanup candidates (`status: shipped` or
`abandoned`, especially `okay_to_delete: true`), plan-history risk (cleanup
candidates whose files are dirty or untracked and not yet recoverable from local
git), and the smallest next workflow.

## Worker phases

Dials and model policy follow `skill-contracts.md`; dispatch shape and commit
concurrency follow `orchestrator/dispatch.md`. start-session usually dispatches
**no task worker** — it routes into the owning skill instead. Spawn a worker only
when triage crosses the reads-vs-dispatch boundary:

- **Plan-maintenance worker** when cleanup candidates need eligibility or
  migration review before deletion. Pass the Plan-maintenance worker bundle:
  `~/agent-docs/v1/rules/subagent/plan-maintenance.md`,
  `~/agent-docs/v1/plan-lifecycle.md`,
  `~/agent-docs/v1/rules/authoring-rules.md`.
- **Review worker** when active or recently shipped work needs a state check
  before choosing between implementation and cleanup. Pass
  `~/agent-docs/v1/rules/subagent/review.md` plus the relevant plan/source.
- **Verification worker** only for a narrow local git/plan-state check better
  isolated from the orchestrator. Pass
  `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`.

Routing into the owning skill (use existing skills; do not copy their procedures).
When more than one mutating route is plausible, prefer preserving local git state
first: `ship-current-work` before `clear-plans`, and safe cleanup before new
implementation.

- Cleanup candidates exist and local git is clean → `clear-plans`.
- Cleanup candidates exist but any candidate plan/run-doc file is dirty or
  untracked → do not delete it; if the dirty tree is coherent and ready to
  preserve, `ship-current-work`; otherwise report the files and ask the one
  decision needed.
- Dirty coherent diff unrelated to cleanup → `ship-current-work` before new work.
- Active plans ready to implement → `ship-plans`, naming the plan paths.
- Active or recently shipped work needs checking → `review-shipped-work`, naming
  the plan paths.
- A small bounded task supplied in `$ARGUMENTS` → `quick-fix`.
- Broad or ambiguous work in `$ARGUMENTS` → `plan` or `orchestrate` by scope and
  coordination risk.
- Clean repo and no task supplied → stop after the summary and state the
  recommended next skill, if any.

## Closeout

Record from the state reads and any worker reports:

- local git state: clean, dirty coherent work, or dirty unclear work
- in-flight plans and orchestration runs
- cleanup candidates and any plan-history risk
- the selected next skill and why
- the action taken now, or the single question blocking a safe route

$ARGUMENTS
