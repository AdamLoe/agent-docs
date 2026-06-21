---
wave: 2
status: complete
commit: (see below)
---

# Wave 2 stream — Align role + mutation contracts

## Contradictions found and how they are reconciled

### 1. Closeout contradiction (headline fix)

**Contradiction:** `implementation.tracked` is `mutating` in the profile table
and the plan says it should be able to close the selected plan. But
`src/rules/subagent/implementation.md` line 31 said: "Do not switch roles. You
do not create broad plans, run review lifecycle, **change plan status**, or
choose another skill." This blanket prohibition made the profile's purpose
(`selected tracked-plan implementation and closeout`) self-contradictory.

**Resolution:** Three files now agree:
- `src/rules/subagent/implementation.md` — prohibits plan-status changes in
  general, with an explicit carved-out exception: `implementation.tracked` may
  close ONLY the selected plan when the dispatch grants `plan_closeout`.
- `src/rules/context-profiles.md` profile table — `implementation.tracked`
  purpose now reads "may close the selected plan when dispatch grants
  `plan_closeout`".
- `src/rules/orchestrator/dispatch.md` Mutation Authority section — adds a
  dedicated `plan_closeout` grant paragraph naming the exact token, what it
  permits, and the default-off rule.

The token `plan_closeout` is the explicit grant name in all three files.

### 2. planning.brief: read-only boundary

**State before:** The planning role card blurred brief vs tracked. References
listed `plan-lifecycle.md` and `plan-template.md` without distinguishing which
variant loads them. A naive reader could assume brief loads lifecycle rules.

**Resolution:** Added a "Profile variants" section before "How you work":
- `planning.brief` — explicitly read-only, never loads `plan-lifecycle.md`,
  `plan-template.md`, or `repo-rules.md`, never stages or commits, returns inline
  only.
- `planning.tracked` — explicitly mutating, may create/edit/stage/commit the
  assigned plan file, references the dirty-tree + commit contract in repo-rules.md
  (already in its resolved profile).

The References section (non-loading) still lists lifecycle/template for when a
tracked worker needs them; the variant block makes clear they only apply to
tracked.

### 3. planning.tracked: dirty-tree + commit contract

**State before:** Role card said "When you write a tracked plan, follow..." but
didn't spell out the commit discipline (snapshot, stage by filename, commit
before reporting, never push).

**Resolution:** Profile-variants block in planning.md now explicitly states the
dirty-tree and commit contract for tracked: snapshot git status --short, stage
only the plan file by filename, commit before reporting, never push. This is
cross-referenced to repo-rules.md (the canonical owner) rather than duplicating
full rules.

### 4. implementation.code vs .code-docs boundary

**State before:** Role card was generic across all three variants; no reader
could tell which scope applied to `.code` vs `.code-docs` vs `.tracked`.

**Resolution:** "Profile scope" paragraph added at the end of "How you work":
`.code` = code/tests only, stop if docs migration is needed; `.code-docs` = code
plus directly-owned docs via ownership.json; `.tracked` = code, owning docs, and
plan closeout when `plan_closeout` is granted.

### 5. Fix-enabled review/verification paths

**State before:** `review.md` said "Stay read-only. Report misses and route the
fix to implementation..." — correct intent but could be read as "fix it then
report." `verification.md` said "Do not fix the code you are verifying. If a
gate fails, report the failure with output; the orchestrator routes a fix worker."
— correct but soft.

**Resolution:**
- `review.md`: Changed to "**Stay read-only.** Never edit, stage, or commit any
  file. Report misses with evidence and name the required mutator profile..."
- `verification.md`: Consolidated the "do not fix" and "stay read-only" lines
  into "**Stay read-only.** Never edit, stage, or commit any file. If a gate
  fails, report the failure with evidence; the orchestrator routes an
  implementation, docs-maintenance, or plan-maintenance worker to fix it."

No fix-enabled path existed as code, only ambiguous phrasing. Phrasing is now
unambiguous.

Dispatch.md Mutation Authority also now says "Review and verification profiles
are always read-only — they never edit, stage, or commit."

### 6. Worker report contract: invalidation conditions

**State before:** Worker Reports in dispatch.md listed 8 required fields. The
Resuming section described when to invalidate a worker, but "invalidation
conditions" was not a required report field — so returned workers didn't
document what would make their report stale.

**Resolution:** Worker Reports now requires 9 fields; "invalidation conditions"
is added: name the changes that would make this report stale or unsafe to resume
from. The observed-basis and sources-inspected bullets were also made more
explicit ("observed commit and dirty-path state", "sources inspected and
precedence used", "evidence", "touched paths", "commits").

## Gate results

```
bash src/verify-agent-docs.sh
→ exit 0: ALL AGENT-DOCS GATES PASS

bash src/verify-agent-docs.sh --context-report
→ exit 0: CONTEXT REPORT PASS

bash src/verify-agent-docs.sh --resolve implementation.tracked
→ exit 0: RESOLVE PASS, mutation: mutating
```

`rg -n "plan_closeout" src/rules` shows consistent use in:
- `src/rules/context-profiles.md` (profile table purpose field)
- `src/rules/orchestrator/dispatch.md` (Mutation Authority grant paragraph, ×2)
- `src/rules/subagent/implementation.md` (plan-status exception, ×2)

## Files edited

- `src/rules/subagent/implementation.md` — plan_closeout carve-out + profile-scope block
- `src/rules/subagent/planning.md` — profile-variants block (brief vs tracked)
- `src/rules/subagent/review.md` — read-only statement hardened
- `src/rules/subagent/verification.md` — read-only statement hardened
- `src/rules/context-profiles.md` — implementation.tracked purpose updated
- `src/rules/orchestrator/dispatch.md` — Mutation Authority + Worker Reports updated

## Durable facts for migration (Wave 6)

- `plan_closeout` is the canonical grant token for selected-plan closeout authority.
- `planning.brief` never loads lifecycle/template/repo-mutation rules.
- Review and verification are read-only at the role-card, profile, and dispatch
  level; failed phases return evidence + required mutator profile to orchestrator.
- Every worker report must include invalidation conditions.
