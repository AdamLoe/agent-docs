---
status:        draft
owner:         unassigned
last_updated:  2026-06-08
okay_to_delete: false
long_lived:    false
owning_docs:
  - v1/agent-docs-guide.md
  - v1/README.md
  - v1/rules/authoring-rules.md
---

# Stream E — work lifecycle & `/ship-current-work`

Part of [overhaul-agent-docs.md](overhaul-agent-docs.md). **Phase 2,
parallel** — owns one new skill plus two existing skills, disjoint from the
other Phase-2 streams.

## Mission

Give ordinary work a real finish line. Add `/ship-current-work` as the
default completion command (inspect diff → update owning docs → run narrow
gates → migrate touched plan context → commit), and demote
`/wrap-up-current-chat` to capturing only chat-specific durable knowledge.

## Scope

- **In:** create
  [`v1/skills/ship-current-work/SKILL.md`](../../v1/skills/ship-current-work/SKILL.md);
  rewrite [`wrap-up-current-chat`](../../v1/skills/wrap-up-current-chat/SKILL.md)
  to point at it; add a one-line pointer in
  [`fresh-chat`](../../v1/skills/fresh-chat/SKILL.md).
- **Out:** `v1/rules/authoring-rules.md` adapter wording (Stream H). Out:
  `README.md`/`v1/agent-docs-guide.md` lifecycle prose (propose for the lead
  in Phase 4). Out: skill `name:` frontmatter (Stream C adds it for the new
  skill).

### Owned files

```
v1/skills/ship-current-work/SKILL.md     (new)
v1/skills/wrap-up-current-chat/SKILL.md
v1/skills/fresh-chat/SKILL.md
```

## Approach

1. **Create `/ship-current-work`.** Body in the kit's house style (link the
   rules, restate only what's needed to act safely). **Write complete
   frontmatter on creation** — `name: ship-current-work` and a tight one-line
   `description:` — so Stream C only verifies it, never rewrites it. Required
   behavior:
   - Read `docs/_meta/manifest.md`, `docs/_meta/ownership.json`, and the kit
     rules `~/agent-docs/v1/rules/{authoring-rules,repo-rules}.md`. **Read the
     manifest by these exact slot keys** (locked in Phase 1, do not invent
     variants): `code_root`, `change-to-doc`, `drift-gates`,
     `drift-verification`, `decisions-domains`; owning-doc map from
     `ownership.json`.
   - Inspect: `git status --short`, `git diff --stat`, `git diff --name-only`.
   - Determine owning docs from the manifest `change-to-doc` table + the
     ownership data.
   - Update architecture docs in place; update decisions docs only for
     durable rationale.
   - If a plan was touched/completed: migrate durable context, update
     `status` / `last_updated` / `okay_to_delete` — **do not delete plans
     here** (that's `/clear-plans`).
   - Run the narrow gates from the manifest `drift-gates` slot (real
     assertions — a gate that can't fail isn't a gate).
   - Stage by filename; commit if green; **never push** unless told.
2. **Demote `/wrap-up-current-chat`.** State it is not the default finish
   command; it captures only this chat's durable knowledge not recoverable
   from docs/code/git. Point to `/ship-current-work` for normal completion
   and `/clear-plans` for repo-wide plan sweeps. (It already references
   `clear-plans` and `fix-docs-drift-all` — keep those.)
3. **Update `/fresh-chat`.** Add one line: normal work finishes with
   `/ship-current-work`.

> **Runnable here.** Phase 1 adds a minimal `docs/_meta/manifest.md` +
> `ownership.json` to this repo, so `/ship-current-work` can actually run on
> agent-docs itself — Phase 5 may use it as its own first real exercise. Write
> the skill so it degrades gracefully if a manifest slot is thin (this repo's
> owning docs are the kit files, not an `architecture/` tree).

## Exit gate

```sh
test -f v1/skills/ship-current-work/SKILL.md && echo "skill exists"
sed -n '1,12p' v1/skills/ship-current-work/SKILL.md | grep -qE '^name:' && echo "has name"
grep -RIn 'ship-current-work' v1/skills/wrap-up-current-chat/SKILL.md   # wrap-up points to it
```

`/ship-current-work` exists with complete frontmatter, is discoverable by
`/list-skills`, and `/wrap-up-current-chat` defers to it and to `/clear-plans`.

## Dispatch prompt

```
Task:        Create /ship-current-work (with complete name:+description frontmatter); demote /wrap-up-current-chat to chat-memory capture.
Scope:       the three owned skill files only. Write ship-current-work's frontmatter complete so Stream C only verifies it.
Files you MAY touch: v1/skills/ship-current-work/SKILL.md (new), v1/skills/{wrap-up-current-chat,fresh-chat}/SKILL.md
Files you must NOT touch: v1/rules/authoring-rules.md (Stream H), README.md / v1/agent-docs-guide.md (lead applies lifecycle prose), other skills
Authoritative source of truth: the work-lifecycle steps in this stream file; the kit's authoring + repo rules
Gate:        ship-current-work exists; wrap-up-current-chat points to ship-current-work and clear-plans
Report back: new skill summary, changed references, the proposed README/guide lifecycle paragraph
Fallback:    if a manifest slot name is uncertain, follow existing skills' usage (e.g. fix-docs-drift-all) and flag it
```

## See also

- [overhaul-agent-docs.md](overhaul-agent-docs.md) — hub; lifecycle prose
  lands in `v1/agent-docs-guide.md`/`v1/README.md` at Phase 4.
- [overhaul-F-rebuild-agent-docs.md](overhaul-F-rebuild-agent-docs.md) — the
  rebuild skill ends with `/ship-current-work` semantics.
- [`v1/rules/repo-rules.md`](../../v1/rules/repo-rules.md) — the commit
  discipline `/ship-current-work` enforces.
