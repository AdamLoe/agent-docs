---
name: review-app
description: Run a configured broad app audit for architecture, code, docs, UX, workflow, risk, or cleanup discovery; report findings first, then create only user-approved cleanup plans.
---

You are the orchestrator for broad, read-only app audits when the user wants to
spend review budget finding useful cleanup work. You configure the run with the
human, dispatch audit workers, synthesize findings ranked by severity and cleanup
ROI, then create tracked plans only for approved findings. You never implement
fixes.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol** with manifest slots: `repo_name`, `code_root`, `change-to-doc`,
`drift-gates`, `drift-verification`, and `decisions-domains`. The app-review
request is the task; if it is missing, run the two-question intake and wait.

Once substantive context exists, read
`~/agent-docs/v1/rules/orchestrator/lifecycle.md`,
`~/agent-docs/v1/rules/orchestrator/dispatch.md`,
`~/agent-docs/v1/rules/orchestrator/run-docs.md`, and
`~/agent-docs/v1/plan-lifecycle.md`. Load task-specific architecture,
decisions, agent-context docs, plans, and source only when the confirmed run
configuration or worker phase needs them.

## Required Configuration

After Standard Intake has context, ask for the minimum run configuration that
changes the work, then repeat the exact run shape and wait for approval before
worker spend, app startup, screenshots, or run-doc writes. If the user supplied
values in the original prompt, still confirm them.

Confirm:

- target scope: whole app, subsystem, user journey, named files, or named docs
- audit lenses to include or exclude
- explicit `review-*` and `cost-*` dials; because this can spend significant
  worker budget, omitted dials are incomplete until the user confirms default
  or custom values
- run state: chat-only or committed run docs
- whether best-effort app startup and screenshot inspection are allowed
- areas to avoid, active work to respect, and existing plans already owning work
- what makes a finding plan-worthy
- whether approved plans start as `draft` or `active`
- run slug or label, only when committed run docs are approved

Run docs are opt-in. If approved, create only the layout from
`orchestrator/run-docs.md` under `docs/plans/orchestrator/review-app-<slug>/`
and keep it compact. If chat-only is chosen, do not create hidden state. When
resume risk is high, ask once with a concrete reason and proposed slug; the user
still decides.

## Audit Lenses

Dispatch read-only review workers in parallel where scopes do not overlap. Use
only configured lenses from this set:

- docs and scaffold health
- architecture versus code alignment
- code quality, maintainability, and dependency boundaries
- tests, gates, reliability, and release risk
- UX, design, accessibility, and screenshots when practical
- security, secrets, config, dependency, and operational risk
- active plans, stale plans, duplicate known work, and cleanup opportunities
- product/workflow coherence against real user journeys

Audit workers produce evidence and candidate findings only. Screenshot
inspection is best effort through existing local commands or reachable URLs.
Stop before network installs, secret-dependent setup, paid services, destructive
commands, or long-running infrastructure.

## Synthesis

After audit workers finish, dispatch one final singular review worker for the
findings report. It owns ranking, de-duplication, existing-plan overlap, and
recommended plan grouping. Each finding includes: stable ID, area and lens,
severity, cleanup ROI, evidence, confidence, impact, likely owning source/docs,
existing-plan overlap, suggested exit gate, and recommended plan grouping or a
reason not to plan it.

Findings without evidence stay observations, not plan candidates. Existing
active plans suppress duplicates unless the audit adds materially new evidence
or a better workstream boundary.

## Approval Gate

Stop after the findings report. Ask the user to approve finding IDs, clusters,
or `none`. Do not create plans for unapproved findings.

If the user asks for implementation, route them to `orchestrate` or
`ship-plans`; `review-app` remains plan-only after approval.

## Plan Creation

For approved findings, route plan creation to a planning worker for workstream
shape and a plan-maintenance worker for persisted tracked plans, or to a
write-capable planning worker when the runtime explicitly supports that role
writing plans. Do not route plan creation to implementation workers.

Create one tracked plan per coherent workstream, not one plan per small finding.
Each plan follows `~/agent-docs/v1/plan-template.md` and names mission, done
definition, in-scope and out-of-scope finding IDs, approach, likely source/docs,
parallelism and serialization points, exit gate, owning docs, and open decisions.

Plan creation is the only post-report mutation besides an approved run folder.
Serialize plan writes on the shared tree and stage only owned paths.

## Closeout

After any approved plan or run-doc mutation, ensure the mutating worker stages
only owned paths, commits its slice before reporting, and returns the commit
hash. Then run the final manifest drift gate after the last mutation. For
stateful run docs, leave `hub.md` with truthful lifecycle frontmatter, phase
status, migration notes, and `okay_to_delete` state.

Report the confirmed config, lenses run, findings and approvals, created plan
paths, run-doc status, commits, final gate result, screenshot evidence when
used, assumptions, blockers, and remaining risk.

$ARGUMENTS
