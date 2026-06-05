---
description: Consistency-check one or more NAMED docs/ docs against the code and the house authoring rules — accuracy-vs-code (stale path→symbol pointers, wrong constant values, contradictions) and clarity/altitude — then report findings. Read-only: no edits, no commits. The lightweight, report-only cousin of fix-docs-drift-all (whole-tree, fixes in place). Mechanical, not editorial — for the big-picture "is this the right doc?" read use review-docs. Loads authoring rules from ${CLAUDE_PLUGIN_ROOT}/rules/authoring-rules.md and ownership from docs/_meta/ownership.json; waits for you to name the doc(s) if none are passed.
---

You are running a **doc consistency check** over one or more named docs in
`docs/`. This is the **read-only, report-only** flow of the three
doc-maintenance skills:

- **fix-docs-drift-all** — sweeps the **whole tree** and **fixes drift in
  place + commits**. Heavyweight, mutating.
- **this skill** — checks the **doc(s) you name** for consistency and
  **reports findings**. Lightweight, changes nothing.
- **review-docs** — the **editorial** read: is this the right doc, in the
  right shape, heading the right way? Judgment, not grep.

So this flow is mechanical, not editorial: does each named doc still match
the code and the house authoring rules? You change **nothing** — no edits,
no commits. If findings should be applied, that's a follow-up edit pass or
the `fix-docs-drift-all` sweep. The codebase is authoritative for behaviour;
the docs are authoritative for what's-where and why.

## Before you begin — load app context

Read `docs/_meta/manifest.md` and extract:

- **`code_root`** — the directory that is the root of the app source tree
  (all code paths in docs are relative to it).
- **`drift-gates`** — the named CI tests / scripts that enforce counts and
  cross-language contracts; use these when assessing whether a literal count
  is gated.
- **`drift-verification`** — the app-specific high-risk surfaces and
  verification steps; borrow from this when spot-checking accuracy claims.

Also read `${CLAUDE_PLUGIN_ROOT}/rules/authoring-rules.md` — this is the
house authoring standard all docs are graded against (the clarity lens below
cites its rules by number).

For ownership questions, read `docs/_meta/ownership.json` — it maps concepts
to their owning doc.

## The two lenses

Check every named doc against exactly these two lenses, both anchored to the
codebase's own standards. (Structure/routing and LLM-navigation are *not*
this flow's lenses — those are big-picture judgments that belong to
**review-docs**. Note one here only if it's glaring; don't go hunting.)

### 1. Accuracy vs code — spot-check when it's cheap

Code is the source of truth for behaviour. Verify the doc's claims against
it, but stay frugal — spot-check the high-risk claims, don't boil the ocean:

- **Resolve `path → symbol` pointers and `Code anchors`.** Grep the named
  symbol at the named path (relative to `code_root`); **match by name, never
  by line** (docs record none). Renamed/moved → stale pointer finding. Gone
  → flag it.
  - Rust: `grep -nE 'fn|struct|enum|const|impl|mod|trait' <path>`
  - Python: `grep -nE 'def |class |^[A-Z_]+ =' <path>`
  - TS: `grep -nE 'function|class|interface|const|export' <path>`
- **Check literal constant values in prose** against their declaration.
- **Flag contradictions** between doc and code — and where the **doc may be
  the intended spec and the code looks like the bug**, surface that explicitly
  rather than siding with either.

For app-specific high-risk surfaces and their verification steps, borrow from
the **`drift-verification`** slot in `docs/_meta/manifest.md` — but
**report instead of fixing**.

### 2. Clarity & altitude — grade against the authoring rules

The rubric is the authoring rules at
`${CLAUDE_PLUGIN_ROOT}/rules/authoring-rules.md`. Flag where the doc
violates them:

- **Altitude** (rule 4): a subsystem doc is ~1–2k tokens — map + invariants
  + gotchas + why. Flag bloat, and flag a doc that has grown past ~2k tokens
  and should split.
- **What IS, not what changed** (rule 2): no "slice N introduced…" / "as of
  v1.X…" / version-flavoured framing in architecture docs.
- **No transcription, no ungated counts** (rules 3, 3a): flag full DDL,
  struct/enum field dumps, multi-line code/pseudocode, exhaustive
  enumerations of columns/fields/routes/variants, and any literal count not
  backed by a named CI test or drift gate (see `drift-gates` in
  `docs/_meta/manifest.md`).
- **Ownership** (rule 1): the doc defines only the concepts it owns (check
  against `docs/_meta/ownership.json`); flag a non-owner growing substantive
  content it should link instead.
- **The generic read** (beyond the house rules): does the opening orient the
  reader to scope? Is terminology consistent? Any dead, confusing, or
  self-contradictory passage? Would a fresh agent arrive with a question and
  leave with the answer?

## How to run it

- **One doc** → check it inline.
- **Several docs** → check each with a fresh-context sub-agent (one per doc
  keeps the reads independent), then collate the reports.
- Read the whole doc for the clarity lens; spot-check the accuracy lens where
  it's cheap.

## Report format

One short report per doc — no edits, no commits:

- **Verdict** — one line (e.g. "consistent", "accurate but bloated", "two
  stale pointers").
- **Accuracy findings** — each as `location → issue` (stale pointer, wrong
  value, contradicts code, possible code bug). State "none" if clean.
- **Clarity findings** — each as `location → issue`, naming the rule it trips
  (altitude / transcription / ownership / readability). State "none" if clean.
- **Suggested next step** — e.g. "minor, fix inline", "run
  `fix-docs-drift-all`", "needs an editorial `review-docs` pass", or
  "escalate the possible code bug at X".

## See also

- **fix-docs-drift-all** skill — the heavyweight whole-tree sweep that fixes
  drift in place and commits.
- **review-docs** skill — the editorial/direction review (is this the right
  doc, in the right shape?).
- `${CLAUDE_PLUGIN_ROOT}/rules/authoring-rules.md` — the authoring rules
  this check grades against.

The doc(s) to check are below — a path, several paths, or empty. **If empty,
ask which doc(s) to check** before proceeding.

$ARGUMENTS
