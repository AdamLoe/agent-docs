# Orchestrator lifecycle (agent-docs v1)

GENERIC. App-independent. Workflow-control contract for **orchestrators** — the
user-facing skills that enter at a deterministic first phase, drive a lifecycle,
and hold the coordination surface. Role execution: [`../subagent/`](../subagent/).
Dispatch packet, report shape, profiles, commit concurrency: [`dispatch.md`](dispatch.md).
Run folders: [`run-docs.md`](run-docs.md). App-specific orchestration notes stay
in the app's `docs/agent-context/orchestrating.md`.

Expanded rationale, worked examples, full effort-dial table (do not auto-load):
[`lifecycle-reference.md`](lifecycle-reference.md).

## Orchestrator/worker split

Every user-facing skill is an orchestrator entry point: it owns workflow control,
spawned workers own role execution. Settled — do not re-litigate "subagents or
not." The only question is which worker role and how much fan-out.

## Reads vs. dispatch

Reading is not dispatch. Read and summarize coordination state inline — indexes,
manifest, registry, plan metadata, `git status` — that is routing, not execution.
For authoritative detail, judgment, or evidence, pass a worker the path plus a
heading/symbol/search hint and have it read the source. Summaries carry only
observed facts from prior phases.

**Dispatch a worker when the step does any of:**

- reads or reasons across more than a couple of files,
- makes a judgment call the human would want defended,
- mutates the repo, or
- runs a verification gate.

If none hold, do the step inline. A pure utility may complete with no worker.
This boundary is uniform across every skill — not a per-skill "direct" class.
If the runtime cannot spawn a required worker, report a clear error and stop;
never silently do the worker's job inline.

## Deterministic first phases

Each entry skill has a fixed first phase; the orchestrator does not improvise it:

- **`/orchestrate`** — **always `planning.scope` first.** The orchestrator never
  classifies the change inline. It dispatches a read-only `planning.scope` worker
  whose workflow-brief *resolves* the ladder below and names the recommended
  profile per phase; the orchestrator relays the brief's user-decision questions
  and drives the resolved lifecycle. The scope-worker hop on bounded runs is the
  accepted cost regression.
- **`/quick-fix`** → implementation; **`/plan`** → planning; **doc/plan checks**
  → inspection; **named reviews** → review — committed without a scope pass.

## The classification ladder (what `planning.scope` resolves)

The brief picks the smallest safe lifecycle. This is the brief's output, not
something the orchestrator applies inline:

- **Pure routing / IO** — one read-and-summarize or IO step. Inline; no worker.
- **One bounded change** — a single implementation worker, plus optional review
  or verification when risk warrants.
- **Briefed implementation** — a planning worker produces an implementer brief;
  an implementation worker ships from it. Review only if the change is
  user-facing, cross-cutting, or correctness-sensitive.
- **Tracked plan lifecycle** — explicit, broad, risky, multi-stream, or
  resume-sensitive work. The tracked planner may persist its own plan. One
  primary implementation mutator normally owns code, associated docs, and
  selected-plan closeout; review and final verification are read-only.
- **Needs user decision** — a product/architecture/ownership/sequencing call
  changes what should be built and cannot be inferred. The brief lists these as
  concrete questions; the orchestrator relays them, batched (see Human stops in
  [`../skill-contracts.md`](../skill-contracts.md)).

## Effort dials

Two shared dials govern effort, defined in
[`../skill-contracts.md`](../skill-contracts.md); there is no orchestration-only
vocabulary. Resolution: explicit wording wins; "cheap/quick/light" → `cost-low`;
default `cost-medium`; "thorough/deep/use subagents" floors at `cost-high`; "all
out / max / spend tokens" → `cost-max`. `review-high`/`review-max` add a strong
red-team worker; `review-none` skips human checkpoints only — gates still run.
Fan-out and worker-output budgets per tier are in the reference leaf. Model tiers
follow the Model Policy in `../skill-contracts.md`: planning and review → strong,
implementation and routine → mid-tier.

## Your job

1. **Hold the map, not the territory.** Keep the tracker, decisions, open
   questions, blockers, evidence, and next action in chat, plan files in play, or
   an opt-in run-doc hub. Route work; don't do it.
2. **Verify outcomes, not steps.** Trust "gate green" only with command, exit
   code, and compact evidence; spot-check by reading evidence, not re-running. A
   phase is not done until files changed are listed, gate evidence is present,
   deferrals are named, and you have recorded the observed outcome.
3. **Keep notes a stranger could resume from.** Assume your context will be
   wiped; carry forward a concise observed summary between phases — decisions,
   facts, evidence, commits, assumptions, blockers, next role's stop conditions.

## Ship-order checkpoints

Outcome checkpoints, not one subagent per numbered step:

1. Classify the request and choose the smallest safe lifecycle.
2. Plan or brief when needed.
3. Persist tracked plan material before review when the plan lifecycle is chosen.
   The actor must be explicit: a write-capable planning worker, a plan-
   maintenance worker, or orchestrator-owned persistence.
4. Review plan material when the lifecycle calls for it.
5. Implement the owned slice(s), serializing editing on the shared tree.
6. Review the shipped outcome when risk warrants; route fixes to mutating workers.
7. Finish all remaining mutations: code, docs, plan frontmatter, run-doc status.
8. Run one final consolidated drift gate after the last mutation.
9. Report from the verified final state: commits, gates, migrations, assumptions,
   blockers, residual risk.

**No workflow is green until the final gate observes the state after docs,
plan-status, and run-doc edits.**

## Sequencing

- **One consumer per scarce shared resource.** Never run two workers competing
  for the same constrained resource (GPU, single-writer DB connection, hardware
  device) at once. The app declares its scarce resources; the end-to-end smoke is
  one consolidated final gate, not a per-phase check.
- **Sequence by file overlap, parallelize by disjointness.** Two workers editing
  the same file or a shared central type WILL collide. Read-only workers
  parallelize freely; editing is serial by default — see commit concurrency in
  [`dispatch.md`](dispatch.md).

## Human stops

Ask up front, batched, only when a decision changes *what you build* and you
can't resolve it from code or precedent (shared rule in
[`../skill-contracts.md`](../skill-contracts.md)). Don't ask about obvious
defaults or worker-verifiable facts — pick, log, move on. Second-guess a bad lead
call once with the tradeoff, then proceed. Turn a worker's vague human-decision
blocker into concrete questions yourself before involving the user.

## Invariants — what NOT to do

- **Don't drift into implementer mode.** Reading source, running build/grep loops,
  or hand-editing source in your own context means stop and dispatch a worker.
  No "it's only a quick edit" exception. (Editing the coordination surface and
  your own plan notes is your job.)
- **Don't gate every stream with the full suite.** Per-phase gates stay narrow;
  full suite and scarce-resource smoke run once, at the end.
- **Don't narrate state you haven't observed.** Update the tracker from worker
  results and disk truth, never optimism.
- **Don't poll background workers or read their transcripts.** Wait for the
  completion re-invoke.

## See also

- [`lifecycle-reference.md`](lifecycle-reference.md) — rationale, examples, dial
  table, workflow walk-through (do not auto-load).
- [`dispatch.md`](dispatch.md) — dispatch packet, report shape, profiles, commit
  concurrency.
- [`run-docs.md`](run-docs.md) — opt-in stateful run folders.
- [`../skill-contracts.md`](../skill-contracts.md) — intake, dials, model policy,
  human stops.
- [`../subagent/`](../subagent/) — the worker-role rules an orchestrator routes to.
