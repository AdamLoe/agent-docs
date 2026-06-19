# Install and adapters

This repo's real checkout is `~/agent-docs`. Stable kit files live under `v1/`.
Tool-owned paths are adapters only.

## Discovery contract

| Path | Target | Purpose |
|---|---|---|
| `AGENTS.md` | `docs/index.md`, `docs/overview.md` | Root router for agent tools that auto-load it. |
| `CLAUDE.md` | `docs/index.md`, `docs/overview.md` | Root router for Claude. |
| `~/.claude/skills/<name>` | copied from `~/agent-docs/v1/skills/<name>` | Claude personal skill discovery. Agent-docs copies carry `.agent-docs-managed`. |
| `~/.agents/skills/<name>` | copied from `~/agent-docs/v1/skills/<name>` | Codex native user skill discovery. Agent-docs copies carry `.agent-docs-managed`. |

`~/agent-docs` stays the checkout root, not a symlink to `v1/`; the version
segment remains explicit wherever a file path enters the kit. Claude plugin
manifests are not a supported adapter path for this repo. Root auto-loaded files
are router-only adapters and must not own architecture, decisions, or workflow
facts.

## Installer

Run:

```sh
bash ~/agent-docs/v1/install.sh ~/agent-docs
```

The installer verifies:

- `~/agent-docs/v1/rules/authoring-rules.md`
- `~/.claude/skills/fresh-chat/SKILL.md`
- `~/.claude/skills/plan/SKILL.md`
- `~/.agents/skills/fresh-chat/SKILL.md`
- `~/.agents/skills/plan/SKILL.md`

## After skill changes

When a skill is added, renamed, or removed under `v1/skills/`, run:

```sh
bash ~/agent-docs/v1/copy-skills.sh ~/agent-docs
bash ~/agent-docs/v1/copy-skills.sh --check ~/agent-docs
```

The copy script is the only tool-discovery path this repo manages. It marks
copied skills with `.agent-docs-managed` and only replaces/removes skills
carrying that marker, so unrelated personal skills in `~/.claude/skills` and
`~/.agents/skills` are left alone. `--check` is read-only and fails when a
managed copied skill is missing, stale, or left behind after a source rename.
Restart the tool if refreshed skills do not appear in the current session.

## Reference convention

Stable docs and skills use `~/agent-docs/v1/...` for kit files. Relative links
are fine inside repo Markdown when they point to neighboring docs.

## See also

- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`workflow-kit.md`](workflow-kit.md)
- [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md)
