# agent-docs

A portable, tool-neutral documentation system for LLM-assisted codebases:
a set of doc-authoring **rules** + workflow **commands** that any repo can
adopt, with each repo supplying only its own facts in `docs/_meta/`.

Repo: `github.com/AdamLoe/agent-docs`

## Canonical install location — REQUIRED

This repo **must live at `~/.claude/agent-docs/`.** That path is part of
the contract, not a preference: every reference to the kit — inside the
Claude skills, the Codex prompt shims, and **every consuming repo's doc
stubs** — uses the absolute path `~/.claude/agent-docs/…`.

Install:

```sh
git clone https://github.com/AdamLoe/agent-docs.git ~/.claude/agent-docs
```

Do **not** clone it elsewhere and reference that other location. If the
bytes must physically live elsewhere (a shared volume, a dotfiles repo),
put them there and leave a **compatibility symlink at
`~/.claude/agent-docs`** pointing to them — so the canonical path always
resolves. *The canonical path never changes; only what sits behind it
may.* That is the entire relocation story.

## Reference convention — official

Anything that points at the kit uses the **absolute** path
`~/.claude/agent-docs/<version>/…`:

- ✅ `~/agent-docs/v1/rules/authoring-rules.md`
- ❌ relative (`../../rules/…`) — breaks when a skill is read through its
  `~/.claude/skills/` symlink.
- ❌ `${CLAUDE_PLUGIN_ROOT}/…` — only resolves if the kit is loaded as an
  installed Claude *plugin*, not as the standard symlinked skills.

This is safe **because** the install location is fixed. See
[`v1/README.md`](v1/README.md) § "How a skill links back" for the full
rationale.

## Layout & versioning

```
~/.claude/agent-docs/
  README.md          ← this file (the install + reference law)
  v1/                ← the kit: skills/, rules/, plan-lifecycle.md,
                       plan-template.md, agent-docs-guide.md, README.md
  v2/                ← a future revision: copy v1, evolve from there
```

A consuming repo pins its version via `agent_docs_version` in
`docs/_meta/manifest.md`. Old repos stay on their version untouched; new
repos adopt the latest.

## Per-tool setup

See [`v1/README.md`](v1/README.md) → "Getting it working" for the Claude
Code (skill symlinks) and Codex (`AGENTS.md` + `~/.codex/prompts/` shims)
adapters. Both reference this one kit; nothing is duplicated.
