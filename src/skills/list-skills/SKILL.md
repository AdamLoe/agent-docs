---
name: list-skills
description: Report the canonical source skill inventory, project skills, and installed adapter freshness.
---

You are the orchestrator for a report-only skill-inventory listing. Report the
canonical agent-docs source skills, project-local skills, and whether the
installed Claude/Codex adapter copies are fresh. Do not invent skills, and do
not run any listed skill.

## Bootstrap

Read `~/.agentdocs/rules/skill-contracts.md` and run the **Standard Intake
Protocol**. This skill is **state-driven**: it runs off the registry and on-disk
skill state, so it skips both intake questions and never stops to prompt. Honor
any filter passed in `$ARGUMENTS` (a case-insensitive substring matched against
skill names and descriptions); dials are inert here.

Read the inventory state inline:

- `~/.agentdocs/skills/registry.md` — the skill inventory of record.
- `~/.agentdocs/skills/*/SKILL.md` frontmatter (`name:`, `description:`).

A helper ships beside this skill to do the on-disk scan, freshness comparison,
and formatting:

```sh
bash ~/.agents/skills/list-skills/list-skills.sh "$ARGUMENTS"
```

From another adapter, use that copied skill path instead, e.g.
`bash ~/.claude/skills/list-skills/list-skills.sh "$ARGUMENTS"`. The helper
lists `~/.agentdocs/skills/<name>` as the canonical source inventory, scans
project skills in the current repo's `.agents/skills/<name>` and
`.claude/skills/<name>`, and compares installed copies in
`~/.agents/skills/<name>` and `~/.claude/skills/<name>` to the source. Built-in /
plugin skills are not reliably globbable; if the session's available-skills list
names skills the scans miss, include them under a best-effort
"Built-in / plugin" group.

## Worker phases

Usually **none.** Reading the registry and frontmatter and emitting the grouped
list is inline routing/IO — there is nothing to fan out or isolate, so do not
invent a one-line worker to satisfy the shape.

Dispatch a worker only when the request crosses the boundary:

- **Consistency gate** (registry/frontmatter cross-check) → profile
  `verification.readonly`, scoped to the skill inventory.
- **Deep freshness evidence** (exact stale file names under `~/.agents/skills/`
  or `~/.claude/skills/`) → profile `verification.readonly`, scoped to that
  comparison.

This skill's kernel workflow is `list-skills`; `src/kernel/workflows.json` is the
machine authority for its phase sequence and allowed profiles (it is inline by
default — a worker runs only for the optional consistency/freshness check above).
Each dispatch names that profile's exact rule files directly; `--resolve` is a
source-only authoring aid, not a runtime worker step.

## Closeout

Report:

- the skill list grouped by source/category — **Source (agent-docs)**,
  **Project**, **Built-in / plugin** — one line per skill as
  `` - `/<name>` — <description> ``, descriptions trimmed to the first sentence.
- installed adapter freshness for Claude and Codex.
- any registry mismatches, missing skill directories, or stale adapter copies if
  discovered.
- a no-change result: this skill only reports. Repairs go through another skill,
  not here.

$ARGUMENTS
