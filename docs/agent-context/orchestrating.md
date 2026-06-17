# Orchestrating in agent-docs

This repo follows the generic orchestration rules in
[`../../v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md).

## Repo-local notes

- There are no scarce runtime resources.
- The main collision risk is documentation surface overlap: keep root
  `README.md`, `docs/architecture/*`, `docs/decisions/*`, and `v1/skills/*`
  ownership explicit before parallel edits.
- Do not push unless the user explicitly asks.

## See also

- [`../plans/index.md`](../plans/index.md)
- [`repo-rules.md`](repo-rules.md)
