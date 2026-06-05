# agent-docs v1

A portable, tool-neutral documentation system for LLM-assisted codebases.
One self-contained folder holds **both** the workflow commands and the
generic rules they route into; per-repo facts live in each repo's
`docs/_meta/`.

```
~/.claude/agent-docs/v1/        ← the kit (single source of truth)
  .claude-plugin/plugin.json    ← optional: lets it install as a Claude plugin
  skills/                       ← the generic commands (fresh-chat, …)
  rules/                        ← authoring-rules, coding-style, repo-rules, orchestrating
  README.md                     ← this file
  template/                     ← scaffold for a new app's docs/ (TODO — empty)
```

The generic commands are the workflow machinery; `rules/` is the
app-independent discipline they cite. **Skills reference the rules by an
absolute path** (`~/.claude/agent-docs/v1/rules/<file>.md`) — see "Why
absolute" below.

## Per-app binding

The skills/rules are app-agnostic. Each repo supplies its own facts in
`docs/_meta/manifest.md` (`code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`, `decisions-domains`) and `docs/_meta/ownership.json`.
A repo declares which kit version it targets via `agent_docs_version` in
the manifest.

---

# Getting it working

The kit is **one folder**; each tool gets a thin adapter that points at it.
Nothing is duplicated — the adapters reference the same `skills/` files.

## Claude Code (active)

Personal skills live in `~/.claude/skills/`. To keep a single source, the
**whole directory** is a symlink into this kit — so every skill added under
`agent-docs/v1/skills/` shows up automatically with no per-skill wiring:

```sh
cd ~/.claude
rm -rf skills
ln -s agent-docs/v1/skills skills
```

Claude Code discovers skills through the symlinked dir, so the commands load
**un-namespaced** (`/fresh-chat`, etc.). Verify with `/help`, `/list-skills`,
or by checking the skill list. App-specific commands (e.g. `start-app`,
`run-training`) stay as project skills in each repo's `.claude/skills/`.

> Earlier versions symlinked each skill individually
> (`for s in …; do ln -s "../agent-docs/v1/skills/$s" "$s"; done`). The
> single directory symlink supersedes that — there is no per-skill list to
> keep in sync.

### How a skill links back to the rules

Skills reference the rules (and the other kit files) by the **absolute
path** `~/.claude/agent-docs/v1/…`. This is the official convention — see
the [root README](../README.md) § "Reference convention." It is the only
form that resolves correctly when a skill is read through its
`~/.claude/skills/` symlink:

- relative (`../../rules/…`) resolves against the *symlink* location
  (`~/.claude/skills/…`), landing in the wrong place;
- `${CLAUDE_PLUGIN_ROOT}` exists *only* when the kit is loaded as an
  installed plugin, not as a symlinked skill.

Because the kit's install location is fixed at `~/.claude/agent-docs/`,
the absolute path is a stable interface, not a liability. (If you ever
prefer a relocatable-relative reference at the price of **namespaced**
commands, install the kit as a plugin and switch the paths to
`${CLAUDE_PLUGIN_ROOT}/…` — the alternative mode, not the default.)

## Codex (active)

Codex orients from an auto-loaded `AGENTS.md` and runs reusable commands
from `~/.codex/prompts/*.md`. Both point at this same kit:

- **Per-repo `AGENTS.md`** (committed at the repo root) is a *router only*
  — it sends the agent to `docs/index.md` → `docs/overview.md`, names where
  code/bindings/rules live, and lists the commands. It owns no facts, which
  is what keeps it compatible with the agent-docs "no auto-loaded facts"
  rule. This is Codex's equivalent of Claude's `/fresh-chat`.
- **`~/.codex/prompts/<name>.md`** are thin shims that each say "read and
  follow `~/.claude/agent-docs/v1/skills/<name>/SKILL.md`." They appear as
  `/fresh-chat`, `/fix-docs-drift-all`, etc. in the Codex TUI.

To (re)generate the Codex prompt shims:

```sh
mkdir -p ~/.codex/prompts
for d in ~/.claude/agent-docs/v1/skills/*/; do
  s=$(basename "$d")
  printf 'Run the agent-docs **%s** command. Follow this shared instruction file exactly:\n\n    ~/.claude/agent-docs/v1/skills/%s/SKILL.md\n\nIt reads app facts from docs/_meta/ and rules from ~/.claude/agent-docs/v1/rules/.\n\nArguments: $ARGUMENTS\n' "$s" "$s" > ~/.codex/prompts/"$s".md
done
```

## The cross-tool contract

| Layer | Shared? | Claude Code | Codex |
|---|---|---|---|
| docs tree + `_meta/` (per repo) | ✅ identical | reads files | reads files |
| `rules/` | ✅ identical | reads files | reads files |
| command **bodies** (`skills/*/SKILL.md`) | ✅ one source | symlinked into `~/.claude/skills/` | referenced by `~/.codex/prompts/` |
| orientation entry-point | adapter | `/fresh-chat` skill | auto-loaded `AGENTS.md` |

Only the thin entry-point/wrapper differs per tool. "Support a new tool" =
add one more adapter; the docs and rules never fork.

> **Tool-neutral home (optional).** The kit currently lives under
> `~/.claude/` for convenience. For a cleaner split you can move it to a
> neutral path (e.g. `~/.agent-docs/v1/`) and symlink `~/.claude/agent-docs`
> → there, so neither tool "owns" it. The Codex shims and Claude symlinks
> resolve through the chain unchanged.
