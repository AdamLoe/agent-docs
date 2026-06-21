# agent-docs overview

`agent-docs` is a reusable documentation-workflow kit for LLM-assisted
codebases. The repo contains generic rules and skills under `src/`; the
installed runtime lives at `~/.agentdocs/`; each consuming repo supplies
app-specific facts in its own `docs/_meta/`.

## Layout

```text
~/agent-docs/                  # source checkout (dogfood)
  install-agentdocs-local.sh   # dev/dogfood installer
  src/
    skills/                    # reusable command bodies
    rules/                     # authoring, coding, repo, orchestration rules
    template/                  # docs scaffold copied by /rebuild-agent-docs
    install-agentdocs.sh       # GitHub installer (bundled)
    verify-agent-docs.sh       # source-repo gate and scaffold checker

~/.agentdocs/                  # installed runtime (all self-references point here)
  skills/
  rules/
  template/
  install-agentdocs.sh
  verify-agent-docs.sh
  .agentdocs-install-manifest  # provenance only
```

## Discovery adapters

The kit is tool-neutral. Tool-owned paths are only adapters:

- `AGENTS.md` and `CLAUDE.md` are root router files pointing to `docs/index.md`
- `~/.claude/skills/<name>` copied from `~/.agentdocs/skills/<name>` by the installers
- `~/.agents/skills/<name>` copied from `~/.agentdocs/skills/<name>` by the installers

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
