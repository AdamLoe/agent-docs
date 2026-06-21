# Doc authoring rules — expanded detail (do not auto-load)

GENERIC. App-independent. Reference companion to
[`authoring-rules.md`](authoring-rules.md). The terse normative contract lives
there; this leaf carries the context-layer definitions, class budgets,
banned-form examples, anti-pattern catalogue, workflow walk-through, and
app-binding slot table. **Never auto-loaded.** Read it when you need the "why",
worked examples, or the full budget/layer reference.

## Context layers and class budgets (rule 4 expansion)

**Cache-stable layer:** router-only `AGENTS.md`/`CLAUDE.md`, the stable
runtime card in `~/.agentdocs/rules/skill-contracts.md`, manifest startup slots,
`docs/index.md`, subtree indexes, and worker role cards. `docs/overview.md`
is stable orientation, but still task-routed unless a skill names it.

**Task-specific layer:** one architecture leaf, one decisions domain, one
agent-context procedure, selected plan/run-doc files, and selected
source/test files. Query ownership metadata only for ownership questions;
use `docs/repository-layout.md` only to locate files.

**Never-auto-loaded layer:** architecture leaves, decisions, plans, run docs,
`~/.agentdocs/agent-docs-guide.md`, full ownership JSON, repository layout, source
files, verifier output, and narrative pitch material.

**Documentation class budgets:** routers and subtree indexes `<=250` words;
overview docs `<=350`; architecture leaves `<=1,500`; decision domains,
active plans, and run hubs `<=2,600`; run findings/stream notes `<=1,200`;
skill bodies `<=900`; subagent role cards `<=500`. Split or route when a
file needs more. The repo verifier owns the hard word-count checks.

## Banned-form examples (rule 3 expansion)

Replace each of these with a `path → symbol` pointer plus only the
non-obvious invariant, gotcha, or why:

- Full DDL / `CREATE TABLE` bodies
- Struct/enum field dumps
- Multi-line implementation or pseudocode
- Exhaustive enumerations of columns, fields, routes, or variants

Note: `path → symbol_name`, NOT `path:line` — line numbers drift; symbol
names are grep-stable and surface meaningful refactors.

## Anti-patterns to refuse

- **"Just add a quick note in a status / changelog doc."** No such doc
  exists. Route to `decisions/<domain>.md` (rationale) or
  `architecture/<doc>.md` (current state).
- **"Add a `## v1.0.1` section to the architecture doc."** Rewrite in
  place. Version-flavoured framing is what makes doc trees drift.
- **"Start every plan with an in-flight/disclaimer paragraph."** Use
  the status frontmatter.
- **"It's faster to put the launch command in this prompt too."**
  Prompts own no facts. Link to the canonical owner.
- **"Let me drop a one-liner in an auto-loaded instructions file."**
  No fact dump belongs there. Put procedural facts in `agent-context/<doc>`,
  architecture facts in `architecture/<doc>`, choices in `decisions/<domain>`.
- **"This decision is superseded but I'll keep the old text."** The git
  log is the context. Delete superseded decisions.
- **"Leave this plan `long_lived` so future readers find it."** First
  migrate the context into architecture/decisions. `long_lived` is a
  rare escape hatch.

## Workflow when shipping a plan — detailed

1. Make the code change.
2. **Update the architecture doc(s)** that own the touched surfaces.
   Rewrite in place — don't append a version-flavoured section.
3. **Update `decisions/<domain>.md`** if the change introduces a new
   decision. Use the three mandatory + four optional fields.
4. **Migrate any plan-prose context worth preserving** into
   architecture/decisions so the plan can be `okay_to_delete: true`.
5. Update the plan/run-doc frontmatter: `status`, `last_updated`, and
   `okay_to_delete` truthfully.
6. Run the final drift gate after all code, docs, plan-status, and run-doc
   mutations (manifest `drift-gates` slot).
7. Commit the verified final state. Report from that final state, not from a
   pre-migration gate.

## App bindings this doc reads (from the manifest)

| Slot | What it supplies |
|---|---|
| `code_root` | the path all doc code-anchors are relative to (e.g. `app/`) |
| `change-to-doc` | the "changed file → update doc" table |
| `drift-gates` | the per-commit gate commands |
| `decisions-domains` | the app's `decisions/<domain>.md` file set |

> **Code anchors are relative to the manifest's `code_root`.** When you
> write `crates/foo/src/bar.rs → symbol`, it resolves under `code_root`,
> not the repo root and not `docs/`. State `code_root` once in the
> manifest; never repeat a code-root prefix in individual anchors.
