# Orchestrating in agent-docs

This repo follows the generic orchestrator rules under
[`../../src/rules/orchestrator/`](../../src/rules/orchestrator/) and the worker
rules under [`../../src/rules/subagent/`](../../src/rules/subagent/).

## Repo-local notes

- There are no scarce runtime resources.
- The main collision risk is documentation surface overlap: keep root
  `README.md`, `docs/architecture/*`, `docs/decisions/*`, and `src/skills/*`
  ownership explicit before parallel edits, and run editing workers serially per
  the commit-concurrency rule in
  [`../../src/rules/orchestrator/dispatch.md`](../../src/rules/orchestrator/dispatch.md).
- Do not push unless the user explicitly asks.

## See also

- [`../plans/index.md`](../plans/index.md)
- [`repo-rules.md`](repo-rules.md)
