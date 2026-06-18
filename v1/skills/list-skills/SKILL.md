---
name: list-skills
description: List the skills available in this session, grouped by adapter source.
---

You are listing the skills available right now. Skills are prompt directories
containing a `SKILL.md` whose frontmatter `description:` is the one-liner
shown to the user. Produce a grouped inventory — do not invent skills, only
report what actually exists.

This skill runs directly — no intake questions and no dials apply. (It is a
pure inventory utility; the shared contracts in
`~/agent-docs/v1/rules/skill-contracts.md` are not needed here.)

## How to gather

Run the helper shipped beside this skill:

```sh
bash ~/.agents/skills/list-skills/list-skills.sh "$ARGUMENTS"
```

When running from another adapter, use that copied skill path instead, e.g.
`bash ~/.claude/skills/list-skills/list-skills.sh "$ARGUMENTS"`. The optional
argument is a case-insensitive filter substring matched against skill names and
descriptions.

The helper scans:

- Global skills copied into `~/.agents/skills/<name>` and
  `~/.claude/skills/<name>` by `v1/copy-skills.sh`.
- Project skills in the current repo's `.agents/skills/<name>` and
  `.claude/skills/<name>` directories, if present.

**Built-in / plugin skills** are not files you can reliably glob.
If the session's available-skills list names skills not found by the scans
above, include them under a "Built-in / plugin" group, labelled best-effort.

## How to report

Group by origin, in this order: **Global (agent-docs)**, **Project**,
**Built-in / plugin**. For each skill, one line:

```
- `/<name>` — <description>
```

The helper already formats file-discoverable skills this way and keeps
descriptions to their first sentence if they are long. If you add a
best-effort built-in/plugin group, keep the helper's source-of-truth note as
the final line. Do not run any of the listed skills — only list them.

Arguments (optional filter substring): $ARGUMENTS

If an argument is given, list only skills whose name or description contains
it (case-insensitive).
