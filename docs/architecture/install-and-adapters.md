# Install and adapters

The physical checkout may live anywhere. The canonical self-reference path is
`~/agent-docs`; `v1/install.sh` makes that path resolve to the physical checkout
when the checkout lives somewhere else. Stable kit files live under `v1/`.
Tool-owned paths are adapters only.

## Discovery contract

| Path | Target | Purpose |
|---|---|---|
| `AGENTS.md` | `docs/index.md` | Root router for agent tools that auto-load it. |
| `CLAUDE.md` | `docs/index.md` | Root router for Claude. |
| `~/.claude/skills/<name>` | copied from `~/agent-docs/v1/skills/<name>` | Claude personal skill discovery. Agent-docs copies carry `.agent-docs-managed`. |
| `~/.agents/skills/<name>` | copied from `~/agent-docs/v1/skills/<name>` | Codex native user skill discovery. Agent-docs copies carry `.agent-docs-managed`. |

`~/agent-docs` is the stable way docs and skills refer back to the kit. It
points at the checkout root, not at `v1/`; the version segment remains explicit
wherever a file path enters the kit. Claude plugin manifests are not a supported
adapter path for this repo. Root auto-loaded files are router-only adapters and
must not own architecture, decisions, or workflow facts; `docs/overview.md` is
read through the docs index when a task needs system-shape orientation.

## Installer

Run:

```sh
bash ~/agent-docs/v1/install.sh ~/agent-docs
```

If the checkout lives somewhere else, pass the physical checkout path:

```sh
bash /path/to/agent-docs/v1/install.sh /path/to/agent-docs
```

The installer verifies:

- `~/agent-docs/v1/rules/authoring-rules.md`
- `~/.claude/skills/fresh-chat/SKILL.md`
- `~/.claude/skills/plan/SKILL.md`
- `~/.agents/skills/fresh-chat/SKILL.md`
- `~/.agents/skills/plan/SKILL.md`

`v1/install.sh --dry-run` reports the canonical path and copied-adapter actions
without mutating `$HOME`. The installer always targets the documented Claude and
Codex skill roots; it ignores `AGENT_DOCS_SKILLS_DEST` when calling
`v1/copy-skills.sh`.

## After skill changes

When a skill is added, renamed, or removed under `v1/skills/`, run:

```sh
bash ~/agent-docs/v1/copy-skills.sh ~/agent-docs
bash ~/agent-docs/v1/copy-skills.sh --check ~/agent-docs
```

The copy script is the only tool-discovery path this repo manages. It treats the
tool skill root directories as tool-owned roots and refuses to replace them when
they are symlinks. Inside a real skill root, it marks copied skills with
`.agent-docs-managed` and only replaces/removes child skill directories carrying
that marker, so unrelated personal skills in `~/.claude/skills` and
`~/.agents/skills` are left alone.

Before deleting stale managed children or refreshing any skill, `copy-skills.sh`
preflights every source skill name for unmanaged destination conflicts.
`--dry-run` reports the copy/remove actions without mutating the destination.
`--check` is read-only and fails when a managed copied skill is missing, stale,
left behind after a source rename, unmanaged at a source skill name, or rooted at
a symlinked skill directory. Restart the tool if refreshed skills do not appear
in the current session.

`AGENT_DOCS_SKILLS_DEST=/tmp/some-skills-root` is a public testing hook for
`v1/copy-skills.sh`: it makes copy, dry-run, and check mode operate on that one
destination instead of both tool roots. It is not part of installer behavior.

## Reference convention

Stable docs and skills use `~/agent-docs/v1/...` for kit files. Relative links
are fine inside repo Markdown when they point to neighboring docs.

## See also

- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`workflow-kit.md`](workflow-kit.md)
- [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md)
