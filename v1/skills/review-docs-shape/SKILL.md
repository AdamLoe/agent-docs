---
name: review-docs-shape
description: Editorial review of docs/ for fit, shape, and direction.
---

You are running an **editorial doc review** over a doc, a subtree, or the
whole `docs/` tree. This is the **judgment** flow of the three doc-maintenance
skills — it asks the questions grep can't:

- **fix-docs-drift** — whole tree, **fixes drift in place + commits**.
  Mechanical, mutating.
- **check-docs** — named docs, **checks accuracy-vs-code +
  the house rules**, reports. Mechanical.
- **this skill** — is this the **right** doc, in the **right shape**,
  **heading the right way**? Editorial, opinionated, report-only.

The other two ask "does the doc match the code and the rules?" This one asks
"is this the doc we should have at all?" It is **report-only**: you form a
point of view and recommend; you don't edit or commit. Structural moves belong
in a plan.

This skill runs directly — no intake questions. Read
`~/agent-docs/v1/rules/skill-contracts.md` for the shared dials and model
policy, and honor any dials passed in `$ARGUMENTS`. Scale fan-out to scope:
one doc is `cost-low` (review inline); a subtree is `cost-medium`; the whole
tree defaults to `cost-high`, and `cost-max` only when scope needs to fan out
harder still.

**Be opinionated.** A hedged editorial review is useless. Say what's wrong
with the direction and what you'd do instead.

## Before you begin — load app context

Read `docs/_meta/manifest.md` and extract:

- **`decisions-domains`** — the set of decision domains this app uses, to
  judge whether `decisions/` coverage is complete.
- Any other slots relevant to the scope of the review (e.g.
  `change-to-doc` for direction/debt judgments).

Also read:

- `docs/_meta/ownership.json` — to judge whether concepts sit with the right
  owner.
- `~/agent-docs/v1/rules/authoring-rules.md` — the authoring standards the
  tree is meant to meet.

## Orient first

Before judging, load the shape so the opinion is grounded, not free-floating:

- `docs/overview.md` (if it exists) — the system at a glance, to judge
  coverage: what exists vs what's documented.
- The relevant index — `docs/architecture/index.md`,
  `docs/decisions/index.md`, `docs/agent-context/index.md` (whichever are in
  scope) — to judge routing and fit.
- `docs/_meta/ownership.json` — to judge whether concepts sit with the right
  owner.
- Skim `docs/plans/` and any active plan — to judge *direction*: what's
  coming that the docs will need to serve.

## The lenses

1. **Coverage & gaps.** What important subsystem, decision rationale, or
   gotcha has no doc — or is buried where no one finds it? What is documented
   that no longer earns its place (dead subsystem, a doc no reader needs)?
   Under- and over-documentation are both findings.

2. **Structure & organization.** Is the material in the right layer
   (architecture = what IS, decisions = why, agent-context = procedure)?
   Should a doc split (sprawls past one subsystem) or merge (two thin docs
   circling one idea)? Is a concept owned cleanly, or smeared across docs?

3. **Routing & fresh-chat fit.** The tree is built to be navigated by a fresh
   LLM chat: start small, route by task. Trace the path a fresh chat would
   take to answer a real question in this area — does it land in the right
   place, or dead-end / over-read? Where does onboarding break?

4. **Altitude & framing.** Is the area pitched for its reader — the map, the
   invariants, the why — or does it drift into what the author found
   interesting? Is the framing "what IS", or has it crept toward changelog /
   history?

5. **Direction.** Given where the project is heading (the plans), what doc
   debt is accruing? What will need to exist soon? Is the doc system's own
   design still right as the system grows?

## Codebase pointers

This review judges docs *as docs* — it does **not** re-verify every code
claim. But ground coverage claims in reality:

- System shape: `docs/overview.md`, `docs/repository-layout.md` (or
  equivalents in the repo).
- Authoring standards the tree is meant to meet:
  `~/agent-docs/v1/rules/authoring-rules.md`.

## How to run it

- **One doc / small area** → read it plus its neighbours and index inline;
  judge it *in context*, not in isolation.
- **A subtree or the whole tree** → read the indexes, sample the docs, fan
  out a fresh-context sub-agent per cluster if it's large, then synthesize
  **one** point of view. This is judgment work — prefer the stronger model.

## Report format

An opinionated editorial, not a checklist:

- **Take** — 2–4 sentences: the honest state of this area's docs and the
  single most important thing to change.
- **Findings** — each as `area → the problem → what you'd do`, ordered by
  impact. Cover gaps, structure, routing, altitude, direction as they apply.
  Be concrete: "split X into A+B", "Y has no home — add a decisions entry",
  "the architecture index routes Z wrong".
- **Leave alone** — what's working, so it doesn't get churned.
- **Next step** — usually "draft a plan for the structural changes" (offer to
  write one into `docs/plans/`) and/or "run `fix-docs-drift` /
  `check-docs` for the mechanical cleanup this surfaced".

## See also

- **check-docs** skill — the mechanical accuracy +
  house-rules check on named docs.
- **fix-docs-drift** skill — the whole-tree drift sweep that fixes in
  place and commits.
- `~/agent-docs/v1/rules/authoring-rules.md` — the authoring
  standards.

What to review is below — a doc, a subtree, or empty. **If empty, default to
the whole `docs/` tree** (`cost-high`, per above); do not stop to ask.

$ARGUMENTS
