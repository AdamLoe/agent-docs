# agent-docs v1 (Claude Code plugin)

One self-contained folder holding **both** the workflow machinery and the
generic rules it routes into:

```
agent-docs/v1/                ← the plugin root (= ${CLAUDE_PLUGIN_ROOT})
  .claude-plugin/plugin.json  ← makes this a Claude Code plugin
  skills/                     ← the 7 generic commands (fresh-chat, …)
  rules/                      ← authoring-rules, coding-style, repo-rules, orchestrating
  template/                   ← (scaffold for a new app's docs/, TODO)
```

Skills reference the rules by `${CLAUDE_PLUGIN_ROOT}/rules/<file>.md`, so
the bundle is relocatable — nothing hard-codes an absolute `~/.claude`
path anymore.

## Per-app binding

These skills/rules are app-agnostic. Each repo supplies its own facts in
`docs/_meta/manifest.md` (`code_root`, `change-to-doc`, `drift-gates`,
`drift-verification`, `decisions-domains`) and `docs/_meta/ownership.json`.
Apps declare which version they target via `agent_docs_version` in the
manifest; the plugin `version` is the matching major.

## Activation (the one trade-off)

Right now the live commands are the **flat** copies in `~/.claude/skills/*`
(invoked un-namespaced: `/fresh-chat`). To switch to this bundled plugin:

1. Register it as a local plugin (e.g. add this dir via the `/plugin`
   flow or `--plugin-dir`), then remove the flat `~/.claude/skills/*`
   copies so they don't shadow it.
2. Commands then load namespaced as `/agent-docs:fresh-chat`, etc.

The flat copies and this plugin are byte-identical except for the rules
path (`${CLAUDE_PLUGIN_ROOT}` vs absolute). Keep ONE as the source of
truth to avoid drift — the plugin is the intended home; the flat copies
are the pre-plugin live set.
