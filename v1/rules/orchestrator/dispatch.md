# Orchestrator dispatch (agent-docs v1)

GENERIC. App-independent. This is the canonical rule for **how an orchestrator
dispatches a worker**: the packet shape, the rule bundles a worker receives, the
report a worker returns, dispatch-failure behavior, and commit concurrency.
Lifecycle and phase choice live in [`lifecycle.md`](lifecycle.md).

## Dispatch packet

Pass **exact rule-file links** to each worker. Do not copy full rules into the
prompt, and do not tell a worker to discover the workflow system. Keep dispatch
minimal; it routes work, it does not replace planning investigation. Fill every
field:

```text
Role:                       (planning | implementation | review | docs-maintenance | plan-maintenance | verification)
Task:                       (the one outcome this worker owns)
Input docs/plans/context:   (paths and facts the worker starts from)
Read these exact rules:
- <rule file>
- <rule file>
Expected output:
Expected checks/evidence:   (the cheapest sufficient gate; paste its result)
Report back with:           (the worker report fields below)
```

Also include a concise carry-forward summary when prior worker evidence matters:

```text
Observed so far:
- decisions made
- facts proven
- files/docs touched
- gates run and pasted results
- commits, blockers, assumptions
```

Avoid detailed file-ownership fences unless parallel workers are likely to
collide; planning and implementation workers identify their own touched files
after reading the task. Fences address read/analysis overlap, not commit safety
— concurrent editing uses the serial-commit or worktree rule below.

## Planner-produced implementation briefs

For already bounded work, the dispatch can go straight to implementation with
the task, starting inputs, rules, checks, and report shape above.

For unclear or medium work, dispatch a planning worker first. The planning worker
owns the implementer-ready brief fields:

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

The orchestrator may pass the planner's brief through to an implementation
worker after adding the worker role, exact rules, observed-so-far summary,
expected evidence, and report shape. Do not invent packet helper scripts,
generated context bundles, or workspace files for this handoff.

## Worker report

Every worker report includes:

- concise outcome
- files/docs touched or inspected
- checks run and result
- durable facts or decisions that need migration
- blockers, assumptions, and residual risk
- **commit hash for edited work, or a clear no-change report for read-only work**

## Rule bundles

Shorthand the orchestrator expands into exact `Read these exact rules` links.
Universal rules ([`../skill-contracts.md`](../skill-contracts.md),
[`../repo-rules.md`](../repo-rules.md),
[`../authoring-rules.md`](../authoring-rules.md),
[`../coding-style.md`](../coding-style.md)) are added per role as listed.

| Bundle | Rule files |
|---|---|
| Orchestrator core | `v1/rules/skill-contracts.md`, `v1/rules/orchestrator/lifecycle.md`, `v1/rules/orchestrator/dispatch.md` |
| Stateful orchestration | Orchestrator core + `v1/rules/orchestrator/run-docs.md`, `v1/plan-lifecycle.md` |
| Planning worker | `v1/rules/subagent/planning.md`, `v1/plan-lifecycle.md`, `v1/plan-template.md` |
| Implementation worker | `v1/rules/subagent/implementation.md`, `v1/rules/coding-style.md`, `v1/rules/authoring-rules.md`, `v1/rules/repo-rules.md` |
| Review worker | `v1/rules/subagent/review.md`, plus the role-specific source being reviewed |
| Docs-maintenance worker | `v1/rules/subagent/docs-maintenance.md`, `v1/rules/authoring-rules.md` |
| Plan-maintenance worker | `v1/rules/subagent/plan-maintenance.md`, `v1/plan-lifecycle.md`, `v1/rules/authoring-rules.md` |
| Verification worker | `v1/rules/subagent/verification.md`, `v1/rules/repo-rules.md` |

## Resuming vs. spawning

- **You can't redirect a worker mid-run.** Get the dispatch right up front. If a
  decision changes while a worker is in flight, queue a follow-up worker rather
  than steering the running one.
- **Once a worker returns, prefer resuming it** when the next task overlaps its
  context — it saves ramp-up. But spawn fresh when its context is bloated or far
  from the new task. Resume for continuity; spawn for a clean slate.
- **Background workers are the workhorse for long streams** — launch and get
  re-invoked on completion. Don't poll; don't read their transcripts.

## Standard preamble

Bake these into every worker prompt so you stop re-litigating them:

- **Name the authoritative source of truth.** Verify shapes against it, never a
  mock or fixture. When sources disagree, state a precedence order.
- **Carry forward observed evidence.** Give the next worker the concise
  decisions/facts/checks/commits it needs, not full prior transcripts.
- **New tests go in their own per-feature file**, never a shared one — two
  workers appending to one file is a merge hazard.
- **State the cheapest sufficient gate** for the slice and require the worker to
  paste its result. Forbid the full suite and scarce-resource smoke per phase;
  those run once as the consolidated end gate.
- **Report format: tight and self-contained** — key finding, files changed, gate
  result, deferrals. No big diffs.
- **Honesty clause:** if a decision turns out infeasible, implement the
  documented fallback and flag it — don't fake a value or silently descope.

## Dispatch failure

Runtimes are expected to support worker dispatch; Claude Code, Codex, and similar
adapters own the mechanics. If an adapter or environment cannot spawn a required
worker, the skill **reports a clear error and stops**. It does not fall back to
running the worker's job inline.

## Commit concurrency

The workflow is commit-heavy by design. Workers that edit repo files **commit
their own completed slice before reporting**. Later workers may repair or revert
earlier commits with additional commits. The orchestrator records commit hashes
and verifies the final observed state; local history is allowed to be
commit-heavy because the user can squash later.

**Editing is serial by default** because concurrent commits race the git index.
Run at most one editing worker at a time on the shared working tree; it commits
its slice before the next editing worker starts. Read-only workers (planning
investigation, review, verification) run in parallel at any time.

When parallel editing is worth the cost, give each editing worker its own git
worktree and integrate afterward, or have workers return patches that the
orchestrator applies and commits itself. File-ownership fences alone do not make
concurrent commits safe.

## See also

- [`lifecycle.md`](lifecycle.md) — classification, phases, dials, sequencing.
- [`run-docs.md`](run-docs.md) — opt-in run folders.
- [`../subagent/`](../subagent/) — the worker-role rules referenced by the bundles.
