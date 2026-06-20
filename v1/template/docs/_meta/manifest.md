# agent-docs manifest

repo_name: repo-name
agent_docs_version: v1
code_root: .

## change-to-doc

| Changed surface | Owning doc |
|---|---|
| Agent-docs manifest bindings and ownership data | docs/_meta/manifest.md, docs/_meta/ownership.json |
| Docs routing and overview | docs/index.md, docs/overview.md |
| Repository layout inventory | docs/repository-layout.md |

## drift-gates

Run from the repository root:

```sh
fail() { printf 'GATE FAIL: %s\n' "$*" >&2; exit 1; }
# Replace this block with repo-specific checks or a repo-local verifier script.
```

## drift-verification

Record any stronger manual or mutating verification commands that are not safe
as default drift gates.

## decisions-domains

| Domain | Owning doc |
|---|---|
| Repo architecture decisions | docs/decisions/index.md |
