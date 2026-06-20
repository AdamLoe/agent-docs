---
status:        shipped
owner:         unassigned
last_updated:  2026-06-20
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Review app skill

## Mission

Create a `review-app` skill that runs an explicitly configured, optionally
stateful, broad review of an app when the user wants to spend surplus review
budget on finding useful cleanup work. The skill reports findings first, ranked
by both severity and cleanup return on investment. It creates tracked plans only
after the user approves specific findings or workstream clusters. It never
implements fixes.

Done means the source skill exists under `v1/skills/review-app/`, the registry
and command docs surface it, copied adapter skills are refreshed, and the kit
verification gates pass.

## Settled decisions

- Skill name: `review-app`.
- Intake order: run the exact Standard Intake Protocol first. Once substantive
  review-app context exists, collect and confirm the review-app run
  configuration.
- Defaults and options: shared dial defaults may exist, and the skill may
  recommend options, but the final options must be confirmed before worker spend
  or run-doc writes.
- Run docs: the user decides at startup whether the run is chat-only or
  stateful. Create `docs/plans/orchestrator/review-app-<slug>/` only when the
  user opts into committed run docs.
- Screenshots: the skill may inspect screenshots on a best-effort basis when
  the app appears to support local startup or an available URL.
- Findings report: rank by both severity and cleanup ROI.
- Phase owners: audit review workers produce evidence; one final singular
  synthesis review worker owns the findings report; approved plan creation is
  routed to planning or plan-maintenance, not implementation.
- Post-report mutation: create plans only. Do not implement fixes from this
  skill.

## Scope

In scope:

- Add `v1/skills/review-app/SKILL.md`.
- Add a `review-app` row to `v1/skills/registry.md`.
- Update command-surface docs that list workflow skills, especially
  `docs/architecture/workflow-kit.md`.
- Include explicit intake and confirmation rules so the skill has no
  unconfirmed audit options.
- Include explicit run-doc consent and chat-only versus stateful behavior.
- Define the read-only audit lenses and worker phases.
- Define the findings report shape and approval gate.
- Define the plan-creation phase and owner boundary for approved findings or
  clusters.
- Define the intended `v1/skills/registry.md` row shape.
- Refresh copied adapter skills and run the kit verifier.

Out of scope:

- Running an actual app audit as part of building the skill.
- Implementing any findings that a future `review-app` run discovers.
- Changing the generic worker-role rules unless the implementation uncovers a
  true shared-rule gap.
- Creating a personal-only Codex skill outside the `agent-docs` kit.

## Approach

### 1. Skill contract

Write `v1/skills/review-app/SKILL.md` as an orchestrator skill. Its frontmatter
description should trigger on requests for broad app reviews, surplus-budget
audits, cleanup discovery, architecture/design/code/doc reviews, and
findings-before-plans workflows.

The skill should run the exact Standard Intake Protocol before its own staged
configuration. It reads manifest slots that support this breadth: `repo_name`,
`code_root`, `change-to-doc`, `drift-gates`, and `decisions-domains`. Its
registry intake should be `asks`.

If context is absent, the skill asks the Standard Intake two-question batch and
waits. The user's answer becomes the substantive task context. If context is
already present, the skill treats the prompt as the first answer and parses any
dials from it. Only after that Standard Intake step does `review-app` collect
and confirm its run configuration.

### 2. Mandatory run configuration

After Standard Intake has produced substantive context, and before dispatching
audit workers, attempting app startup, inspecting screenshots, or creating run
docs, the skill asks for the minimum configuration that changes the work:

- target scope: whole app, selected subsystem, selected user journey, or named
  files/docs.
- audit lenses to include or exclude.
- budget and fan-out dials. Shared defaults such as `review-medium` and
  `cost-medium` may be preselected or recommended, but they still need user
  confirmation.
- run state: chat-only coordination with no committed run folder, or stateful
  coordination with committed run docs.
- whether best-effort app startup and screenshot inspection are allowed.
- any known areas to avoid, active work to respect, or existing plans to treat
  as already-owned.
- what makes a finding plan-worthy.
- whether approved plans should start as `draft` or `active`.
- run slug or human-readable run label, required only for stateful run docs.

Then the skill repeats the exact run shape back to the user and waits for
approval. If the user supplied these values in the original prompt, the skill
still confirms them before worker spend, app interaction, or run-doc writes.

### 3. Run documentation choice

If the user approves stateful run docs, create:

```text
docs/plans/orchestrator/review-app-<slug>/
  hub.md
  streams/
  findings/
```

The hub tracks the confirmed config, phase status, worker streams, decisions,
open questions, blockers, findings summary, approval status, plan paths, and
verification evidence. Stream and findings files stay compact and disposable
per `v1/rules/orchestrator/run-docs.md`.

If the user chooses chat-only coordination, do not create a hidden state area.
Keep the coordination surface in chat and worker reports, accepting the lower
resumability. When resume risk is high and the user has not chosen stateful
mode, ask once with a concrete reason and proposed slug; the user still decides.

### 4. Audit worker phases

Run read-only audit review workers in parallel where their scopes do not
overlap. These workers produce evidence and candidate findings; they do not own
the final synthesis report and they do not create plans. The skill should choose
only the configured lenses, but the available lens set is:

- docs and scaffold health.
- architecture versus code alignment.
- code quality, maintainability, and dependency boundaries.
- tests, gates, reliability, and release risk.
- UX, design, accessibility, and screenshots when practical.
- security, secrets, config, dependency, and operational risk.
- active plans, stale plans, duplicated known work, and cleanup opportunities.
- product/workflow coherence against real user journeys.

Workers report findings with evidence. Screenshot inspection is best effort:
use existing local commands or reachable URLs when available, but stop before
network installs, secret-dependent setup, paid services, destructive commands,
or long-running infrastructure.

### 5. Findings synthesis

After the audit workers finish, dispatch one final singular synthesis review
worker to create one findings report before any plan creation. The synthesis
worker owns ranking, de-duplication, existing-plan overlap, and plan-grouping
recommendations. Each finding should include:

- stable ID.
- area and lens.
- severity.
- cleanup ROI.
- concrete evidence.
- confidence.
- user or maintainer impact.
- likely owning docs or source areas.
- overlap with existing plans.
- suggested exit gate.
- recommended plan grouping, or a reason not to plan it.

Findings without evidence stay as observations, not plan candidates. Existing
active plans suppress duplicate findings unless the audit adds materially new
evidence or a better workstream boundary.

### 6. Approval gate

Stop after the findings report. Ask the user to approve finding IDs, clusters,
or "none". Do not create plans for unapproved findings.

If the user asks for implementation instead of plans, route them to
`orchestrate` or `ship-plans`; `review-app` itself remains plan-only after
approval.

### 7. Plan creation

For approved findings, route plan creation to a planning worker for workstream
shape and a plan-maintenance worker for persisted tracked plans, or to a
write-capable planning worker when the runtime explicitly supports that role
writing plans. Do not route this phase to implementation workers.

Create one tracked plan per coherent workstream rather than one plan per small
finding. Each plan follows `v1/plan-template.md` and includes:

- mission and done definition.
- in-scope and out-of-scope findings by ID.
- implementation approach and likely file/doc areas.
- expected parallelism and serialization points.
- exit gate.
- owning docs for migration.
- residual open decisions.

Plan creation is the only post-report mutation besides maintaining an
opted-in run folder. If multiple plans are created, serialize writes on the
shared tree and stage only owned paths.

### 8. Registry, docs, and adapter refresh

Add `review-app` to `v1/skills/registry.md` with an action that reflects its
two-phase nature: broad review first, approved plan creation second. It may
mutate the repo through opted-in run docs and approved plans, but it must never
implement code fixes.

Intended row shape:

```markdown
| `review-app` | review with approved planning | run a configured app audit, report findings, then create approved cleanup plans | review, planning, plan-maintenance, verification | yes, via plan-maintenance worker for opted-in run docs and approved plans | asks | strong | app scope, lenses, run-doc choice, plan approval |
```

Update `docs/architecture/workflow-kit.md` so the command list and routing table
mention `review-app` as the broad app audit and cleanup-discovery entry point.
Update additional docs only if implementation reveals a routed owner from
`docs/_meta/manifest.md`.

After source edits, refresh copied skills and check freshness:

```sh
bash v1/copy-skills.sh ~/agent-docs
bash v1/copy-skills.sh --check ~/agent-docs
```

Then run the kit drift gate:

```sh
bash v1/verify-agent-docs.sh
```

Adapter refresh may require approval in sandboxed runtimes because it writes to
user skill directories outside the repo.

## Exit gate

- `v1/skills/review-app/SKILL.md` exists and follows the shared skill contract.
- `v1/skills/registry.md` has a coherent `review-app` row using the intended
  mode/action/owner shape above.
- `docs/architecture/workflow-kit.md` routes users to `review-app`.
- `bash v1/copy-skills.sh --check ~/agent-docs` passes after adapter refresh.
- `bash v1/verify-agent-docs.sh` passes.

## Discipline rules

- Do not infer unconfirmed audit options for `review-app`; shared defaults may
  be offered only as options and must be confirmed.
- Do not create run docs unless the user opts into stateful coordination.
- Do not implement audit findings from this skill.
- Do not create plans until the user approves findings or clusters.
- Do not route approved plan creation to implementation workers.
- Do not treat screenshot review as mandatory; it is best effort when the app
  supports it safely.
- Preserve unrelated dirty work in `docs/plans/` and elsewhere.

## Migration notes (filled in at ship time)

- `docs/architecture/workflow-kit.md` carries the durable command-surface facts:
  `/review-app` is the broad app audit and cleanup-discovery entry point; it
  runs a confirmed read-only audit, ranks findings by severity and cleanup ROI,
  and creates only user-approved plans. Its command-routing table maps broad
  cleanup discovery through a configured app audit to `/review-app`.
- `docs/decisions/agent-docs.md` did not need a new entry. Implementation added
  no durable rationale beyond this plan's settled decisions; the existing
  workflow decisions already cover subagent-first orchestration, opt-in run
  docs, final-state shipping, and plan cleanup.
- Implementation shipped in commit `da2a36d` with `v1/skills/review-app/`,
  the `v1/skills/registry.md` row, the workflow command-surface update, and
  verifier support. A read-only review found no findings, so the plan is
  disposable after this closeout commit.

## See also

- `v1/skills/registry.md`
- `v1/rules/skill-contracts.md`
- `v1/rules/orchestrator/lifecycle.md`
- `v1/rules/orchestrator/dispatch.md`
- `v1/rules/orchestrator/run-docs.md`
- `v1/plan-lifecycle.md`
- `v1/plan-template.md`
