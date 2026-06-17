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

1. **Global / personal skills** — read the personal discovery roots directly:

   ```sh
   for f in ~/.claude/skills/*/SKILL.md; do
     [ -e "$f" ] || continue
     printf '%s\n' "$f"
     awk '/^description:/{sub(/^description: */,""); print; exit}' "$f"
   done
   for f in ~/.agents/skills/*/SKILL.md; do
     [ -e "$f" ] || continue
     printf '%s\n' "$f"
     awk '/^description:/{sub(/^description: */,""); print; exit}' "$f"
   done
   ```

   Claude skills are copied into `~/.claude/skills/<name>` and Codex user
   skills are copied into `~/.agents/skills/<name>` by `v1/copy-skills.sh`.

2. **Project skills** — same scan against the current repo, if present:

   ```sh
   for f in ./.claude/skills/*/SKILL.md; do
     [ -e "$f" ] || continue
     printf '%s\n' "$f"
     awk '/^description:/{sub(/^description: */,""); print; exit}' "$f"
   done
   for f in ./.agents/skills/*/SKILL.md; do
     [ -e "$f" ] || continue
     printf '%s\n' "$f"
     awk '/^description:/{sub(/^description: */,""); print; exit}' "$f"
   done
   ```

3. **Built-in / plugin skills** — these are not files you can reliably glob.
   If the session's available-skills list names skills not found by the scans
   above, include them under a "Built-in / plugin" group, labelled
   best-effort.

## How to report

Group by origin, in this order: **Global (agent-docs)**, **Project**,
**Built-in / plugin**. For each skill, one line:

```
- `/<name>` — <description>
```

Keep descriptions to their first sentence if they are long. End with a
one-line note on how the source of truth is organized: agent-docs global skills live in
`~/agent-docs/v1/skills/`; Claude reads copied skills in `~/.claude/skills/`
and Codex reads copied skills in `~/.agents/skills/`.
Project skills live in the repo's `.agents/skills/`. Do not run any of the listed
skills — only list them.

Arguments (optional filter substring): $ARGUMENTS

If an argument is given, list only skills whose name or description contains
it (case-insensitive).
