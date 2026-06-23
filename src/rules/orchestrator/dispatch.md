# Orchestrator dispatch (agent-docs v1)

GENERIC. App-independent. The canonical rule for **how an orchestrator dispatches
a worker**: packet shape, context-profile use, worker reports, mutation
authority, resume, dispatch-failure behavior, and the clean-handoff git
invariant. Lifecycle and phase choice live in [`lifecycle.md`](lifecycle.md).
Profile definitions live in [`../context-profiles.md`](../context-profiles.md).

Expanded rationale + examples + standard preamble (do not auto-load):
[`dispatch-reference.md`](dispatch-reference.md).

## Dispatch Packet

Pass exact routes, not copied rules. Target `<=350` output tokens for routine
packets. Fill every field:

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

Carry forward only observed facts from prior phases (decisions, proven facts,
touched files, gate evidence, commits, blockers, assumptions): `<=10` bullets or
`<=300` output tokens. It is not a substitute for the authoritative docs, source,
plans, or gates. For large docs or broad source, pass the path plus a
heading/symbol/search hint. Do not create generated summaries, packet helpers,
prompt artifacts, or per-run context workspaces.

## Context Profiles

Profiles name exact core rule files, conditional overlays, mutation capability,
budgets, and enforcement status in
[`../context-profiles.md`](../context-profiles.md). Skills and dispatches name
profile IDs instead of copying tables. Use
`bash ~/.agentdocs/verify-agent-docs.sh --context-report [--profile <id>]` to
print exact files, conditions, word totals, and budget exceptions. Task-owned
architecture, decisions, agent-context, plan, source, and test files remain
conditional overlays named in the dispatch.

## Worker Reports

Every worker report includes:

- concise outcome
- **observed commit and dirty-path state** (snapshot before and after editing)
- **sources inspected and precedence used** (name each; state which wins when sources disagree)
- **evidence** — compact proof or failure excerpt for every finding
- **touched paths** — files edited, staged, or committed (or explicit none)
- **commits** — hash for each commit made, or an explicit no-change statement
- **invalidation conditions** — the changes that would make this report stale or
  unsafe to resume from: e.g. "a new commit to any touched file", "a change to
  the plan's frontmatter", or "any mutation to the dispatch-named source after
  HEAD X"
- durable facts or decisions that need migration
- blockers, assumptions, and residual risk
- raw runtime usage counts only when exposed by the runtime or explicitly asked

Routine reports target `<=600` output tokens; planning/review `<=1,200` unless
the requested artifact is the report. Passing gates report command, exit code,
and the shortest proof line; failing gates include the shortest useful excerpt.

## Mutation Authority

Implementation, docs-maintenance, plan-maintenance, and tracked planning are the
write-capable profiles. Review and verification profiles are always read-only —
they never edit, stage, or commit. When they find a miss, they return the
evidence and name the required mutator profile; the orchestrator routes a new
implementation, docs-maintenance, or plan-maintenance worker.

**Selected-plan closeout (`plan_closeout` grant):** an `implementation.tracked`
dispatch may explicitly grant `plan_closeout`. Only with that named grant may the
worker close the selected plan — setting frontmatter to `status: shipped` and
`okay_to_delete: true` after migration is complete. Without the grant, all
plan-status changes are prohibited even for tracked implementation workers.

**No self-upgrade of write authority.** A worker's role and mutation capability
are fixed by the profile its dispatch names; discovery never raises them. After
discovery a worker may *request* an allowed pack from the orchestrator (the
repo's `execution.yaml` pack routes are the allowlist), but it may not change
role, gain mutation capability, or grant itself a mutator pack. A read-only
profile (`review.*`, `verification.readonly`, `docs.inspect`, `plans.inspect`)
stays read-only: it returns findings and names the mutator profile the
orchestrator must route. The dispatch enforces this — it names the profile's
fixed `mutation_capability`, so a read-only profile is never turned into a
mutating capability or a mutator pack. A worker that needs write authority it was
not dispatched with stops and reports; it does not self-elevate. (The kit author
can confirm the same merge with the source-only aid
`bash src/verify-agent-docs.sh --resolve --skill <name> [--risk <tag>]`, which
needs the kernel and so runs only in the source checkout, never at runtime.)

## Resuming

You cannot redirect a worker mid-run; if a decision changes while a worker is in
flight, queue a follow-up worker. Resume a returned worker only when intervening
changes do not affect its source set, touched paths, acceptance criteria, or
bindings — otherwise require a delta reread or a fresh worker. A final
verification report names the exact commit and dirty state it observed.

## Dispatch Failure

Runtimes are expected to support worker dispatch. If an adapter or environment
cannot spawn a required worker, the skill reports a clear error and stops. It
does not perform the worker's job inline.

## Clean-Handoff Git Invariant

A mutating worker **never hands off unexplained owned dirt.** It ends in exactly
one of three terminal states:

1. **committed** — owned slice committed, its gate green;
2. **clean no-op** — nothing to change, tree left clean;
3. **blocked handoff** — records the exact owned dirty paths, the check/gate
   state, why a safe commit is impossible, and the resume profile to continue
   from.

**Discharge gate.** A blocked-handoff record must be committed or reverted before
final verification — no run ends with an undischarged blocked handoff. Long or
resume-sensitive work may take **constrained checkpoint commits** but must not
revive the per-slice micro-commit cadence this invariant replaces. Before
editing, a worker snapshots `git status --short`, preserves unrelated user
changes and deletions, and stages only owned paths by filename; if unrelated dirt
blocks a coherent slice or clean gate, it stops with the concrete blocker.

Editing is serial by default because concurrent commits race the git index. Run
at most one editing worker at a time on the shared tree; the next starts only
after it reaches a terminal state. Read-only workers may run in parallel except
when a scarce-resource or final-state gate must observe a specific state. When
parallel editing is worth the cost, give each editing worker its own git
worktree, or have workers return patches the orchestrator applies and commits;
file-ownership fences alone do not make concurrent commits safe.

## See also

- [`dispatch-reference.md`](dispatch-reference.md) — rationale, preamble, examples (do not auto-load).
- [`lifecycle.md`](lifecycle.md)
- [`run-docs.md`](run-docs.md)
- [`../context-profiles.md`](../context-profiles.md)
- [`../subagent/`](../subagent/)
