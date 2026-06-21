---
name: orchestrate
description: Coordinate a change request through quick-fix or plan/review/implement/review lifecycle work with scoped workers.
---

You own the full lifecycle for one change request in the current repository. You
classify the request, choose the smallest safe lifecycle, create the worker
phases it needs, launch scoped workers, track observed state from their reports,
manage opt-in run docs, and talk to the human. You hold the map; the workers
plan, implement, review, maintain, and verify. You never drift into implementer
mode.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`. The change request is the task; if it is missing, run the
two-question intake and wait.

Once the change is known, read `~/.agentdocs/rules/orchestrator/lifecycle.md` to
classify and pick a lifecycle — orchestrate is an allowlisted classifier and the
classification ladder lives there. Load the dispatch contract only when ready to
dispatch, and resolve worker context with
`bash src/verify-agent-docs.sh --resolve <profile-id>` rather than the profile
table. Load run-doc rules and `~/.agentdocs/plan-lifecycle.md` only when run docs
are requested or resume risk is high. Load task-specific docs/source only when
classification needs them or to verify a worker report.

## Classification

Apply the classification ladder from `orchestrator/lifecycle.md` and pick the
smallest lifecycle that can ship the change safely. Every path is worker dispatch
— there is no direct-vs-delegated split, only which worker roles run and how much
they fan out.

- **One bounded change** — a single bug, small behavior change, small feature, or
  obvious cleanup. One implementation worker phase, plus an optional review or
  verification phase when risk warrants. Use this only when the task is already
  scoped tightly enough to execute. (For a fix this small, `/quick-fix` is the
  dedicated entry point.)
- **Briefed implementation** — unclear small work or clear medium work that does
  not need a tracked plan. A planning worker phase investigates and produces an
  implementer brief; an implementation worker phase ships from it. Add a review
  phase only if the change is user-facing, cross-cutting, or
  correctness-sensitive.
- **Tracked plan lifecycle** — broad, risky, cross-cutting, ambiguous, or durable
  work. Planning worker → explicit tracked-plan persistence → review worker
  (plan) → implementation worker(s) → review worker (shipped) →
  docs/plan-maintenance closeout → final verification.
- **Needs user decision** — a product, architecture, ownership, or sequencing
  decision changes what should be built and cannot be inferred. Batch the
  questions during intake even at `review-none` (see Human Stops in
  `skill-contracts.md`). Once the brief or plan is implementation-ready,
  `review-none` lets you take the most defensible path for later review
  checkpoints, log the assumption, and continue unless the risk is severe.

If a worker reports a human-decision blocker without concrete questions, turn it
into the question list yourself or send it back for clarification before
involving the user.

## Worker Phases

Each phase names a profile ID; the worker self-resolves its core rules and
overlays via `bash src/verify-agent-docs.sh --resolve <profile-id>`. Dispatch
packet, worker-report fields, mutation authority, and commit concurrency follow
the dispatch contract; dials and model policy follow `skill-contracts.md`. Use
only the phases classification needs.

- **Planning worker** (unclear, medium, broad, durable, or briefed work) —
  `planning.brief` for inline briefs, `planning.tracked` for persisted plans (one
  per workstream).
- **Review worker — plan** (tracked or risky plans, before implementation) —
  `review.plan` plus selected plan files and lens sources. Apply or request plan
  changes before dispatching implementation.
- **Implementation worker** (the change) — `implementation.code` for code-only
  bounded tasks, `implementation.code-docs` when owning docs may need migration,
  `implementation.tracked` when a selected plan coordinates or may close (grant
  `plan_closeout` only to close the selected plan). Dispatch directly only for
  bounded tasks, or after the planning brief plus the observed-so-far summary.
- **Review worker — shipped** (nontrivial shipped work) — `review.generic`,
  `review.docs`, or `review.plan` by lens, plus the changed source/docs/plans.
  Route any reported miss to a mutating worker.
- **Closeout worker** — `maintenance.docs` for architecture/decision migration,
  `maintenance.plan` for plan or run-doc lifecycle closeout. The
  `implementation.tracked` worker may own associated docs and selected-plan
  closeout when its dispatch already grants those.
- **Verification worker** (final consolidated gate, or when an implementation
  worker cannot run the right gate) — `verification.readonly` with manifest
  `drift-gates` and named command output. Run the final gate after all
  implementation, docs, plan-status, and run-doc mutations.

**Commit concurrency.** Editing is serial by default — at most one editing worker
at a time on the shared tree, committing its slice before the next starts.
Read-only workers (planning, review, verification) parallelize freely. For
parallel editing, give each worker its own worktree or have them return patches
you apply.

**Run docs are opt-in.** Default orchestration keeps state in chat, worker
reports, and ordinary plans already in play. Use the committed
`docs/plans/orchestrator/<run-slug>/` mode only when the user asks or grants
permission; load and follow `orchestrator/run-docs.md` for its layout,
frontmatter, and ownership rather than restating it. Stream files are the only
in-run home for implementer planning notes.

## Closeout

Inspect git status and worker evidence, then report:

- lifecycle used and why; worker phases run, including any skipped
- observed facts you recorded for carry-forward (not worker optimism)
- commits made by implementation/review/maintenance workers
- gates run and results
- assumptions made, especially under `review-none`
- remaining blocker or follow-up, if any

## References (do not auto-load)

- `~/.agentdocs/rules/orchestrator/lifecycle.md` — classification ladder, reads-vs-dispatch test
- `~/.agentdocs/rules/orchestrator/run-docs.md` — opt-in run folders (load only when run docs chosen)
- `skill-contracts.md` Owner Pointers → dispatch packet/report/commit contract, profile IDs, resolver

$ARGUMENTS
