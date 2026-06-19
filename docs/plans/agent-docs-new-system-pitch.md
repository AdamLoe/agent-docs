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

Every mutating lifecycle should converge on one order:

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
