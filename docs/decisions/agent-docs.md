# agent-docs decisions

## Source/runtime split

**Decision.** The editable source checkout lives at the repo root with the
exported kit under `src/`. The installed runtime is always `~/.agentdocs/`;
skills, rules, templates, and consuming-repo docs self-reference
`~/.agentdocs/...` as the only stable runtime path. `v1/` is retired as a
versioning term; `src/` is the source directory name only.

**Why.** Local edits to the source checkout do not affect other projects until
an installer runs explicitly, and a fixed runtime path keeps all consuming repos
pointing at one location regardless of clone location.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../README.md`](../../README.md).

## Two-installer model (install equals update)

**Decision.** Two install entry points; update is the same operation as install.
`install-agentdocs-local.sh` (top-level) is the dogfood/dev path: it publishes
the local `src/` bundle into `~/.agentdocs/` (source kind `local`).
`src/install-agentdocs.sh` (bundled) is the normal user path: it downloads a
GitHub codeload archive from `AdamLoe/agent-docs` (default `main` or a named
tag), validates bundle shape, then atomically replaces `~/.agentdocs/` (source
kind `github`). Even from a checkout, the GitHub installer installs from GitHub,
not local source. There is no separate update script.

**Why.** One install/update operation eliminates a separate command that can
drift. Two entry points keep the dogfood path explicit, not behind a flag.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../install-agentdocs-local.sh`](../../install-agentdocs-local.sh), [`../../src/install-agentdocs.sh`](../../src/install-agentdocs.sh).

## Agent install/update requires explicit user permission

**Decision.** An agent must not run any agent-docs installer
(`install-agentdocs-local.sh`, `src/install-agentdocs.sh`, or
`~/.agentdocs/install-agentdocs.sh`) without first proposing it and receiving
explicit user confirmation.

**Why.** Running an installer atomically replaces `~/.agentdocs/` and refreshes
or deletes managed skill copies under `~/.claude/skills/` and `~/.agents/skills/`
— a destructive operation against the user's home, not recoverable without a
re-install.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../src/rules/repo-rules.md`](../../src/rules/repo-rules.md).

## Tool paths are adapters

**Decision.** Claude and Codex both use copied user skill directories: the
installers copy agent-docs skills from `~/.agentdocs/skills/` into
`~/.claude/skills/<name>` and `~/.agents/skills/<name>`, marking each copy with
`.agent-docs-managed`. Tool skill roots stay tool-owned; symlinked roots are
refused. Claude plugin manifests are not a supported adapter path.

**Why.** Tools discover skills differently, but command bodies should not fork.
One copy model avoids adapter surprises; the marker scopes refreshes to
agent-docs copies.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Managed-skill deletion policy

**Decision.** The per-skill `.agent-docs-managed` marker file is the deletion
authority. On install, stale managed skills (marker present, no longer in the
runtime bundle) are pruned. An unmanaged same-name skill collision stops the
install with an error — the installer never silently deletes unowned user
content. There is no force flag.

**Why.** The per-skill marker needs no external manifest to track removals.
Stopping on unmanaged conflicts protects user skills; a clear error beats silent
override.

**Alternatives considered.** A force flag for collision override — rejected for
too easily destroying unowned user content without confirmation.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Install manifest is provenance only

**Decision.** `~/.agentdocs/.agentdocs-install-manifest` records source kind,
path/tag, URL (GitHub installs), and install timestamp. It is not the
skill-deletion authority and is not consulted to decide what to remove.

**Why.** The manifest is a lightweight "where did this runtime come from and
when?" provenance record. Deletion logic belongs in the per-skill marker, not a
manifest that could drift.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Skill refresh is embedded in installers

**Decision.** After replacing `~/.agentdocs/`, both installers run the
managed-skill copy logic inline. The retired `copy-skills.sh` is removed; there
is no standalone refresh command. After skill changes in `src/`, run the local
installer then the verifier.

**Why.** Embedding refresh removes a separate script that could drift; the
manifest gate checks adapter freshness.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Router-only auto-loaded files

**Decision.** Root `AGENTS.md` and `CLAUDE.md` exist only as routers to the docs
entry point. They must not own architecture, decisions, or app facts.

**Why.** Always-loaded fact dumps drift and crowd the context window. Routers
keep startup cheap while the normal docs tree stays the owner.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../src/rules/authoring-rules.md`](../../src/rules/authoring-rules.md).

## Overview is task-routed

**Decision.** Standard skill startup reads `~/.agentdocs/rules/skill-contracts.md`,
the manifest slots the skill needs, and `docs/index.md`; `docs/overview.md` loads
only when the task needs system-shape orientation or a skill names it as input.

**Why.** The route audit showed every skill can classify from its own body,
manifest slots, and the docs index. Optional overview keeps repeated startup
cache-stable while keeping the orientation route.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/skill-contracts.md`](../../src/rules/skill-contracts.md), [`../../src/skills/`](../../src/skills/).

## Work ships through `/ship-current-work`

**Decision.** Ordinary changes finish through `/ship-current-work`.
`/wrap-up-current-chat` is reserved for chat-only memory capture.

**Why.** Shipping is more than summarization: diff review, owning-doc updates,
manifest gates, plan migration, staging, and commit.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/ship-current-work/SKILL.md`](../../src/skills/ship-current-work/SKILL.md).

## Planning uses `/plan`

**Decision.** The planning entry point is `/plan`, backed by
`src/skills/plan/SKILL.md`; the older `fresh-planning-chat` name is retired.

**Why.** Planning is a first-class workflow, not a fresh-chat variant. The
shorter command makes clear the agent owns concern-shaping, briefs, and
high-level plan/doc routing.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/plan/SKILL.md`](../../src/skills/plan/SKILL.md).

## Skill contracts are shared

**Decision.** Suite-wide skill metadata and reusable policy live in
`src/skills/registry.md` and `src/rules/skill-contracts.md`.

**Why.** Repeating mode, bootstrap, shipping, and model-tier policy in every
skill makes them drift. A registry plus shared contracts gives the doctor and
skill-review flows concrete checks.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/registry.md`](../../src/skills/registry.md), [`../../src/rules/skill-contracts.md`](../../src/rules/skill-contracts.md).

## Verifier modes are explicit

**Decision.** `src/verify-agent-docs.sh` with no arguments validates the
agent-docs source checkout containing the script. Consuming repos use the
target-aware scaffold mode: `~/.agentdocs/verify-agent-docs.sh --scaffold
<repo-root>`. Run outside the source repo, it prints a `--scaffold` directive and
exits 0.

**Why.** A script reached through `~/.agentdocs/` resolves to the runtime bundle,
not the caller's repo. An explicit target stops a rebuild from appearing verified
when only the shared kit was checked.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/verify-agent-docs.sh`](../../src/verify-agent-docs.sh), [`../../src/skills/rebuild-agent-docs/SKILL.md`](../../src/skills/rebuild-agent-docs/SKILL.md), [`../../src/skills/doctor/SKILL.md`](../../src/skills/doctor/SKILL.md).

## Startup checks route to existing skills

**Decision.** `/start-session` is the local beginning-of-day/session check for
git state, plan state, and cleanup candidates, delegating mutation to the
existing workflow skills.

**Why.** Startup should make the next action obvious without creating a second
implementation, cleanup, or orchestration path that drifts from the owning
skills. A startup run may hand off to a mutating skill, but that mutation still
follows the skill's verification, migration, and commit contract.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/start-session/SKILL.md`](../../src/skills/start-session/SKILL.md), [`../../src/skills/clear-plans/SKILL.md`](../../src/skills/clear-plans/SKILL.md).

## Plan cleanup preserves local history

**Decision.** `/clear-plans` deletes shipped or abandoned plan files and
orchestration run docs only when the latest candidate content is clean and
tracked in git.

**Why.** Plans are disposable after migration, but the deleted latest version
should stay recoverable from git rather than lost from an uncommitted tree.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/clear-plans/SKILL.md`](../../src/skills/clear-plans/SKILL.md), [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md).

## Command names favor short job labels

**Decision.** Workflow commands use short job-oriented names; the registry
groups them by job family.

**Why.** Agents choose commands more reliably when the surface is compact and
grouped by intent, not one long list.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/registry.md`](../../src/skills/registry.md).

## Skill listing reports source plus freshness

**Decision.** `/list-skills` reports the canonical `~/.agentdocs/skills/`
inventory, project-local skill directories, and freshness of the installed
Claude/Codex adapter copies.

**Why.** Source skill bodies are the contract of record; tool adapters are
copied discovery surfaces that can go stale. Listing both prevents a copy from
being mistaken for the authoritative inventory.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/list-skills/SKILL.md`](../../src/skills/list-skills/SKILL.md), [`../../src/skills/registry.md`](../../src/skills/registry.md).

## Feedback inbox lives in the runtime and survives installs

**Decision.** `/feedback-agent-docs` appends kit-level feedback to
`~/.agentdocs/feedback.jsonl`. Both installers save this file before the atomic
runtime replace and restore it afterward, so a feedback log is never wiped by
an install or update.

**Why.** The inbox must be a low-friction capture queue — including while
dogfooding inside the kit repo — without creating accidental untracked source
changes. Living in `~/.agentdocs/` (outside any source checkout) removes the need
for a `.gitignore` entry; preserving it across installs means feedback survives a
`main`-branch update.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../src/skills/feedback-agent-docs/SKILL.md`](../../src/skills/feedback-agent-docs/SKILL.md), [`../../install-agentdocs-local.sh`](../../install-agentdocs-local.sh), [`../../src/install-agentdocs.sh`](../../src/install-agentdocs.sh).

## Subagent-first execution

**Decision.** Every user-facing skill is an orchestrator entry point.
Orchestrators do **coordination IO and user communication only** — classify,
dispatch role-scoped workers with exact rule-file routes, relay worker questions
to the user, hold the map/evidence/next-action, run the consolidated end gate.
**All implementation — code, docs, plan edits, reviews — happens in dispatched
workers**, never inline; the only inline step is pure routing/IO under the
reads-vs-dispatch test. There is no direct-vs-delegated mode or no-intake
command class; `cost-*` and `review-*` tune fan-out and review intensity, not
whether workers run.

**Why.** One instruction set serving both "navigate the workflow" and "do the
task" bloated and blurred the skills. Splitting orchestrator control
(`src/rules/orchestrator/`) from worker roles (`src/rules/subagent/`) keeps both
lean. Skill *names* are unchanged — internal execution model, not command
surface. A missing dispatch capability is an error to report, not a reason to
inline.

**Alternatives considered.** A direct/delegated boolean per skill — rejected for
reviving the two-jobs problem and a per-skill "should I delegate?" debate.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/skill-contracts.md`](../../src/rules/skill-contracts.md), [`../../src/rules/orchestrator/`](../../src/rules/orchestrator/), [`../../src/rules/subagent/`](../../src/rules/subagent/), [`../../src/skills/registry.md`](../../src/skills/registry.md).

## Clean-handoff git invariant

**Decision.** Supersedes "Commit-heavy worker shipping". A mutating worker never
hands off unexplained owned dirt. It ends in one of three terminal states:
**committed** (owned slice committed, gate green); **clean no-op** (tree clean);
or **explicit blocked handoff** recording the dirty paths, the check/gate state,
why a safe commit is impossible, and the resume profile. A **discharge gate**
binds every blocked-handoff record to its resolution — committed or reverted —
before final verification; no run ends undischarged. Long work may take
**constrained checkpoint commits** but must not revive the per-slice micro-commit
cadence this replaces. Editing stays serial per tree; `repo-rules.md` owns the
snapshot/staging rules.

**Why.** Committing every slice churned history and stranded half-done work; the
invariant keeps the outcome — no unexplained dirt — with a blocked state
auditable and discharged.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/orchestrator/`](../../src/rules/orchestrator/), [`../../src/rules/subagent/`](../../src/rules/subagent/), [`../../src/rules/repo-rules.md`](../../src/rules/repo-rules.md).

## Source-first compact handoffs

**Decision.** Dispatch is source-first and compact: orchestrators pass exact rule
links plus path/heading hints, workers read authoritative docs/source directly,
and carry-forward summaries hold only the observed facts dispatch.md lists —
never a copy of the source.

**Why.** Summaries become risky when they replace the source that owns the fact;
short packets save tokens without weakening evidence.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md), [`../../src/rules/subagent/`](../../src/rules/subagent/).

## Profiles are the sole worker-context authority

**Decision.** The kernel (`src/kernel/profiles.json`) owns the worker profiles;
`src/rules/context-profiles.md` is the human contract. Skills name profile IDs and
a dispatch names that profile's rule files directly — runtime workers never run
`--resolve` (a source-only aid). Role cards add no rule files beyond the named
profile. The verifier exits nonzero on budget overrun or contract-check failure.

**Why.** One authority prevents role cards from silently expanding context;
deterministic checks catch drift without adapter runtime metrics.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/context-profiles.md`](../../src/rules/context-profiles.md), [`../../src/verify-agent-docs.sh`](../../src/verify-agent-docs.sh).

## Enforced budgets with correctness floors (E3)

**Decision.** All budgets enforced. Three profiles were raised to measured floors
(planning.tracked 1600, review.docs 1200, maintenance.plan 2100) after full
relocation with zero correctness loss. Launch budgets: fixed-skill 2000,
classifier 3300. No budget rises without a documented correctness reason.

**Why.** Deleting rules to hit a number is worse than an honest floor;
enforcement makes over-budget a hard gate failure.

**Code anchors.** `src/rules/context-profiles.md → Budget floors`, `Launch budgets`; `src/verify-agent-docs.sh → fixed_budget`, `classifier_budget`.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/context-profiles.md`](../../src/rules/context-profiles.md), [`../../src/verify-agent-docs.sh`](../../src/verify-agent-docs.sh).

## Reference-leaf relocation pattern

**Decision.** Each dense runtime rule keeps only the normative contract; examples
and rationale relocate to never-auto-loaded `*-reference.md` leaves. Language
idioms split into conditional overlays
(`coding-style-{rust,python,frontend}.md`). Both add zero launch cost.

**Why.** Relocating explanations compresses rules to correctness floors while
keeping rationale.

**Code anchors.** `src/rules/*-reference.md`; `src/rules/orchestrator/*-reference.md`; `src/rules/coding-style-{rust,python,frontend}.md`.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), `src/rules/*.md`, `src/rules/orchestrator/`.

## Thin-recipe skills and classifier allowlist

**Decision.** A skill body owns only profile IDs, phase order, unique gates,
escalation, and result shape — nothing copied from shared contracts. Fixed skills
must not load `orchestrator/lifecycle.md`. Only `orchestrate`, `fresh-chat`, and
`start-session` classify; `--contract-check` gates on all.

**Why.** Re-embedding shared prose creates a second policy surface that drifts.

**Code anchors.** `src/rules/skill-contracts.md → Skill Recipe`, `src/verify-agent-docs.sh → contract_check`.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/skill-contracts.md`](../../src/rules/skill-contracts.md), [`../../src/skills/`](../../src/skills/).

## plan_closeout grant for implementation.tracked

**Decision.** `implementation.tracked` may close only the selected plan when
dispatch grants `plan_closeout`; review and verification stay read-only. The
grant stays consistent across `context-profiles.md`,
`subagent/implementation.md`, and `orchestrator/dispatch.md`.

**Why.** An explicit grant keeps mutation authority traceable; implicit closeout
risks the wrong plan.

**Code anchors.** `src/rules/context-profiles.md → implementation.tracked`; `src/rules/subagent/implementation.md → plan_closeout`; `src/rules/orchestrator/dispatch.md → plan_closeout`.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/context-profiles.md`](../../src/rules/context-profiles.md), [`../../src/rules/subagent/implementation.md`](../../src/rules/subagent/implementation.md), [`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md).

## Source-bound contract-check gate

**Decision.** `--contract-check` runs nine source-bound checks — launch budgets,
lifecycle loading, subagent bundles, role authority, plan_closeout consistency,
review-app pre-audit, scenario source-binding, report fields, and final-ordering.
Exits nonzero on any violation; `PASS` never prints while a violation exists.
`workflow-scenarios.json` is verifier-only.

**Why.** Phrase-checking a self-authored table proves only self-consistency;
source-bound checks prove the contract against real files.

**Code anchors.** `src/verify-agent-docs.sh → contract_check`; `src/verify-fixtures/workflow-scenarios.json`.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/verify-agent-docs.sh`](../../src/verify-agent-docs.sh), [`../../src/verify-fixtures/`](../../src/verify-fixtures/).

## Final-state shipping order

**Decision.** Mutating workflows finish all code, docs, plan-frontmatter, and
run-doc mutations before the final consolidated drift gate, then report from that
verified state. Review and verification workers are read-only; findings route
back to implementation, docs-maintenance, or plan-maintenance.

**Why.** A gate run before plan status or doc migration does not prove the state
the user receives. Mutation authority must match the profile telling a worker how
to edit, verify, stage, and commit.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/orchestrator/lifecycle.md`](../../src/rules/orchestrator/lifecycle.md), [`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md), [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md).

## Orchestration run docs are opt-in

**Decision.** `/orchestrate` creates `docs/plans/orchestrator/<run-slug>/` only
when the user asks for stateful run docs or grants permission after the
orchestrator explains a concrete resume risk.

**Why.** Persistent run state helps long multi-agent work, but defaulting it on
would create extra temporary docs for ordinary changes. Keeping the mode inside
`/orchestrate` preserves the compact command surface. Default runs are less
resumable after context loss — the accepted cost of not committing folders
unasked.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/orchestrate/SKILL.md`](../../src/skills/orchestrate/SKILL.md), [`../../src/rules/orchestrator/run-docs.md`](../../src/rules/orchestrator/run-docs.md), [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md).

## Kernel-as-consolidation

> **Supersedes** the prior "Focused handoffs over generated context" decision
> (now removed; its rejected alternatives are restated below).

**Decision.** The focused execution kernel **consolidates and validates machine
authority that already exists** — adding NO generated workspaces, packet helpers,
generated prompt bodies, per-run context, or new parser. It pulls three
already-normative sources into one JSON authority under `src/kernel/`: the
context-profiles Markdown table, the `workflow-scenarios.json` fixture, and the
hardcoded budget constants in `src/verify-agent-docs.sh` (`fixed_budget`,
`classifier_budget`, per-profile budgets, `classifier_allowlist`). The
**existing** verifier reads it (extended `--resolve`/`--contract-check`, no
parallel CLI). The resolver emits **exact references** (paths + heading hints +
sizes), copies no body, and writes no artifact.

**Why.** The superseded decision rejected generated workspaces, packet helpers,
YAML metadata, parser work, and launcher behavior — a *second* workflow surface.
The kernel adds none: it validates data the verifier already parses and generates
nothing, so it is **not** a revival of metadata-v2 or
generated-repo-local-context. One machine fact never lives in both the kernel and
Markdown/bash.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/context-profiles.md`](../../src/rules/context-profiles.md), [`../../src/verify-agent-docs.sh`](../../src/verify-agent-docs.sh).

## Conditional bounded fast path for `/orchestrate`

> **Supersedes** "Uniform `planning.scope` `/orchestrate` entry" (mandatory
> scope-first).

**Decision.** `/orchestrate` classifies inline (routing, never implementation). A
bounded request (outcome + acceptance + likely check) dispatches an
`implementation.*` worker **directly**, no scope hop. A read-only `planning.scope`
worker runs **only** when classification, decomposition, or a user decision is
unresolved; its brief then resolves the lifecycle. Subagent-first holds on both
routes; the now-moot cost-regression scope-hop budget guard is removed.

**Why.** The mandatory scope phase taxed every already-bounded run with a worker
hop that resolved nothing new — not worth it for a single-author dogfood kit.
Conditional scope restores the fast path, keeping source-backed scoping for
unresolved work.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/orchestrate/SKILL.md`](../../src/skills/orchestrate/SKILL.md), [`../../src/rules/orchestrator/`](../../src/rules/orchestrator/), [`../../src/kernel/`](../../src/kernel/).

## Source-only until final migration

**Decision.** Through the execution-kernel build, all work and all
`bash src/verify-agent-docs.sh` gating runs against `src/` only. No installer
runs, `~/.agentdocs/` is not refreshed, and adapter skill copies are untouched
until the overhaul is green end-to-end AND the user explicitly authorizes one
deliberate migration updating the runtime and all consuming repos together.

**Why.** Building against source neutralizes the adapter-freshness /
`remove_stale_managed` coupling and the consuming-repo breakage an in-progress
kernel would otherwise cause. The verifier reads `src/kernel/` and
`src/verify-fixtures/` directly and neither installer bundles them, so the cutover
needs no installer change.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/repo-rules.md`](../../src/rules/repo-rules.md), [`../../src/verify-agent-docs.sh`](../../src/verify-agent-docs.sh).
