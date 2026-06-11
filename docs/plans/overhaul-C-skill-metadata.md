---
status:        draft
owner:         unassigned
last_updated:  2026-06-08
okay_to_delete: false
long_lived:    false
owning_docs:
  - v1/README.md
---

# Stream C — skill metadata, length & discoverability

Part of [overhaul-agent-docs.md](overhaul-agent-docs.md). **Phase 3, single
pass over every skill** — after the behavioral edits (D/E/F) land, so it
operates on final skill bodies.

> **Stream G folded in.** Metadata (`name:`/description) and body-length
> trimming both edit every `SKILL.md`. Running them as two "coordinated"
> agents is the exact one-file-two-writers collision the plan avoids — so this
> is **one editorial pass per skill, one agent**: add `name:`, tighten the
> description, trim the body, all at once.

## Mission

Give every skill a `name:` and a tight one-line `description:`, trim hot-path
skill bodies without deleting execution constraints, and teach `/list-skills`
the new adapter model. Recon (2026-06-08): **all 8 existing skills lack
`name:`**.

## Scope

- **In:** `name:` frontmatter on every skill; trimming over-long frontmatter
  `description:` lines; trimming hot-path skill **bodies**; updating
  [`v1/skills/list-skills/SKILL.md`](../../v1/skills/list-skills/SKILL.md) to
  scan both tool adapters and describe the source-vs-adapter distinction.
- **Out:** `README.md`/`v1/README.md` (return the cross-tool-contract table
  edit as slot content for the lead). Out: changing skill *behavior* set by
  D/E/F — shorten wording, don't change semantics. Out: blindly shortening the
  reference docs (`agent-docs-guide.md`, `authoring-rules.md`,
  `orchestrating.md`, `plan-lifecycle.md`) — only flag obvious repetition
  there for the lead.

### Owned files

```
v1/skills/*/SKILL.md            # add name:, tighten description, trim body
v1/skills/list-skills/SKILL.md  # adapter-aware scan + wording
```

## Approach

1. **`name:` on every skill**, matching its directory:

   ```yaml
   ---
   name: fresh-chat
   description: Bootstrap a fresh chat… (≤ ~160 chars, one sentence)
   ---
   ```

   The 8 existing names: `check-docs-consistency-some`, `clear-plans` (kept),
   `fix-docs-drift-all`, `fresh-chat`, `fresh-orchestrator`, `list-skills`,
   `review-docs`, `wrap-up-current-chat`.
2. **The two new skills arrive complete.** `ship-current-work` (Stream E) and
   `rebuild-agent-docs` (Stream F) are created with correct `name:` +
   description already. **Verify them, do not rewrite them** — confirm the
   frontmatter is present and well-formed; leave their bodies to E/F.
3. **Tighten long descriptions** to one sentence where possible; keep the
   disambiguation cues, push full nuance into the body.
4. **Trim hot-path bodies.** Reference docs may stay long if not hot-path;
   skill bodies load on every invocation, so they should be tight. Target
   shape: `1. Purpose  2. Files to read  3. What to do  4. What not to do
   5. Exit/report`. Do **not** paste the authoring rubric into a skill — link
   `~/agent-docs/v1/rules/authoring-rules.md` and restate only what's needed
   to act safely. Same for repeated install-path and "the three
   doc-maintenance skills" explanations.
   - **Do not trim away execution constraints.** A skill intentionally long
     (e.g. `fix-docs-drift-all`, which carries an inline verification recipe
     agents need cold) stays long — justify it in the size report.
   - **Do not trim the effort-resolution sentences D added** to
     `fix-docs-drift-all` and `review-docs` — shorten surrounding prose, keep
     the level mappings intact. **Prove it, don't promise it:** before
     touching those two files, snapshot the level lines
     (`grep -nE 'inline|light|standard|deep|max' <file> > /tmp/<file>.before`);
     after editing, re-grep and diff — the level-bearing lines must still be
     present. Record the before/after in your report. Same for the two new
     skills: snapshot their `name:`/`description:` and confirm byte-identical
     frontmatter after your pass (you verify them, you do not rewrite them).
5. **Update `/list-skills`** (mind that the two tools discover differently —
   Claude is flat, Codex recurses):
   - Scan global Claude skills: `~/.claude/skills/*/SKILL.md` (one level —
     Claude does not recurse).
   - Scan global Codex skills: `~/.codex/skills/**/SKILL.md` (Codex recurses;
     the kit mounts under the `~/.codex/skills/agent-docs/` bucket).
   - Scan project skills: `./.claude/skills/*/SKILL.md` and
     `./.codex/skills/**/SKILL.md`.
   - Report sources as **adapters**: "Global skills are discovered through
     `~/.claude/skills/<name>` (per-skill) or the `~/.codex/skills/agent-docs`
     bucket; the agent-docs source copy is `~/agent-docs/v1/skills`." Remove
     the current claim that `~/.claude/skills` is a symlink to
     `~/.claude/agent-docs/v1/skills`.
6. Return a one-paragraph slot for the README "cross-tool contract" table
   reflecting the `~/.codex/skills` adapter (keyed to the skeleton heading).

## Exit gate

Real assertions (each fails non-zero when unmet), plus a size report that is
informational only:

```sh
fail() { echo "GATE FAIL: $*" >&2; exit 1; }
# every skill has name:
for f in v1/skills/*/SKILL.md; do sed -n '1,12p' "$f" | grep -qE '^name:' || fail "no name: in $f"; done
# PRESERVATION (item 3): D's level mappings survived the trim
grep -qE '\b(deep|standard|light)\b' v1/skills/fix-docs-drift-all/SKILL.md || fail "fix-docs-drift-all lost its effort levels"
grep -qE '\b(inline|standard|deep)\b' v1/skills/review-docs/SKILL.md || fail "review-docs lost its effort levels"
# PRESERVATION: the two new skills' frontmatter is intact (verified, not rewritten)
for s in ship-current-work rebuild-agent-docs; do grep -qE "^name: $s\$" v1/skills/$s/SKILL.md || fail "$s frontmatter altered/missing"; done
# /list-skills updated to the new model, old symlink claim gone
grep -q '~/.codex/skills/agent-docs' v1/skills/list-skills/SKILL.md || fail "list-skills missing codex bucket"
grep -q '~/.claude/agent-docs/v1/skills' v1/skills/list-skills/SKILL.md && fail "list-skills still asserts the old symlink target" || true
echo "C GATES PASS"
wc -w v1/skills/*/SKILL.md | sort -n   # informational size report (compare to the before-snapshot)
```

Every skill has `name:`; `/list-skills` names the Codex bucket and no longer
asserts the old symlink target; no body re-pastes the authoring rubric; D's
effort-resolution prose is provably still present in
`fix-docs-drift-all`/`review-docs`; the two new skills' frontmatter is
byte-stable.

## Dispatch prompt

```
Task:        One pass per skill — add name:, tighten description, trim body — and make /list-skills adapter-aware.
Scope:       v1/skills/*/SKILL.md frontmatter + bodies + list-skills. ONE edit per skill (metadata + length together).
Files you MAY touch: v1/skills/*/SKILL.md
Files you must NOT touch: README.md, v1/README.md (return the cross-tool-contract table edit as slot content). Do NOT rewrite ship-current-work / rebuild-agent-docs bodies — only verify their frontmatter. Do NOT trim the effort-resolution sentences in fix-docs-drift-all / review-docs.
Codex path:  /list-skills scans ~/.codex/skills recursively (kit lives in the ~/.codex/skills/agent-docs bucket); Claude skills are flat in ~/.claude/skills/<name>.
Authoritative source of truth: directory names under v1/skills/ ; the adapter model + skeleton in the hub plan
Gate:        the for-loop prints ok for every skill; wc -w before/after report; list-skills names ~/.codex/skills; no body re-pastes the authoring rubric
Report back: skills updated, descriptions shortened, body reductions (with any skill intentionally left long + why), list-skills changes, proposed README table edit
Fallback:    if unsure a constraint is safe to cut, keep it and produce a report-only bloat list
```

## See also

- [overhaul-agent-docs.md](overhaul-agent-docs.md) — hub.
- [overhaul-B-install.md](overhaul-B-install.md) — the adapter model this
  stream's `/list-skills` wording must match.
- [overhaul-D-orchestration.md](overhaul-D-orchestration.md) — owns the
  effort-resolution prose this stream must preserve.
