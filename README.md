# agent-docs

A portable, tool-neutral documentation system for LLM-assisted codebases:
a set of doc-authoring **rules** + workflow **commands** that any repo can
adopt, with each repo supplying only its own facts in `docs/_meta/`.

Repo: `github.com/AdamLoe/agent-docs`

## Source and runtime layout

The source checkout and the installed runtime are separate:

- **Source checkout** lives wherever you clone it (e.g. `~/agent-docs`). The
  exported kit lives under `src/` in the checkout.
- **Runtime** is always at `~/.agentdocs/`. Skills, rules, templates, and
  consuming-repo docs self-reference `~/.agentdocs/...`; the source path is
  not part of the runtime contract.

## Install / Update — REQUIRED

Install and update are the same operation. Two entry points:

**Normal install from GitHub (recommended):**

```sh
bash ~/.agentdocs/install-agentdocs.sh        # update from main branch
bash ~/.agentdocs/install-agentdocs.sh <tag>  # install a specific tag
```

Or run the bundled installer directly from a checkout:

```sh
git clone https://github.com/AdamLoe/agent-docs.git ~/agent-docs
bash ~/agent-docs/src/install-agentdocs.sh
```

This downloads a GitHub codeload archive of `AdamLoe/agent-docs` (default
`main` branch, or the named tag), validates the bundle shape, then atomically
replaces `~/.agentdocs/`. Even when run from a local checkout, it installs
from GitHub, not from local source.

**Dogfood / development install (source checkout only):**

```sh
bash ~/agent-docs/install-agentdocs-local.sh
```

Publishes the local `src/` bundle into `~/.agentdocs/`. Source edits do not
affect other projects until this runs. Use `--dry-run` to preview.

Both installers then refresh the managed Claude and Codex skill copies from
`~/.agentdocs/skills/` into `~/.claude/skills/<name>` and
`~/.agents/skills/<name>`.

> **Note for agents:** always propose an install or update and wait for
> explicit user confirmation before running any installer. Install and update
> replace `~/.agentdocs/` and refresh or delete managed skill copies; they
> are not safe to run autonomously.

## After skill changes (dogfood workflow)

After editing source skills, republish and verify:

```sh
bash ~/agent-docs/install-agentdocs-local.sh
bash src/verify-agent-docs.sh
```

## Reference convention

Skills, rules, and consuming-repo docs use the runtime path
`~/.agentdocs/...` as their stable self-reference:

- Use `~/.agentdocs/rules/authoring-rules.md`.
- Do not use relative paths like `../../rules/...` for kit references; a
  skill may be read through a copied adapter path.

## More detail

See [`docs/index.md`](docs/index.md) for the dogfood docs router:

- [`docs/architecture/install-and-adapters.md`](docs/architecture/install-and-adapters.md)
  covers the source/runtime split, installers, and per-tool adapters.
- [`docs/architecture/workflow-kit.md`](docs/architecture/workflow-kit.md)
  covers skills, rules, templates, and workflow commands.
- [`docs/decisions/agent-docs.md`](docs/decisions/agent-docs.md)
  records the durable decisions.
