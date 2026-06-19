---
status:        draft
owner:         unassigned
last_updated:  2026-06-19
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# V1 focused subagent handoffs

## Mission

Stay on the v1 skill and docs model, but make worker handoffs much sharper.
The goal is lower context and better task focus without generated workspaces,
metadata v2, packet helpers, static context bundles, or broader `docs/index.md`
routing.

Done means v1 clearly separates the work:

- orchestrators classify, ask human-level questions, choose worker phases,
  pass focused inputs, and record worker evidence;
- planning workers do the heavier thinking needed to turn unclear or medium
  work into implementer-ready briefs;
- implementation, review, verification, docs-maintenance, and plan-maintenance
  workers execute only their assigned role and report back when the task grows
  outside that role or materially beyond scope.

## Scope

In scope:

- Keep v1 as the active system and retire the generated-context v2 direction.
- Preserve root router-only adapter files and the current Markdown manifest
  model.
- Update v1 orchestration docs so detailed implementer packet shaping belongs
  mostly to planning workers, not the orchestrator.
- Rewrite subagent rule docs as concise role job cards.
- Update `plan`, `orchestrate`, and `quick-fix` skill docs so they dispatch
  planning workers when a brief needs real investigation, and implementation
  workers only when the task is already scoped enough to execute.
- Add an implementer-brief contract to the planning worker rules. The brief may
  name goal, scope cuts, authoritative docs, likely source areas, known risks,
  cheapest sufficient checks, and stop conditions.
- Let implementation workers discover source files and tests within the
  assigned slice. They escalate back to the orchestrator only when the work
  grows materially, crosses role boundaries, or needs a direction-setting
  decision.
- Dogfood the revised rules on a planning-to-implementation flow, preferably
  against `fluid-simulation` after the docs are updated.

Out of scope:

- Generated repo-local workspaces, `.agent-docs/agents`, `sources.yaml`, or
  disposable generated context files.
- Metadata v2, `manifest.yaml`, ownership v2, or YAML parser work.
- Static context bundle files whose main purpose is deduplicating rule lists.
- Packet helper scripts or command-generated dispatch prompts.
- Expanding `docs/index.md` into a role or skill routing system.
- Requiring orchestrators to fill every implementer-detail field for complex
  work before a planning worker has investigated.
- Letting subagents switch skills, run lifecycle phases they were not assigned,
  or broaden into planning/review/closeout work on their own.

## Approach

### 1. Retire the v2-generated-context direction

Mark the v2 generated-context and metadata-v2 plans as abandoned or superseded
by this v1 refactor after any useful lessons are migrated here and into durable
architecture/decision docs. Remove or quarantine the narrow v2 proof code when
no live v1 path references it.

Useful lessons to keep:

- context should be role-specific;
- inputs should be deterministic and source-backed;
- generated prose is not the product;
- lower context comes from better selection and sharper worker roles.

Lessons to reject:

- per-agent generated folders;
- run-local context infrastructure;
- making orchestrators manage worker folders;
- turning context handoff into a generator problem.

### 2. Define the v1 role split

Update `v1/rules/orchestrator/lifecycle.md` and
`v1/rules/orchestrator/dispatch.md` around this split:

- **Orchestrator**: intake, lifecycle choice, high-level human questions,
  worker selection, minimal input routing, sequencing, and evidence tracking.
  It may pass obvious docs for small tasks, but it does not burn context
  building a detailed implementation brief for ambiguous or medium work.
- **Planning worker**: investigates enough to produce an implementer-ready
  brief or tracked plan. It owns the rich fields that are expensive for the
  orchestrator to think through.
- **Implementation worker**: executes the assigned brief or bounded task,
  discovers source locally within scope, runs the cheapest sufficient gate,
  updates durable docs when required, commits, and reports.
- **Review worker**: reviews only the assigned plan, diff, docs, or shipped
  state under the named lens. It does not become an implementer unless the
  dispatch explicitly authorizes obvious fixes.
- **Verification worker**: runs named gates and reports exact output. It does
  not fix failures.
- **Maintenance workers**: perform assigned docs or plan lifecycle hygiene only.

### 3. Make planning workers produce implementer briefs

Update `v1/rules/subagent/planning.md` so a planning worker can return an
implementation brief with this shape when the next phase is implementation:

```text
Goal:
Non-goals:
Authoritative docs:
Likely source areas:
Expected behavior:
Implementation notes:
Cheapest sufficient checks:
Stop and report if:
Open decisions:
```

This is a writing contract for the planning worker, not a new generated packet
format and not a helper script. The orchestrator can pass the brief directly to
an implementation worker.

### 4. Tighten worker job cards

Rewrite the subagent rules to be shorter and more role-specific:

- `implementation.md`: no planning lifecycle, no review lifecycle, no skill
  switching. Execute the assigned slice; discover files within scope; stop when
  scope or decisions grow past the brief.
- `review.md`: findings-first under the assigned lens; no broad tree sweep
  unless requested; no fixes unless authorized.
- `verification.md`: exact gates only; no repairs.
- `docs-maintenance.md`: docs ownership and drift work only.
- `plan-maintenance.md`: plan migration/status hygiene only.
- `planning.md`: richer than the others, because it is the worker role that
  should spend context on thinking and handoff quality.

### 5. Update skill bodies to use the split

Update v1 skill docs where they currently imply the orchestrator should fill
too much detail itself:

- `v1/skills/plan/SKILL.md`: planning workers produce briefs or tracked plans;
  orchestrator owns questions and final placement.
- `v1/skills/orchestrate/SKILL.md`: medium work goes through a planning-worker
  brief before implementation; direct implementation is for already-bounded
  tasks.
- `v1/skills/quick-fix/SKILL.md`: still one implementation worker, but only for
  tasks that are already scoped tightly enough to execute.

Do not add multi-skill discovery rules for workers. If another skill is needed,
the orchestrator starts a new phase or skill invocation.

### 6. Verify and dogfood

After the docs are updated:

1. Run the v1 verifier.
2. Run copied-skill freshness checks if global skill files changed.
3. Dogfood a small planning-to-implementation handoff and inspect whether the
   orchestrator stayed small, the planning worker carried the heavy brief, and
   the implementation worker stayed focused.

## Exit gate

- The active docs no longer present v2 generated context as the path forward.
- `docs/plans/generated-repo-local-agent-context.md` and
  `docs/plans/metadata-v2.md` are abandoned, superseded, or otherwise clearly
  not active direction.
- `v1/rules/orchestrator/dispatch.md` distinguishes minimal orchestrator
  dispatch from planner-produced implementation briefs.
- `v1/rules/orchestrator/lifecycle.md` says detailed brief shaping belongs to a
  planning worker when the task is not already bounded.
- `v1/rules/subagent/*.md` are concise, role-focused job cards.
- `v1/skills/plan/SKILL.md`, `v1/skills/orchestrate/SKILL.md`, and
  `v1/skills/quick-fix/SKILL.md` route work according to the new split.
- No new packet helper, context bundle file, generated workspace, metadata v2
  parser, or `docs/index.md` expansion is introduced.
- `bash v1/verify-agent-docs.sh` passes.
- If copied skill files change, `bash v1/copy-skills.sh --check` passes or the
  required refresh is documented.
- A dogfood handoff shows that the orchestrator can pass a planning-worker brief
  to an implementation worker without loading the implementation details itself.

## Discipline rules

- Stay on v1.
- Prefer concise role instructions over abstraction.
- Duplication is acceptable when it makes a skill or worker prompt clearer.
- Do not solve context quality with generated files.
- Do not make subagents responsible for choosing skills.
- Do not make `docs/index.md` a skill router.
- Do not make orchestrators do planner-level brief writing for work that needs
  investigation.
- Let workers discover local source within their assigned slice, but require
  them to report back when the task materially changes shape.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts into:

- `architecture/workflow-kit.md` - v1 role split, planner-produced briefs, and
  focused worker job-card model.
- `decisions/agent-docs.md` - rationale for staying on v1 and rejecting
  generated workspaces, metadata v2, packet helpers, and static context bundles.
- `_meta/ownership.json` - any ownership updates for worker rules or skill
  routing concepts.

Record whether the old v2 plans were abandoned, deleted, or reduced to archived
lessons.

## See also

- [`generated-repo-local-agent-context.md`](generated-repo-local-agent-context.md)
- [`metadata-v2.md`](metadata-v2.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/rules/orchestrator/dispatch.md`](../../v1/rules/orchestrator/dispatch.md)
- [`../../v1/rules/subagent/planning.md`](../../v1/rules/subagent/planning.md)
