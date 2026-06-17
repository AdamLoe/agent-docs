# agent-docs manifest

repo_name: <!-- fill -->
agent_docs_version: v1
code_root: <!-- fill -->

## change-to-doc

| Changed surface | Owning doc |
|---|---|
| Agent-docs manifest bindings and ownership data | docs/_meta/manifest.md, docs/_meta/ownership.json |
| Repository layout inventory | docs/repository-layout.md |
| <!-- fill --> | <!-- fill --> |

## drift-gates

Run from the repository root:

```sh
fail() { printf 'GATE FAIL: %s\n' "$*" >&2; exit 1; }
# Fill with repo-specific checks, or call a repo-local verifier script.
```

## drift-verification

<!-- fill -->

## decisions-domains

| Domain | Owning doc |
|---|---|
| <!-- fill --> | <!-- fill --> |
