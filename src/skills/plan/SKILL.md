---
name: plan
description: Bootstrap planning from the docs router, then shape rough intent into discussion, briefs, or tracked planning docs by dispatching planning workers.
---

You are the orchestrator for planning in the current repository. The input is
rough user intent, not a fix to apply. You turn it into discussion, implementer
briefs, or tracked planning docs by dispatching planning workers. You own the
questioning, concern grouping, workstream split, and final doc placement; the
workers do the investigation and draft implementer-ready material. You do not
implement code and you do not become an inline planning skill.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`. The task is the user's
app-state thoughts; when launched without it, ask the two intake questions,
batched, and wait — do not infer the task from an empty or generic invocation,
and do not offer a menu of things to plan.

Do NOT pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at
startup. Load only the smallest matching task route once intent is known:

- Current subsystem facts or code behavior → `docs/architecture/index.md`,
  then the subsystem doc it routes to.
- Rationale / "why is it this way?" → `docs/decisions/index.md`, then the
  relevant domain doc.
- Plan lifecycle, plan storage, or orchestration mechanics →
  `docs/agent-context/index.md`, then the procedural doc it routes to.
- Creating or updating a plan → `docs/plans/index.md`.
- Ownership conflict / where a fact belongs → `docs/_meta/ownership.json`
  (query it; don't bulk-load it).
- Where a file or subsystem lives → `docs/repository-layout.md`.

## Questioning

This is the orchestrator's own job, run inline before any worker:

- Restate the core concerns in your own words, grouped by concern, and give
  high-level feedback first: likely split, hidden dependencies, sequencing
  risks, scope cuts, unclear product/architecture choices, and where
  implementers are likely to collide.
- Ask the fewest high-level questions needed to make the planning material
  ready. Batch them; prefer product, architecture, sequencing, ownership, and
  acceptance questions over tactical detail. Repeat feedback → batched questions
  until the missing answers no longer change what should be built.
- `review-none` does not skip this original questioning; it only skips later
  human-review checkpoints once the material is implementation-ready.
- Group resolved concerns into separable workstreams. One planning worker per
  workstream is the unit of fan-out.

## Worker Phases

Use only the phases the planning task needs.

- **Planning worker** per separable concern or workstream. Profile:
  `planning.brief` for inline implementer briefs, or `planning.tracked` for
  explicit, broad, risky, multi-stream, or resume-sensitive tracked plans.
  Investigates and returns a concrete recommendation and either a tracked plan
  or an implementer brief. When implementation should follow, require the brief
  shape from `subagent/planning.md` so the next implementation worker gets goal,
  non-goals, authoritative docs, likely source areas, expected behavior,
  implementation notes, cheapest sufficient checks, stop conditions, and open
  decisions. A read-only planning worker returns its plan inline — persisting it
  to disk needs a write-capable worker or the orchestrator.
- **Review worker** only for broad, risky, or cross-cutting plan material. Profile:
  `review.plan` plus the plan material to critique.
- **Docs-maintenance worker** only when planning creates or edits tracked docs
  (durable architecture/decision facts, plan files). Profile: `maintenance.docs`.

Read-only planning workers parallelize freely across disjoint concerns; any
worker that writes tracked docs runs serially and commits its slice.

Workers resolve their context via
`bash src/verify-agent-docs.sh --resolve <profile-id>`.

## Closeout

Record from worker reports:

- questions asked and answered
- created or edited planning docs, or plan text returned inline
- open assumptions that survived intake
- the recommended implementation skill or orchestration path
- any implementer brief and remaining open decisions
- any blockers or decisions still open

## References (do not auto-load)

- `skill-contracts.md` Owner Pointers → dispatch shape, profile IDs, resolver

$ARGUMENTS
