# agent-docs overview

`agent-docs` is a reusable documentation-workflow kit for LLM-assisted
codebases. The repo contains generic rules and skills under `v1/`; each
consuming repo supplies app-specific facts in its own `docs/_meta/`.

## Current layout

```text
~/agent-docs/                  # canonical self-reference path
  README.md                    # user-facing install summary
  AGENTS.md, CLAUDE.md         # router-only auto-loaded files
  docs/                        # this repo's dogfood docs
  v1/
    skills/                    # reusable command bodies
    rules/                     # generic authoring, coding, repo, orchestration rules
    template/                  # docs scaffold copied by /rebuild-agent-docs
```

## Discovery adapters

The repo is tool-neutral. Tool-owned paths are only adapters:

- `AGENTS.md` and `CLAUDE.md` are root router files that point to
  `docs/index.md`; this overview is task-routed from that index
- `~/.claude/skills/<name>` copied from `~/agent-docs/v1/skills/<name>` by
  `v1/copy-skills.sh`
- `~/.agents/skills/<name>` copied from `~/agent-docs/v1/skills/<name>` by
  `v1/copy-skills.sh`

## See also

- [`architecture/install-and-adapters.md`](architecture/install-and-adapters.md)
- [`architecture/workflow-kit.md`](architecture/workflow-kit.md)
- [`decisions/agent-docs.md`](decisions/agent-docs.md)
