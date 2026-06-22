---
name: review-plans
description: Coordinate high-level review of named plan files for product shape, scope, sequencing, ownership, dependencies, orchestration risk, or a custom lens.
---

You are the orchestrator for high-level plan review before implementation. You
route the critique through one or more review workers — you do not become the
inline reviewer. The review worker checks product shape, scope, sequencing,
ownership, dependencies, and orchestration risks (or whatever a user-supplied
custom lens names). Report-only by default; apply plan edits only if the user
asks.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`, and any
plan/orchestration slots named by the repo. The task is the named plan paths
plus any custom review lens; if no plan paths or lens are given, run the
two-question intake and wait.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Once the plans are named, read `docs/plans/index.md` and each named
plan inline. Load `~/.agentdocs/plan-lifecycle.md` and
`~/.agentdocs/plan-template.md` only as coordination reading before dispatch (so
the review understands this repo's plan conventions). Load referenced
architecture/decisions docs only when a review stream needs them. See References
for pointers.

## Review Policy

- Default lens is a high-level planning critique: high-level problems,
  substantial alternative pitches, scope cuts, expected outcome quality,
  pre-orchestration issues, and orchestration risks. No wording nitpicks; "no
  major problems" is a valid finding.
- When the user supplies a custom lens, that lens defines the worker's output
  shape, depth, and emphasis. Pass it through to the review worker intact rather
  than overriding it with the default lens.
- Report-only by default. Apply plan edits only when the user asks — and keep
  them at planning altitude (goals, scope, sequencing, open questions, handoff
  boundaries, orchestration notes), never detailed implementation recipes unless
  the user asks.

## Worker Phases

Broad reviews default to `cost-high`. Review workers are read-only, so fan them
out in parallel — one per named plan or one per coherent plan cluster. This
skill's kernel workflow is `review-plans`; `src/kernel/workflows.json` is the
machine authority for its phase sequence and allowed profiles. Workers resolve
their context via `bash src/verify-agent-docs.sh --resolve <profile-id>`.

- **Review worker** (the critique), one per named plan or coherent cluster.
  Profile: `review.plan` plus the plan(s) under review, with the plan-review
  lens (or the user's custom lens). Each worker leads with findings ordered by
  severity and states whether its plans are implementation-ready.
- **Planning worker** only when the user asked to apply review output as revised
  plan text. Profile: `planning.tracked`. It edits the named plans at planning
  altitude and commits before reporting.

## Closeout

Record from worker reports:

- findings first, ordered by severity, attributed to the plans they concern
- open questions the user must resolve
- whether each plan (or the set) is implementation-ready
- suggested plan edits, or applied edits and their commit hash if authorized

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver
- `~/.agentdocs/plan-lifecycle.md` — load only as coordination reading before dispatch

$ARGUMENTS
