# agent-docs decisions

## Source/runtime split

**Decision.** The editable source checkout lives at the repo root with the
exported kit under `src/`. The installed runtime is always at `~/.agentdocs/`;
skills, rules, templates, and consuming-repo docs self-reference
`~/.agentdocs/...` as the only stable runtime path. `v1/` is retired as a
runtime versioning term; `src/` is the source directory name only.

**Why.** Separating source from runtime means local edits to the source
checkout do not affect other projects until an installer runs explicitly. A
fixed global runtime path keeps all consuming repos pointing at the same
location regardless of where the source is cloned.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../README.md`](../../README.md).

## Two-installer model (install equals update)

**Decision.** There are two install entry points; update is the same operation
as install. `install-agentdocs-local.sh` (top-level) is the dogfood/dev path:
it publishes the local `src/` bundle into `~/.agentdocs/` (source kind
`local`). `src/install-agentdocs.sh` (bundled) is the normal user path: it
downloads a GitHub codeload archive from `AdamLoe/agent-docs` (default `main`
branch or a named tag), validates bundle shape, then atomically replaces
`~/.agentdocs/` (source kind `github`). Even when called from a checkout, the
GitHub installer installs from GitHub — not local source. There is no separate
update script.

**Why.** Keeping install and update as one operation eliminates a separate
update command that can drift. Two entry points preserve the explicit dogfood
path without hiding it behind a flag.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../install-agentdocs-local.sh`](../../install-agentdocs-local.sh), [`../../src/install-agentdocs.sh`](../../src/install-agentdocs.sh).

## Agent install/update requires explicit user permission

**Decision.** An agent must not run any agent-docs installer
(`install-agentdocs-local.sh`, `src/install-agentdocs.sh`, or
`~/.agentdocs/install-agentdocs.sh`) without first proposing it and receiving
explicit user confirmation.

**Why.** Running an installer atomically replaces `~/.agentdocs/` and refreshes
or deletes managed skill copies under `~/.claude/skills/` and
`~/.agents/skills/`. This is a destructive operation against the user's home
environment; autonomous execution is not recoverable without a re-install.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../src/rules/repo-rules.md`](../../src/rules/repo-rules.md).

## Tool paths are adapters

**Decision.** Claude and Codex both use copied user skill directories: the
installers copy agent-docs skills from `~/.agentdocs/skills/` into
`~/.claude/skills/<name>` and `~/.agents/skills/<name>` and mark each copy
with `.agent-docs-managed`. The tool skill roots themselves stay tool-owned;
symlinked roots are refused. Claude plugin manifests are not a supported
adapter path.

**Why.** Tools discover skills differently, but the command bodies should not
fork. Using the same copy model for both tools avoids adapter-specific
surprises, while the marker lets refreshes update only agent-docs copies.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Managed-skill deletion policy

**Decision.** The per-skill `.agent-docs-managed` marker file is the deletion
authority. On install, stale managed skills (marker present, no longer in the
runtime bundle) are pruned. An unmanaged same-name skill collision stops the
install with an error — the installer never silently deletes unowned user
content. There is no force flag.

**Why.** Tying deletion to the per-skill marker means no external manifest is
needed to track which skills to remove. Stopping on unmanaged conflicts
protects personal user skills; a clear error is better than a silent override.

**Alternatives considered.** A force flag for collision override — rejected
because it too easily destroys unowned user content without confirmation.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Install manifest is provenance only

**Decision.** `~/.agentdocs/.agentdocs-install-manifest` records source kind,
source path or tag, source URL (GitHub installs), and install timestamp. It is
not the skill-deletion authority and is not consulted to decide what to remove.

**Why.** The manifest answers "where did this runtime come from and when?" —
a lightweight provenance record. Deletion logic belongs in the per-skill
marker, not in a manifest that could get out of sync with actual installed
content.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Skill refresh is embedded in installers

**Decision.** After replacing `~/.agentdocs/`, both installers run the
managed-skill copy logic inline. The retired `copy-skills.sh` is removed;
there is no standalone refresh command. After skill changes in `src/`, run the
local installer then the verifier.

**Why.** Embedding refresh in the installers removes a separate script that
could be forgotten or drift. The manifest gate checks adapter freshness.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Router-only auto-loaded files

**Decision.** Root `AGENTS.md` and `CLAUDE.md` exist only as routers to the
docs entry point. They must not own architecture, decisions, or app facts.

**Why.** Always-loaded fact dumps drift and crowd the context window. Routers
keep startup cheap while preserving the normal docs tree as the owner.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../src/rules/authoring-rules.md`](../../src/rules/authoring-rules.md).

## Overview is task-routed

**Decision.** Standard skill startup reads `~/.agentdocs/rules/skill-contracts.md`,
the manifest slots needed by the skill, and `docs/index.md`;
`docs/overview.md` is loaded only when the task needs system-shape orientation
or a skill names it as task input.

**Why.** The route audit showed every skill can classify from its own body,
manifest slots, and the docs index. Making overview optional keeps repeated
startup cache-stable without losing the one-screen orientation route.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/skill-contracts.md`](../../src/rules/skill-contracts.md), [`../../src/skills/`](../../src/skills/).

## Work ships through `/ship-current-work`

**Decision.** Ordinary changes finish through `/ship-current-work`.
`/wrap-up-current-chat` is reserved for chat-only memory capture.

**Why.** Shipping is more than chat summarization: it includes diff review,
owning-doc updates, manifest gates, plan migration, staging, and commit.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/ship-current-work/SKILL.md`](../../src/skills/ship-current-work/SKILL.md).

## Planning uses `/plan`

**Decision.** The planning entry point is `/plan`, backed by
`src/skills/plan/SKILL.md`; the older `fresh-planning-chat` name is retired.

**Why.** Planning is a first-class workflow, not just a fresh-chat variant.
The shorter command makes it clear that the agent owns concern-shaping,
implementer briefs, and high-level plan/doc routing.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/plan/SKILL.md`](../../src/skills/plan/SKILL.md).

## Skill contracts are shared

**Decision.** Suite-wide skill metadata and reusable skill policy live in
`src/skills/registry.md` and `src/rules/skill-contracts.md`.

**Why.** Repeating mode, bootstrap, shipping, and model-tier policy inside
every skill makes the skills drift from each other. A registry plus shared
contracts gives the doctor and skill-review flows something concrete to
validate.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/registry.md`](../../src/skills/registry.md), [`../../src/rules/skill-contracts.md`](../../src/rules/skill-contracts.md).

## Verifier modes are explicit

**Decision.** `src/verify-agent-docs.sh` with no arguments validates the
agent-docs source checkout that contains the script. Consuming repos use the
target-aware scaffold mode: `~/.agentdocs/verify-agent-docs.sh --scaffold
<repo-root>`. When run outside the source repo, the verifier prints a
`--scaffold` directive and exits 0.

**Why.** A script reached through `~/.agentdocs/` resolves to the runtime
bundle, not to the caller's repository. Making the target explicit prevents a
rebuild from appearing verified when only the shared kit was checked.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/verify-agent-docs.sh`](../../src/verify-agent-docs.sh), [`../../src/skills/rebuild-agent-docs/SKILL.md`](../../src/skills/rebuild-agent-docs/SKILL.md), [`../../src/skills/doctor/SKILL.md`](../../src/skills/doctor/SKILL.md).

## Startup checks route to existing skills

**Decision.** `/start-session` is the local beginning-of-day/session check for
git state, plan state, and cleanup candidates, but it delegates mutation to
the existing workflow skills.

**Why.** Startup should make the next action obvious without creating a second
implementation, cleanup, or orchestration path that can drift from the owning
skills.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/start-session/SKILL.md`](../../src/skills/start-session/SKILL.md), [`../../src/skills/clear-plans/SKILL.md`](../../src/skills/clear-plans/SKILL.md).

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

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/clear-plans/SKILL.md`](../../src/skills/clear-plans/SKILL.md), [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md).

## Command names favor short job labels

**Decision.** Workflow commands use short job-oriented names and the skill
registry groups them by job family.

**Why.** Agents choose commands more reliably when the command surface is
compact and grouped by intent instead of exposed as one long undifferentiated
list.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/registry.md`](../../src/skills/registry.md).

## Skill listing reports source plus freshness

**Decision.** `/list-skills` reports the canonical `~/.agentdocs/skills/`
inventory, project-local skill directories, and freshness of the installed
Claude/Codex adapter copies.

**Why.** Source skill bodies are the contract of record, while tool adapters
are copied discovery surfaces that can go stale. Listing both prevents an
installed copy from being mistaken for the authoritative inventory.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/list-skills/SKILL.md`](../../src/skills/list-skills/SKILL.md), [`../../src/skills/registry.md`](../../src/skills/registry.md).

## Feedback inbox lives in the runtime and survives installs

**Decision.** `/feedback-agent-docs` appends kit-level feedback to
`~/.agentdocs/feedback.jsonl`. Both installers save this file before the atomic
runtime replace and restore it afterward, so a feedback log is never wiped by
an install or update.

**Why.** The inbox must be a low-friction capture queue — including while
dogfooding inside the kit repo — without creating accidental untracked source
changes. Moving it into `~/.agentdocs/` (the runtime, outside any source
checkout) removes the need for a `.gitignore` entry. Preserving it across
installs means accumulated feedback survives a `main`-branch update.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../src/skills/feedback-agent-docs/SKILL.md`](../../src/skills/feedback-agent-docs/SKILL.md), [`../../install-agentdocs-local.sh`](../../install-agentdocs-local.sh), [`../../src/install-agentdocs.sh`](../../src/install-agentdocs.sh).

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
control (`src/rules/orchestrator/`) from worker roles (`src/rules/subagent/`)
keeps orchestrator context lean and worker prompts clean, and passing exact
rule-file links — instead of copied prose or open-ended "discover the system"
instructions — keeps dispatch cheap and unambiguous. User-facing skill *names*
stay the same because the change is internal execution model, not command
surface; a missing worker-dispatch capability is an error to report, not a
reason to inline.

**Alternatives considered.** A direct/delegated boolean per skill — rejected
because it reintroduced the two-jobs problem and a per-skill "should I
delegate?" debate the docs spent context re-litigating.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/skill-contracts.md`](../../src/rules/skill-contracts.md), [`../../src/rules/orchestrator/`](../../src/rules/orchestrator/), [`../../src/rules/subagent/`](../../src/rules/subagent/), [`../../src/skills/registry.md`](../../src/skills/registry.md).

## Commit-heavy worker shipping

**Decision.** Editing workers commit their own completed slice before
reporting; follow-up workers repair or revert through additional commits.
Editing is serial per working tree because concurrent commits race the git
index, and parallel editing uses worktree isolation or orchestrator-applied
patches. Each mutating worker snapshots dirty state, preserves unrelated user
changes and deletions, stages only owned paths by filename, and stops if
unrelated dirty state blocks a coherent slice. The orchestrator records commit
hashes and verifies the final observed state; the user squashes later if
desired.

**Why.** Workers own their slice end to end, so the commit belongs with the
worker that verified it green. Serial-by-default editing avoids index races
that file-ownership fences cannot prevent.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/orchestrator/`](../../src/rules/orchestrator/), [`../../src/rules/subagent/`](../../src/rules/subagent/).

## Source-first compact handoffs

**Decision.** Worker dispatch is source-first and compact: orchestrators pass
exact rule links and path plus heading/search hints, workers read authoritative
docs/source directly for exact details, and carry-forward summaries contain
only observed decisions, findings, touched files, gates, commits, blockers, and
assumptions.

**Why.** Summaries are useful continuity, but they become risky when they
replace the document or source that owns the fact. Keeping dispatch packets and
reports short saves output tokens without weakening evidence.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md), [`../../src/rules/orchestrator/lifecycle.md`](../../src/rules/orchestrator/lifecycle.md), [`../../src/rules/subagent/`](../../src/rules/subagent/).

**Tradeoffs.** Workers spend some input reading source docs directly, but the
workflow avoids stale generated context and large prior-transcript handoffs.

## Context profiles before usage reports

**Decision.** Agent-docs enforces context economy with static layer contracts,
word-count budgets, a canonical `src/rules/context-profiles.md` owner, and the
read-only `src/verify-agent-docs.sh --context-report` resolver. Worker reports
include runtime usage counts only when raw counts are exposed by the runtime or
explicitly requested.

**Why.** Deterministic profile reports and scenario rows catch context drift
without requiring every adapter to expose identical runtime metrics. Optional
raw counts can inform later review, but they are not default boilerplate.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/context-profiles.md`](../../src/rules/context-profiles.md), [`../../src/rules/authoring-rules.md`](../../src/rules/authoring-rules.md), [`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md), [`../../src/verify-agent-docs.sh`](../../src/verify-agent-docs.sh).

## Final-state shipping order

**Decision.** Mutating workflows finish all code, docs, plan-frontmatter, and
run-doc mutations before running the final consolidated drift gate, then report
from that verified final state. Review and verification workers are read-only;
findings route back to implementation, docs-maintenance, or plan-maintenance.

**Why.** A gate run before plan status or doc migration does not prove the
state the user receives. Mutation authority must match the context profile that
tells a worker how to edit, verify, stage, and commit safely.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/orchestrator/lifecycle.md`](../../src/rules/orchestrator/lifecycle.md), [`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md), [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md).

## Orchestrate coordinates specialists

**Decision.** `/orchestrate` is a lifecycle controller that dispatches
planning, plan-review, implementation, work-review, or quick-fix worker phases
instead of reimplementing them inline.

**Why.** Broad change work needs continuity across phases, but the best way to
keep quality and context under control is to preserve specialist worker
boundaries and let the orchestrator hold only the map, evidence, assumptions,
and next action.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/orchestrate/SKILL.md`](../../src/skills/orchestrate/SKILL.md), [`../../src/rules/orchestrator/`](../../src/rules/orchestrator/).

## Orchestration run docs are opt-in

**Decision.** `/orchestrate` creates
`docs/plans/orchestrator/<run-slug>/` only when the user asks for stateful run
docs or grants permission after the orchestrator explains a concrete resume
risk.

**Why.** Persistent run state is valuable for long multi-agent work, but
making it the default would create extra temporary documentation for ordinary
changes. Keeping the mode inside `/orchestrate` preserves the compact command
surface and avoids reviving retired orchestration command names.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/skills/orchestrate/SKILL.md`](../../src/skills/orchestrate/SKILL.md), [`../../src/rules/orchestrator/run-docs.md`](../../src/rules/orchestrator/run-docs.md), [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md).

**Tradeoffs.** Default runs are less resumable after context loss, but they
avoid committed coordination folders unless the user accepts that cost.

## Focused handoffs over generated context

**Decision.** The active kit lowers context through focused worker roles,
planner-produced implementation briefs, and concise orchestrator carry-forward
summaries.

**Why.** The useful part of the generated-context exploration was
deterministic, source-backed, role-specific input. The cost was extra
infrastructure: generated workspaces, packet helpers, YAML metadata, parser
work, and launcher behavior that became another workflow surface to keep
correct. The focused handoff model gets the benefit without the infrastructure.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md), [`../../src/rules/orchestrator/lifecycle.md`](../../src/rules/orchestrator/lifecycle.md), [`../../src/rules/subagent/planning.md`](../../src/rules/subagent/planning.md).

**Alternatives considered.** Generated repo-local workspaces, metadata v2,
packet helper scripts, generated context artifacts, and broader `docs/index.md`
skill routing.

**Tradeoffs.** Orchestrators still need discipline to pass compact summaries
and route unclear work to planning workers. The upside is that handoffs remain
plain dispatch text backed by source docs and rules, without adding a second
generated context system.
