---
status: draft
owner: unassigned
last_updated: 2026-06-20
okay_to_delete: false
long_lived: false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Agent-docs execution-kernel and context overhaul

## Mission

Make agent-docs more powerful, faster, more accurate, and cheaper by reducing
unnecessary context, cold model starts, human round trips, and serial mutation
phases. Each agent should receive the smallest correct context for its current
phase, know which repository state it observed, and escalate context, model
strength, review, or persistence only when the work warrants it.

This is an execution-system redesign, not merely a rule-file compression pass.

## Settled decisions

- Keep the active system on `v1` and change it in place. Backward compatibility,
  aliases, and dual behavior are not required.
- Support Claude Code and Codex only.
- Quick fixes still use an implementation worker, including one-line changes.
- Only one worker mutates the shared tree at a time. Read-only work may run in
  parallel; worktrees are not the normal path.
- Generated prompt bundles, context files, skill wrappers, and per-run context
  workspaces remain prohibited.
- A deterministic read-only context-profile resolver may print exact paths,
  conditions, and word totals, but writes no artifacts or prompt bodies.
- The resolver/report command lives in
  `bash v1/verify-agent-docs.sh --context-report`, with an optional
  `--profile <id>` filter. It is read-only and prints exact files, conditions,
  word totals, and budget exceptions.
- Model choice is based on risk and uncertainty, not a rigid role table.
- Commit cadence is independent of worker topology. One primary mutator may make
  several meaningful commits; extra mutators are not created for history alone.
- Review and verification are read-only. Findings route back to implementation,
  docs-maintenance, or plan-maintenance rather than loading fix-enabled bundles.
- Inline implementation briefs are the default. Tracked plans are for explicit,
  broad, risky, multi-stream, or resume-sensitive work.
- Do not expand telemetry. Remove default token-usage boilerplate and rely on
  deterministic context reports and scenario benchmarks.
- Commands may be renamed, merged, or deleted, but do not replace fixed recipes
  with one large universal classifier.

## Done definition

Supplied values are accepted, fixed workflows avoid the generic classifier,
skill bodies keep only recipe-specific behavior, profiles resolve to exact paths
and budgets, one primary mutator owns normal change work, reports name their
observed state, risk drives model/review strength, final gates run after the
last mutation, and representative workflows improve context/latency without
more missed requirements or rework.

Initial controlled-context targets:

| Load | Target |
|---|---:|
| Fixed skill launch, including recipe | `<=1,200` words |
| Generic classifier launch | `<=2,000` words |
| Fixed skill body | `<=350` words |
| Generic classifier skill body | `<=650` words |
| Planning brief worker | `<=700` words |
| Tracked planning worker | `<=1,300` words |
| Code-only implementation worker | `<=1,700` words |
| Code + docs + plan implementation worker | `<=2,500` words |
| Generic read-only review worker | `<=700` words |
| Read-only verification worker | `<=500` words |

Task-routed source/tests are measured separately. A budget exception must print
its exact files and record a correctness reason.

## Target design

Fixed recipes and generic routers resolve a read-only context profile, run only
needed discovery/review, use one primary mutator by default, and add independent
final review or verification when risk requires it.

### Tiny execution kernel

Keep shared policy in small, single-purpose owners:

- `skill-contracts.md`: startup defaults, task-missing behavior, material human
  stops, dials, and owner links.
- `lifecycle.md`: generic classification, phase selection, risk escalation, and
  read-only parallelism versus serial mutation.
- `dispatch.md`: dispatch/report envelopes, source precedence, repository-state
  basis, invalidation, resume rules, failure behavior, and final ordering.
- `context-profiles.md`: profile IDs, purposes, exact rule paths, conditional
  overlays, mutation capability, word budgets, enforcement status, and budget
  exception rules.

Only genuine routers such as `orchestrate` load `lifecycle.md`. A fixed skill
body contains only purpose, inputs/defaults, phase order, profile IDs, unique
approval gates, escalation conditions, and closeout result.

### Context-profile owner contract

Add `v1/rules/context-profiles.md` as the canonical tracked owner for context
profiles. Do not duplicate profile tables in skills, dispatch rules, or docs.
Each profile row must define `id`, `purpose`, `core_rule_paths`, conditional
`overlays`, `mutation_capability`, `budget_words`, and `enforcement_status`
(`report-only`, `pilot-enforced`, or `enforced`).

The first implementation creates the owner in `report-only` status. Enforcement
is enabled only after the quick-fix pilot and converted skills prove the profile
table, resolver output, scenario expectations, and verifier checks agree.

### Context profiles

Skills name profiles from `v1/rules/context-profiles.md` instead of copying rule
bundles:

| Profile | Core context |
|---|---|
| `planning.brief` | planning role card |
| `planning.tracked` | planning, plan lifecycle/template, repo rules |
| `implementation.code` | implementation, repo rules, coding style |
| `implementation.code-docs` | code profile + authoring rules |
| `implementation.tracked` | code-docs profile + plan lifecycle |
| `review.generic` | review role card + named lens sources |
| `review.docs` | review + authoring rules |
| `review.plan` | review + plan lifecycle |
| `maintenance.docs` | docs-maintenance, authoring, repo rules |
| `maintenance.plan` | plan-maintenance, plan lifecycle, authoring, repo rules |
| `verification.readonly` | verification role + exact gate binding |

Ownership entries, architecture/decision leaves, plans, and source remain
conditional task routes. An implementation worker may begin code-only and load a
named docs/plan overlay only after proving the trigger and reporting it. There
are no fix-enabled review or verification profiles.

### Worker topology and commits

- `planning.brief` is read-only. `planning.tracked` may write and commit its plan
  so a separate persistence worker is unnecessary.
- Implementation is the primary delivery role and may own code, tests, directly
  associated docs, and selected plan/run closeout when its profile grants them.
- Docs-maintenance remains for docs-only or independently difficult migration.
- Plan-maintenance remains for plan health, cleanup, and plan-only lifecycle.
- Review and verification remain independent and read-only.

Prefer:

```text
optional read-only discovery
-> one implementation worker
-> optional independent review
-> final verification
```

instead of automatically chaining implementation, docs maintenance, plan
maintenance, fix-enabled review, and verification. The primary mutator may make
multiple coherent commits to preserve useful history.

### State and provenance contract

Every dispatch includes:

```text
Role/profile; task and acceptance result
State basis: HEAD plus exact dirty paths
Authoritative sources and precedence
Resolved bindings and starting path/symbol hints
Expected evidence
```

Every report includes outcome, observed basis, sources inspected, files touched,
checks, commits, carry-forward facts, and invalidation conditions. Resume a
worker only when intervening changes do not affect its source set, touched paths,
acceptance criteria, or bindings; otherwise require a delta reread or fresh
worker. Final verification names the exact commit and dirty state it observed.

### Interaction defaults

Explicit values are final, omitted dials silently use `review-medium` and
`cost-medium`, task-driven skills with no task ask one task question, and
state-driven skills ask nothing unless a concrete safety/product decision is
unresolved. Stop only for decisions that alter public behavior, security/data
risk, irreversible action, durable ownership, lifecycle scope, or unresolved
product/architecture choice.

For `review-app`: accept supplied configuration, default to chat-only, disable
startup/screenshots unless requested or necessary for the selected lens, and
retain only the post-findings approval gate before plan creation.

### Risk-based models and review

Escalate for security/auth, migrations, destructive behavior, public APIs,
concurrency, hard algorithms, broad changes, conflicting sources, unclear
acceptance, repeated failures, or weak verification. `cost-*` tunes fan-out;
`review-*` tunes review intensity, not required gates.

### Plans and command surface

Create tracked plans only for explicit, broad, risky, multi-stream, or
resume-sensitive work. The tracked planner writes/commits the plan; plan-review
edits normally resume that planner. An `implementation.tracked` worker may close
the selected plan; use plan-maintenance for plan-only work.

Dedicated commands are often cheaper because they avoid classification. Merge
or delete a command only when another recipe genuinely subsumes its inputs,
lifecycle, approvals, and result while retaining reliable triggering in Claude
Code and Codex. Because compatibility is irrelevant, remove obsolete source
skills, registry rows, docs, and copied adapters together; leave no aliases.

### Telemetry policy migration

Removing default token-usage boilerplate is a policy migration, not a local
cleanup. The implementation must remove or rewrite token-usage requirements
across:

- `v1/rules/skill-contracts.md`
- `v1/rules/orchestrator/dispatch.md`
- `v1/rules/subagent/*.md`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`
- `v1/verify-agent-docs.sh` checks

Reports may still include runtime usage only when exposed by the runtime or
explicitly requested by a caller. The default proof surface becomes the
deterministic context report plus scenario benchmark output.

## Work

### Stream ownership and dependencies

| Stream | Owns | Depends on | Avoids |
|---|---|---|---|
| Profile contract/resolver | `v1/rules/context-profiles.md`, context-report path, fixtures/rows | None | Skill rewrites beyond profile wiring |
| Quick-fix pilot | quick-fix skill, registry row, adapter copies, scenarios | Report-only resolver | Other skills or enforcement |
| Skill migration | `v1/skills/*`, registry, copied skills, targeted docs | Resolver and quick-fix pilot | Enforcement before conversion |
| Kernel/rule migration | skill contracts, lifecycle/dispatch, subagent rules, telemetry text | Profile/scenario contracts | Recipe source except consistency fixes |
| Docs/decision migration | workflow-kit, decisions, manifest/ownership, guide | Implemented kernel/skills | Unimplemented behavior |
| Enforcement | verifier, fixtures/checks, drift gates | Converted profiles, skills, docs | Behavior changes outside gate fixes |

Only one write-capable stream mutates the shared tree at a time. Read-only
baseline, scenario review, and docs inspection may run in parallel. If two
streams need the same file, the earlier dependency owns the first edit and the
later stream rebases on the committed result.

### Wave 0: Contract, report-only resolver, and baseline

- Add `v1/rules/context-profiles.md` with the owner contract above and initial
  profile rows in `report-only` status.
- Add the read-only resolver/report mode at
  `bash v1/verify-agent-docs.sh --context-report`, with optional
  `--profile <id>`. It prints exact files, conditions, word totals, and budget
  exceptions, and writes nothing.
- Record current complete controlled loads, cold starts, human stops, worker
  counts, serial mutation phases, and carry-forward sizes.
- Create a small scenario matrix covering bounded fix, unclear small work,
  medium brief, tracked change, dirty-tree shipping, named-plan shipping, docs
  repair, report-only review, configured app review, failed verification, and a
  resumed worker invalidated by an intervening commit.
- Record expected questions, profiles, phases, mutator counts, state-basis
  fields, and final ordering for each scenario.
- Keep all profile budgets and scenario checks report-only in this wave.

### Wave 1: Quick-fix pilot vertical slice

- Convert `quick-fix` first because it is fixed-recipe, has low classification
  need, and preserves the settled decision that quick fixes still use an
  implementation worker.
- Wire `quick-fix` to resolved profile IDs without loading the generic
  classifier or plan context by default.
- Preserve one implementation mutator, optional read-only review only when risk
  requires it, and final verification after the last mutation.
- Add quick-fix scenarios for supplied task, omitted values, dirty tree, failed
  gate, and commit closeout.
- Run the `implementation.code` context report and quick-fix scenario check in
  report-only mode.

### Wave 2: Kernel rules, telemetry migration, and skill conversion

- Rewrite `skill-contracts`, `lifecycle`, and `dispatch` to the ownership above.
- Split brief versus tracked planning.
- Let tracked planning persist its own plan.
- Make implementation the primary code/docs/selected-plan mutator through
  conditional profiles.
- Reserve docs/plan maintenance for specialist workflows.
- Make review and verification unconditionally read-only.
- Permit multiple coherent commits per mutator while preserving serial editing.
- Add state-basis/invalidation fields to dispatches and reports.
- Remove bundle definitions from skills and replace them with profile IDs plus
  conditional overlays.
- Remove default usage blocks, telemetry JSONL policy, and related
  verifier/doc requirements across the explicit telemetry migration file set.
- Keep resolver and scenario failures report-only until the converted skill set
  and copied adapters agree.

### Wave 3: High-value recipes and scenario gates

After the quick-fix pilot, rewrite and benchmark:

1. `plan`: inline brief by default; tracked plan only under the policy above.
2. `orchestrate`: main generic classifier; one primary mutator by default.
3. `ship-current-work`: optional read-only diff review, one finishing mutator,
   final gate.
4. `ship-plans`: planner only for unready plans; implementation may close plans.
5. `review-app`: no configuration reconfirmation; audits, synthesis, approval,
   then tracked-plan writing.

Run context and scenario checks after each recipe instead of rewriting the whole
suite before measuring.

### Wave 4: Remaining skills, enforcement, and migration

- Convert remaining skills to thin fixed recipes or justified classifiers.
- Audit command overlap and remove only proven redundancy.
- Keep `registry.md` as inventory/unique metadata, not a workflow manual.
- Extend the verifier to fail on over-budget profiles, fixed skills loading the
  classifier, repeated bundle/model/report policy, mutation authority in review
  or verification, missing profile paths, generated context artifacts, and
  source/registry/adapter drift.
- Turn `context-profiles.md` enforcement statuses from `report-only` to
  `enforced` only after the corresponding skill and scenario conversion lands.
- Migrate the implemented model into `docs/architecture/workflow-kit.md`,
  `docs/decisions/agent-docs.md`, manifest/ownership metadata, and
  `v1/agent-docs-guide.md`; delete superseded policy.
- Refresh and check both Claude and Codex copied skills.

## Scenario gate contract

The verifier context-report path must expose a named scenario contract/check,
using fixtures or documented task rows. Each row names `scenario_id`,
`task_shape`, `expected_questions`, `expected_profiles`, `expected_phases`,
`expected_mutator_count`, `state_basis_fields`, `final_ordering`, and
`budget_expectation`.

Minimum scenarios:

| Scenario | Required check |
|---|---|
| `bounded-quick-fix` | No classifier, `implementation.code`, one implementation worker, final gate after mutation. |
| `unclear-small-work` | One material question before worker dispatch, no dial picker. |
| `medium-brief-plan` | `planning.brief`, read-only, inline brief result. |
| `tracked-change-plan` | `planning.tracked`, plan lifecycle/template loaded, plan-only mutation. |
| `dirty-tree-shipping` | State basis lists exact dirty paths and stages owned files only. |
| `named-plan-shipping` | Implementation may close selected plan only when profile grants it. |
| `docs-repair` | Docs-maintenance profile, docs-only mutation, authoring rules loaded. |
| `report-only-review` | Review profile is read-only with no fix-enabled path. |
| `configured-app-review` | Supplied config accepted; plan creation waits for post-findings approval. |
| `failed-verification` | Findings route back to a mutator; verification remains read-only. |
| `resume-invalidated` | Intervening commit or dirty-path overlap forces delta reread or fresh worker. |

## Likely files

- `v1/rules/skill-contracts.md`
- `v1/rules/context-profiles.md`
- `v1/rules/orchestrator/{lifecycle,dispatch}.md`
- `v1/rules/subagent/*.md`
- `v1/skills/*/SKILL.md`, `v1/skills/registry.md`
- `v1/verify-agent-docs.sh`
- `v1/agent-docs-guide.md`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`
- `docs/_meta/{manifest.md,ownership.json}`

## Exit gate

| Gate | Executable or inspectable proof |
|---|---|
| Profile budgets | Context report lists profiles, files, word totals, and correctness exceptions. |
| Profile filter | `--context-report --profile <id>` prints one profile and rejects unknown IDs. |
| Fixed skills avoid classifier | Verifier scans fixed skills for default `lifecycle.md` loads unless justified. |
| Supplied values accepted | Quick-fix and configured-review scenarios show no reconfirmation. |
| Quick-fix topology | `bounded-quick-fix` expects an implementation worker, no classifier, one mutator, and final gate after mutation. |
| Serial mutation | Dispatch/scenario checks require at most one write-capable worker active per shared tree. |
| Read-only review/verification | Verifier check fails on mutation authority in review or verification profiles/rules. |
| Resume invalidation | `resume-invalidated` requires delta reread or fresh worker after relevant state changes. |
| Tracked-plan policy | Registry/docs show tracked plans only for explicit, broad, risky, multi-stream, or resume-sensitive work. |
| No generated context | Verifier fails on generated prompt bundles, artifacts, wrappers, or context workspaces. |
| No compatibility aliases | Source/registry/adapter drift check confirms obsolete commands are deleted together. |
| Telemetry policy removed | Verifier/docs confirm default usage boilerplate and telemetry JSONL policy are absent. |
| Adapter parity | Existing source/Claude/Codex copy checks pass after each converted skill. |
| Final ordering | Scenario rows require final gates to observe the state after the last code, docs, plan, or run-doc mutation. |
| Full drift gate | `bash v1/verify-agent-docs.sh` passes after the implementation and migration are complete. |
