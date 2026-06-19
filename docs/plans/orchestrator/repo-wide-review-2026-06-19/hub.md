---
status:        shipped
owner:         codex
last_updated:  2026-06-19
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - architecture/install-and-adapters.md
  - decisions/agent-docs.md
  - repository-layout.md
---

# Repo-wide review run

## Request

Orchestrate an in-depth review of the whole `agent-docs` repo, focused on
`docs/`, `v1/`, `v1/skills/`, and `v1/rules/`, with at least six subagents and
separate findings docs.

## Lifecycle

Report-only stateful orchestration. No implementation or cleanup fixes are in
scope for this run unless the user asks after reviewing the findings.

## Streams

| Stream | Area | Status | Last observed fact | Next action | Blockers |
|---|---|---|---|---|---|
| docs-shape | `docs/`, routers, README | complete | Install/canonical path wording and ownership coverage are the main recoverability gaps | Findings written | None |
| rules | `v1/rules/` | complete | Mutating worker bundles are not self-contained enough for the behavior they authorize | Findings written | None |
| skills | `v1/skills/`, registry | complete | Registry/body drift exists around optional mutation, feedback capture, and list-skills inventory meaning | Findings written | None |
| lifecycle | plans, orchestrator, worker lifecycle | complete | Final verification order and tracked-plan persistence are underspecified | Findings written | None |
| install | install/copy scripts and adapter docs | complete | `copy-skills.sh` can replace symlinked tool skill roots and can partially refresh before later conflicts | Findings written | None |
| template | `v1/template/`, guide, rebuild flow | complete | `rebuild-agent-docs` points consumers at a verifier that validates the kit checkout, not the target repo | Findings written | None |
| drift | manifest, ownership, verifier, layout coverage | complete | `v1/template/docs/` lacks explicit metadata ownership, and registry/layout checks are shallow | Findings written | None |

## Observed State

- Manifest `code_root` is `v1/`.
- Manifest drift gate is `bash v1/verify-agent-docs.sh`.
- Pre-existing working tree state includes deleted files under `docs/plans/`;
  this run will not restore, stage, or otherwise modify those deletions.
- Six initial read-only review workers completed, then a seventh drift/metadata
  worker ran after a worker slot freed.
- Worker report bodies are recorded under `findings/`, with a consolidated
  synthesis at `findings/synthesis.md`.
- Highest-confidence fix themes: installer/copy safety, consumer scaffold
  verification, self-contained dispatch bundles, canonical final-gate ordering,
  tracked-plan persistence, and metadata/verifier coverage.

## Decisions

- Use run docs because the user explicitly requested review findings documents.
- Keep workers read-only and write their returned report bodies into findings
  files from this coordination layer to avoid concurrent shared-tree edits.

## Open Questions

None.

## Verification

Final gate passed after review artifacts were written:

```text
agent-docs skills are fresh in /home/adamg/.agents/skills
agent-docs skills are fresh in /home/adamg/.claude/skills
ALL AGENT-DOCS GATES PASS
```

## Closeout

- Review artifacts intentionally remain in this run folder as the requested
  deliverable; `okay_to_delete` stays `false`.
- No source fixes were applied in this run.
- Pre-existing deleted plan files under `docs/plans/` were left untouched.
