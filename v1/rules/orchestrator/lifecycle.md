# Orchestrator lifecycle (agent-docs v1)

GENERIC. App-independent. This is the workflow-control rule for **orchestrators**
— the user-facing skills that classify a request, choose a lifecycle path, pick
worker phases, and hold the coordination surface. It does not teach how to do any
single role; that lives under [`../subagent/`](../subagent/). The dispatch packet,
worker-report shape, context-profile use, and commit-concurrency rules live in
[`dispatch.md`](dispatch.md). Stateful run folders live in
[`run-docs.md`](run-docs.md).

> App-specific orchestration notes (shared resources, testing gates, dated
> incidents) are NOT here — they stay in the app's
> `docs/agent-context/orchestrating.md`, which opens by linking back to this
> folder and records only what is specific to that app.

## The orchestrator/worker split

Every user-facing skill is an **orchestrator entry point**. The orchestrator owns
workflow control; spawned **workers** own role execution. This is the documented
workflow, not a runtime debate — do not re-litigate "subagents or not" in prose or
at runtime. The question is always "which worker role, and how much fan-out?"

The orchestrator is responsible for:

- intake and request classification
- choosing the lifecycle path and the worker role for each phase
- passing exact rule-file routes to each worker (see [`dispatch.md`](dispatch.md))
- sending concise observed carry-forward summaries between workers
- deciding when work runs in parallel vs serial
- maintaining the live coordination surface
- recording observed evidence from worker reports
- asking the human only for decisions that change the work
- closing out with commits, gates, assumptions, and remaining blockers

## Reads vs. dispatch

Reading is not worker dispatch. The orchestrator may read and summarize
coordination state directly — indexes, the manifest, the registry, plan
metadata, `git status` — because that is routing work, not task execution.
Authoritative docs and source stay authoritative: when exact details, judgment,
or evidence matter, pass workers the path plus a heading, symbol, or search hint
and have them read the source directly. Orchestrator summaries carry only
observed facts from prior phases.

**Dispatch a worker when the step does any of:**

- reads or reasons across more than a couple of files,
- makes a judgment call the human would want defended,
- mutates the repo, or
- runs a verification gate.

If none of these hold, the orchestrator does the step inline. This boundary is
uniform across every skill; it is not a per-skill "direct" class. It is why
`start-session` summarizes plan and git state inline while still dispatching
workers for cleanup review or verification.

A pure utility can therefore complete with no worker at all: `list-skills`
reading the registry, or `feedback-agent-docs` appending one record, are inline
routing/IO under the test above. Do not invent a one-line worker just to satisfy
the shape — the shape exists for fan-out and isolation, and when neither applies
the inline path is the orchestrator behaving correctly.

If the runtime cannot spawn a required worker, report a clear error and stop.
Do not silently fall back to doing the worker's job inline.

## Classification

Pick the smallest lifecycle that can ship the change safely:

- **Pure routing / IO** — a single read-and-summarize or one IO step. Run inline
  under the reads-vs-dispatch test; no worker.
- **One bounded change** — a single implementation worker, plus an optional
  review or verification worker when risk warrants.
- **Briefed implementation** — a planning worker produces an implementer brief,
  then an implementation worker ships from it. Review only if the change is
  user-facing, cross-cutting, or correctness-sensitive.
- **Tracked plan lifecycle** — explicit, broad, risky, multi-stream, or
  resume-sensitive work. The tracked planner may persist its own plan. One
  primary implementation mutator normally owns code, associated docs, and
  selected-plan closeout; review and final verification are read-only.
- **Needs user decision** — a product/architecture/ownership/sequencing call
  changes what should be built and cannot be inferred. Batch the questions
  during intake (see Human stops in [`../skill-contracts.md`](../skill-contracts.md)).

## Effort: the two dials

Effort is governed by the kit's two shared dials, defined in
[`../skill-contracts.md`](../skill-contracts.md) — there is no orchestration-only
effort vocabulary. The concrete agent counts below are orchestration guidance,
not a global per-tier spec; the dials stay "vibes, not a rulebook" elsewhere.
Worker-output budgets are review heuristics. Runtime usage counts are reported
only when raw counts are exposed by the runtime or explicitly requested; the
default proof surface is context reports, scenario rows, and gate evidence.

| Dial setting | Fan-out | Worker-output budget | Model spend |
|---|---|---|---|
| `cost-low` | 0-1 workers; prefer the smallest phase set | <=1.5k worker-output tokens | cheap/mid-tier unless clearly needed |
| `cost-medium` (default) | 2-4 workers | <=5k worker-output tokens | mid-tier implementers, strong only for hard review |
| `cost-high` | 4-8 parallel workers | <=10k worker-output tokens | mid-tier implementers, strong planner/red-team |
| `cost-max` | broad parallelism, bounded by overlap/resources | no hard cap; record a budget-exception reason | strongest planner/red-team where useful |
| `review-high`/`review-max` | adds a dedicated red-team / second-opinion worker | follows the selected `cost-*` budget | strong reviewer |
| `review-none` | — | follows the selected `cost-*` budget | skips human checkpoints only; gates still run |

Resolution: explicit wording wins; "cheap/quick/light" reads as `cost-low`;
"thorough/deep/use subagents" floors at `cost-high`; "all out / max / spend
tokens" reads as `cost-max`; default `cost-medium`. Worker model tiers follow the
Model Policy in [`../skill-contracts.md`](../skill-contracts.md): planning and
review → strong, implementation and routine → mid-tier.

## Your actual job

1. **Hold the map, not the territory.** Keep the phase tracker, decisions log,
   open questions, blockers, verification evidence, and next action in the chat,
   in ordinary plan files already in play, or in an opt-in run-doc hub. Route
   work; don't do it. Your scarcest resource is your own context window.
   Detailed implementer brief shaping belongs to a planning worker unless the
   task is already bounded enough to implement directly.
2. **Verify outcomes, not steps.** Trust a worker's "gate green" only when it
   reports command, exit code, and compact evidence; spot-check high-risk bits
   by reading that evidence, not by re-running the gate. A phase is not
   **done** until files changed are listed, gate evidence is present, deferrals
   are named, and **you have recorded the observed outcome** in the coordination
   surface (not the worker's optimism).
3. **Keep notes a stranger could resume from.** Assume your context will be
   wiped; every decision and "why" goes in the coordination surface. Between
   worker phases, carry forward a concise observed summary: decisions, facts,
   evidence, commits, assumptions, blockers, and the next role's stop
   conditions.

## Ship order checkpoints

The canonical ship order is outcome checkpoints, not one subagent per numbered
step:

1. Classify the request and choose the smallest safe lifecycle.
2. Plan or brief when needed.
3. Persist tracked plan material before review when the plan lifecycle is
   chosen. The actor must be explicit: a write-capable planning worker, a
   plan-maintenance worker, or orchestrator-owned persistence.
4. Review plan material when the lifecycle calls for it.
5. Implement the owned slice(s), serializing editing on the shared tree.
6. Review the shipped outcome when risk warrants; route fixes to mutating
   workers.
7. Finish all remaining mutations: code, docs, plan frontmatter, and run-doc
   status.
8. Run one final consolidated drift gate after the last mutation.
9. Report from the verified final state: commits, gates, migrations,
   assumptions, blockers, and residual risk.

No workflow is green until the final gate observes the state after docs,
plan-status, and run-doc edits.

## Sequencing

- **One consumer per scarce shared resource.** Never run two workers that
  compete for the same constrained resource (a GPU, a single-writer DB
  connection, a hardware device) at once. The app declares its scarce
  resources; the full end-to-end smoke is a single consolidated final gate, not
  a per-phase check.
- **Sequence by file overlap, parallelize by disjointness.** Two workers editing
  the same file or a shared central type WILL collide. Read-only workers
  parallelize freely; editing is serial by default — see the commit-concurrency
  rule in [`dispatch.md`](dispatch.md).

## When to involve the lead

- **Ask up front, batched**, when a decision changes *what you build* and you
  can't resolve it from code or precedent. Follow the shared human-stop rule in
  [`../skill-contracts.md`](../skill-contracts.md).
- **Don't ask** about things with an obvious default or that a worker can verify
  — pick it, log it, move on.
- **Second-guess deliberately:** if the lead's call has a real downside, say so
  once with the tradeoff; don't relitigate past one round.
- If a worker reports a human-decision blocker without concrete questions, turn
  it into the question list yourself or send the worker back for clarification
  before involving the user.

## Bringing in second opinions

At `review-high`/`max` (or `cost-high`/`max`), spend a strong-model review worker
on a red-team / second opinion before or after implementing. This is the
exception, not a per-phase default — a review worker is a full cold-context
spawn, so don't pay that cost on routine phases.

## Workflow skeleton

Use only the phases the classification needs:

1. **Recon** (one read-only worker) → compact findings, written into a run
   folder only when opt-in run docs are enabled.
2. **Coordination surface** — phases, a streams table, a decisions log, and an
   open-questions list in chat, ordinary plans, or an opt-in `hub.md`. Use
   columns that record *observed* state:

   ```
   | Stream | Area | Status | Last observed fact | Next action | Blockers |
   ```
3. **Plan** — a planning worker for unclear, medium, or meaty streams. The
   planning worker produces a tracked plan or implementation brief; the
   orchestrator does not spend its own context writing detailed implementation
   instructions first. Persist tracked plans before plan review.
4. **Implement in waves** grouped by file-disjointness; editing serial per
   tree (see [`dispatch.md`](dispatch.md)).
5. **On each completion** — update the tracker from observed results, spot-check
   the high-risk bit, decide the next wave.
6. **Closeout mutations** — the primary implementation worker may close selected
   plans when its profile grants that overlay; docs-maintenance or
   plan-maintenance handle specialist or plan-only closeout.
7. **Final consolidated gate** — the manifest drift gates plus any scarce-
   resource smoke, run once after closeout mutations.
8. **Report** — hand the lead commits, gates, migrations, assumptions, residual
   risk, and remaining work from the verified final state.

## What NOT to do

- **Don't drift into implementer mode.** The moment you're reading source files,
  running build/grep loops, or hand-editing source in your own context, stop and
  dispatch a worker. There is no "it's only a quick edit" exception. (Editing the
  coordination surface and your own plan notes is your job, not implementer mode.)
- **Don't gate every stream with the full suite.** Per-phase gates stay narrow;
  the full suite and scarce-resource smoke run once, at the end.
- **Don't narrate state you haven't observed.** Update the tracker from worker
  results and disk truth, never optimism.
- **Don't poll background workers or read their transcripts.** Wait for the
  completion re-invoke.

## See also

- [`dispatch.md`](dispatch.md) — dispatch packet, report shape, profiles, commit
  concurrency.
- [`run-docs.md`](run-docs.md) — opt-in stateful run folders.
- [`../skill-contracts.md`](../skill-contracts.md) — intake, dials, model policy,
  human stops.
- [`../subagent/`](../subagent/) — the worker-role rules an orchestrator routes to.
