# Orchestrator run docs (agent-docs v1)

GENERIC. App-independent. The opt-in stateful coordination mode for an
orchestrated run. Most runs keep state in the chat, worker reports, and ordinary
plan files already in play; this rule covers the committed run-folder mode for
long-running or resume-risk work. Lifecycle and dispatch live in
[`lifecycle.md`](lifecycle.md) and [`dispatch.md`](dispatch.md).

## When to use run docs

Default orchestration keeps state in chat, worker reports, and ordinary plans. A
stateful run writes committed coordination history under
`docs/plans/orchestrator/<run-slug>/`, but only when the user explicitly asks
("use run docs", "stateful orchestration", "create an orchestration run folder")
or grants permission after the orchestrator asks.

If resume risk is high and the user has not asked, ask once with a concrete
reason and the proposed run slug. If permission is declined, continue without the
folder and accept the lower resumability; do not create a hidden state area.

## Layout

```text
docs/plans/orchestrator/<run-slug>/
  hub.md
  streams/
    <stream-id>.md
  findings/
    <topic-or-agent>.md   # optional
```

`hub.md` is the only required lifecycle/status surface. It starts with plan-style
frontmatter so cleanup tools can reason about the run without parsing prose:

```yaml
---
status:        draft | active | shipped | abandoned
owner:         <name or "unassigned">
last_updated:  YYYY-MM-DD
okay_to_delete: false | true
long_lived:    false | true
owning_docs:
  - architecture/<doc>.md
  - decisions/<domain>.md
---
```

## Ownership

- The orchestrator owns `hub.md`: phase/status tracker, decisions, open
  questions, blockers, verification evidence, closeout notes, migration status.
  Before setting `okay_to_delete: true`, the hub must name the durable
  facts/rationale migrated into `owning_docs`.
- Stream files under `streams/` are compact worker-owned notes and, when needed,
  implementer planning notes for a single workstream. Do not create extra root
  files in the run folder.
- Findings files are optional read-only investigation notes when the hub would
  otherwise overload.
- Workers may write only the stream or findings files named in their dispatch.
- Commit run docs at normal orchestration checkpoints or closeout, not after
  every status update.

Once the work ships, migrate durable facts and rationale into
architecture/decisions; the committed run folder remains disposable plan
material and is cleaned up through the normal plan lifecycle
([`../../plan-lifecycle.md`](../../plan-lifecycle.md)).

## See also

- [`lifecycle.md`](lifecycle.md), [`dispatch.md`](dispatch.md)
- [`../../plan-lifecycle.md`](../../plan-lifecycle.md) — plan/run-folder lifecycle.
