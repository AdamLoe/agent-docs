# Repo rules for agent-docs

This repo follows the generic repo rules in
[`../../src/rules/repo-rules.md`](../../src/rules/repo-rules.md).

## Local gates

Use the `drift-gates` slot in [`../_meta/manifest.md`](../_meta/manifest.md).
That slot calls `bash src/verify-agent-docs.sh`, which resolves the repo root
from its own location and runs the non-mutating agent-readiness checks. The
installer resolution checks mutate `$HOME`, so run them deliberately.

After editing `src/skills/`, republish the runtime bundle and verify:

```sh
bash install-agentdocs-local.sh
bash src/verify-agent-docs.sh
```

`install-agentdocs-local.sh` publishes the local `src/` bundle into
`~/.agentdocs/` and refreshes the managed Claude and Codex skill copies.
`src/verify-agent-docs.sh` then runs the source-repo gate including adapter
freshness. Restart the tool if a new or renamed skill does not appear.

## See also

- [`../_meta/manifest.md`](../_meta/manifest.md)
- [`../../install-agentdocs-local.sh`](../../install-agentdocs-local.sh)
- [`../../src/install-agentdocs.sh`](../../src/install-agentdocs.sh)
