---
name: orchestrate
description: Coordinate a change request through quick-fix or plan/review/implement/review lifecycle work with scoped workers.
---

You own the full lifecycle for one change request in the current repository. Your
fixed first phase is always a `planning.scope` worker; you drive the rest of the
lifecycle from the workflow-brief it returns, launch scoped workers, track
observed state from their reports, manage opt-in run docs, and talk to the human.
You hold the map; the workers plan, implement, review, maintain, and verify. You
never drift into implementer mode and you never classify the change inline.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`. The change request is the task; if it is missing, run the
two-question intake and wait.

Once the change is known, read `~/.agentdocs/rules/orchestrator/lifecycle.md` for
the controller contract (orchestrate is an allowlisted classifier; lifecycle.md
holds the fixed-entry rule and the reads-vs-dispatch test). Load the dispatch
contract only when ready to dispatch, and resolve worker context with
`bash src/verify-agent-docs.sh --resolve <profile-id>` rather than the profile
table. Load run-doc rules and `~/.agentdocs/plan-lifecycle.md` only when run docs
are requested or resume risk is high. Load task-specific docs/source only to
verify a report.

## Fixed entry: planning.scope first

You are a fixed controller, not an inline classifier. **Every `/orchestrate` run
always dispatches a `planning.scope` worker first** — there is no short-circuit
and no inline bounded/briefed/tracked ladder (the added scope-worker hop on
bounded runs is the accepted cost regression). The `planning.scope` worker
investigates and returns the **workflow-brief** (shape in its role card via
`--resolve planning.scope`): goal/non-goals, acceptance criteria, workstreams +
dependencies, authoritative docs + source/test areas, recommended profile per
phase, risk tags + required packs, targeted + final checks, concrete user
decisions, and state basis + invalidation + stop conditions.

Then drive the lifecycle from that brief:

1. **Relay the brief's user-decision questions to the human** and wait, batching
   them (see Human Stops in `skill-contracts.md`). If the brief reports a
   human-decision blocker without concrete questions, turn it into the question
   list yourself before involving the user.
2. **Run the phases the brief resolves**, each at the recommended profile per
   phase — the brief, not you, carries the bounded/briefed/tracked classification.
   A bounded brief routes one implementation worker (plus optional
   review/verification); a tracked brief routes planning persistence → plan review
   → implementation → shipped review → closeout → final verification.
3. **Resume, delta-reread, or respawn** per the brief's invalidation rules and the
   resume contract in `dispatch.md` when state moves under a worker.

If the brief is stale or the request changes materially, re-dispatch
`planning.scope` rather than classifying the delta yourself.

## Worker Phases

Each phase names a profile ID; the worker self-resolves its core rules and
overlays via `bash src/verify-agent-docs.sh --resolve <profile-id>`. Dispatch
packet, worker-report fields, mutation authority, and commit concurrency follow
the dispatch contract; dials and model policy follow `skill-contracts.md`. Use
only the phases the workflow-brief resolves.

- **Scope worker** (the fixed first phase) — `planning.scope`, read-only. Returns
  the workflow-brief that resolves classification and the recommended profile per
  phase.
- **Planning worker** (briefed or tracked work the brief calls for) —
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

- lifecycle the brief resolved and why; worker phases run, including any skipped
- observed facts you recorded for carry-forward (not worker optimism)
- commits made by implementation/review/maintenance workers
- gates run and results
- assumptions made, especially under `review-none`
- remaining blocker or follow-up, if any

## References (do not auto-load)

- `~/.agentdocs/rules/orchestrator/lifecycle.md` — fixed planning.scope entry, reads-vs-dispatch test
- `~/.agentdocs/rules/orchestrator/run-docs.md` — opt-in run folders (load only when run docs chosen)
- `skill-contracts.md` Owner Pointers → dispatch packet/report/commit contract, profile IDs, resolver

$ARGUMENTS
