# Orchestrator dispatch (agent-docs v1)

GENERIC. App-independent. This is the canonical rule for **how an orchestrator
dispatches a worker**: packet shape, context-profile use, worker reports,
dispatch-failure behavior, invalidation, and commit concurrency. Lifecycle and
phase choice live in [`lifecycle.md`](lifecycle.md). Profile definitions live in
[`../context-profiles.md`](../context-profiles.md).

## Dispatch Packet

Pass exact routes, not copied rules. Target `<=350` output tokens for routine
dispatch packets. Fill every field:

```text
Role/profile:               (role plus profile ID from context-profiles.md)
Task:                       (the one outcome this worker owns)
State basis:                (HEAD plus exact dirty paths, or observed commit)
Authoritative sources:      (paths and precedence)
Input docs/plans/context:   (paths, heading/search hints, and starting facts)
Resolved bindings:          (path/symbol hints and conditional overlays)
Expected output:
Expected checks/evidence:   (command, exit code, shortest proof/failure excerpt)
Report back with:           (the worker report fields below)
```

Carry forward only observed facts from prior phases: decisions, proven facts,
touched files, gate evidence, commits, blockers, and assumptions. Keep that
summary to `<=10` bullets or `<=300` output tokens. It is not a substitute for
the authoritative docs, source, plans, or gates.

For large docs or broad source areas, pass the path plus a heading, symbol, or
search hint. Do not create generated summaries, packet helpers, prompt
artifacts, or per-run context workspaces.

## Context Profiles

Profiles name exact core rule files, conditional overlays, mutation capability,
budgets, and enforcement status in [`../context-profiles.md`](../context-profiles.md).
Skills and dispatches name profile IDs instead of copying profile tables.

Use:

```sh
bash ~/.agentdocs/verify-agent-docs.sh --context-report
bash ~/.agentdocs/verify-agent-docs.sh --context-report --profile implementation.code
```

to print exact files, conditions, word totals, and budget exceptions. Task-owned
architecture, decisions, agent-context, plan, source, and test files remain
conditional overlays named in the dispatch.

## Worker Reports

Every worker report includes:

- concise outcome
- **observed commit and dirty-path state** (snapshot before and after editing)
- **sources inspected and precedence used** (name each source; state which wins when sources disagree)
- **evidence** — compact proof or failure excerpt for every finding
- **touched paths** — files edited, staged, or committed (or explicit none)
- **commits** — hash for each commit made, or an explicit no-change statement
- **invalidation conditions** — name the changes that would make this report stale or unsafe to resume from: e.g., "a new commit to any of the touched files", "a change to the plan's frontmatter", or "any mutation to the dispatch-named source after HEAD X"
- durable facts or decisions that need migration
- blockers, assumptions, and residual risk
- raw runtime usage counts only when exposed by the runtime or explicitly asked

Routine reports target `<=600` output tokens. Planning and review reports target
`<=1,200` unless the requested artifact is the report. Passing gates report the
command, exit code, and shortest proof line; failing gates include the shortest
useful excerpt.

## Mutation Authority

Implementation, docs-maintenance, plan-maintenance, and tracked planning are the
write-capable profiles. Review and verification profiles are always read-only —
they never edit, stage, or commit. When they find a miss, they return the
evidence and name the required mutator profile; the orchestrator routes a new
implementation, docs-maintenance, or plan-maintenance worker.

**Selected-plan closeout (`plan_closeout` grant):** An `implementation.tracked`
dispatch may explicitly grant `plan_closeout`. Only with that named grant may the
worker close the selected plan — setting its frontmatter to `status: shipped` and
`okay_to_delete: true` after migration is complete. Without the grant, all
plan-status changes are prohibited even for tracked implementation workers.

## Resuming

You cannot redirect a worker mid-run. If a decision changes while a worker is in
flight, queue a follow-up worker. Resume a returned worker only when intervening
changes do not affect its source set, touched paths, acceptance criteria, or
bindings. Otherwise require a delta reread or spawn a fresh worker. A final
verification report names the exact commit and dirty state it observed.

## Standard Preamble

Bake these into every worker prompt:

- Verify against the authoritative source, never a mock or fixture.
- State source precedence when sources disagree.
- Carry forward observed evidence, not full transcripts.
- Put new tests in their own per-feature file.
- Run the cheapest sufficient gate for the slice and report command, exit code,
  and compact proof or failure excerpt.
- Do not run the full suite or scarce-resource smoke per phase; those run once
  as the consolidated end gate.
- If a documented fallback becomes necessary, say so rather than silently
  descoping.

## Dispatch Failure

Runtimes are expected to support worker dispatch. If an adapter or environment
cannot spawn a required worker, the skill reports a clear error and stops. It
does not perform the worker's job inline.

## Commit Concurrency

The workflow is commit-heavy by design. Workers that edit repo files commit
their completed slice before reporting. Later workers may repair or revert with
additional commits. The orchestrator records commit hashes and verifies the
final observed state.

Before a mutating worker edits, it snapshots `git status --short`, preserves
unrelated user changes and deletions, and stages only owned paths by filename.
If unrelated dirty state blocks a coherent slice or clean gate result, the
worker stops with the concrete blocker.

Editing is serial by default because concurrent commits race the git index. Run
at most one editing worker at a time on the shared working tree; it commits its
slice before the next editing worker starts. Read-only workers may run in
parallel except when a scarce-resource or final-state gate must observe a
specific state.

When parallel editing is worth the cost, give each editing worker its own git
worktree, or have workers return patches that the orchestrator applies and
commits. File-ownership fences alone do not make concurrent commits safe.

## See also

- [`lifecycle.md`](lifecycle.md)
- [`run-docs.md`](run-docs.md)
- [`../context-profiles.md`](../context-profiles.md)
- [`../subagent/`](../subagent/)
