---
status:        draft
owner:         unassigned
last_updated:  2026-06-18
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Workflow rule abstraction

## Mission

Make the workflow kit easier to evolve without making runtime agents navigate
a maze of process docs. Shared rules should live in canonical kit files, while
skills remain executable entry points with enough local context to run well.
Delegated agents should receive exact rule-file routes from the dispatcher
instead of copied rule prose or open-ended instructions to discover the
workflow system.

Done means the kit has a clear rule organization, skills consistently state
which rule files they instantiate, and delegation is represented as an
execution mode separate from cost/review intensity.

## Scope

In scope:

- Decide which workflow rules stay in `v1/rules/skill-contracts.md` and which
  move into domain or role-specific rule files.
- Introduce an explicit delegation execution mode, e.g. `delegate-on`,
  `delegate-off`, and skill default.
- Define defaults per skill family: direct skills, planning skills,
  implementation skills, orchestration skills, review skills, and cleanup
  skills.
- Define how dispatchers pass exact rule-file links to subagents.
- Slim duplicated policy from skill bodies while preserving executable
  skill-specific summaries.
- Update workflow architecture and decisions docs after the new shape is
  chosen.

Out of scope:

- Removing all procedure from skill bodies. Skills should still carry their
  purpose, routing, output shape, and skill-specific judgment.
- Creating separate command names for delegated vs inline execution.
- Making every normal agent read every workflow rule.
- Reworking app-specific manifest, ownership, drift-gate, or adapter behavior
  except where needed to document the new rule routes.

## Current Direction

Keep `v1/rules/skill-contracts.md` as the single universal contract for all
skills. It should own only the behavior every skill needs at runtime:
standard intake, human stops, verification fallback, review/cost dials, model
policy, modes, shared shipping shape, registry expectations, and the
delegation execution-mode vocabulary.

Use smaller rule files for workflow domains or roles that only some skills
need. Candidate split:

- `v1/rules/repo-rules.md` continues to own universal git and destructive
  command discipline.
- `v1/rules/authoring-rules.md` continues to own doc maintenance and
  architecture/decision writing rules.
- `v1/rules/orchestrating.md` owns behavior only for `delegate-on`
  orchestration: state tracking, subagent dispatch, result accounting,
  run-doc policy, and human communication.
- `v1/plan-lifecycle.md` owns plan metadata, state transitions, and the
  disposable-plan model.
- A new `v1/rules/plan-maintenance.md` may own cleanup operations now embedded
  in `clear-plans`, `review-plans-health`, and plan-shipping paths.
- A new `v1/rules/implementation-rules.md` may own shared implementer
  expectations currently repeated across `quick-fix`, `ship-plans`,
  `ship-current-work`, and `review-shipped-work`.
- A new `v1/rules/planning-rules.md` or `review-rules.md` should be added only
  if duplication is obvious after the first extraction.

## Delegation Mode

Delegation should be a boolean execution mode, not a cost tier.

Proposed vocabulary:

- `delegate-default` — use the skill's normal behavior.
- `delegate-on` — act as a dispatcher/orchestrator over subagents.
- `delegate-off` — act directly as the worker.

`cost-*` continues to tune spend inside the selected execution mode. For
example, `delegate-on cost-low` means use cheap or tightly scoped subagents,
not "avoid subagents." `delegate-off cost-high` means work inline with more
reasoning/review budget, not "spawn agents."

Initial defaults:

| Skill family | Delegation default |
|---|---|
| `quick-fix`, `ship-current-work`, `clear-plans`, `wrap-up-current-chat` | `delegate-off` |
| `plan` | `delegate-off` unless the planning surface is broad enough to need separate investigation or design streams |
| `ship-plans` | `delegate-on` for nontrivial or multi-stream plans; `delegate-off` for small single-stream plans |
| `orchestrate` | `delegate-on` |
| Broad review skills | `delegate-on` when the review naturally splits by area; otherwise `delegate-off` |
| Narrow report-only checks | `delegate-off` |

Explicit user wording wins when it is clear: "use subagents", "delegate",
"orchestrate this", or "do it through agents" selects `delegate-on`; "do it
yourself", "inline", or "no subagents" selects `delegate-off`.

## Subagent Rule Routing

Dispatchers should pass exact rule-file routes, not copied rule prose and not
open-ended discovery instructions. A subagent prompt should say which role it
is playing and exactly which files to read before acting.

Example implementer route:

```text
You are implementing this plan.

Read:
- ~/agent-docs/v1/rules/skill-contracts.md
- ~/agent-docs/v1/rules/implementation-rules.md
- ~/agent-docs/v1/rules/repo-rules.md
- ~/agent-docs/v1/rules/authoring-rules.md
- docs/_meta/manifest.md

Use the named plan as scope. Report touched files, checks run, docs updated,
commit made, and blockers.
```

The dispatcher should not usually decide exact file ownership fences. The
planning or implementation agent has better local context for likely files,
actual touched files, and detailed scope. The dispatcher tracks collision risk
at the stream or surface level and adds strict file fences only when parallel
agents are likely to compete for the same area.

## Workstreams

### 1. Rule Taxonomy

Outcome: a small, explicit rule map for universal, role-specific, domain, and
app-bound workflow facts.

Tasks:

- Audit current skill bodies for duplicated policy around shipping, plan
  cleanup, plan implementation, review, and orchestration.
- Decide which candidate new rule files are warranted now.
- Document the rule ownership model in `docs/architecture/workflow-kit.md`.

### 2. Delegation Contract

Outcome: delegation is a first-class execution mode in the shared contract.

Tasks:

- Add delegation vocabulary and defaults to `v1/rules/skill-contracts.md`.
- Clarify that `cost-*` and `review-*` tune behavior inside the chosen
  execution mode.
- Update skill bodies whose defaults differ from the shared default.
- Update `v1/skills/registry.md` if registry metadata should expose
  delegation defaults.

### 3. Rule Extraction Pilot

Outcome: one concrete extraction proves the abstraction improves clarity
without increasing runtime navigation cost.

Preferred pilot: plan maintenance.

Tasks:

- Move cleanup bucket policy from `v1/skills/clear-plans/SKILL.md` into a
  canonical rule file if the extraction reads better.
- Update `clear-plans`, `review-plans-health`, and any plan-shipping skills to
  reference the canonical cleanup/maintenance rule.
- Keep each skill's local procedure short and executable.

### 4. Skill Slimming Pass

Outcome: skills reference canonical rules consistently while retaining local
identity and output expectations.

Tasks:

- Replace duplicated rule prose with exact rule routes plus concise
  skill-specific summaries.
- Preserve the skill-specific classification logic in `plan`, `orchestrate`,
  `ship-plans`, and review skills.
- Ensure subagent-capable skills say whether they dispatch rule-file links to
  subagents or run inline.

### 5. Verification And Drift Guards

Outcome: the new structure has enough checks that rule drift does not quietly
return.

Tasks:

- Extend `v1/verify-agent-docs.sh` only where cheap static checks are useful:
  missing rule files, stale referenced paths, registry mismatches, or invalid
  delegation metadata.
- Avoid brittle prose linting unless a specific recurring failure appears.
- Run copied-skill freshness checks after skill edits.

## Exit Gate

- `v1/rules/skill-contracts.md` documents delegation mode separately from
  cost/review dials.
- Any new rule files are referenced by the skills that use them and by
  `docs/architecture/workflow-kit.md`.
- Skills still have executable local summaries and do not require agents to
  discover a rule graph.
- Subagent-dispatching skills pass exact rule-file routes in their dispatch
  shape.
- `bash v1/verify-agent-docs.sh` passes.
- If skills change, `bash v1/copy-skills.sh ~/agent-docs` and
  `bash v1/copy-skills.sh --check ~/agent-docs` pass or any manual adapter
  limitation is reported.

## Discipline Rules

- Optimize canonical rule files for skill authors and orchestrators first;
  runtime subagents should receive exact routes.
- Extract only policy that is reused or likely to drift. Do not split rules
  merely to make files small.
- Keep `skill-contracts.md` as the universal fast path. Do not turn it into a
  generic table of contents.
- Treat `orchestrate` as inherently `delegate-on`, but do not force all work
  through orchestration.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts into:

- `architecture/workflow-kit.md` — rule file layout, skill responsibility,
  delegation-mode behavior, and adapter/verifier impact.
- `decisions/agent-docs.md` — rationale for delegation as a separate execution
  mode and for exact rule-file routing instead of pasted rule prose.
- `_meta/ownership.json` — only if a new concept needs an explicit owner.

## See also

- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/rules/skill-contracts.md`](../../v1/rules/skill-contracts.md)
- [`../../v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
