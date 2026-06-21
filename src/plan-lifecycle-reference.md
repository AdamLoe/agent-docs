# Plan lifecycle — expanded rationale + run-folder detail (do not auto-load)

GENERIC. App-independent. Reference companion to
[`plan-lifecycle.md`](plan-lifecycle.md). The terse normative contract lives
there; this leaf carries the field-meaning rationale, workflow walk-through, and
run-folder structure detail. **Never auto-loaded.** Read it when you need the
"why" behind a lifecycle field or a worked example of the migration workflow.

## Field rationale

- **`status`:** The four-state lifecycle forces explicit tracking. `draft`
  prevents premature execution; `active` signals "read this before writing
  code"; `shipped` unlocks deletion; `abandoned` captures explicit scope-outs
  so future readers don't wonder why a plan was dropped.
- **`okay_to_delete`:** The two-step (status + delete flag) prevents accidental
  deletion of plans that are shipped but whose context hasn't been migrated yet.
  The user makes the deletion call; the flag is just the signal.
- **`long_lived`:** Reserved for multi-month coordination docs (ongoing
  trade-off logs, external dependency trackers) where migration is genuinely
  impossible. Not an escape from the migration rule — use it sparingly. The
  default expectation is that shipped plans get deleted.
- **`owning_docs`:** Updated on every edit so the maintainer can cross-reference
  what's been migrated without reading the full plan. Cross-links are cheap;
  their absence is expensive.

## Workflow walk-through

The migration step (step 4) is the one most commonly skipped. It means: read
the plan start to finish, and for every sentence that is either a permanent
fact, a settled design choice, or a trade-off rationale:

- Permanent fact → `architecture/<doc>.md` (rewrite in place, not append).
- Settled design choice → `decisions/<domain>.md` (three mandatory fields).
- New concept requiring routing → `_meta/ownership.json`.

Context that is purely historical ("we decided to not do X because at the time
Y was true") has no home in the architecture tree — that is git-log context and
should not be migrated.

After migration, the plan body should contain only: mission, scope, the ordered
stream list (for resume-sensitive tracking), the exit gate, and the migration
notes section (filled in to confirm what was migrated and where).

## Run-folder structure

`docs/plans/orchestrator/<run-slug>/` is reserved for opt-in stateful run
folders committed for coordination history:

- Required: `hub.md` — carries the same lifecycle frontmatter as a plan file
  (`status`, `owner`, `last_updated`, `okay_to_delete`, `long_lived`,
  `owning_docs`). The hub is the status source for cleanup.
- Optional: `streams/<stream-name>.md` — per-stream notes and findings.
- Optional: `findings/` — read-only evidence from review or verification passes.

Once the run's work ships or is abandoned, migrate durable facts and rationale
into architecture/decisions, record the migration targets in the hub, and set
`okay_to_delete: true` only when the run is disposable.
