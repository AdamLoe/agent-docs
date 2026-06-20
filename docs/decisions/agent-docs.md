# agent-docs decisions

## Neutral checkout path

**Decision.** `~/agent-docs` is the canonical self-reference path for the kit;
the physical checkout may live elsewhere, and `v1/install.sh` makes the
canonical path resolve to that checkout. Versioned kit files live under `v1/`.

**Why.** The kit is shared by Claude, Codex, and future tools. A neutral
canonical path keeps the source from appearing owned by one tool while still
letting docs, skills, and copied adapters use stable absolute references.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../README.md`](../../README.md).

## Tool paths are adapters

**Decision.** Claude and Codex both use copied user skill directories:
`v1/copy-skills.sh` copies agent-docs skills into `~/.claude/skills/<name>`
and `~/.agents/skills/<name>` and marks them with `.agent-docs-managed`.
The tool skill roots themselves stay tool-owned; symlinked roots are conflicts
by default. Claude plugin manifests are not a supported adapter path.

**Why.** Tools discover skills differently, but the command bodies should not
fork. Using the same copy model for both tools avoids adapter-specific
surprises, while the marker lets refreshes update only agent-docs copies.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Skill updates use the copy refresh

**Decision.** After agent-docs skills change, run `v1/copy-skills.sh` to
refresh Claude's `~/.claude/skills` and Codex's `~/.agents/skills`
directories with marked agent-docs-managed copies, then run
`v1/copy-skills.sh --check` to prove those copies match the source.
`copy-skills.sh` preflights unmanaged source-name conflicts before removing
stale managed children or refreshing copied skills, and `--dry-run` previews the
same mutation plan without writing.

**Why.** Tool sessions may not notice newly-created source directories. A
dedicated copy refresh makes the update step explicit while preserving
unrelated personal skills; the read-only check catches stale installed command
bodies before a future agent starts from the wrong instructions.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../v1/copy-skills.sh`](../../v1/copy-skills.sh).

## Installer ignores copy test destinations

**Decision.** `AGENT_DOCS_SKILLS_DEST` is a public testing hook for
`v1/copy-skills.sh`, not installer configuration. `v1/install.sh` clears it when
calling the copy script so installs always target the documented Claude and
Codex skill roots.

**Why.** A test-only destination is useful for isolated safety checks, but the
installer's job is to make the canonical self-reference path and both tool
adapters usable in `$HOME`.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../v1/install.sh`](../../v1/install.sh), [`../../v1/copy-skills.sh`](../../v1/copy-skills.sh).

## Router-only auto-loaded files

**Decision.** Root `AGENTS.md` and `CLAUDE.md` exist only as routers to the
docs entry point. They must not own architecture, decisions, or app facts.

**Why.** Always-loaded fact dumps drift and crowd the context window. Routers
keep startup cheap while preserving the normal docs tree as the owner.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md).

## Overview is task-routed

**Decision.** Standard skill startup reads `v1/rules/skill-contracts.md`, the
manifest slots needed by the skill, and `docs/index.md`; `docs/overview.md` is
loaded only when the task needs system-shape orientation or a skill names it as
task input.

**Why.** The route audit showed every skill can classify from its own body,
manifest slots, and the docs index. Making overview optional keeps repeated
startup cache-stable without losing the one-screen orientation route.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/rules/skill-contracts.md`](../../v1/rules/skill-contracts.md), [`../../v1/skills/`](../../v1/skills/).

## Work ships through `/ship-current-work`

**Decision.** Ordinary changes finish through `/ship-current-work`.
`/wrap-up-current-chat` is reserved for chat-only memory capture.

**Why.** Shipping is more than chat summarization: it includes diff review,
owning-doc updates, manifest gates, plan migration, staging, and commit.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/ship-current-work/SKILL.md`](../../v1/skills/ship-current-work/SKILL.md).

## Planning uses `/plan`

**Decision.** The planning entry point is `/plan`, backed by
`v1/skills/plan/SKILL.md`; the older `fresh-planning-chat` name is retired.

**Why.** Planning is a first-class workflow, not just a fresh-chat variant.
The shorter command makes it clear that the agent owns concern-shaping,
implementer briefs, and high-level plan/doc routing.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/plan/SKILL.md`](../../v1/skills/plan/SKILL.md), [`../../v1/install.sh`](../../v1/install.sh).

## Skill contracts are shared

**Decision.** Suite-wide skill metadata and reusable skill policy live in
`v1/skills/registry.md` and `v1/rules/skill-contracts.md`.

**Why.** Repeating mode, bootstrap, shipping, and model-tier policy inside
every skill makes the skills drift from each other. A registry plus shared
contracts gives the doctor and skill-review flows something concrete to
validate.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/registry.md`](../../v1/skills/registry.md), [`../../v1/rules/skill-contracts.md`](../../v1/rules/skill-contracts.md).

## Verifier modes are explicit

**Decision.** `v1/verify-agent-docs.sh` with no arguments validates the
agent-docs kit checkout that contains the script. Consuming repos use the
target-aware scaffold mode:
`v1/verify-agent-docs.sh --scaffold <repo-root>`.

**Why.** A script reached through `~/agent-docs` resolves to the kit checkout,
not automatically to the caller's repository. Making the target explicit
prevents a rebuild from appearing verified when only the shared kit was checked.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/verify-agent-docs.sh`](../../v1/verify-agent-docs.sh), [`../../v1/skills/rebuild-agent-docs/SKILL.md`](../../v1/skills/rebuild-agent-docs/SKILL.md), [`../../v1/skills/doctor/SKILL.md`](../../v1/skills/doctor/SKILL.md).

## Startup checks route to existing skills

**Decision.** `/start-session` is the local beginning-of-day/session check for
git state, plan state, and cleanup candidates, but it delegates mutation to
the existing workflow skills.

**Why.** Startup should make the next action obvious without creating a second
implementation, cleanup, or orchestration path that can drift from the owning
skills.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/start-session/SKILL.md`](../../v1/skills/start-session/SKILL.md), [`../../v1/skills/clear-plans/SKILL.md`](../../v1/skills/clear-plans/SKILL.md).

**Tradeoffs.** A startup run may immediately hand off to a mutating skill, but
the mutation still follows that skill's verification, doc migration, and commit
contract.

## Plan cleanup preserves local history

**Decision.** `/clear-plans` deletes shipped or abandoned plan files and
orchestration run docs only when the latest candidate content is clean and
tracked in local git.

**Why.** Plans are disposable coordination material after migration, but the
deleted latest version should remain recoverable from git history rather than
being lost from an uncommitted working tree.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/clear-plans/SKILL.md`](../../v1/skills/clear-plans/SKILL.md), [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md).

## Command names favor short job labels

**Decision.** Workflow commands use short job-oriented names and the skill
registry groups them by job family.

**Why.** Agents choose commands more reliably when the command surface is
compact and grouped by intent instead of exposed as one long undifferentiated
list.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/registry.md`](../../v1/skills/registry.md).

## Skill listing reports source plus freshness

**Decision.** `/list-skills` reports the canonical `~/agent-docs/v1/skills/`
inventory, project-local skill directories, and freshness of the installed
Claude/Codex adapter copies.

**Why.** Source skill bodies are the contract of record, while tool adapters are
copied discovery surfaces that can go stale. Listing both prevents an installed
copy from being mistaken for the authoritative inventory.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/list-skills/SKILL.md`](../../v1/skills/list-skills/SKILL.md), [`../../v1/skills/list-skills/list-skills.sh`](../../v1/skills/list-skills/list-skills.sh), [`../../v1/skills/registry.md`](../../v1/skills/registry.md).

## Feedback inbox is gitignored

**Decision.** `/feedback-agent-docs` appends kit-level feedback to
`~/agent-docs/feedback/inbox.jsonl`, and the agent-docs checkout ignores that
inbox file.

**Why.** The inbox should be a low-friction capture queue, including while
dogfooding inside the kit repo, without creating accidental untracked source
changes or a required commit for every note.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/feedback-agent-docs/SKILL.md`](../../v1/skills/feedback-agent-docs/SKILL.md), [`../../.gitignore`](../../.gitignore).

## Subagent-first orchestration

**Decision.** Every user-facing skill is an orchestrator entry point that
dispatches role-scoped workers with exact rule-file routes; it only runs a step
inline when it is pure routing/IO under the reads-vs-dispatch test. There is no
direct-vs-delegated execution mode, no `delegate-on`/`delegate-off` switch, and
no no-intake/direct-execution command class. `cost-*` and `review-*` tune the
orchestrated workflow's fan-out and review intensity, not whether workers are
used.

**Why.** Making one agent instruction set serve both "navigate the workflow" and
"do the task" is what bloated and blurred the skills. Splitting orchestrator
control (`v1/rules/orchestrator/`) from worker roles (`v1/rules/subagent/`) keeps
orchestrator context lean and worker prompts clean, and passing exact rule-file
links — instead of copied prose or open-ended "discover the system" instructions
— keeps dispatch cheap and unambiguous. User-facing skill *names* stay the same
because the change is internal execution model, not command surface; a missing
worker-dispatch capability is an error to report, not a reason to inline.

**Alternatives considered.** A direct/delegated boolean per skill — rejected
because it reintroduced the two-jobs problem and a per-skill "should I delegate?"
debate the docs spent context re-litigating.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/rules/skill-contracts.md`](../../v1/rules/skill-contracts.md), [`../../v1/rules/orchestrator/`](../../v1/rules/orchestrator/), [`../../v1/rules/subagent/`](../../v1/rules/subagent/), [`../../v1/skills/registry.md`](../../v1/skills/registry.md).

## Commit-heavy worker shipping

**Decision.** Editing workers commit their own completed slice before reporting;
follow-up workers repair or revert through additional commits. Editing is serial
per working tree because concurrent commits race the git index, and parallel
editing uses worktree isolation or orchestrator-applied patches. Each mutating
worker snapshots dirty state, preserves unrelated user changes and deletions,
stages only owned paths by filename, and stops if unrelated dirty state blocks a
coherent slice. The orchestrator records commit hashes and verifies the final
observed state; the user squashes later if desired.

**Why.** Workers own their slice end to end, so the commit belongs with the
worker that verified it green. Serial-by-default editing avoids index races that
file-ownership fences cannot prevent.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/rules/orchestrator/`](../../v1/rules/orchestrator/), [`../../v1/rules/subagent/`](../../v1/rules/subagent/).

## Source-first compact handoffs

**Decision.** Worker dispatch is source-first and compact: orchestrators pass
exact rule links and path plus heading/search hints, workers read authoritative
docs/source directly for exact details, and carry-forward summaries contain only
observed decisions, findings, touched files, gates, commits, blockers, and
assumptions.

**Why.** Summaries are useful continuity, but they become risky when they replace
the document or source that owns the fact. Keeping dispatch packets and reports
short saves output tokens without weakening evidence.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/rules/orchestrator/dispatch.md`](../../v1/rules/orchestrator/dispatch.md), [`../../v1/rules/orchestrator/lifecycle.md`](../../v1/rules/orchestrator/lifecycle.md), [`../../v1/rules/subagent/`](../../v1/rules/subagent/).

**Tradeoffs.** Workers spend some input reading source docs directly, but the
workflow avoids stale generated context and large prior-transcript handoffs.

## Static budgets before usage gates

**Decision.** Agent-docs enforces context economy first with static layer
contracts and word-count budgets: cache-stable startup inputs stay small,
task-specific docs are routed by owner, and never-auto-loaded material stays out
of startup. Worker reports may include raw token usage when the runtime exposes
it, but unavailable usage is represented by `unavailable_reason`; vendor dollar
pricing and runtime-specific cache scoring are not part of the contract.

**Why.** Static budgets catch the cheap regressions without requiring every
adapter to expose identical telemetry. Optional raw counts can inform later
review, but gating on prices or one runtime's cache model would make the
tool-neutral kit brittle.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md), [`../../v1/rules/orchestrator/dispatch.md`](../../v1/rules/orchestrator/dispatch.md), [`../../v1/verify-agent-docs.sh`](../../v1/verify-agent-docs.sh).

## Final-state shipping order

**Decision.** Mutating workflows finish all code, docs, plan-frontmatter, and
run-doc mutations before running the final consolidated drift gate, then report
from that verified final state. Review and verification workers are read-only
unless dispatched with implementation and repo rules plus a bounded fix scope.

**Why.** A gate run before plan status or doc migration does not prove the state
the user receives. Mutation authority must match the rule bundle that tells a
worker how to edit, verify, stage, and commit safely.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/rules/orchestrator/lifecycle.md`](../../v1/rules/orchestrator/lifecycle.md), [`../../v1/rules/orchestrator/dispatch.md`](../../v1/rules/orchestrator/dispatch.md), [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md).

## Orchestrate coordinates specialists

**Decision.** `/orchestrate` is a lifecycle controller that dispatches
planning, plan-review, implementation, work-review, or quick-fix worker phases
instead of reimplementing them inline.

**Why.** Broad change work needs continuity across phases, but the best way to
keep quality and context under control is to preserve specialist worker
boundaries and let the orchestrator hold only the map, evidence, assumptions,
and next action.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/orchestrate/SKILL.md`](../../v1/skills/orchestrate/SKILL.md), [`../../v1/rules/orchestrator/`](../../v1/rules/orchestrator/).

## Orchestration run docs are opt-in

**Decision.** `/orchestrate` creates
`docs/plans/orchestrator/<run-slug>/` only when the user asks for stateful run
docs or grants permission after the orchestrator explains a concrete resume
risk.

**Why.** Persistent run state is valuable for long multi-agent work, but making
it the default would create extra temporary documentation for ordinary changes.
Keeping the mode inside `/orchestrate` preserves the compact command surface
and avoids reviving retired orchestration command names.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/orchestrate/SKILL.md`](../../v1/skills/orchestrate/SKILL.md), [`../../v1/rules/orchestrator/run-docs.md`](../../v1/rules/orchestrator/run-docs.md), [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md).

**Tradeoffs.** Default runs are less resumable after context loss, but they
avoid committed coordination folders unless the user accepts that cost.

## Focused v1 handoffs over generated context

**Decision.** The active kit stays on v1 and lowers context through focused
worker roles, planner-produced implementation briefs, and concise orchestrator
carry-forward summaries.

**Why.** The useful part of the generated-context exploration was deterministic,
source-backed, role-specific input. The cost was extra infrastructure: generated
workspaces, packet helpers, YAML metadata, parser work, and launcher behavior
that became another workflow surface to keep correct. V1 can get the benefit by
making the handoff boundary explicit.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/rules/orchestrator/dispatch.md`](../../v1/rules/orchestrator/dispatch.md), [`../../v1/rules/orchestrator/lifecycle.md`](../../v1/rules/orchestrator/lifecycle.md), [`../../v1/rules/subagent/planning.md`](../../v1/rules/subagent/planning.md).

**Alternatives considered.** Generated repo-local workspaces, metadata v2,
packet helper scripts, static context bundles, and broader `docs/index.md`
skill routing.

**Tradeoffs.** Orchestrators still need discipline to pass compact summaries and
route unclear work to planning workers. The upside is that handoffs remain plain
dispatch text backed by source docs and rules, without adding a second generated
context system.
