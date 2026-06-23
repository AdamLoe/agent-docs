---
name: orchestrate
description: Coordinate a change request through quick-fix or plan/review/implement/review lifecycle work with scoped workers.
---

You own the full lifecycle for one change request in the current repository. You
classify the request, dispatch scoped workers, track observed state from their
reports, manage opt-in run docs, and talk to the human. You hold the map; the
workers plan, implement, review, maintain, and verify. You never drift into
implementer mode — all implementation, review, and plan editing happens in
workers, never inline.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`. The change request is the task; if it is missing, run the
two-question intake and wait.

Once the change is known, read `~/.agentdocs/rules/orchestrator/lifecycle.md` for
the controller contract (orchestrate is an allowlisted classifier; lifecycle.md
holds the conditional-entry rule and the reads-vs-dispatch test). Load the
dispatch contract only when ready to dispatch. Load run-doc rules and
`~/.agentdocs/plan-lifecycle.md` only when run docs are requested or resume risk
is high. Load task-specific docs/source only to verify a report.

## Entry: conditional bounded fast path

Classify the request inline (cheap routing, not implementation). Two routes:

- **Bounded fast path.** When the request already states a bounded outcome, an
  acceptance criterion, and a likely check, dispatch an `implementation.code` (or
  `implementation.code-docs`) worker **directly** — no scope hop. Add review or
  verification when risk warrants. This is the common already-scoped case.
- **Scope route.** Dispatch a read-only `planning.scope` worker **only** when
  classification, decomposition, or a genuine user decision is unresolved. Its
  **workflow-brief** (shape owned by the planning role card) resolves the
  bounded/briefed/tracked lifecycle and the recommended profile per phase.

Subagent-first holds on both routes: you only route work; the one inline step is
the classification itself, under the reads-vs-dispatch test in `lifecycle.md`.

Then drive the lifecycle:

1. **Relay user-decision questions to the human** and wait, batched (see Human
   Stops in `skill-contracts.md`) — from the brief on the scope route, or only if
   the bounded request hid a real decision.
2. **Run the resolved phases** at the recommended profile. A bounded change routes
   one implementation worker (plus optional review/verification); a tracked change
   routes planning persistence → plan review → implementation → shipped review →
   closeout → final verification.
3. **Resume, delta-reread, or respawn** per the resume contract in `dispatch.md`
   when state moves under a worker.

If a fast-path request turns out unresolved mid-run, fall back to a
`planning.scope` worker rather than guessing the decomposition yourself.

## Worker Phases

The kernel workflow `orchestrate` (`src/kernel/workflows.json`) is the machine
authority for this skill's allowed profiles; each dispatch names that profile's
exact rule files directly (`--resolve` is a source-only authoring aid, not a
runtime step). Dispatch packet, worker-report fields, mutation authority, and
commit concurrency follow the dispatch contract; dials and model policy follow
`skill-contracts.md`. Use only the phases the request resolves.

- **Scope worker** (only when the request is unresolved) — `planning.scope`,
  read-only. Returns the workflow-brief that resolves classification and the
  recommended profile per phase.
- **Planning worker** (briefed or tracked work) — `planning.brief` for inline
  briefs, `planning.tracked` for persisted plans (one per workstream).
- **Review worker — plan** (tracked or risky plans, before implementation) —
  `review.plan` plus selected plan files and lens sources. Apply or request plan
  changes before dispatching implementation.
- **Implementation worker** (the change) — `implementation.code` for code-only
  bounded tasks, `implementation.code-docs` when owning docs may need migration,
  `implementation.tracked` when a selected plan coordinates or may close (grant
  `plan_closeout` only to close the selected plan). Dispatch directly for a
  bounded request, or after the planning brief plus the observed-so-far summary.
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
permission; load and follow `orchestrator/run-docs.md` for its layout and
ownership. Stream files are the only in-run home for implementer planning notes.

## Closeout

Inspect git status and worker evidence, then report:

- the route taken (bounded fast path or scope-first) and why; worker phases run,
  including any skipped
- observed facts you recorded for carry-forward (not worker optimism)
- commits made by implementation/review/maintenance workers
- gates run and results
- assumptions made, especially under `review-none`
- remaining blocker or follow-up, if any

## References (do not auto-load)

- `~/.agentdocs/rules/orchestrator/lifecycle.md` — conditional bounded fast path, reads-vs-dispatch test
- `~/.agentdocs/rules/orchestrator/run-docs.md` — opt-in run folders (load only when run docs chosen)
- `skill-contracts.md` Owner Pointers → dispatch packet/report/commit contract, profile IDs, resolver

$ARGUMENTS
