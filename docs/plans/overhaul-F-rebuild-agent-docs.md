---
status:        draft
owner:         unassigned
last_updated:  2026-06-08
okay_to_delete: false
long_lived:    false
owning_docs:
  - v1/README.md
  - v1/agent-docs-guide.md
---

# Stream F — `new-project-prompt.md` → `/rebuild-agent-docs`

Part of [overhaul-agent-docs.md](overhaul-agent-docs.md). **Phase 2,
parallel** — owns one new skill file plus the retirement of one prose file,
disjoint from the other Phase-2 streams.

## Mission

Turn the one-off [`v1/new-project-prompt.md`](../../v1/new-project-prompt.md)
into a reusable `/rebuild-agent-docs` skill that orchestrates a docs overhaul
for any repo adopting or repairing agent-docs — with no hardcoded
app-specific paths (today it hardcodes `../quoridor-ml-studio/docs/` and has
a typo'd `~.claude/agent-docs`).

## Scope

- **In:** create
  [`v1/skills/rebuild-agent-docs/SKILL.md`](../../v1/skills/rebuild-agent-docs/SKILL.md);
  retire/move `v1/new-project-prompt.md` (delete with a pointer, or leave a
  one-line deprecation stub pointing at the skill).
- **Out:** README/guide prose updates (propose a pointer for the lead). Out:
  `name:` frontmatter (Stream C).

### Owned files

```
v1/skills/rebuild-agent-docs/SKILL.md   (new)
v1/template/                            (populate — the docs scaffold to copy from)
v1/new-project-prompt.md                (retire / deprecate)
```

## Approach

0. **Fill the empty scaffold first.** `v1/template/` exists but is empty (the
   v1/README marks it "TODO — empty"). `/rebuild-agent-docs` should **copy and
   adapt** a real skeleton, not hallucinate the whole docs tree from prose
   every run. Populate `v1/template/` with the canonical empty docs shape:
   `docs/index.md`, `docs/overview.md`, `docs/architecture/index.md`,
   `docs/decisions/index.md`, `docs/agent-context/index.md`,
   `docs/plans/index.md`, `docs/_meta/manifest.md`, `docs/_meta/ownership.json`
   — each a stub with the right headings and `<!-- fill -->` markers, matching
   `~/agent-docs/v1/agent-docs-guide.md`.
1. **Create `/rebuild-agent-docs`** with **complete frontmatter on creation**
   (`name: rebuild-agent-docs` + a tight one-line `description:`) so Stream C
   only verifies it. Purpose: orchestrate a docs overhaul for a repo adopting
   or repairing agent-docs. Inputs via `$ARGUMENTS` (all optional): current
   docs path, example docs path, desired effort level, rebuild-vs-patch.
   Defaults: current docs path `docs/`; generic kit path `~/agent-docs/v1/`;
   example docs path only if explicitly named. Behavior:
   - Read the manifest if present; inventory the current docs shape.
   - Compare against `~/agent-docs/v1/agent-docs-guide.md`.
   - **Seed missing files from `~/agent-docs/v1/template/`**, then adapt
     them: `docs/index.md`, `docs/overview.md`, `docs/architecture/index.md`,
     `docs/decisions/index.md`, `docs/agent-context/index.md`,
     `docs/plans/index.md`, `docs/_meta/manifest.md`,
     `docs/_meta/ownership.json`.
   - Migrate durable facts; avoid code transcription.
   - Use subagents per the effort level from
     [Stream D](overhaul-D-orchestration.md)
     (`inline|light|standard|deep|max`).
   - End with `/ship-current-work` semantics, or a clear report if no
     code/docs edits were made.
2. **Retire `new-project-prompt.md`.** Prefer deleting it and pointing the
   README/guide at `/rebuild-agent-docs`; if kept, reduce it to a one-line
   deprecation stub. Strip the hardcoded `../quoridor-ml-studio/docs/`
   example and the `~.claude/agent-docs` typo.

## Exit gate

Real assertions (each fails non-zero when unmet):

```sh
fail() { echo "GATE FAIL: $*" >&2; exit 1; }
test -f v1/skills/rebuild-agent-docs/SKILL.md || fail "skill missing"
sed -n '1,12p' v1/skills/rebuild-agent-docs/SKILL.md | grep -qE '^name:' || fail "no name:"
test -f v1/template/docs/_meta/manifest.md || fail "scaffold not populated"
# new-project-prompt may remain ONLY as a deprecation pointer, never as a live entry
grep -RIn 'new-project-prompt' v1 README.md | grep -viE 'deprecat|retired|replaced by|→ /rebuild' \
  && fail "new-project-prompt still referenced as a live entry point" || true
# the new skill carries NO one-off app paths
grep -RIn 'quoridor-ml-studio\|~\.claude/agent-docs' v1/skills/rebuild-agent-docs/SKILL.md \
  && fail "hardcoded app path / typo leaked into the skill" || true
echo "F GATES PASS"
```

`new-project-prompt.md` is no longer the main workflow entry; `v1/template/`
holds a real scaffold to copy from; the skill list includes
`/rebuild-agent-docs` (with complete frontmatter); the new skill carries no
one-off app paths.

## Dispatch prompt

```
Task:        Populate v1/template/ with the docs scaffold; convert new-project-prompt.md into a reusable /rebuild-agent-docs skill (it copies from the scaffold); retire the old prompt.
Scope:       the new skill + v1/template/ + the old prompt file only.
Files you MAY touch: v1/skills/rebuild-agent-docs/SKILL.md (new, complete frontmatter), v1/template/* (populate), v1/new-project-prompt.md
Files you must NOT touch: unrelated skills; README.md/v1-guide prose (propose a pointer for the lead)
Authoritative source of truth: the existing new-project-prompt + agent-docs-guide.md; effort levels from Stream D
Gate:        v1/template/ populated; new skill exists with name/description, seeds missing docs from the template, and has NO app-specific hardcoded paths; new-project-prompt no longer referenced as the entry point
Report back: created skill summary, what happened to the old prompt, any example path left unresolved
Fallback:    if unsure whether to delete the old prompt, leave a one-line deprecation stub pointing at the new skill
```

## See also

- [overhaul-agent-docs.md](overhaul-agent-docs.md) — hub.
- [overhaul-D-orchestration.md](overhaul-D-orchestration.md) — effort levels
  this skill consumes.
- [overhaul-E-ship-current-work.md](overhaul-E-ship-current-work.md) — the
  finish semantics this skill ends with.
