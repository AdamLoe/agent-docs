# Install and adapters

The agent-docs source checkout and the installed runtime are separate paths.
The source kit lives under `src/` in the checkout. The runtime is always
at `~/.agentdocs/`; skills, rules, templates, and consuming-repo docs
self-reference `~/.agentdocs/...` as the only stable runtime path.
Tool-owned paths are adapters only.

## Discovery contract

| Path | Target | Purpose |
|---|---|---|
| `AGENTS.md` | `docs/index.md` | Root router for agent tools that auto-load it. |
| `CLAUDE.md` | `docs/index.md` | Root router for Claude. |
| `~/.claude/skills/<name>` | copied from `~/.agentdocs/skills/<name>` | Claude personal skill discovery. Copies carry `.agent-docs-managed`. |
| `~/.agents/skills/<name>` | copied from `~/.agentdocs/skills/<name>` | Codex native user skill discovery. Copies carry `.agent-docs-managed`. |

Root auto-loaded files are router-only adapters and must not own architecture,
decisions, or workflow facts. `docs/overview.md` is read through the docs
index when a task needs system-shape orientation.

## Installers

Install and update are the same operation. Two entry points, both supporting
`--dry-run`.

### `src/install-agentdocs.sh` (GitHub installer)

The normal user install path. Accepts an optional tag argument; defaults to
the `main` branch. Downloads a GitHub codeload archive from
`AdamLoe/agent-docs`, validates the bundle shape, stages in a temp directory,
then atomically replaces `~/.agentdocs/`. Runs both from a source checkout
and from the installed runtime (`~/.agentdocs/install-agentdocs.sh`). Even
when called from a checkout, it installs from GitHub — not from local source.

```sh
bash src/install-agentdocs.sh          # install from main branch
bash src/install-agentdocs.sh <tag>    # install a specific tag
```

### `install-agentdocs-local.sh` (dev/dogfood installer)

The development path. Publishes the local `src/` bundle to `~/.agentdocs/`.
Source edits do not affect other projects until this runs intentionally.

```sh
bash install-agentdocs-local.sh
```

Both installers write `.agentdocs-install-manifest` at the runtime root
(provenance only: source kind, path or tag, and timestamp), then refresh the
managed skill copies.

## Managed skill adapter refresh

After replacing the runtime bundle, both installers copy every skill directory
from `~/.agentdocs/skills/` into `~/.claude/skills/<name>` and
`~/.agents/skills/<name>`. Each copied skill is marked with
`.agent-docs-managed`.

**Deletion policy.** The per-skill `.agent-docs-managed` marker file is the
deletion authority. On install, stale managed skills (marker present, no
longer in the runtime bundle) are pruned. Unmanaged skills at a source skill
name stop the install with an error — the installer never silently deletes
unowned user content. There is no force flag. Destination skill-root symlinks
are refused.

**No separate refresh step.** The retired `copy-skills.sh` is replaced by
the skill-refresh logic embedded in both installers. Run the appropriate
installer after skill changes; the manifest gate checks freshness.

## See also

- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`workflow-kit.md`](workflow-kit.md)
- [`../../src/rules/authoring-rules.md`](../../src/rules/authoring-rules.md)
