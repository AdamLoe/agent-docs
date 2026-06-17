---
name: fix-docs-drift-all
description: Full docs/ drift sweep that fixes stale pointers and transcription, then commits if green.
---

> **Note.** This skill owns no facts. The docs no longer assert literal
> counts (see authoring rules 3 and 3a), so the sweep verifies that the
> docs' `path → symbol` pointers still resolve, flags any forbidden
> transcription that crept back, and spot-checks high-risk facts against the
> code that owns them. Code is authoritative; the sweep moves the doc toward
> the code, never the reverse.

You are running a **doc-fix sweep** over `docs/`. This is the heavyweight
flow: run it when you have context/tokens to spare. It fans out across the
doc tree with subagents, **fixes drift in place**, and escalates only what
needs human judgment. As a whole-tree sweep it defaults to `cost-high`, but
it must still be frugal.

This skill runs directly on disk state — no intake questions. Read
`~/agent-docs/v1/rules/skill-contracts.md` for the shared dials and model
policy, and honor any dials passed in `$ARGUMENTS`.

## Before you begin — load app context

Read `docs/_meta/manifest.md` and extract:

- **`code_root`** — the directory that is the root of the app source tree
  (all code paths below are relative to it).
- **`drift-gates`** — the named CI tests / scripts that enforce counts and
  cross-language contracts; reference these when flagging ungated counts.
- **`drift-verification`** — the app-specific high-risk surfaces and
  verification steps to run in Phase 2 (inline this into the agent briefs).
- **`change-to-doc`** — the surface → doc mapping, used to triage
  `Update when` bullets in Phase 3.

Also read `~/agent-docs/v1/rules/authoring-rules.md` — this is the
house authoring standard all docs are graded against.

## Fix vs. escalate

The **codebase is the source of truth for behaviour**; **docs are the source
of truth for what's-where and why.** So:

- **Fix in place** (following the authoring rules):
  stale `Code anchors` and `path → symbol` pointers that no longer
  resolve (renamed/moved/deleted symbols), wrong literal constant
  *values* in prose, drifted short interface snippets, broken
  cross-links, outdated path references. Also fix **forbidden transcription**
  that crept back (full DDL, struct/enum dumps, exhaustive
  column/field/route/variant enumerations) by collapsing it to a
  `path → symbol` pointer, and any **ungated literal count** by replacing
  it with the owning symbol pointer (authoring rules 3 and 3a). Architecture
  is **rewritten in place** — never an "as of slice N…" section.
- **Escalate, don't guess** (report for the user, change nothing): missing
  decision *rationale*, ownership questions, anything needing a design
  judgment, or a mismatch where the **doc may be the intended spec and the
  code is the bug**. Do **not** rewrite a doc to bless behaviour that looks
  like a bug — flag it.

The sweep **commits its own fixes** at the end (see Phase 3) — don't leave
them for the user.

## Orchestration — three phases

**Phase 1 — plan the sweep (do this yourself; cheap).**
- `ls docs/architecture/` and `ls docs/decisions/`.
- Group the docs into ~subsystem **clusters** (a cluster = an architecture
  doc + its `decisions/<domain>.md` + tightly-coupled neighbours).
- **Tier each cluster:**
  - **Strong model** — clusters that touch a high-risk contract surface
    (from the `drift-verification` slot of `docs/_meta/manifest.md`) or
    that require multi-file reconciliation. Cross-file contract reasoning is
    where cheaper models slip.
  - **Mid-tier model** — everything else (mechanical verify-and-fix).
- Aim for ~5–8 agents total, run in parallel. This is the `cost-high` band.
  Do **not** spawn one agent per doc — batch by cluster. Keep strong-model
  use to the few contract clusters.
- Don't read the docs yourself in this phase beyond what you need to cluster
  them — delegate the reading to the agents.

Scope resolution for the `cost` dial: a whole-tree sweep is `cost-high`; a
small or targeted sweep resolves to `cost-medium`; an explicit quick pass
resolves to `cost-low`.

**Phase 2 — dispatch subagents (Agent tool).**
For each cluster, spawn an editing-capable general-purpose agent (the
read-only exploration role cannot fix), using a mid-tier or strong model per
the tier. Run them in parallel. Give each agent:
- its assigned doc paths,
- the **verification recipe** below (inline it — the agent starts cold),
- the **fix vs. escalate** rules above,
- the app-specific **`drift-verification`** content from `docs/_meta/manifest.md`,
- and this required reply format: a compact list of `fixed:` (one line each,
  `doc → what`) and `escalate:` (one line each, with the reason).

Agents fix their own cluster in place and report back. They must not touch
docs outside their cluster — cross-cluster issues go in `escalate:` for you
to reconcile.

**Phase 3 — reconcile (do this yourself).**
- Apply cross-doc fixes no single agent owned (e.g. a renamed symbol whose
  pointer appears in three docs).
- Curate any append-only living-notes section in `docs/` — see the section
  below. This is a lead-only judgment task; don't delegate it.
- Use the **`change-to-doc`** slot from `docs/_meta/manifest.md` to triage
  `Update when` bullets: for each bullet, `git log --oneline -20 -- <path>`
  to spot a recent commit that touched the surface without updating the doc;
  fix the doc or escalate.
- Resolve the escalations you safely can; list the rest for the user.
- **Commit the fixes** once the tree is green — batch the whole sweep into
  one commit (or a few, if cleanly separable). Don't push; branch first if
  on the default branch.
- Final summary: what was **fixed** (grouped by cluster), what **needs human
  review**, and explicitly whether any mismatch **smells like a code bug**
  rather than doc drift.

## Curate living-notes sections (do this yourself)

If `docs/` contains any append-only **Living notes** sections (dated
incidents), curate — don't drift-check — them:

- **Cap it.** Keep roughly the last ~6–8 distinct lessons. Past that, every
  new incident should cost an old one — the section should come out of a
  sweep **shorter or flat, never longer**.
- **Drop dead weight.** Delete entries that are duplicative, superseded by a
  later one, or a one-off with no transferable lesson. Two notes teaching the
  same rule collapse into one.
- **Promote, don't paste.** When an incident has recurred or hardened into a
  standing rule, fold its *general* form into the body above — prefer
  extending an existing bullet over adding a new one — then delete the dated
  incident. Promote **sparingly**: the body stays general and concise. A
  lesson already covered by the body, or too situational to generalize, gets
  dropped or left as a note, **not** promoted.

## Verification recipe (each agent runs this on its cluster)

For each architecture doc, run these checks. The backbone is **pointer
resolution + transcription scan**, not a count checklist.

1. **Resolve every `path → symbol` pointer.** For each `Code anchors` entry
   and every named function / type / constant / route referenced in prose,
   verify the symbol exists at that path — **match by name, never by line
   number** (docs record none). Paths are relative to `code_root` (from
   `docs/_meta/manifest.md`):
   - Rust: `grep -nE 'fn|struct|enum|const|impl|mod|trait' <path>`
   - Python: `grep -nE 'def |class |^[A-Z_]+ =' <path>`
   - TS: `grep -nE 'function|class|interface|const|export' <path>`
   Renamed/moved symbol → fix the pointer. Gone entirely → escalate.
   For any literal constant *value* still in prose, grep the declaration and
   compare; fix the doc to match code, or escalate if the code value looks
   like the bug.

2. **Scan for forbidden transcription that crept back.** Flag (and collapse
   to a `path → symbol` pointer) any full DDL / `CREATE TABLE` body,
   struct/enum field dump, multi-line impl/pseudocode, or exhaustive
   enumeration of columns / fields / routes / variants. A single `pub fn`
   signature or a ~≤8-line payload shape is the allowed snippet ceiling;
   anything larger is transcription. Apply the recoverability test from
   authoring rule 3.

3. **Flag any ungated literal count.** If a doc asserts "N tables / N
   endpoints / N-variant X / N-kind Y / N version constants" without naming
   the CI test or drift gate that enforces it (see `drift-gates` in
   `docs/_meta/manifest.md`), replace the number with a pointer to the owning
   symbol (authoring rule 3a). Do not re-count and re-bless — point to the
   list.

4. **Spot-check high-risk facts against code.** Run every step in the
   **`drift-verification`** slot from `docs/_meta/manifest.md` — those are
   the app-specific surfaces, file paths, and verification commands for this
   repo. Only run the steps your cluster owns; cross-cluster mismatches go in
   `escalate:`.

5. **`Update when` triage.** For each bullet in the docs your cluster owns,
   check `git log --oneline -20 -- <path>` (using paths from the
   `change-to-doc` slot) to spot a recent commit that touched the surface
   without updating the doc; fix the doc or escalate.

$ARGUMENTS
