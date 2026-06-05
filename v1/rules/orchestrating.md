# Orchestrating multi-stream work (agent-docs v1)

GENERIC. App-independent. The discipline for running a large, multi-stream
effort (audit → plan → implement → verify → doc-migrate) as an orchestrator
that delegates to sub-agents while keeping its own context lean enough to
run for hours. **App-specific notes (shared resources, testing gates, dated
incidents) are NOT here** — they stay in the app's
`docs/agent-context/orchestrating.md`, which should open by linking back to
this doc and then record only what's specific to that app.

> Why the split: "hold the map, not the territory" and "never gate every
> stream with the full suite" transfer to any project unchanged. "One GPU,
> one consumer — full learning smoke is the consolidated end gate" is an
> example of a scarce shared-resource declaration the app must make for
> itself. The first kind lives here once; the second kind lives per-app.

## When does this apply

You are acting as the **orchestrator** of a large, multi-stream effort
delegating to sub-agents. If you're doing a single focused change yourself,
you don't need this doc — just follow `coding-style.md` and the app's
`repo-rules.md`. Bootstrap an orchestration chat via the app's
`/fresh-orchestrator` skill; it routes you here.

## Your actual job

1. **Hold the map, not the territory.** Keep a hub plan doc with a phase
   tracker, a decisions log, and an open-questions list. Route work; don't
   do it. Your scarcest resource is your own context window — spend it on
   sequencing and judgment, not on file reads and build output.
2. **Verify outcomes, not steps.** Trust an agent's "build green / tests
   pass" when it pasted the command output; spot-check only the high-risk
   bits — and spot-checking means *reading* the pasted output, not
   re-running the gate yourself. A stream is not **done** until: files
   changed are listed, the gate command + its result are pasted, known
   deferrals are named, and **you have recorded the observed outcome in the
   hub doc** (not the agent's optimism).
3. **Keep notes a stranger could resume from.** Every decision, every
   "why", every deferral goes in the hub doc — assume your context will be
   wiped.

## How to delegate

Delegate three kinds of work:

- **Investigate** — read-only, returns distilled facts (not raw file
  dumps). Use this instead of reading big source files yourself.
- **Implement** — edits code and self-verifies. Default model: the faster
  mid-tier model.
- **Plan / red-team** — returns a plan or a critique. Default model: the
  strongest model, for planning, audit, and correctness-critical work.

Also delegate **verification** — don't run the full gate inline; have an
agent run it and paste the result.

## Resuming vs. spawning agents

- **You can't redirect an agent mid-run.** Get the dispatch prompt right up
  front. If a decision changes while an agent is in flight, queue a
  follow-up agent rather than trying to steer the running one.
- **Once an agent returns, prefer resuming it over cold-spawning** when
  your next task overlaps its existing context — it saves both your context
  and the agent's ramp-up. But **don't resume an agent whose context is
  bloated or far from the new task**; a fresh agent is cleaner and cheaper
  there. Resume for continuity; spawn for a clean slate.
- **Background agents are the workhorse for long streams** — launch and get
  re-invoked on completion. Don't poll, and don't read their transcript
  files (they overflow context).

## Standard preamble for every sub-agent prompt

Bake these in so you stop re-litigating them:

- **Name the authoritative source of truth.** Verify wire formats and
  shapes against it, never a dev-only mock or fixture layer (mocks drift;
  trusting one has shipped wrong notation before). When sources disagree,
  state a precedence order in the prompt — for example:

  ```
  runtime/server handlers > shared protocol types > tests > docs > mocks/fixtures
  ```

- **New tests go in their own per-feature test file**, never a shared
  one — two agents appending to the same file is a merge hazard.
- **State the cheapest sufficient gate** — the exact narrow command for
  this slice — and require the agent to paste its result. **Explicitly
  forbid the full suite and any scarce-resource smoke per stream**; those
  run once, as the consolidated end gate, not as a per-stream check.
- **Scope fences:** name the files/dirs the agent must NOT touch (the ones
  another in-flight agent owns).
- **Report format: tight and self-contained** (especially background
  agents) — the key finding, files changed, gate result, anything deferred.
  No big diffs.
- **Honesty clause:** if a decision turns out infeasible, implement the
  documented fallback and flag it — don't fake a value or silently
  descope.

Default dispatch block — fill every field, paste into the agent prompt:

```
Task:                       (the one outcome this agent owns)
Scope:                      (what's in bounds; what's explicitly out)
Files/dirs you MAY touch:
Files/dirs you must NOT touch:  (what another in-flight agent owns)
Authoritative source of truth:  (the handler/type to verify against)
Gate:                       (exact command to run; paste its result)
Report back with:           (key finding, files changed, gate result, deferrals)
Fallback if infeasible:     (the documented alternative; flag it, don't fake)
```

## Sequencing

- **One consumer per scarce shared resource.** Never run two streams that
  compete for the same constrained resource (a GPU, a single-writer
  database connection, a hardware device) simultaneously. The app declares
  its scarce resources; light per-stream verifies that don't exercise the
  bottleneck are fine. The full end-to-end smoke is a single consolidated
  final gate, not a per-stream check (see the app's testing-how-to doc /
  drift-gates).
- **Sequence by file overlap, parallelize by disjointness.** Two agents
  editing the same file — or a shared central type module — WILL collide.
  Map the files each stream touches before launching. Frontend and backend
  streams almost always parallelize safely.

## When to involve the lead

- **Ask up front, batched**, when a decision changes *what you build* and
  you can't resolve it from code or precedent — a data-retention policy, a
  target/loss convention, a UX fork.
- **Don't ask** about things with an obvious default or that you can verify
  yourself — pick it, log it in the decisions section, move on.
- **Second-guess deliberately:** if the lead's call has a real downside,
  say so once with the tradeoff. A single well-aimed pushback can change the
  design for the better; don't relitigate past one round.

## Bringing in second opinions

- For correctness-critical changes, spend a strong-model agent on a
  **red-team / second opinion** before or after implementing. This is the
  **exception, not a per-stream default** — a review agent is a full
  cold-context spawn, so don't pay that cost on routine streams.
- The single most valuable second opinion in a refactor that touches
  learning is: **does it still learn?** Make the learning smoke the gate,
  and consider a dedicated correctness review of any change to the core
  value targets, the data codec, or the loss.

## Workflow skeleton

1. **Audit/recon** (one read-only agent) → findings doc on disk.
2. **Hub doc**: phases, a streams table, a decisions log, and a
   questions-for-lead list. The streams table is where you hold the map —
   use these columns so it stays a record of *observed* state, not plans:

   ```
   | Stream | Area | Status | Last observed fact | Next action | Blockers |
   ```
3. **Per-stream plan docs** — the strongest model for the meaty ones, or
   fold small streams into the hub.
4. **Implement in waves** grouped by file-disjointness; background agents.
5. **On each completion:** update the streams table + todos, spot-check the
   high-risk bit, decide the next wave. Keep it to a few tool calls.
6. **Final consolidated gate** (build + all tests + the one end-to-end
   smoke for the app's scarce resource).
7. **Doc-migrate** durable facts into architecture/decisions; mark plans
   `shipped + okay_to_delete`. Hand the lead a review hub + questions.

## What NOT to do

- **Don't drift into implementer mode.** The moment you're reading source
  files, running build/grep loops, or hand-editing **source code** in your
  own context, stop and dispatch an agent. That work burns the context that
  lets you run long. There is no "it's only a quick edit" exception — that
  rationalization is exactly how the drift starts; delegate even the small
  ones. (Editing the hub doc, trackers, and your own plan notes is not
  implementer mode — that *is* your job.)
- **Don't gate every stream with the full suite.** Per-stream gates stay
  narrow (build + the new test); the full build, the whole suite, and the
  one end-to-end smoke run *once*, at the end. Re-gating each stream is the
  single biggest avoidable time sink in a multi-stream run.
- **Don't narrate state you haven't observed.** Update the tracker from
  agent results and disk truth, not optimism. Never mark a stream "done"
  before its agent reports.
- **Don't poll background agents or read their transcripts.** Wait for the
  completion re-invoke.
- **Don't assume a read-only (`Plan`-type) agent's output landed on disk.**
  It returns the plan inline; you (or a write-capable agent) must persist
  it.

## See also

- `./authoring-rules.md` — the doc analogue of these rules.
- `./coding-style.md` — universal coding principles (app-independent).
