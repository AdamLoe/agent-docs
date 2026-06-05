---
description: List the skills available in this session — global agent-docs skills, this repo's project skills, and (best-effort) built-in/plugin skills — each with its one-line description and where it lives. Use when the user asks "what skills do I have", "list my skills", or wants to discover what commands exist.
---

You are listing the skills available right now. Skills are prompt
directories containing a `SKILL.md` whose frontmatter `description:` is the
one-liner shown to the user. Produce a grouped, readable inventory — do not
invent skills, only report what actually exists.

## How to gather

1. **Global / personal skills** — read the `SKILL.md` frontmatter under the
   personal skills dir:

   ```sh
   for f in ~/.claude/skills/*/SKILL.md; do
     printf '%s\n' "$f"
     awk '/^description:/{sub(/^description: */,""); print; exit}' "$f"
   done
   ```

   Note: `~/.claude/skills` is a symlink to
   `~/.claude/agent-docs/v1/skills` (the agent-docs kit is the source of
   truth), so these are the portable agent-docs commands.

2. **Project skills** — same scan against the current repo, if present:

   ```sh
   for f in ./.claude/skills/*/SKILL.md; do
     [ -e "$f" ] || continue
     printf '%s\n' "$f"
     awk '/^description:/{sub(/^description: */,""); print; exit}' "$f"
   done
   ```

3. **Built-in / plugin skills** — these are not files you can reliably
   glob. If the session's available-skills list (the one provided to you in
   context) names skills not found by the scans above, include them under a
   "Built-in / plugin" group, labelled best-effort. Do not fabricate
   descriptions; use the one from the available-skills list verbatim.

## How to report

Group by origin, in this order: **Global (agent-docs)**, **Project**,
**Built-in / plugin**. For each skill, one line:

```
- `/<name>` — <description>
```

Keep descriptions to their first sentence if they are long. End with a
one-line note on how the source of truth is organized (global skills live
in `~/.claude/agent-docs/v1/skills/`; project skills in the repo's
`.claude/skills/`). Do not run any of the listed skills — only list them.

Arguments (optional filter substring): $ARGUMENTS

If an argument is given, list only skills whose name or description contains
it (case-insensitive).
