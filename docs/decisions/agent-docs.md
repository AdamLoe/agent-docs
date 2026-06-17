# agent-docs decisions

## Neutral checkout path

**Decision.** The real checkout lives at `~/agent-docs`; versioned kit files
live under `v1/`.

**Why.** The kit is shared by Claude, Codex, and future tools. A neutral
checkout path keeps the source from appearing owned by one tool.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../README.md`](../../README.md).

## Tool paths are adapters

**Decision.** Claude and Codex both use copied user skill directories:
`v1/copy-skills.sh` copies agent-docs skills into `~/.claude/skills/<name>`
and `~/.agents/skills/<name>` and marks them with `.agent-docs-managed`.

**Why.** Tools discover skills differently, but the command bodies should not
fork. Using the same copy model for both tools avoids adapter-specific
surprises, while the marker lets refreshes update only agent-docs copies.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md).

## Skill updates use the copy refresh

**Decision.** After agent-docs skills change, run `v1/copy-skills.sh` to
refresh Claude's `~/.claude/skills` and Codex's `~/.agents/skills`
directories with marked agent-docs-managed copies, then run
`v1/copy-skills.sh --check` to prove those copies match the source.

**Why.** Tool sessions may not notice newly-created source directories. A
dedicated copy refresh makes the update step explicit while preserving
unrelated personal skills; the read-only check catches stale installed command
bodies before a future agent starts from the wrong instructions.

**Applies to.** [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md), [`../../v1/copy-skills.sh`](../../v1/copy-skills.sh).

## Router-only auto-loaded files

**Decision.** Auto-loaded files such as `AGENTS.md` or `CLAUDE.md` may exist
only as routers. They must not own architecture, decisions, or app facts.

**Why.** Always-loaded fact dumps drift and crowd the context window. Routers
keep startup cheap while preserving the normal docs tree as the owner.

**Applies to.** [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md).

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

## Orchestrate coordinates specialists

**Decision.** `/orchestrate` is a lifecycle controller that dispatches
the existing planning, plan-review, implementation, work-review, or quick-fix
flows instead of reimplementing them inline.

**Why.** Broad change work needs continuity across phases, but the best way to
keep quality and context under control is to preserve specialist skill
boundaries and let the orchestrator hold only the map, evidence, assumptions,
and next action.

**Applies to.** [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md), [`../../v1/skills/orchestrate/SKILL.md`](../../v1/skills/orchestrate/SKILL.md), [`../../v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md).
