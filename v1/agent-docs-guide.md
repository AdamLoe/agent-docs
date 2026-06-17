# How agent-docs is shaped (and how to adopt it)

A portable description of the documentation system in this kit. It states
the principles first and uses a concrete app tree only as a worked
example. Nothing here is app-specific; the shape transfers to any codebase
whose primary documentation reader is an LLM.

This is **agent-docs v1**. Its defining move: the generic machinery — the
authoring rules and the maintenance/chat commands — lives **once**, in
this kit (`agent-docs/v1/`), and every app supplies only its own facts
through a small binding file. You are reading the generic half.

## The problem this solves

Two failure modes kill most project docs:

1. **Drift.** A doc transcribes how the code works. The code changes. The
   doc now lies, and a reader trusts the lie. The more detail a doc copies
   from the code, the faster it rots.
2. **Context cost.** An agent has a finite context window. A single 200KB
   "everything" doc, or a sprawl of overlapping files, forces it to burn
   budget reading things it doesn't need before it can start the task.

Everything below is downstream of fighting those two forces. If a rule
seems fussy, ask which of *drift* or *context cost* it defends against —
usually both.

## The mantra

> **Docs carry the map, the invariants, the gotchas, and the why.
> Code carries the behavior. Start small, route by task, load only the
> subtree you need.**

Four corollaries:

- **The code is authoritative for behavior; docs are authoritative for
  what's-where and why.** Never duplicate what the code already states.
- **Describe what *is*, not what *changed*.** History lives in the git
  log, not in a doc.
- **Every fact has exactly one owner.** Other docs link to it; they never
  re-explain it.
- **No auto-loaded facts.** No `CLAUDE.md` / `AGENTS.md` dumping ground.
  If a tool requires an auto-loaded file, keep it router-only and keep
  architecture, decisions, and app-specific facts in `docs/`.

## The recoverability test (the single most important rule)

Before you write any sentence into a doc, ask:

> *Could an agent recover this fact in ~30 seconds by reading the named
> code file?*

- **Yes** → it's transcription. Delete it. Replace it with a pointer:
  `path/to/file.rs → symbol_name`.
- **No** (it's a map, an invariant, a gotcha, or a rationale) → keep it.
  This is exactly the stuff that *isn't* in the code and can't be
  recovered by reading it.

Pointers use **symbol names, not line numbers** (`schema.rs → build_ddl`,
not `schema.rs:412`). Line numbers drift the instant anyone edits above
them; symbol names are grep-stable.

**Banned forms** (always transcription): full schema/DDL bodies,
struct/enum field dumps, multi-line code or pseudocode, exhaustive lists
of columns/routes/variants. Point to the symbol that *is* the
authoritative list and let the reader read it. **One narrow exception:** a
single function signature or a tiny stable payload shape (≤ ~8 lines) may
sit inline when it's a contract a reader needs at a glance. That's the
ceiling.

**Corollary — don't assert counts.** "There are 14 routes" is the cheapest
fact to drift and the costliest to trust once stale. Only state a literal
count if a named CI test or drift gate *fails* when the number is wrong —
and then cite that gate inline. Otherwise point to the list and let the
reader count.

## What's generic vs. what's per-app (the v1 split)

This is the structural heart of v1. Documentation divides into two layers
that change at different rates and have different owners:

| Layer | Lives in | Owns |
|---|---|---|
| **Generic kit** (`agent-docs/v1/`) | this kit, versioned, shared across apps | the authoring rules, the coding/repo/orchestrating rules, the chat & maintenance **skills**, this guide, the plan-lifecycle rules, the plan template |
| **Per-app docs** (`docs/`) | each repo | the app's architecture, decisions, agent-context, plans, and a `_meta/manifest.md` that fills the kit's slots |

The rules in the kit are written to be app-agnostic. Wherever a rule needs
an app fact — a code root, a constant, the "if you changed file X update
doc Y" table — it does **not** inline it; it points at a **slot** in the
app's `docs/_meta/manifest.md`. An app adopts the system by writing that
manifest, not by copying rules. Upgrade the rules once in the kit and
every app moves together.

The previous generation of this system had a fourth in-repo doc tree
called `prompts/` (copy-paste templates for starting a chat or running a
task). v1 removes it: those templates became **skills** in the kit
(`/fresh-chat`, `/fix-docs-drift-all`, …), invoked directly, owning no
facts. There is no `prompts/` tree.

## The kinds of doc

"Documentation" is really several different things with different
lifetimes. Keep them in separate trees so each can follow its own rule.

| Kind | Answers | Lifetime | Rule |
|---|---|---|---|
| **Architecture** | "What *is* the system right now?" | Rewritten in place on every change | Current state only. No "v2.1 added…". |
| **Decisions** | "*Why* is it this way?" | Append a decision; delete when superseded | Sectioned by domain, not by date. No `Date:` field — git owns dates. |
| **Agent-context** | "When working on X, do Y, don't do Z." | Procedural, evolves with workflow | Each doc opens with "when does this apply"; links up to its generic kit rule. |
| **Plans** | Coordination surface for in-flight multi-step work | Disposable; migrated into architecture/decisions on ship | Status frontmatter. Designed to be deleted. |

Two clarifying examples of the architecture/decisions split:

- *Architecture* says: "Sessions use a two-phase reserve→promote start;
  one session of any kind runs at a time (`sessions.rs → reserve`)."
- *Decisions* says: "We allow only one active session because there is a
  single GPU and contention would corrupt throughput numbers." With `Why`
  and `Applies to: architecture/sessions.md`.

The architecture doc tells you the shape; the decision tells you why
you're not allowed to change it without thinking.

## The supporting files

On top of the trees, a handful of files do the connective work. In v1 the
ownership map and the app bindings are **data**, not prose:

- **`index.md`** — the global router. The first thing anyone reads. A
  table of "Need → Read" rows. It owns no facts; it points.
- **`overview.md`** — the system in one screen: a diagram, the major
  components, the handful of hard-to-grep facts (exact dependency
  versions, environment quirks). Read once at chat start for shape.
- **`_meta/manifest.md`** — the app's binding to this kit. Fills the
  kit's slots: `code_root` (what code paths resolve against), the
  `change-to-doc` table, the `drift-gates`, the `decisions-domains` set.
  This is what makes the generic rules executable against a specific repo.
- **`_meta/ownership.json`** — the tie-breaker, as structured data:
  concept → its one canonical owner doc (+ allowed referencers). When two
  docs could explain the same thing, this decides; the loser links. Query
  it; don't bulk-load it.
- **`repository-layout.md`** — a file/directory inventory. Read only when
  you need to find where code lives, never proactively.

## Routing: start small, descend by task

The tree is a decision tree, not a book. A reader never reads it top to
bottom. The flow is always:

```
/fresh-chat  →  _meta/manifest.md  →  index.md  →  overview.md  →  (wait for the task)
                                                                       │
                          ┌────────────────────────────┬──────────────┼───────────────┐
                          ▼                ▼            ▼              ▼
                  architecture/      decisions/   agent-context/    plans/
                     index.md         index.md       index.md       index.md
                          │                │            │                │
                     one subsystem    one domain    one procedure   one plan
```

Each `index.md` is a router with a `Need → Read` table. Each leaf doc is
kept to **~1–2k tokens, one subsystem per file** — big enough to be worth
a hop, small enough that loading the wrong one is cheap. If a leaf grows
past ~2k tokens, split it.

The payoff: an agent answering "why does training stop mid-run save a
model?" reads `index → decisions/index → decisions/training.md` and
touches maybe 3k tokens total, never loading anything about the HTTP layer
or the renderer.

## Ownership in practice

Ownership keeps two docs from slowly growing two subtly different
explanations of the same thing.

- Each concept appears in exactly one owner doc (the ownership data names
  it).
- Every other doc that needs it **links** to the owner instead of
  re-explaining.
- When a non-owner doc grows real content about a concept it doesn't own,
  that's drift — move the content to the owner, leave a link.

`See also` sections at the bottom of each doc are where the cross-links
live. Link liberally: to sibling architecture docs, to the decision that
constrains this doc, to the procedural doc that touches it.

## Plans: the staging area, designed to be deleted

Multi-step work needs a coordination surface, but that surface must not
become permanent shadow-architecture. So plans are explicitly temporary:

- Each plan is a file with YAML frontmatter: `status`, `owner`,
  `last_updated`, `okay_to_delete`, `long_lived`, `owning_docs`. The full
  field spec is in [`plan-lifecycle.md`](plan-lifecycle.md); new plans
  start from [`plan-template.md`](plan-template.md).
- While `active`, the plan is the source of truth for in-flight work.
- **When the work ships, you migrate the plan's durable content** — facts
  into architecture, rationale into decisions — and then the plan becomes
  deletable.
- The default expectation is that **shipped plans get deleted.**
  `long_lived: true` is a rare escape hatch for context that genuinely
  can't be routed elsewhere.

The goal this enforces: *a fresh chat should never need to read plan
history to understand the current system.* If it does, migration was
incomplete.

## Maintenance is part of the system, not an afterthought

A docs system that relies on humans remembering to update it will drift.
So maintenance is built in two ways.

**A change→doc table.** Before any change is "done," you consult a table:
"If you changed file X, update doc Y." Because that table is entirely
app-specific, it lives in the app's manifest (the `change-to-doc` slot),
not in the generic rules. The rules point at the slot. This turns
"remember to update the docs" into a lookup.

**Automated sweeps, shipped as skills.** The kit carries a small set of
commands that maintain the tree on two axes — scope (whole tree vs. named
docs) and action (fix vs. check vs. review):

- a **fix** sweep (`/fix-docs-drift-all`) that walks the whole tree,
  verifies every `path → symbol` pointer still resolves, scans for
  forbidden transcription, and fixes drift in place;
- a **check** pass (`/check-docs-consistency-some`) that grades named docs
  against the rules and reports without changing anything;
- an **editorial review** (`/review-docs`) that asks the higher question —
  is this even the *right* doc, in the right shape?

Plus the chat/lifecycle commands: `/fresh-chat`, `/agent-docs-doctor`,
`/orchestrate`, `/plan`, `/quick-fix`, `/implement-plans`, `/review-work`,
`/review-plans-high-level`, `/review-plans-health`, `/review-plans-custom`,
`/review-agent-docs-skills`, `/ship-current-work`, `/wrap-up-current-chat`,
`/clear-plans`, `/rebuild-agent-docs`, `/list-skills`, and
`/lodge-agent-docs-feedback`. The principle — *the rules for maintaining the
docs are themselves runnable* — is what keeps the system honest over time.

## Work lifecycle

Ordinary work starts with `/fresh-chat`, proceeds against the app's code
and docs, and finishes with `/ship-current-work`. Shipping means inspecting
the diff, finding owning docs through `docs/_meta/manifest.md` and
`docs/_meta/ownership.json`, updating durable docs, running the manifest
drift gates, migrating any touched plan context, staging by filename, and
committing only when green.

Planning starts with `/plan`: it reads the docs router, turns rough app-state
thoughts into separated concerns, gives high-level feedback, asks batched
questions until the important choices are settled, and writes one or more
implementation-ready planning docs with ordering, boundaries, and
verification.

End-to-end change orchestration starts with `/orchestrate`: it asks for
the desired change, decides whether the work is a quick fix, a briefed
implementation, or a tracked plan lifecycle, and dispatches the specialist
planning, review, implementation, and work-review agents needed to ship it.

Small problem-driven fixes can start with `/quick-fix`: it skips plan
machinery unless plans are touched, keeps the change bounded, updates durable
docs if behaviour changes, and commits when green.

`/wrap-up-current-chat` is not the normal finish command. Use it only to
capture durable knowledge from the current chat that is not recoverable
from docs, code, or git history. Use `/clear-plans` for repo-wide cleanup
of plans that already shipped or were abandoned.

Plan implementation starts with `/implement-plans`, which reads the selected
plans, implements them through verification, migrates durable context into
architecture/decisions, marks shipped plans, and commits when green. Large or
multi-stream plan work delegates through the orchestration rules as needed.

Use `/review-plans-high-level` before orchestration or implementation when
named plans need a high-level critique — wrong goal, missing premise,
sequencing risk, scope cuts, or orchestration hazards — before work is handed
to implementers. This is the plan-review phase `/orchestrate` dispatches.

Use `/review-work` after implementation when you need an independent read on
whether named plans actually shipped, what remains, whether app state has been
verified, and whether any obvious follow-up fixes should be applied.

Use `/review-plans-health` when `docs/plans/` needs a hygiene pass for stale,
duplicate, blocked, oversized, or poorly migrated plans before cleanup.

Use `/review-plans-custom` for open-ended plan review prompts that change from
run to run, such as generating alternate configuration options or exploring a
specific tradeoff without creating a new dedicated skill.

Use `/review-agent-docs-skills` to dogfood the workflow commands themselves:
it checks skill registry drift, duplicate policy, adapter leakage, and
lifecycle gaps.

Use `/agent-docs-doctor` for a mechanical health check of the scaffold,
manifest slots, ownership JSON, skill registry, and stale references.

## Adopting / repairing agent-docs

Use `/rebuild-agent-docs` when a repo is adopting this kit for the first
time or repairing a drifted docs tree. It inventories the current docs,
compares them to this guide, seeds missing files from
`~/agent-docs/v1/template/`, migrates durable facts into the right owners,
and ends with `/ship-current-work` semantics.

`v1/new-project-prompt.md` is retired; `/rebuild-agent-docs` is the
reusable entry point.

## No auto-loaded facts

Auto-loaded files such as `CLAUDE.md`, `AGENTS.md`, or equivalents must not
own architecture, decisions, or app-specific facts. They may exist only as
router/adapters when a tool requires one: point to `docs/index.md`,
`docs/overview.md`, and relevant skill entry points, then stop.

`docs/` owns app facts. Skills and rules own workflow. Tool adapters own no
facts.

## Dials and intake

Every skill reads [`rules/skill-contracts.md`](rules/skill-contracts.md) at
startup and runs the same **Standard Intake Protocol**: read the manifest and
the two router files, then stop. If the invocation already carries a task, it
proceeds; if not, it asks exactly two questions — a dial picker and an
open-ended "what do you want to do?" — and waits, without guessing the task.
A few context-free skills (e.g. `/clear-plans`, `/fix-docs-drift-all`) operate
on disk state and skip the questions.

Two shared dials tune behavior, defaulting to `medium`:

- **`review-[none|low|medium|high|max]`** — how much a skill stops for human
  review and how hard its AI review works. Only `review-none` is hard-defined
  (skip human checkpoints; never skip automated gates).
- **`cost-[low|medium|high|max]`** — subagent fan-out and model spend.

Model policy follows from the same file: **planning and review use the strong
model; implementation, tweaks, and routine work use the mid tier**, which is
the default workhorse. Whole-tree maintenance and broad reviews default a
notch higher on `cost`, as the skill states.

## Adapting this to your app — a checklist

1. **Point the app at this kit.** Write `docs/_meta/manifest.md` with
   `agent_docs_version`, `repo_name`, and the slots the rules read:
   `code_root`, `change-to-doc`, `drift-gates`, `decisions-domains`.
2. **Write the router first.** A top-level `docs/index.md` that is *only*
   a `Need → Read` table. Resist putting facts in it.
3. **Write a one-screen overview.** Diagram + components + the
   hard-to-grep facts (exact versions, environment gotchas).
4. **Adopt the recoverability test.** Every sentence either survives it or
   becomes a `path → symbol` pointer. This one habit prevents most drift.
5. **Name owners as conflicts appear.** Don't pre-build a giant ownership
   map; add an entry to `_meta/ownership.json` the first time two docs
   reach for the same fact.
6. **Cap leaf size.** ~1–2k tokens per subsystem doc. Split when it grows.
7. **Make plans deletable.** Use the kit's plan template + lifecycle; a
   shipped plan migrates into architecture/decisions.
8. **Fill the change→doc table.** Even a short one in the manifest. It's
   what makes "done" include "docs updated."
9. **Keep `_meta/` visible.** Route manifest and ownership questions to
   `docs/_meta/manifest.md` and `docs/_meta/ownership.json`; do not create a
   separate prose ownership guide.
10. **No auto-loaded fact dump.** Orientation happens by reading the router
   on demand. If a tool requires `AGENTS.md`, `CLAUDE.md`, or equivalent,
   keep it router-only.

## The one-paragraph version

Treat docs as the complement of code, never its echo: the code is the
truth about *behavior*, so docs only hold what reading the code can't
cheaply give you — the map, the invariants, the gotchas, and the why.
Split those into small, single-owner, task-routed files behind a pure
router; describe only the present; push history into git and rationale
into a decisions tree; stage multi-step work in disposable plans that get
migrated on ship. Keep the generic machinery — rules and commands — in one
shared, versioned kit, and let each app bind to it with a small manifest
of its own facts. Start small, route by task, load only what you need.

## See also (resolved relative to this kit)

- [`rules/authoring-rules.md`](rules/authoring-rules.md) — the enforceable
  rules this guide motivates.
- [`plan-lifecycle.md`](plan-lifecycle.md) — plan status metadata and the
  ship-time migration workflow.
- [`plan-template.md`](plan-template.md) — the plan skeleton.
- [`../README.md`](../README.md) — how the kit is packaged and activated.
- [`../docs/index.md`](../docs/index.md) — this repo's dogfood docs router.
