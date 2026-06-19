---
status:        draft
owner:         codex
last_updated:  2026-06-19
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - architecture/install-and-adapters.md
  - decisions/agent-docs.md
---

# Agent-docs hardened system pitch

## The Pitch

Agent-docs should feel like a small operating system for agent work:

- **Routers stay tiny.** Auto-loaded files point to docs; they do not contain
  facts.
- **Docs are the map.** Architecture says what is true now, decisions say why,
  plans coordinate temporary work, and ownership metadata routes edits.
- **Skills are entry points.** User-facing skills classify work, choose the
  lifecycle, and dispatch workers with exact rule files.
- **Workers own execution.** Planning, implementation, review, verification,
  docs-maintenance, and plan-maintenance each have explicit responsibilities.
- **Scripts enforce promises.** Install, copy, verifier, registry, scaffold, and
  ownership checks catch drift before users have to reason about it manually.

## Core Shape

- `AGENTS.md` / `CLAUDE.md`
  - router-only adapters;
  - point to `docs/index.md` and `docs/overview.md`;
  - no durable workflow facts.
- `docs/`
  - repo-specific facts and routing;
  - `architecture/` for current-state system shape;
  - `decisions/` for active rationale;
  - `agent-context/` for repo-local procedural notes;
  - `_meta/manifest.md` for gates and change-to-doc routing;
  - `_meta/ownership.json` for concept ownership;
  - `plans/` for temporary coordination only.
- `v1/`
  - reusable kit;
  - `skills/` for command bodies;
  - `rules/` for generic workflow contracts;
  - `template/` for rebuild/adoption scaffold;
  - verifier and install/copy scripts.

## Core Ship Order

Every mutating lifecycle should converge on one order. These are outcome
checkpoints, not a one-to-one list of spawned subagents:

- **1. Classify**
  - Identify whether the work is bounded, briefed, tracked, review-only, or
    blocked on a human decision.
  - Read only the smallest route needed for the task.
- **2. Plan**
  - Use a planning worker for broad, cross-cutting, or unclear work.
  - Persist tracked plans before review when a plan lifecycle is chosen.
  - Keep implementation briefs concise and source-backed.
- **3. Implement**
  - Run editing workers serially on the shared tree unless separate worktrees or
    patches are used.
  - Preserve unrelated dirty work.
  - Stage only owned files.
- **4. Review**
  - Review the shipped outcome, not just the diff.
  - If reviewers may fix, they must receive the implementation and repo rule
    bundle; otherwise fixes route to implementation workers.
- **5. Migrate Docs**
  - Update architecture for current-state facts.
  - Update decisions for rationale and tradeoffs.
  - Update ownership metadata for new routing concepts.
  - Update plan or run-doc status after durable context is migrated.
- **6. Final Gate**
  - Run the manifest drift gate after the last mutation.
  - For this repo: `bash v1/verify-agent-docs.sh`.
- **7. Commit And Report**
  - Commit green work locally.
  - Report commits, gates, assumptions, skipped work, and residual risk.
  - Do not push unless the user explicitly asks.

## Subagent Spawn Model

- **Orchestrator skills decide; worker subagents execute.**
  - User-facing skills classify the request, choose phases, and maintain the
    coordination surface.
  - Workers own role execution: planning, implementation, review,
    docs-maintenance, plan-maintenance, or verification.
- **Spawning is triggered by the work, not by the step number.**
  - Spawn when the phase reads across more than a couple files, makes a
    defensible judgment call, mutates the repo, or runs a verification gate.
  - Stay inline for pure routing and small coordination reads: manifest, index,
    overview, registry rows, plan metadata, and `git status`.
- **Workers receive exact rule bundles.**
  - Dispatch packets name the role, one owned task, input docs/context, exact
    rule files, expected output, expected checks, and report shape.
  - Prior worker evidence is carried forward as facts, not transcripts.
- **Editing is serial by default.**
  - One editing worker uses the shared tree at a time and commits before the
    next editing worker starts.
  - Parallel editing needs separate worktrees or patch return/integration.
- **Read-only workers can fan out.**
  - Planning, review, and investigation workers can run in parallel when their
    lenses are disjoint and they do not compete for scarce resources.
- **Commit/report is not a standalone worker role.**
  - Implementation, docs-maintenance, and plan-maintenance workers commit their
    completed slices.
  - The orchestrator records observed commit hashes, runs or dispatches final
    verification, and reports the final state.

## Ship Order To Worker Map

| Ship order | Normal owner | Worker role | Skills that usually spawn it | Notes |
|---|---|---|---|---|
| 1. Classify | Orchestrator inline | None by default | all user-facing skills | Reads router, manifest, registry, plan metadata, and git state only as needed. |
| 2. Plan | Planning worker, sometimes plan-maintenance | `planning`; `plan-maintenance` for persisted plan files | `/plan`, `/orchestrate`, `/ship-plans` for stale plans, `/quick-fix` only when a small issue needs a brief | Planning may return an implementer brief or tracked plan text; persistence must be explicit. |
| 3. Implement | Implementation worker | `implementation` | `/quick-fix`, `/orchestrate`, `/ship-plans`, `/ship-current-work` for obvious misses, `/rebuild-agent-docs` for script/template repairs, fix-enabled review/doctor flows | Implements the owned slice, runs the cheapest sufficient local gate, updates docs only when needed for the slice, and commits. |
| 4. Review | Review worker | `review` | `/orchestrate`, `/ship-current-work`, `/ship-plans`, `/review-*`, `/check-docs`, `/doctor` | Reviews plan material, current diff, or shipped outcome. If it can fix, it must receive the implementation/repo rule bundle or route fixes to implementation. |
| 5. Migrate docs/plans | Docs- or plan-maintenance worker | `docs-maintenance`; `plan-maintenance` | `/ship-current-work`, `/ship-plans`, `/orchestrate`, `/clear-plans`, `/rebuild-agent-docs`, `/wrap-up-current-chat`, `/fix-docs-drift` | Migrates durable facts/rationale into architecture/decisions and sets plan/run-doc status truthfully. |
| 6. Final gate | Verification worker | `verification` | `/orchestrate`, `/ship-current-work`, `/ship-plans`, `/quick-fix` when isolated gate is needed, `/rebuild-agent-docs`, `/doctor` fix flows, `/clear-plans`, `/wrap-up-current-chat` | Runs after the last mutation, including doc and plan-status edits. |
| 7. Commit and report | Editing workers, then orchestrator inline | No dedicated worker | all mutating skills | Workers commit their slices; orchestrator reports commits, gates, assumptions, and residual risk. |

## Skill Spawn Patterns

- **Bootstrap/routing skills**
  - `/fresh-chat` and `/start-session` mostly read inline and route.
  - They spawn only when state inspection needs a real review, verification, or
    plan-maintenance pass.
- **Planning skill**
  - `/plan` spawns planning workers per separable concern.
  - It may spawn a review worker for broad/risky plan material.
  - It may spawn docs-maintenance only to persist or update tracked plan docs.
  - It does not spawn implementation workers.
- **Primary lifecycle orchestrator**
  - `/orchestrate` can run the full chain:
    - planning worker for briefs/plans;
    - review worker for plan critique;
    - implementation worker(s) by stream;
    - review worker for shipped outcome;
    - verification worker for final gates;
    - docs- or plan-maintenance worker for closeout.
  - It uses run docs only when requested or when resumability risk justifies
    asking.
- **Bounded fix skill**
  - `/quick-fix` normally spawns one implementation worker.
  - It adds a planning worker only when the problem is still small but not
    implementation-ready.
  - It adds review or verification workers only when risk or gate isolation
    warrants it.
- **Finishing skills**
  - `/ship-current-work` starts with a review worker over the existing diff,
    then dispatches docs-maintenance, plan-maintenance, verification, or an
    implementation worker only for missing obvious work.
  - `/ship-plans` dispatches implementation workers by plan/workstream, then
    review, final verification, and plan-maintenance.
- **Maintenance and scaffold skills**
  - `/rebuild-agent-docs` centers docs-maintenance, with implementation only for
    script/template repairs, verification for scaffold gates, and
    plan-maintenance only if plan material is created or retired.
  - `/doctor` is report-only by default; when fixes are requested, failures route
    to docs-maintenance or implementation and then verification.
  - `/fix-docs-drift` should route cross-file judgment to review or
    docs-maintenance workers, then verification.
- **Review skills**
  - `/review-*`, `/check-docs`, and `/review-docs-shape` lead with review or
    docs-maintenance-style inspection.
  - Optional fixes must be explicit: either route to implementation/
    docs-maintenance workers or give the review worker the full mutation bundle.

## Main Skills

- `/fresh-chat`
  - bootstraps from the docs router;
  - routes the next task without over-reading.
- `/start-session`
  - checks repo state, active plans, cleanup candidates, and likely next skill.
- `/plan`
  - turns rough intent into tracked plans or implementer briefs.
- `/orchestrate`
  - coordinates broad or risky change lifecycles across planning, review,
    implementation, verification, and closeout workers.
- `/quick-fix`
  - handles one bounded problem with the smallest safe lifecycle.
- `/ship-current-work`
  - finishes existing dirty work through diff review, docs migration, gates, and
    commit.
- `/ship-plans`
  - implements named plan files end to end, then migrates durable context and
    closes the plans.
- `/review-*`
  - report-only or review-with-optional-fixes entry points;
  - mutation behavior must be explicit in the registry and skill body.
- `/doctor`
  - validates scaffold shape, manifest/ownership state, registry coverage, and
    stale references.
- `/rebuild-agent-docs`
  - seeds or repairs a consuming repo's docs scaffold and validates the target
    repo, not just the kit checkout.
- `/list-skills`
  - reports canonical source inventory and, if useful, installed adapter
    freshness as separate facts.

## Flow Of Work

- **New chat**
  - Read `docs/index.md` and `docs/overview.md`.
  - Use `/fresh-chat` or `/start-session` when the next action is unclear.
- **Small bug or cleanup**
  - Use `/quick-fix`.
  - One implementation worker, targeted check, docs migration if needed, commit.
- **Medium unclear work**
  - Use `/plan`.
  - Planning worker returns an implementer brief.
  - Implementation follows through `/orchestrate` or `/quick-fix` depending on
    risk.
- **Broad or risky work**
  - Use `/orchestrate`.
  - Planning worker creates/persists tracked plan material.
  - Review worker critiques the plan.
  - Implementation workers ship serial or disjoint streams.
  - Shipped review verifies the outcome.
  - Docs/plan maintenance migrates durable facts.
  - Final gate runs after all mutations.
- **Existing dirty tree**
  - Use `/ship-current-work`.
  - Snapshot status first.
  - Preserve unrelated user changes.
  - Commit only the completed owned slice.
- **Docs drift or scaffold repair**
  - Use `/doctor`, `/check-docs`, `/fix-docs-drift`, or
    `/rebuild-agent-docs`.
  - Keep repo-specific facts in `docs/`; keep generic workflow rules in `v1/`.

## Enforcement Points

- **Installer safety**
  - Tool skill roots are not silently replaced.
  - Managed skill children are copied only after conflict preflight.
- **Verifier clarity**
  - Kit repo checks and consuming-repo scaffold checks are distinct.
  - Local adapter freshness is labeled separately from repo-only drift checks.
- **Registry truth**
  - Every skill has one row.
  - No stale rows.
  - Mode, action, commit behavior, intake, and launch tier are valid.
- **Ownership truth**
  - Every first-class surface has a routing owner.
  - `v1/template/docs/` and command families are explicitly owned.
- **Plan truth**
  - Plans and run docs are temporary.
  - `okay_to_delete` means shipped or abandoned and durable context is migrated
    or absent.
- **Dirty-tree safety**
  - Workers snapshot status, preserve unrelated changes, and stage by filename.

## What This Removes

- Ambiguous "green" states where verification predates final doc/frontmatter
  edits.
- Review workers that can mutate without the implementation/repo rule bundle.
- Claims that scaffold verification checks a target repo when it only checks the
  kit checkout.
- Registry entries that describe commands as non-mutating when their bodies can
  commit.
- Reader confusion between physical checkout, canonical `~/agent-docs`, and
  copied tool skill adapters.

## Why It Is Better

- Agents can resume work from explicit coordination surfaces.
- Users can trust install/copy scripts around personal tool state.
- Consuming repos get a real scaffold validation path.
- Review and implementation authority are mechanically aligned.
- Final verification reflects the actual final state.
- The docs tree stays small because durable facts migrate out of plans and
  routers remain facts-free.

## See Also

- [`agent-docs-hardening.md`](agent-docs-hardening.md)
- [`orchestrator/repo-wide-review-2026-06-19/findings/synthesis.md`](orchestrator/repo-wide-review-2026-06-19/findings/synthesis.md)
- [`../../docs/architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../../docs/architecture/install-and-adapters.md`](../architecture/install-and-adapters.md)
- [`../../docs/decisions/agent-docs.md`](../decisions/agent-docs.md)
