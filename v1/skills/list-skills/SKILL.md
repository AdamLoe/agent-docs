---
name: list-skills
description: Report the available skill inventory, grouped by source/category.
---

You are the orchestrator for a report-only skill-inventory listing in the current
session. You report the skills that actually exist, grouped by source/category.
Reading the registry and skill frontmatter is inline routing work — the
orchestrator does it the same way `start-session` reads and summarizes plan
state, under the uniform reads-vs-dispatch boundary. This is not a separate
direct path; dispatch a worker only for the rare parts that cross that boundary.
Do not invent skills, and do not run any listed skill.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**. This skill is **state-driven**: it runs off the registry and on-disk
skill state, so it skips both intake questions and never stops to prompt. Honor
any filter passed in `$ARGUMENTS` (a case-insensitive substring matched against
skill names and descriptions); dials are inert here.

Then read, inline, the routing/IO state this listing is built from:

- `~/agent-docs/v1/skills/registry.md` — the skill inventory of record.
- `~/agent-docs/v1/skills/*/SKILL.md` frontmatter (`name:`, `description:`).
- `~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
  `~/agent-docs/v1/rules/orchestrator/dispatch.md` — to confirm the
  reads-vs-dispatch boundary and worker routing if a phase is warranted.

A helper ships beside this skill to do the on-disk scan and formatting:

```sh
bash ~/.agents/skills/list-skills/list-skills.sh "$ARGUMENTS"
```

From another adapter, use that copied skill path instead, e.g.
`bash ~/.claude/skills/list-skills/list-skills.sh "$ARGUMENTS"`. The helper scans
global skills copied into `~/.agents/skills/<name>` and `~/.claude/skills/<name>`
by `v1/copy-skills.sh`, plus project skills in the current repo's
`.agents/skills/<name>` and `.claude/skills/<name>`. Built-in / plugin skills are
not reliably globbable; if the session's available-skills list names skills the
scans miss, include them under a best-effort "Built-in / plugin" group.

## Worker phases

Usually **none.** Reading the registry and frontmatter and emitting the grouped
list is inline routing/IO under the reads-vs-dispatch test — there is nothing to
fan out or isolate, so do not invent a one-line worker to satisfy the shape.

Dispatch a worker only when the request crosses the boundary:

- **Verification worker** only when the user wants a registry/frontmatter
  consistency gate (e.g. every `<name>/SKILL.md` frontmatter matches its registry
  row and directory) rather than a plain listing. Pass
  `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`, scoped to the skill inventory.
- **Adapter-freshness worker** only when the user asks about installed copies
  (whether `~/.agents/skills/` and `~/.claude/skills/` match the `v1/` source).
  Pass `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`, scoped to that comparison.

## Closeout

Report:

- the skill list grouped by source/category — **Global (agent-docs)**,
  **Project**, **Built-in / plugin** — one line per skill as
  `` - `/<name>` — <description> ``, descriptions trimmed to the first sentence.
- any registry mismatches or missing skill directories if discovered.
- a no-change result: this skill only reports. Repairs go through another skill,
  not here.

$ARGUMENTS
