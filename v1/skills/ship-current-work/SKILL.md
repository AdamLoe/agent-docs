---
name: ship-current-work
description: Finish ordinary work by inspecting the diff, updating owned docs, running the manifest drift gates, and committing if green.
---

You are shipping the current work in the current repository. This is the
normal completion path for ordinary changes.

This skill runs directly on the current diff — no intake questions. Read
`~/agent-docs/v1/rules/skill-contracts.md` for the shared Shipping shape,
dials, and model policy, and honor any dials passed in `$ARGUMENTS`.

Read the repo rules before you finish anything that could affect history or
state:

- `~/agent-docs/v1/rules/authoring-rules.md`
- `~/agent-docs/v1/rules/repo-rules.md`

Then follow the repo's manifest and ownership data:

1. Read `docs/_meta/manifest.md`.
2. Read `docs/_meta/ownership.json`.
3. Use the manifest slots by these exact keys: `code_root`,
   `change-to-doc`, `drift-gates`, `drift-verification`,
   `decisions-domains`.
4. Resolve owning docs from `change-to-doc` plus `ownership.json`.

Finish in place, with the smallest change set that makes the current work
real and durable:

- Inspect `git status --short`, `git diff --stat`, and `git diff --name-only`.
- Update the owning architecture docs in place.
- Update decisions docs only for durable rationale.
- If a plan was touched or completed, migrate the durable context first,
  then update `status`, `last_updated`, and `okay_to_delete` truthfully.
  Do not delete plans here.
- Run the narrow gates from the manifest `drift-gates` slot.
- Stage by filename.
- Commit if the tree is green.
- Never push unless explicitly told to do so.

If a manifest slot is thin or a repo-local convention is unclear, follow the
existing skills' usage patterns, make the best conservative call, and flag the
uncertainty in your report.
