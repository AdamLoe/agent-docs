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

## Working model

The workflow is subagent-first: skills are orchestrator entry points. They read
the shared runtime card, needed manifest slots, and `docs/index.md`, then route
to the smallest owner. Pure routing stays inline; work that crosses files, needs
judgment, mutates the repo, or runs a gate goes to a role-scoped worker with
exact rule links.

Workers execute the slice: planning, implementation, review, docs maintenance,
plan maintenance, or verification. Mutating workers preserve unrelated dirty
work, stage by filename, commit their finished slice, and leave the final
workflow to run the drift gate after code, docs, plan, and run-doc mutations are
complete.

Context is layered. Routers, manifest slots, the runtime card, indexes, and
worker role cards stay cache-stable. Architecture leaves, decisions,
agent-context procedures, selected plans, and source are task-routed. Plans,
run docs, pitch material, full ownership JSON, verifier output, and source files
are never auto-loaded. Static word budgets and deterministic context reports
keep that shape enforceable.

## See also

- [`architecture/install-and-adapters.md`](architecture/install-and-adapters.md)
- [`architecture/workflow-kit.md`](architecture/workflow-kit.md)
- [`decisions/agent-docs.md`](decisions/agent-docs.md)
