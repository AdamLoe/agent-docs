# Orchestrator dispatch — expanded rationale + examples (do not auto-load)

GENERIC. App-independent. Reference companion to [`dispatch.md`](dispatch.md).
The terse normative contract — packet fields, profile use, worker-report fields,
mutation authority, resume rule, commit concurrency — lives there. This leaf
carries the rationale, the standard preamble checklist, and worked examples.
**Never auto-loaded.** No skill, profile, or role card loads it at startup. Read
it only for the "why" behind a rule in `dispatch.md`.

## Dispatch packet — why each field

The packet passes exact routes, never copied rule bodies, so a worker resolves
its own context and the controlled budget stays measurable. Every field earns
its place:

- **Role/profile** pins the context-profile ID, which fixes the worker's core
  rule loads (see [`../context-profiles.md`](../context-profiles.md)).
- **Task** is the single outcome the worker owns; one worker, one outcome.
- **State basis** (HEAD plus exact dirty paths, or an observed commit) is what
  lets a returned report be checked for staleness later.
- **Authoritative sources** plus precedence tell the worker which source wins
  when two disagree — the worker must never resolve that silently.
- **Input docs/plans/context** carry paths with heading/search hints and the
  starting facts already observed, so the worker does not re-derive them.
- **Resolved bindings** carry path/symbol hints and the conditional overlays the
  task actually triggers.
- **Expected output / checks / report** set the acceptance bar before the worker
  starts.

For large docs or broad source areas, pass the path plus a heading, symbol, or
search hint rather than a summary — the worker reads the authoritative source.
Do not create generated summaries, packet helpers, prompt artifacts, or per-run
context workspaces; the carry-forward summary (≤10 bullets / ≤300 output tokens
of observed facts) is not a substitute for the authoritative docs, source,
plans, or gates.

## Context profiles — how a dispatch names them

Profiles name exact core rule files, conditional overlays, mutation capability,
budgets, and enforcement status in
[`../context-profiles.md`](../context-profiles.md). Skills and dispatches name
profile IDs instead of copying tables. To print the exact files, conditions,
word totals, and budget exceptions:

```sh
bash ~/.agentdocs/verify-agent-docs.sh --context-report
bash ~/.agentdocs/verify-agent-docs.sh --context-report --profile implementation.code
```

Task-owned architecture, decisions, agent-context, plan, source, and test files
remain conditional overlays named in the dispatch, not core profile rules.

## Worker reports — why invalidation conditions matter

A report's value decays as the tree moves. The **invalidation conditions** field
is what makes a returned report safely resumable: it names the changes that would
make the report stale or unsafe to resume from — e.g. "a new commit to any of the
touched files", "a change to the plan's frontmatter", or "any mutation to the
dispatch-named source after HEAD X". Without it, an orchestrator cannot tell
whether a cached worker result still holds after later phases edited the tree.

The other report fields exist for the same reason — to let the orchestrator
verify outcomes without re-running the work: the observed before/after commit and
dirty state, the sources inspected and precedence used, compact evidence for
every finding, touched paths, commit hashes (or an explicit no-change statement),
durable facts needing migration, and blockers/assumptions/residual risk. Routine
reports target ≤600 output tokens; planning/review target ≤1,200 unless the
artifact *is* the report. Passing gates report command, exit code, and the
shortest proof line; failing gates include the shortest useful excerpt.

## Standard preamble — bake into every worker prompt

- Verify against the authoritative source, never a mock or fixture.
- State source precedence when sources disagree.
- Carry forward observed evidence, not full transcripts.
- Put new tests in their own per-feature file.
- Run the cheapest sufficient gate for the slice and report command, exit code,
  and compact proof or failure excerpt.
- Do not run the full suite or scarce-resource smoke per phase; those run once as
  the consolidated end gate.
- If a documented fallback becomes necessary, say so rather than silently
  descoping.

## Mutation authority — rationale

Write capability is deliberately narrow: implementation, docs-maintenance,
plan-maintenance, and tracked planning are the only write-capable profiles.
Review and verification profiles are *always* read-only — they never edit, stage,
or commit. When a read-only worker finds a miss, it returns the evidence and
names the required mutator profile; the orchestrator then routes a fresh
implementation, docs-maintenance, or plan-maintenance worker. This keeps the
"who may write" answer the same in the profile table, the role cards, and the
recipes.

**Selected-plan closeout.** An `implementation.tracked` dispatch may *explicitly*
grant `plan_closeout`. Only with that named grant may the worker close the
selected plan — setting its frontmatter to `status: shipped` and
`okay_to_delete: true` after migration is complete. Without the grant, all
plan-status changes are prohibited even for tracked implementation workers. The
grant is named in the dispatch, not assumed from the profile.

## Resuming — why you cannot redirect mid-run

You cannot redirect a worker mid-run; if a decision changes while a worker is in
flight, queue a follow-up worker. Resume a returned worker only when intervening
changes do not affect its source set, touched paths, acceptance criteria, or
bindings — otherwise require a delta reread or spawn a fresh worker. A final
verification report names the exact commit and dirty state it observed, because
the final gate must observe the state after the last mutation.

## Dispatch failure — why the skill stops

Runtimes are expected to support worker dispatch. If an adapter or environment
cannot spawn a required worker, the skill reports a clear error and stops. It
does not perform the worker's job inline — silently doing the work in the
orchestrator's own context is exactly the implementer-drift the lifecycle
forbids.

## Clean-handoff git invariant — why editing is serial

A mutating worker never hands off unexplained owned dirt; it ends **committed**
(owned slice green and committed), a **clean no-op** (tree clean), or a **blocked
handoff** recording the exact owned dirty paths, the check/gate state, why a safe
commit is impossible, and the resume profile. The blocked-handoff record must be
committed or reverted before final verification — no run ends undischarged. Long
or resume-sensitive work may take constrained checkpoint commits but must not
revive the per-slice micro-commit cadence this replaces. Before editing, a
mutating worker snapshots `git status --short`, preserves unrelated user changes
and deletions, and stages only owned paths by filename; if unrelated dirty state
blocks a coherent slice or a clean gate, it stops with the concrete blocker.

Editing is serial by default because concurrent commits race the git index. Run
at most one editing worker at a time on the shared tree; the next starts only
after it reaches a terminal state. Read-only workers may run in parallel except
when a scarce-resource or final-state gate must observe a specific state. When
parallel editing is worth the cost, give each editing worker its own git
worktree, or have workers return patches the orchestrator applies and commits —
file-ownership fences alone do not make concurrent commits safe.

## See also

- [`dispatch.md`](dispatch.md) — the normative dispatch contract.
- [`lifecycle.md`](lifecycle.md)
- [`../context-profiles.md`](../context-profiles.md)
- [`../subagent/`](../subagent/)
