---
name: feedback-agent-docs
description: Record a comment or request about the agent-docs kit (a rule, skill, doc structure, or generic doc) into the kit's upstream feedback inbox.
---

You are working in some consuming repo and noticed something about the
**shared agent-docs kit** — a rule that is unclear or wrong, a skill that
misbehaves or is missing, a gap in the doc structure, or a stale generic doc.
This skill records that as one structured entry in the kit's upstream inbox so
the agent-docs maintainer can triage it later. It does **not** edit the kit and
does **not** touch the current repo.

This skill runs directly — the dial/task intake in
`~/agent-docs/v1/rules/skill-contracts.md` does not apply. If the current
conversation already contains a clear kit-level issue, lodge it without a
separate permission checkpoint. If no feedback content was given and nothing
clear can be inferred, ask only for the feedback itself, then proceed.

## What this is for / not for

- **For:** feedback about the GENERIC kit (`~/agent-docs/v1/...`) — rules,
  skills, templates, the doc-structure scaffold, the generic guide.
- **Also for:** friction signals from real use, such as an agent getting
  confused by a rule, a workflow causing unnecessary user frustration, or a
  user explicitly reacting badly to kit behaviour.
- **Not for:** app-specific docs in the *current* repo. Fix those directly or
  via the repo's own review skills. This skill commits nothing and edits no
  kit files.

## Where it lodges

The kit checkout is `~/agent-docs`. Feedback lands as one JSON line in
`~/agent-docs/feedback/inbox.jsonl`. If `~/agent-docs` does not exist, the kit
may be checked out elsewhere — ask the user for the checkout path. If you
cannot locate it, report that and stop; do not invent a destination.

## Gather the entry

If `$ARGUMENTS` already describes the feedback, treat it as the user's input.
Otherwise infer sensible values from the current context. Do not block on
confirmation when the issue is clear and kit-level; lodge the concise entry and
report it. Fields:

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

If `jq` is unavailable, append a single hand-built JSON line with the same
keys, escaping any quotes in the free-text fields.

## Confirm

Echo back the lodged entry (one line) and the inbox path so the user can see
what was recorded. Do not commit, do not edit kit files, and do not modify the
current repo — triage of the inbox happens later inside the agent-docs repo.

Arguments (optional feedback content): $ARGUMENTS
