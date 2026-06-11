---
status:        draft
owner:         unassigned
last_updated:  2026-06-08
okay_to_delete: false
long_lived:    false
owning_docs:
  - v1/rules/authoring-rules.md
  - README.md
  - v1/README.md
---

# Stream H — authoring rules: router-only adapter exception

Part of [overhaul-agent-docs.md](overhaul-agent-docs.md). **Phase 2,
parallel** — owns `authoring-rules.md` (disjoint from every other Phase-2
stream). The README-side wording is proposed here and applied by the lead in
Phase 4.

## Mission

Resolve the contradiction between the authoring rules' outright ban on
`AGENTS.md`/`CLAUDE.md` and the Codex adapter, which needs a router-only
`AGENTS.md`. The real invariant is "no auto-loaded **facts**," not "no
adapter file may exist."

## Scope

- **In:** the ban wording in
  [`v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md)
  (rule 8 at [line 100](../../v1/rules/authoring-rules.md#L100), and the
  matching anti-pattern bullet). Propose the consistent README/guide wording
  for the lead.
- **Out:** the install/adapter snippets themselves (Stream B). Out: editing
  `README.md`/`v1/README.md` directly (lead applies in Phase 4).

### Owned files

```
v1/rules/authoring-rules.md
```

(README.md / v1/README.md / v1/agent-docs-guide.md mentions of AGENTS.md are
reconciled by the lead in Phase 4 using this stream's proposed wording.)

## Approach

1. Replace the hard ban with the facts-vs-router distinction, e.g.:

   ```
   No auto-loaded architecture facts.

   Do not use CLAUDE.md, AGENTS.md, or equivalent auto-loaded files as fact
   dumps. If a tool requires an auto-loaded file, it may exist only as a
   router/adapter: it points to docs/index.md, docs/overview.md, and the
   relevant skill entry points. It must not own architecture, decisions, or
   app-specific facts.
   ```

2. Keep the invariant explicit: `docs/` owns app facts; skills/rules own
   workflow; tool adapter files own no facts.
3. Update the matching anti-pattern bullet
   ([line ~145](../../v1/rules/authoring-rules.md#L145), "Let me drop a
   one-liner in an auto-loaded instructions file") so it bans fact dumps, not
   the existence of a router file.
4. Hand the lead wording so the README's Codex/OpenAI adapter section and the
   guide's "No auto-loaded context" corollary agree with the new rule.

## Exit gate

No contradiction remains between the authoring rules and the README's
Codex/OpenAI adapter guidance: both say a **router-only** `AGENTS.md` is
allowed and a **fact-dump** is not.

```sh
grep -RIn 'AGENTS.md\|auto-loaded' v1/rules/authoring-rules.md
```

## Dispatch prompt

```
Task:        Relax the AGENTS.md/CLAUDE.md ban to "no auto-loaded facts; router-only adapter allowed."
Scope:       authoring-rules.md rule 8 + the matching anti-pattern bullet; propose README/guide wording.
Files you MAY touch: v1/rules/authoring-rules.md
Files you must NOT touch: README.md / v1/README.md / v1/agent-docs-guide.md (lead applies in Phase 4); skill bodies
Authoritative source of truth: invariant — docs/ owns facts, adapters own no facts
Gate:        rule now allows a router-only adapter file but still bans auto-loaded fact dumps; no contradiction with README Codex guidance
Report back: exact rule wording changed + the proposed README/guide wording
Fallback:    if scope is unclear, add the rule wording and flag the README sentences that still conflict
```

## See also

- [overhaul-agent-docs.md](overhaul-agent-docs.md) — hub.
- [overhaul-B-install.md](overhaul-B-install.md) — the Codex adapter section
  whose `AGENTS.md` guidance this rule must match.
- [`v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md) — the doc
  this stream owns.
