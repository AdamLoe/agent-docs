# Orchestrating in agent-docs

This repo follows the generic orchestrator rules under
[`../../v1/rules/orchestrator/`](../../v1/rules/orchestrator/) and the worker
rules under [`../../v1/rules/subagent/`](../../v1/rules/subagent/).

## Repo-local notes

- There are no scarce runtime resources.
- The main collision risk is documentation surface overlap: keep root
  `README.md`, `docs/architecture/*`, `docs/decisions/*`, and `v1/skills/*`
  ownership explicit before parallel edits, and run editing workers serially per
  the commit-concurrency rule in
  [`../../v1/rules/orchestrator/dispatch.md`](../../v1/rules/orchestrator/dispatch.md).
- Do not push unless the user explicitly asks.

## See also

- [`../plans/index.md`](../plans/index.md)
- [`repo-rules.md`](repo-rules.md)
