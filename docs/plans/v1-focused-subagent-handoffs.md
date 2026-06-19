---
status:        shipped
owner:         unassigned
last_updated:  2026-06-19
okay_to_delete: true
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

- Keep v1 as the active system and retire/abandon the generated-context and
  metadata-v2 direction.
- Delete or remove the v2 proof path as active direction unless a live v1
  reference proves it still matters long enough to migrate or quarantine.
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
- Dogfood the revised rules on a planning-to-implementation flow against
  `fluid-simulation` for this initial validation and any related work under
  this plan.

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
- Treating `fluid-simulation` as a long-term required workflow target after
  this plan's validation pass.

## Approach

### Planning streams

| Stream | Area | Status | Last observed fact | Next action | Blockers |
|---|---|---|---|---|---|
| V2 retirement | Generated-context and metadata-v2 plans plus proof path | Planned | Accepted direction is to stay on v1 and stop treating v2 as active work. | Abandon or supersede the v2 plans and remove the v2 proof path unless a live v1 reference proves it still matters. | Need reference check before deleting proof code. |
| Handoff boundary | Orchestrator, dispatch, lifecycle, and planning rules | Planned | Orchestrators should route and preserve evidence; planning workers should spend context on brief quality. | Update the rule docs around the boundary and carry-forward summary. | None known. |
| Worker job cards | Subagent role docs | Planned | Review found the v1/no-generated-infrastructure stance sound. | Tighten each worker role without adding generated packets or helper scripts. | None known. |
| Skill routing | `plan`, `orchestrate`, and `quick-fix` skill docs | Planned | Medium or unclear work should go through planning before implementation. | Update skill docs to use planner-produced briefs where investigation is needed. | None known. |
| Dogfood evidence | `fluid-simulation` validation flow | Planned | `fluid-simulation` is the required initial validation target, not a permanent workflow requirement. | Capture the planner prompt, planner brief, carry-forward summary, derived implementation dispatch, and role-adherence notes. | Need access to the target repo/context at validation time. |

### 1. Retire the v2-generated-context direction

Plan decision: the generated-context and metadata-v2 direction is not the
active path. Mark the v2 generated-context and metadata-v2 plans as abandoned or
superseded by this v1 refactor after any useful lessons are migrated here and
into durable architecture/decision docs. Delete or remove the narrow v2 proof
path as active direction unless a live v1 reference proves it still matters; if
that happens, quarantine it only long enough to migrate the remaining useful
lesson.

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
  worker selection, minimal input routing, sequencing, evidence tracking, and
  carry-forward summaries. It supplies the worker role, task, exact rules,
  starting inputs, evidence/report expectations, and the concise summary of
  prior worker findings that the next worker needs. It may pass obvious docs
  for small tasks, but it does not burn context building a detailed
  implementation brief for ambiguous or medium work.
- **Planning worker**: investigates enough to produce an implementer-ready
  brief or tracked plan. It owns the rich implementation-brief fields when
  investigation is needed.
- **Implementation worker**: executes the assigned brief or bounded task,
  discovers source locally within scope, runs the cheapest sufficient gate,
  updates durable docs when required, commits, and reports.
- **Review worker**: reviews only the assigned plan, diff, docs, or shipped
  state under the named lens. It does not become an implementer unless the
  dispatch explicitly authorizes obvious fixes.
- **Verification worker**: runs named gates and reports exact output. It does
  not fix failures.
- **Maintenance workers**: perform assigned docs or plan lifecycle hygiene only.

Handoff boundary:

- Orchestrator dispatch supplies role, task, exact rule links, starting inputs,
  observed evidence to preserve, expected checks, and report shape.
- Orchestrator carry-forward summary is the knowledge intermediary between
  workers: it records decisions, facts, and evidence observed so far without
  loading the next worker with full prior transcripts.
- Planning worker supplies the implementation brief fields when a task needs
  investigation before implementation.
- Implementation worker receives either a bounded task or the planner's brief
  and reports back when the assignment no longer fits its role.

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
an implementation worker after adding only the role/task/rules, starting inputs,
carry-forward summary, evidence expectations, and report shape needed for the
dispatch.

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
3. Dogfood a small planning-to-implementation handoff using
   `fluid-simulation` as the validation target for this plan.
4. Preserve the dogfood evidence in the plan closeout or migrated docs:
   planner prompt, planner brief returned, orchestrator carry-forward summary,
   implementation dispatch derived from the brief, and notes on whether the
   implementation worker stayed in role.

## Exit gate

- The active docs no longer present v2 generated context as the path forward.
- `docs/plans/generated-repo-local-agent-context.md` and
  `docs/plans/metadata-v2.md` are abandoned, superseded, or otherwise clearly
  not active direction.
- The v2 proof path is deleted/removed from active direction, or explicitly
  quarantined only because a live v1 reference proved it still matters.
- `v1/rules/orchestrator/dispatch.md` distinguishes minimal orchestrator
  dispatch from planner-produced implementation briefs.
- `v1/rules/orchestrator/lifecycle.md` says detailed brief shaping belongs to a
  planning worker when the task is not already bounded.
- The orchestrator-as-knowledge-intermediary behavior is explicit: dispatches
  carry forward a concise observed summary between workers.
- `v1/rules/subagent/*.md` are concise, role-focused job cards.
- `v1/skills/plan/SKILL.md`, `v1/skills/orchestrate/SKILL.md`, and
  `v1/skills/quick-fix/SKILL.md` route work according to the new split.
- No new packet helper, context bundle file, generated workspace, metadata v2
  parser, or `docs/index.md` expansion is introduced.
- `bash v1/verify-agent-docs.sh` passes.
- If copied skill files change, `bash v1/copy-skills.sh --check` passes or the
  required refresh is documented.
- A `fluid-simulation` dogfood handoff shows that the orchestrator can pass a
  planning-worker brief to an implementation worker without loading the
  implementation details itself.
- Dogfood evidence includes the planner prompt, planner brief returned,
  orchestrator carry-forward summary, implementation dispatch derived from the
  brief, and notes on whether the implementation worker stayed in role.

## Discipline rules

- Stay on v1.
- Prefer concise role instructions over abstraction.
- Duplication is acceptable when it makes a skill or worker prompt clearer.
- Do not solve context quality with generated files.
- Do not make subagents responsible for choosing skills.
- Do not make `docs/index.md` a skill router.
- Do not make orchestrators do planner-level brief writing for work that needs
  investigation.
- Make orchestrators carry forward the concise observed summary workers need,
  not the full prior context.
- Let workers discover local source within their assigned slice, but require
  them to report back when the task materially changes shape.
- Use `fluid-simulation` for this plan's initial dogfood and related validation,
  but do not make it a standing workflow requirement.

## Migration notes

Shipped by `328e1c1350bacaaed641c23de89e383a60de5af9`.

Durable current-state facts live in
[`../architecture/workflow-kit.md`](../architecture/workflow-kit.md): v1 is the
active kit, handoffs are focused role dispatches, unclear or medium work routes
through planner-produced implementation briefs, implementation workers discover
source within the assigned slice, and orchestrators carry concise observed
summaries between workers. Durable rationale lives in
[`../decisions/agent-docs.md`](../decisions/agent-docs.md): the kit keeps the
source-backed, role-specific lessons from the generated-context exploration and
rejects generated workspaces, metadata v2, packet helpers, static context
bundles, and broader `docs/index.md` skill routing. The existing ownership data
already maps workflow lifecycle, skill contracts, orchestration, and plan
lifecycle surfaces to their owners.

The generated-context and metadata-v2 plans are abandoned with
`okay_to_delete: true`; their useful lessons point back to the workflow and
decision docs above. The v2 proof path was removed from active direction after
live-reference checks found no required v1 dependency. A post-review skill
adapter refresh copied the agent-docs skills to `~/.agents/skills` and
`~/.claude/skills`.

Dogfood evidence: a read-only planning worker against `fluid-simulation` used
`v1/rules/subagent/planning.md`, `v1/plan-lifecycle.md`, and
`v1/plan-template.md` and returned an implementer brief for root router-only
`AGENTS.md` and `CLAUDE.md` files. The brief identified no app-code, build,
simulation, UI, plan-lifecycle, or global kit changes; named the authoritative
docs and likely files; recommended both root adapters plus at most a concise
repository-layout note; and listed `sed`, `git diff --check`, and
`git status --short` as cheap checks. The orchestrator carry-forward summary
preserved the target repo's docs state and missing root adapters, and the
implementation dispatch passed the brief with exact implementation, coding,
authoring, and repo rules plus a no-write instruction because the target repo
was outside this workspace. The implementation worker stayed in role: it
inspected the target repo, verified no intentional omission policy, ran
`git status --short`, root file existence checks,
`git ls-files -- AGENTS.md CLAUDE.md docs/repository-layout.md`, targeted `rg`,
and `git diff --check -- AGENTS.md CLAUDE.md docs/repository-layout.md`, did
not choose a skill, did not re-plan or broaden into app behavior, did not edit
files, and did not commit.

## See also

- [`generated-repo-local-agent-context.md`](generated-repo-local-agent-context.md)
- [`metadata-v2.md`](metadata-v2.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/rules/orchestrator/dispatch.md`](../../v1/rules/orchestrator/dispatch.md)
- [`../../v1/rules/subagent/planning.md`](../../v1/rules/subagent/planning.md)
