# Repo rules for agent-docs

This repo follows the generic repo rules in
[`../../v1/rules/repo-rules.md`](../../v1/rules/repo-rules.md).

## Local gates

Use the `drift-gates` slot in [`../_meta/manifest.md`](../_meta/manifest.md).
That slot calls `bash v1/verify-agent-docs.sh`, which resolves the repo root
from its own location and runs the non-mutating agent-readiness checks. The
installer resolution checks mutate `$HOME`, so run them deliberately.

After editing `v1/skills/`, run:

```sh
bash ~/agent-docs/v1/copy-skills.sh ~/agent-docs
bash ~/agent-docs/v1/copy-skills.sh --check ~/agent-docs
```

This refreshes Claude and Codex copied user-skill directories and then proves
the copied adapters match `v1/skills/`. Do this before shipping any skill
change; the manifest gate enforces freshness. Restart the tool if a new or
renamed skill still does not appear.

## See also

- [`../_meta/manifest.md`](../_meta/manifest.md)
- [`../../v1/install.sh`](../../v1/install.sh)
- [`../../v1/copy-skills.sh`](../../v1/copy-skills.sh)
