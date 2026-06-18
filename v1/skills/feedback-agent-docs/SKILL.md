---
name: feedback-agent-docs
description: Record a comment or request about the agent-docs kit (a rule, skill, doc structure, or generic doc) into the kit's upstream feedback inbox.
---

You are the orchestrator for a narrow **capture** workflow: append one structured
feedback record about the shared agent-docs kit into the kit's upstream inbox,
which lives **outside** the current repo. Mode: capture. You do not edit the kit,
do not touch the current repo, and do not commit. Appending one record is a
single IO step, so it runs inline — you do not become an inline maintenance
skill, but you also do not invent a worker for a one-line append.

## Bootstrap

Read `~/agent-docs/v1/rules/skill-contracts.md` and run the **Standard Intake
Protocol**: manifest (`repo_name`, `code_root`) → `index.md` → `overview.md` →
stop.

This skill is **state-driven**: skip the dial/task intake — it operates on the
existing conversation plus the inbox on disk, and the dials are inert for a pure
capture utility. The one exception is the feedback content itself: if the
conversation gives no clear kit-level issue and `$ARGUMENTS` is empty, ask **only**
for the feedback to record, then proceed without a separate permission checkpoint.

Then read, against the task:

- the skill-local **routing rules** below (feedback-about-the-kit vs.
  fix-this-repo),
- the existing feedback content the user gave (in `$ARGUMENTS` or the chat),
- the feedback inbox path (below),
- `~/agent-docs/v1/rules/orchestrator/lifecycle.md` and
  `~/agent-docs/v1/rules/orchestrator/dispatch.md` to confirm classification:
  this is pure routing/IO, which runs inline.

## Routing: feedback vs. repo

- **For:** feedback about the GENERIC kit (`~/agent-docs/v1/...`) — rules,
  skills, templates, the doc-structure scaffold, the generic guide. Also friction
  signals from real use: an agent confused by a rule, a workflow causing
  unnecessary user frustration, a user reacting badly to kit behavior.
- **Not for:** app-specific docs in the *current* repo. Fix those directly or via
  the repo's own review skills. This skill commits nothing and edits no kit files.

The kit checkout is `~/agent-docs`; feedback lands as one JSON line in
`~/agent-docs/feedback/inbox.jsonl`. If `~/agent-docs` does not exist, the kit may
be checked out elsewhere — ask the user for the checkout path. If you cannot
locate it, report that and stop; do not invent a destination.

## Worker Phases

Usually **none**. Validate the record and append it inline — it is a single IO
step under the reads-vs-dispatch test in `orchestrator/lifecycle.md`. Spawn a
worker only when judgment genuinely needs isolation:

- **Docs-maintenance worker** only if payload validation or the append path needs
  isolated judgment. Pass `~/agent-docs/v1/rules/subagent/docs-maintenance.md`
  and `~/agent-docs/v1/rules/authoring-rules.md`.
- **Verification worker** only if the append path or schema needs a separate
  check. Pass `~/agent-docs/v1/rules/subagent/verification.md` and
  `~/agent-docs/v1/rules/repo-rules.md`.

Do not force a reusable `capture.md` rule, and do not invent a one-line worker
just to satisfy the shape.

## Gather the entry

If `$ARGUMENTS` describes the feedback, treat it as the user's input; otherwise
infer sensible values from the current context. Do not block on confirmation when
the issue is clear and kit-level. Fields:

- `scope` — one of `rule` | `skill` | `structure` | `generic-doc` | `other`
- `surface` — the specific target, e.g. `v1/rules/authoring-rules.md rule 3`
  or `/quick-fix` or `docs/architecture scaffold`
- `observation` — what is wrong, missing, or confusing
- `suggestion` — optional proposed change
- `severity` — `low` | `medium` | `high`

## Append the entry

Prefer `jq` for safe quoting (substitute the real values for each `<...>`):

```sh
mkdir -p ~/agent-docs/feedback
jq -cn \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg repo "$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")")" \
  --arg scope "<scope>" \
  --arg surface "<surface>" \
  --arg observation "<observation>" \
  --arg suggestion "<suggestion>" \
  --arg severity "<severity>" \
  '{ts:$ts, source_repo:$repo, scope:$scope, surface:$surface,
    observation:$observation, suggestion:$suggestion, severity:$severity}' \
  >> ~/agent-docs/feedback/inbox.jsonl
```

If `jq` is unavailable, append a single hand-built JSON line with the same keys,
escaping any quotes in the free-text fields.

## Closeout

Report:

- the feedback **category** (`scope`) and **surface** recorded
- the inbox record appended — echo the lodged line and the inbox path
- **no-repo-change result**: the append is out-of-repo, so there is no commit;
  surface a commit hash **only** if a worker changed repo files

Do not commit, do not edit kit files, and do not modify the current repo —
triage of the inbox happens later inside the agent-docs repo.

$ARGUMENTS
