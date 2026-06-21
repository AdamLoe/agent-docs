---
status: active
owner: implementation
last_updated: 2026-06-21
okay_to_delete: false
long_lived: false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Finish and enforce the agent-docs execution-kernel overhaul

## Preconditions

The v1→src path rename and `~/.agentdocs/` runtime relocation are already
complete. All `v1/` source paths are now `src/`; the runtime lives at
`~/.agentdocs/`. This plan operates against the current `src/` tree.

## Mission

Complete the in-place context overhaul so agent-docs is fast, accurate, and
powerful in actual use—not only directionally improved in its documentation.
Preserve the new execution-kernel architecture, but finish its authority,
context-budget, recipe-migration, and verification contracts.

Done means each Claude Code or Codex call receives the smallest correct context,
fixed workflows avoid generic classification, worker permissions are
unambiguous, supplied configuration does not cause redundant human stops, and
the verifier fails when the documented workflow is not actually represented by
the skills and role cards.

## Current baseline

The June 20 implementation landed useful provenance, read-only review and
verification, one-primary-mutator guidance, and worker profiles. It did not
finish the prior plan's exit gate.

*The figures below are pre-refactor measurements taken against the old `v1/`
tree. Re-measure against the current `src/` tree in Wave 0 before acting on
these numbers.*

Controlled startup loads, excluding task-routed source/tests:

| Load | Pre-refactor | Target |
|---|---:|---:|
| `quick-fix` fixed launch | 3,532 words | <=1,200 |
| `orchestrate` classifier launch | 5,771 words | <=2,000 |

Current contract drift (pre-refactor inventory — re-verify in Wave 0):

- Seven of eleven worker profiles exceed their declared budgets.
- Every profile remains `report-only`.
- Sixteen of twenty-one skills still load `lifecycle.md`.
- Fifteen skills still spell out subagent rule bundles instead of using profile
  IDs.
- Scenario checks validate phrases in the scenario table, not behavior encoded
  by the actual skills and role cards.
- Role cards independently add rules that profiles intentionally omit.
- `implementation.tracked` is granted selected-plan closeout by skills/profiles,
  while the implementation role card prohibits plan-status changes.
- `review-app` still inserts a pre-audit confirmation stop and eagerly loads
  run-doc and plan context.
- The previous overhaul plan is marked shipped even though these exit conditions
  are unmet.

## Settled decisions

- No parallel versioned system (no v2); no compatibility aliases.
- Support Claude Code and Codex only.
- Quick fixes always use an implementation worker, including one-line changes.
- At most one worker mutates the shared tree at a time.
- One primary mutator may make several meaningful commits; extra mutators are
  not created merely to produce more history.
- Review and verification remain read-only. Their findings route to a mutating
  role.
- Generated prompts, context bundles, wrappers, and per-run context workspaces
  remain prohibited.
- A deterministic read-only resolver may return exact profile paths, requested
  manifest slots, and measurements. It writes no artifacts and synthesizes no
  prompt body.
- Model strength follows risk and uncertainty, not a rigid role table.
- Do not add telemetry infrastructure. Use deterministic measurements,
  contract tests, and a small set of manual Claude/Codex canaries.
- Tracked plans remain for explicit, broad, risky, multi-stream, or
  resume-sensitive work; inline briefs remain the normal medium-work handoff.

## Target contract

1. **Profiles are the sole worker-context authority.** A role card never adds a
   default rule file. A worker reads exactly the resolved profile, named
   overlays, and task-routed source/docs.
2. **Skills are thin recipes.** A fixed skill owns only inputs/defaults, phase
   order, profile IDs, unique approval gates, escalation conditions, and result
   shape.
3. **Only genuine routers classify.** The default classifier allowlist is
   `orchestrate`, `fresh-chat`, and `start-session`. Any additional classifier
   requires an explicit verifier-recognized justification.
4. **Mutation authority is explicit.** `planning.tracked` may persist its plan;
   `implementation.tracked` may close only the selected plan when the dispatch
   grants selected-plan closeout; review and verification never mutate.
5. **Verification observes the final state.** The final gate runs after all
   code, docs, ownership, plan-frontmatter, and run-doc mutations.
6. **A green report is truthful.** Over-budget or contradictory contracts cannot
   end in `PASS` because their status is merely `report-only`.

## Work

### Wave 0: Restore truthful plan state and freeze the baseline

The previous overhaul plan (`agent-docs-context-simplification-plan-revised.md`)
was already deleted during the refactor cleanup — its durable facts were
migrated to architecture/decisions. There is no prior plan to reopen or
supersede. This plan is now the single live tracked plan for the remaining
enforcement work.

- Re-measure controlled-load figures against the current `src/` tree and record
  them as the new baseline (replacing the pre-refactor figures in "Current
  baseline" above).
- Record the controlled-load formula: skill body, shared startup contract,
  required orchestrator rules, docs index, requested manifest slots, and
  resolver output. Keep task-routed source/tests separate.
- Record current profile totals and the current skill migration inventory as
  verifier fixtures or assertions, not generated reports.
- Preserve the already-good state/provenance, serial-mutation, and
  final-ordering rules while later files are compressed.

### Wave 1: Make profile resolution singular and cheap

- Keep `src/rules/context-profiles.md` as the human-owned runtime profile
  contract, but remove the scenario matrix from its runtime load surface.
- Move scenario data into a tracked, never-auto-loaded fixture such as
  `src/verify-fixtures/workflow-scenarios.json`.
- Extend the existing read-only resolver with concise modes that:
  - resolve one profile ID to exact core paths, overlays, capability, and budget;
  - return only the manifest slots requested by a skill for a named repo;
  - measure one worker profile or complete skill launch;
  - write nothing and never emit copied rule bodies.
- Skills resolve profile IDs through the resolver; they do not load the full
  profile owner merely to obtain one row.
- Rewrite every role card's "What you read" section to say: read exactly the
  resolved profile and dispatch overlays. Remove "normally read" lists and make
  `See also` links non-loading references.

### Wave 2: Align role and mutation contracts

- `planning.brief`: read-only, returns an inline implementation brief, never
  loads lifecycle/template/repo mutation rules.
- `planning.tracked`: may create, edit, stage, and commit its assigned plan. Give
  it the complete dirty-tree and commit contract required for that authority.
- `implementation.code`: code/tests only unless a named docs trigger is proven.
- `implementation.code-docs`: may update directly associated owning docs.
- `implementation.tracked`: may implement, migrate associated docs, and close
  only the selected plan when the dispatch explicitly grants `plan_closeout`.
  Update the implementation role card so this is not prohibited.
- Keep docs-maintenance for docs-first repair or difficult independent migration,
  and plan-maintenance for plan-only health, cleanup, or lifecycle work.
- Remove every fix-enabled review/verification path. A failed read-only phase
  returns evidence and the required mutator profile.
- Require every worker report to name observed commit/dirty state, inspected
  sources, evidence, touched paths, commits/no-change, and invalidation
  conditions.

### Wave 3: Meet worker and launch budgets without deleting correctness

Compress runtime rules by moving examples, rationale, and language-specific
reference material to task-routed or never-auto-loaded owners. Do not raise a
budget merely to make the gate green.

Runtime targets:

| File/class | Target |
|---|---:|
| `skill-contracts.md` | <=250 words |
| `orchestrator/dispatch.md` | <=300 |
| `orchestrator/lifecycle.md` | <=500 |
| runtime portion of `context-profiles.md` | <=350 |
| fixed skill body | <=350; prefer <=300 |
| classifier skill body | <=650; prefer <=550 |
| planning role card | <=250 |
| implementation role card | <=325 |
| review/verification role card | <=250 |
| docs/plan-maintenance role card | <=300 |
| `repo-rules.md` runtime contract | <=400 |
| generic coding-style core | <=300 |
| authoring runtime rules | <=700 |
| `plan-lifecycle.md` | <=400 |
| `plan-template.md` | <=200 |

Use conditional language overlays rather than loading Rust, Python, and frontend
idioms together. Move long examples and anti-pattern catalogues into the guide or
reference leaves that workers load only when needed. Preserve all safety,
ownership, dirty-tree, source-precedence, and final-gate invariants.

No profile may remain above its declared budget at the end. A target change
requires an explicit decision entry with the exact correctness reason and a new
complete-launch measurement.

### Wave 4: Finish all skill recipes

Convert every skill to profile IDs and remove copied bundles, shared model/dial
policy, report boilerplate, serial-editing prose, and generic final-gate prose.

Prioritize:

1. `review-app`
2. `quick-fix`, `plan`, `ship-current-work`, and `ship-plans`
3. docs/plan review and maintenance commands
4. bootstrap and utility commands
5. `orchestrate` last, after fixed recipes establish the contracts it routes to

`review-app` defaults must be concrete:

- supplied values are final;
- omitted dials silently use medium;
- run state defaults to chat-only;
- app startup and screenshots default off;
- approved plan status defaults to `draft`;
- no pre-audit "confirm this run shape" stop;
- ask only for a missing choice that materially changes scope, risk, authority,
  or irreversible work;
- the normal approval gate is findings first, then user-approved plan creation;
- load run-doc rules only after run docs are chosen, and load plan lifecycle only
  after findings are approved for planning.

Fixed recipes must not load `lifecycle.md`. They may use the shared dispatch
contract and resolved profiles. Utility skills that perform pure routing/IO
should not load worker or classifier policy merely to prove that they are
utilities.

### Wave 5: Replace decorative checks with source-bound contract gates

Rewrite verifier checks so scenarios are assertions over actual source files and
resolved contracts, not phrase checks over a self-authored scenario table.

The verifier must fail on:

- any enforced profile over budget;
- any profile left `report-only` at final closeout;
- a fixed skill loading `lifecycle.md` without an allowlisted justification;
- a skill spelling out subagent bundles instead of naming profile IDs;
- a role card adding implicit rule files outside the resolved profile;
- review or verification mutation/commit authority;
- contradictory selected-plan closeout authority;
- `review-app` pre-audit confirmation or eager run-doc/plan loading;
- final verification ordered before any later mutation;
- incomplete state-basis or invalidation fields;
- complete fixed/classifier launches above budget;
- source/registry/Claude-copy/Codex-copy drift.

`--context-report` may print measurements even when red, but it must exit
non-zero and must not print `PASS` while an enforced violation exists. Keep the
report deterministic and read-only.

Contract fixtures must cover at least bounded quick fix, inline brief, tracked
planning, dirty-tree shipping, named-plan closeout, docs repair, report-only
review, configured app review, failed verification, and invalidated resume.
Static gates prove the documented contract; they do not claim to prove model
behavior. Run the manual canaries below before shipping.

### Wave 6: Durable migration and closeout

- Rewrite `docs/architecture/workflow-kit.md` from the implemented state.
- Update `docs/decisions/agent-docs.md` with only the decisions still in force.
- Update manifest and ownership coverage for resolver/fixtures and any runtime
  versus reference rule split.
- Update `src/agent-docs-guide.md` without copying the complete runtime contract.
- Remove superseded policy rather than preserving both old bundles and profiles.
- Refresh skill adapters via `bash install-agentdocs-local.sh` (requires
  explicit user permission per `src/rules/repo-rules.md` destructive command
  checklist), then verify adapter freshness with `bash src/verify-agent-docs.sh`.
- Mark this plan truthfully only after all automated and manual exit gates pass.

## Exit gate

Automated proof:

```sh
bash src/verify-agent-docs.sh
bash src/verify-agent-docs.sh --context-report
bash src/verify-agent-docs.sh --context-report --profile implementation.code
bash src/verify-agent-docs.sh --context-report --profile implementation.tracked
```

Adapter freshness (Wave 6 only — requires user permission):

```sh
bash install-agentdocs-local.sh
bash src/verify-agent-docs.sh
```

Required outcomes:

- All eleven profiles are enforced and within budget.
- Fixed launch <=1,200 words; classifier launch <=2,000 words.
- `quick-fix` still dispatches one implementation worker for a bounded task.
- Only the classifier allowlist loads generic lifecycle policy.
- No role card expands a resolved profile implicitly.
- Review and verification are read-only in rules, profiles, and skills.
- Selected-plan closeout authority agrees across profile, role, and recipe.
- Final verification observes the state after the last mutation.
- Full registry, source skill, Claude copy, and Codex copy parity passes.

Manual canaries, once in Claude Code and once in Codex:

1. Supplied bounded `quick-fix`: no dial/config round trip; implementation worker
   runs; final verification observes the committed result.
2. Supplied `review-app` configuration: audit begins without reconfirmation;
   findings are reported; no plan is written before approval.
3. Named `ship-plans`: one primary `implementation.tracked` worker may close the
   selected plan; final gate follows plan/docs closeout.
4. Resume after an overlapping commit: stale worker context is rejected until a
   delta reread or fresh worker occurs.

## Discipline rules

- One mutating worker at a time on the shared tree; read-only inspection may fan
  out.
- Preserve unrelated dirty paths and stage only owned files.
- Prefer several meaningful commits when they improve history, but do not split
  roles solely to create commits.
- Do not introduce v2, compatibility aliases, generated context artifacts,
  background telemetry, or worktrees as the normal path.
- Do not weaken a gate, inflate a budget, or mark a plan shipped to hide an
  incomplete migration.
- Do not push without explicit user instruction.

## Likely files

- `src/rules/context-profiles.md`
- `src/rules/skill-contracts.md`
- `src/rules/orchestrator/{lifecycle,dispatch}.md`
- `src/rules/subagent/*.md`
- `src/rules/{repo-rules,authoring-rules,coding-style}.md`
- `src/plan-{lifecycle,template}.md`
- `src/skills/*/SKILL.md`, `src/skills/registry.md`
- `src/verify-agent-docs.sh`
- `src/verify-fixtures/workflow-scenarios.json` or equivalent tracked fixture
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`
- `docs/_meta/{manifest.md,ownership.json}`
- `src/agent-docs-guide.md`
