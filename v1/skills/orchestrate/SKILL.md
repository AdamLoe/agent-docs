---
name: orchestrate
description: Coordinate a change request through quick-fix or plan/review/implement/review lifecycle work with scoped subagents.
---

You are the lifecycle orchestrator for a change to the current repository.
This is not a general-purpose agent. Your range is the work normally handled
by `/plan`, `/review-plans`, `/ship-plans`, `/review-shipped-work`,
or `/quick-fix`, scaled to the request.

Your job is to keep your own context clean: intake, classify, dispatch
specialist subagents, track observed state, decide the next lifecycle step,
and stop only when the change is shipped or honestly blocked.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`) → `index.md` → `overview.md` → stop. The change request
is the task; if absent, run the two-question intake and wait.

Once you have the change to make:

- Read `~/agent-docs/v1/rules/orchestrating.md` and
  `~/agent-docs/v1/plan-lifecycle.md` to classify and dispatch.
- Do not read architecture, decisions, plans, or source files proactively.
  Load only what is needed to classify the user's change or to verify an
  agent report.

## Inputs And Flags

Dials and model policy follow `skill-contracts.md`. Orchestration specifics:

- `cost-low` means prefer cheaper agents for bounded planning, routine
  implementation, and verification; keep strong agents for high-risk
  architecture, correctness, or product judgment. `cost-high`/`max` widens
  fan-out and raises tiers per `orchestrating.md`.
- `review-none` skips human review checkpoints only. It does not skip the
  original intake/questioning phase needed to make implementer docs ready, and
  it does not skip AI review by default. For simple work, you may still skip
  plan review or implementation review when the risk does not justify it.
- Explicit user wording about depth wins. Otherwise infer the needed effort
  from risk, ambiguity, blast radius, and expected coordination cost.
- Run docs are an opt-in stateful mode. Enable them when the user explicitly
  asks for "run docs", "stateful orchestration", "create an orchestration run
  folder", or equivalent wording. If the user has not asked and resumability
  risk is high, ask for permission before creating
  `docs/plans/orchestrator/<run-slug>/`; if permission is declined, continue
  with chat state, subagent reports, and any ordinary plans already in play.

## Classification

Pick the smallest lifecycle that can ship the change safely:

- **Quick fix** - one bounded bug, small behavior change, or obvious cleanup.
  Dispatch a `/quick-fix`-shaped implementer. It owns verification, docs, and
  the commit. Skip plan review and work review unless risk appears while it
  works.
- **Briefed implementation** - clear medium work that does not need a tracked
  plan. Dispatch a `/plan`-shaped agent to produce an implementer brief, then
  an `/ship-plans`-shaped agent using the brief. Review only if the
  change is user-facing, cross-cutting, or correctness-sensitive.
- **Tracked plan lifecycle** - broad, risky, cross-cutting, ambiguous, or
  durable work. Dispatch `/plan`, review the plan with `/review-plans`,
  dispatch `/ship-plans`, then dispatch `/review-shipped-work`. Use
  `docs/plans/orchestrator/<run-slug>/` only when opt-in run docs are enabled.
- **Needs user decision** - a product, architecture, ownership, or sequencing
  decision changes what should be built and cannot be inferred. Ask batched
  questions during the original planning intake even at `review-none`. After
  the docs are implementation-ready, `review-none` lets you choose the most
  defensible path for later review checkpoints, record the assumption, and
  continue unless the risk is severe.

## User Decision Stops

Follow the shared human-stop rule in `skill-contracts.md`. For orchestration,
this also applies to subagent blockers: if a subagent reports a human-decision
blocker without concrete questions, either turn it into the required question
list yourself or send the subagent back for that clarification before involving
the user.

## Orchestration Rules

- Use specialist subagents for planning, plan review, implementation, and work
  review whenever the lifecycle includes those phases. Prompt each subagent to
  follow the corresponding skill body and return compact evidence.
- Do not re-plan the work yourself. Hold the map: selected lifecycle,
  current phase, files/dirs owned by each agent, gate evidence, decisions,
  assumptions, blockers, and next action.
- When opt-in run docs are enabled, use this layout:

  ```text
  docs/plans/orchestrator/<run-slug>/
    hub.md
    streams/
      <stream-id>.md
    findings/
      <topic-or-agent>.md   # optional
  ```

  The orchestrator owns `hub.md`, including lifecycle state, decisions,
  blockers, verification evidence, closeout notes, and migration status.
  Subagents may write only the stream or findings files named in their
  dispatch. Commit run docs at normal orchestration checkpoints or closeout;
  do not require a commit for every status update. After durable facts migrate
  into architecture/decisions, committed run docs are disposable plan material.
- Do not run two agents against the same files at the same time. Parallelize
  only when ownership is disjoint.
- The implementer ships the work: code, tests, docs migration, plan status
  when applicable, and local commit when green.
- The reviewer verifies the shipped state. If the reviewer finds obvious
  missed shipping work, it may fix, verify, and commit. If substantial work
  remains, route another implementation pass rather than patching it yourself.
- Keep final gates consolidated. Use narrow per-agent gates, then require the
  final implementer or reviewer to run the manifest gates needed to justify
  the final commit.

## Phase Template

Use only the phases the classification needs:

1. **Plan** - dispatch a `/plan`-shaped agent to run think -> batched
   questions until implementation-ready, then produce one implementer planning
   doc per workstream in `docs/plans/`, or under
   `docs/plans/orchestrator/<run-slug>/` when opt-in run docs are enabled.
2. **Plan Review** - dispatch `/review-plans` for tracked or risky
   plans. Apply or request plan changes before implementation.
3. **Implement** - dispatch `/ship-plans` for tracked plans or a bounded
   implementer prompt for briefed work. It owns shipping.
4. **Work Review** - dispatch `/review-shipped-work` for nontrivial shipped work. It
   verifies app state, fixes obvious misses, and commits fixes when green.
5. **Closeout** - inspect git status and agent evidence. Report the lifecycle
   used, commits made, checks run, assumptions, and any remaining work.

## Report Back

Keep user updates concise. At closeout, include:

- Lifecycle used and why.
- Agents/phases run, including any skipped phases.
- Commits made by implementer/reviewer.
- Verification evidence.
- Any assumptions made under `review-none`.
- Remaining blocker or follow-up, if any.

$ARGUMENTS
