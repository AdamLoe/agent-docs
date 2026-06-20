---
status:        shipped
owner:         codex
last_updated:  2026-06-20
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Token economy plan

## Mission

Drastically reduce routine token usage in agent-docs without weakening source
truth, review quality, or workflow resumability. Done means the workflow
optimizes for stable cached input, bounded task-specific input, and compact
output by default; the rule files, docs, verifier, and skills make that behavior
observable and hard to regress.

## Relationship To Hardening Plan

This is an active companion plan folded into
`agent-docs-hardening.md`, not a parallel implementation sequence. Implementation
workers should follow the hardening plan's combined waves and use this file for
token-economy scope, acceptance, and defaults.

The startup default is audit-gated: keep `docs/overview.md` mandatory until the
startup/skill wave proves every skill can classify without it, then make it
task-routed. Copy/install safety must ship before skill-body normalization or
copied-adapter refresh.

## Scope

In scope:

- Cache-first startup and routing contracts.
- Explicit policy for when workers read source docs directly vs receive an
  orchestrator summary.
- Output caps for dispatch packets, carry-forward summaries, worker reports,
  and gate excerpts.
- Documentation-layer budgets for routers, indexes, overviews, architecture
  leaves, decisions, plans, run docs, skill bodies, and worker role cards.
- Optional usage telemetry fields when a runtime exposes input, cached-input,
  and output token counts.
- Static verifier checks that enforce the cheap wins first.
- Migration of durable policy into workflow architecture and decisions.

Out of scope:

- A v2 documentation format.
- Generated context bundles, packet-helper scripts, or static per-run context
  workspaces.
- Vendor-specific pricing tables or hard dependence on one runtime's prompt
  cache behavior.
- Moving durable facts into `AGENTS.md`, `CLAUDE.md`, or other auto-loaded
  adapter files.
- Weakening manifest, ownership, or source-doc routing just to save startup
  tokens.

## Approach

### Stream 1: Cache-First Startup Contract

Owned surfaces:

- `v1/rules/skill-contracts.md`
- `v1/skills/*/SKILL.md`
- `v1/skills/registry.md`
- `docs/index.md`
- `docs/overview.md`
- `AGENTS.md`
- `CLAUDE.md`
- `v1/copy-skills.sh`
- `v1/template/docs/index.md`
- `v1/template/docs/overview.md`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`

Work:

- Rework Standard Intake so only stable router inputs are mandatory. Target
  state: skill contract, manifest startup bindings, and `docs/index.md` are
  mandatory; `docs/overview.md` becomes task-routed. Implementation must first
  prove no skill needs `docs/overview.md` before classification; stop if that
  route audit fails.
- Keep `v1/rules/skill-contracts.md` as a short stable runtime card: intake,
  asks/no-prompt behavior, dials, human stops, model policy, and owner pointers
  only.
- Mechanically normalize skill bodies so shared intake prose lives in
  `skill-contracts.md` instead of being repeated across every skill.
- Order dispatch prompts with a stable role/rule/report prefix first and
  task-specific context after it, so repeated inputs are as cache-friendly as
  the runtime allows.
- Add verifier coverage for stale old intake wording and oversized skill bodies.
- After changing skill bodies, refresh copied skill adapters with
  `bash v1/copy-skills.sh ~/agent-docs` and prove freshness with
  `bash v1/copy-skills.sh --check ~/agent-docs`. If a runtime requires approval
  to write outside the repo, request it explicitly during implementation.

Acceptance:

- `rg` finds no stale `index.md -> overview.md -> stop` instructions once the
  new startup contract is chosen.
- Word counts for startup docs and skill bodies move down or stay within the
  documented budget.
- `bash v1/copy-skills.sh --check ~/agent-docs` passes when skill bodies
  change.

### Stream 2: Source-First Dispatch Economics

Owned surfaces:

- `v1/rules/orchestrator/dispatch.md`
- `v1/rules/orchestrator/lifecycle.md`
- `v1/rules/subagent/*.md`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`

Work:

- Add explicit policy: workers read authoritative docs directly when exact
  details, judgment, or evidence matter. Orchestrators summarize only observed
  carry-forward facts: decisions, proven findings, touched files, gate results,
  blockers, and assumptions.
- For a large partly relevant doc, pass `path + heading/search hint` rather
  than a prose replacement for the doc.
- Resume an existing worker when the next task overlaps the same role and
  workstream. Spawn clean when the next task is a new role, a new lens,
  adversarial review, or would inherit bloated context.
- Keep exact rule links in dispatch packets. Do not copy full rule prose and do
  not revive generated context bundles.
- Make `cost-*` dials describe both fan-out and worker-output budgets.

Acceptance:

- Dispatch rules answer the user's concrete question: when should a subagent
  read the doc, and when should the orchestrator summarize?
- Lifecycle rules explain the cache/input/output trade-off without
  vendor-specific price claims.
- Targeted `rg` confirms no rule tells orchestrators to rewrite authoritative
  docs into generated summaries.

### Stream 3: Compact Output And Gate Evidence

Owned surfaces:

- `v1/rules/orchestrator/dispatch.md`
- `v1/rules/orchestrator/lifecycle.md`
- `v1/rules/subagent/verification.md`
- `v1/rules/subagent/review.md`
- `v1/rules/subagent/planning.md`
- `v1/rules/subagent/implementation.md`
- `v1/rules/subagent/docs-maintenance.md`
- `v1/rules/subagent/plan-maintenance.md`

Work:

- Set initial output targets:
  - Dispatch packet: exact rule links, no copied rules, target <=350 output
    tokens.
  - Carry-forward summary: <=10 bullets or <=300 output tokens.
  - Routine worker report: <=600 output tokens.
  - Planning or review report: <=1,200 output tokens unless the requested
    artifact is the report.
  - `cost-low` run: 0-1 workers and <=1.5k worker-output tokens.
  - `cost-medium` run: existing 2-4 worker band and <=5k worker-output tokens.
  - `cost-high` run: existing 4-8 worker band and <=10k worker-output tokens.
  - `cost-max` run: no hard cap, but require a budget-exception reason.
- For passing gates, report command, exit code, and the shortest proof line.
  For failing gates, include the shortest useful failure excerpt, not the full
  transcript.
- Keep the worker report shape self-contained: outcome, inspected/touched
  files, checks and result, migration facts, blockers/risk, commit or no-change
  statement.

Acceptance:

- Worker rules and dispatch rules agree on compact report expectations.
- Verification still gives enough evidence to prove outcomes.
- Targeted `rg` confirms worker report shapes include compact evidence and avoid
  full transcripts except when explicitly requested.

Default:

- Static doc, rule, and skill size caps are hard checks once documented. Per-run
  output caps are review heuristics until telemetry is available.

### Stream 4: Token-Efficient Documentation Layers

Owned surfaces:

- `v1/rules/authoring-rules.md`
- `docs/overview.md`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`
- `docs/_meta/manifest.md`
- `docs/_meta/ownership.json`
- `v1/template/docs/`
- `v1/verify-agent-docs.sh`

Work:

- Document cache-stable input layers:
  - `AGENTS.md` and `CLAUDE.md`: router-only, tiny, no facts.
  - `skill-contracts.md`: stable startup card.
  - `docs/index.md`, subtree indexes, and possibly `docs/overview.md`: stable
    routing and one-screen model.
  - `v1/rules/subagent/*.md`: stable role cards.
- Document task-specific input layers:
  - one architecture leaf, one decisions domain, one agent-context procedure,
    selected plan/run-doc files, and selected source/test files.
  - query ownership metadata only for ownership questions.
  - use `docs/repository-layout.md` only when locating files.
- Document never-auto-loaded material:
  - architecture leaves, decisions, plans, run docs, `v1/agent-docs-guide.md`,
    full ownership JSON, repository layout, source files, verifier output, and
    narrative pitch material.
- Add doc class budgets to authoring rules and verifier checks. Initial static
  targets:
  - skill bodies <=900 words.
  - subagent role cards <=500 words.
  - architecture docs <=1,500 words.
  - routers and subtree indexes stay small enough to be routing surfaces, not
    manuals.
- Add ownership and manifest coverage for context efficiency, doc budgets,
  cache-stable startup core, and template docs.

Acceptance:

- The docs tree has an explicit layer contract: cache-stable core, routed
  task-specific docs, and never-auto-loaded material.
- `python3 -m json.tool docs/_meta/ownership.json`
- Targeted word-count checks cover the newly documented doc class budgets.

### Stream 5: Usage Measurement And Enforcement

Owned surfaces:

- `v1/rules/skill-contracts.md`
- `v1/rules/orchestrator/dispatch.md`
- `v1/rules/orchestrator/lifecycle.md`
- `v1/rules/subagent/*.md`
- `v1/skills/registry.md`
- `docs/_meta/manifest.md`
- `docs/_meta/ownership.json`
- `v1/verify-agent-docs.sh`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`

Work:

- Add an optional usage block to worker reports when the runtime exposes it:

  ```text
  Token usage:
  - input_tokens:
  - cached_input_tokens:
  - output_tokens:
  - usage_source:
  - unavailable_reason:
  ```

- Gate on raw counts and a repo-defined weighted score only after usage data is
  available. Do not gate on vendor dollars.
- Start mechanical enforcement with static checks:
  - token-budget policy exists in canonical rule files;
  - report shape mentions token usage or an unavailable reason;
  - word-count caps for docs/rules/skills;
  - optional JSONL telemetry validation only if a run log is provided.
- Add review heuristics:
  - Was a strong model or extra worker justified by risk?
  - Did the orchestrator pass compact evidence instead of transcripts?
  - Did the run choose simple reductions before telemetry complexity?
  - Was output capped without losing necessary evidence?
  - Is a low cache-hit result caused by workflow shape or runtime limits?

Acceptance:

- `bash -n v1/verify-agent-docs.sh`
- `python3 -m json.tool docs/_meta/ownership.json`
- Optional telemetry validation passes when a sample run log is provided, or
  cleanly reports usage unavailable when no adapter data exists.

Default:

- Defer any `v1/skills/registry.md` per-skill budget/profile column until
  baseline usage exists.

## Combined Lifecycle Placement

This plan does not create independent implementation waves. Use
`agent-docs-hardening.md` as the anchor and fold token-economy work into these
serial points:

1. **Hardening Wave 3: combined lifecycle/dispatch policy.** Implement
   source-first dispatch, summary boundaries, resume-vs-spawn economics,
   compact report and gate-evidence rules, and cost-dial output heuristics.
2. **Hardening Wave 4: startup/skill normalization after overview audit.**
   Perform the `docs/overview.md` route audit before changing Standard Intake.
   Keep overview mandatory if any skill still needs it to classify work.
   Normalize skill bodies and refresh copied adapters only after install/copy
   safety has shipped.
3. **Hardening Wave 5: metadata/budgets/telemetry/enforcement.** Document
   cache-stable, task-specific, and never-auto-loaded layers; add static
   doc/skill budget checks; add optional usage-report shape and telemetry
   validation only when data exists.
4. **Hardening Wave 6: reader-path and migration closeout.** Migrate durable
   token-economy facts to `docs/architecture/workflow-kit.md`, rationale to
   `docs/decisions/agent-docs.md`, and then update this plan status only after
   migration.

## Exit Gate

- The implemented rules explicitly prefer stable cached input, bounded
  task-specific input, and compact output.
- The dispatch rules answer doc-read vs orchestrator-summary decisions.
- Static size/budget checks catch obvious regressions.
- Optional token-usage reporting has a graceful unavailable path.
- Copied skill adapters are refreshed and checked if skill bodies changed.
- Durable current-state facts are migrated into `docs/architecture/workflow-kit.md`.
- Durable rationale is migrated into `docs/decisions/agent-docs.md`.
- `bash -n v1/verify-agent-docs.sh`
- `python3 -m json.tool docs/_meta/ownership.json`
- `bash v1/copy-skills.sh --check ~/agent-docs` when skill bodies change.
- `bash v1/verify-agent-docs.sh`

## Discipline Rules

- Do not save output tokens by hiding uncertainty. Compact reports still name
  blockers, assumptions, and residual risk.
- Do not summarize away source authority. Summaries carry observed evidence;
  authoritative docs remain the thing workers verify against.
- Do not add a new context system until the simple reductions have shipped and
  measured poorly.
- Preserve unrelated dirty work in this repo. Current planning observed
  pre-existing deleted `docs/plans/` files; this plan does not own them.

## Migration Notes

Closeout migration targets:

- `docs/architecture/workflow-kit.md` carries cache-first startup,
  task-routed overview, source-first dispatch, compact handoffs and reports,
  context layers, static budgets, optional raw usage reporting, and verifier
  enforcement.
- `docs/decisions/agent-docs.md` carries rationale for task-routed overview,
  source-first compact handoffs, static budgets before usage gates, and focused
  v1 handoffs over generated context.
- `docs/_meta/manifest.md` routes context efficiency, documentation budgets,
  and usage reporting to their owners and exposes the drift gate.
- `docs/_meta/ownership.json` owns context-efficiency, documentation-budget,
  and usage-reporting concepts.

No durable token-economy context remains only in this plan.

## Worker Findings

- Startup/context routing worker: recommended cache-first startup, optional
  `overview.md`, skill-body normalization, stable prompt prefixing, and compact
  check output.
- Dispatch/subagent economics worker: recommended source-first, summary-second,
  output-capped policy; direct doc reads for exactness; summaries only for
  observed carry-forward facts.
- Documentation layers worker: recommended explicit cache-stable, task-specific,
  and never-auto-loaded layers with doc class budgets and verifier checks.
- Measurement worker: recommended static budgets first, optional token usage
  blocks when available, and raw-count scoring instead of vendor pricing.

## See Also

- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`
- `docs/plans/agent-docs-hardening.md`
- `v1/rules/skill-contracts.md`
- `v1/rules/orchestrator/dispatch.md`
- `v1/rules/orchestrator/lifecycle.md`
- `v1/rules/authoring-rules.md`
- `v1/verify-agent-docs.sh`
