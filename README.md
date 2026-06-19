# agent-docs

A portable, tool-neutral documentation system for LLM-assisted codebases:
a set of doc-authoring **rules** + workflow **commands** that any repo can
adopt, with each repo supplying only its own facts in `docs/_meta/`.

Repo: `github.com/AdamLoe/agent-docs`

## Install — REQUIRED

Clone the repo anywhere, then run the installer from the checkout:

```sh
git clone https://github.com/AdamLoe/agent-docs.git ~/agent-docs
bash ~/agent-docs/v1/install.sh
```

`v1/install.sh` copies the agent-docs skills into the Claude and Codex user
skill directories. It verifies that `~/agent-docs/v1/...` plus sample skills
resolve through both tools.
If the real checkout lives somewhere else, pass that path:

```sh
bash /path/to/agent-docs/v1/install.sh /path/to/agent-docs
```

Tool-owned paths are adapters only.

## The three-layer model

The real checkout lives at:

```text
~/agent-docs/
```

Tools discover skills through their own adapter paths:

- Claude Code reads copied skill entries from `~/.claude/skills/<name>`.
- Codex reads copied user skills from `~/.agents/skills/<name>`. In this repo
  setup, `v1/copy-skills.sh` refreshes both tool copies from
  `~/agent-docs/v1/skills/<name>`.

The kit remains the source of truth. Tool discovery dirs get refreshed copies;
run `bash ~/agent-docs/v1/copy-skills.sh` after adding, renaming, or deleting
skills, then run `bash ~/agent-docs/v1/copy-skills.sh --check` to confirm the
copied adapters match the source.

## Reference convention

Anything that points at the kit uses the absolute path
`~/agent-docs/<version>/...`:

- Use `~/agent-docs/v1/rules/authoring-rules.md`.
- Do not use relative paths like `../../rules/...` for kit references; a
  skill may be read through a symlinked discovery path.
- Do not use tool-specific roots such as `${CLAUDE_PLUGIN_ROOT}` for the
  standard symlinked install.

Relative links are still fine inside ordinary Markdown files when they
link to neighboring files in the same repo.

## Layout & versioning

```text
~/agent-docs/
  README.md          <- this file, the install summary
  AGENTS.md          <- router-only entry point for agent tools
  CLAUDE.md          <- router-only entry point for Claude
  docs/              <- architecture, decisions, agent-context, plans
  v1/                <- the kit: skills/, rules/, plan-lifecycle.md,
                       plan-template.md, agent-docs-guide.md
```

A consuming repo pins its version via `agent_docs_version` in
`docs/_meta/manifest.md`. Old repos stay on their version untouched; new
repos adopt the latest.

## More detail

See [`docs/index.md`](docs/index.md) for the dogfood docs router:

- [`docs/architecture/install-and-adapters.md`](docs/architecture/install-and-adapters.md)
  covers the symlink contract and per-tool adapters.
- [`docs/architecture/workflow-kit.md`](docs/architecture/workflow-kit.md)
  covers skills, rules, templates, and workflow commands.
- [`docs/decisions/agent-docs.md`](docs/decisions/agent-docs.md)
  records the durable decisions.
