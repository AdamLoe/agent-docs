# Skill contracts (agent-docs v1)

GENERIC. App-independent. These are the shared workflow contracts for
`v1/skills/*/SKILL.md`, so individual skills do not each carry their own copy
of suite-wide policy. **Every skill reads this file at startup** and follows
the protocol below; a skill's own body holds only its identity, its
skill-specific routing, and any deltas from these defaults.

The fast path (Standard Intake Protocol → Dials → Model Policy) is first
because it runs on every invocation. Reference material (Modes, Shipping,
Registry) is below it.

## Standard Intake Protocol

This is the shared bootstrap every skill runs. It replaces the per-skill
"read manifest, read index/overview, then ask" boilerplate.

1. **Read this file** (you are doing that now).
2. **Read `docs/_meta/manifest.md`** — at minimum `repo_name` and `code_root`;
   plus whichever slots your task needs (`change-to-doc`, `drift-gates`,
   `drift-verification`, `decisions-domains`).
3. **Read `docs/index.md` and `docs/overview.md`** for orientation.
4. **Stop.** Do not read rule files, architecture/decisions/agent-context
   docs, plans, templates, or source yet. Those load *after* the task and its
   inputs are known — read them against the actual work, never proactively.

Then branch on what the invocation gave you:

- **Context present** — `$ARGUMENTS` already contains a substantive task,
  target paths, or a custom lens. Treat it as the user's first answer and
  proceed. Parse any dials named in it; otherwise use the defaults below.
- **Context absent** — `$ARGUMENTS` is empty or only starts the skill. Ask
  the user **exactly two questions, batched, then wait**:
  1. A multiple-choice for the two dials (see Dials), with `review-medium`
     and `cost-medium` preselected.
  2. An open-ended "what do you want to do?" — **never guess the task and
     never offer a menu of tasks.** The user describes the work; you don't.

  Do not read any heavier file until they answer.

**Exception — context-free skills.** A few skills operate on existing disk
and git state rather than a user-described task: `clear-plans`,
`fix-docs-drift`, `list-skills`, `doctor`,
`review-plans-health`, `review-docs-shape`, `ship-current-work`,
`wrap-up-current-chat`, `review-skills`, `rebuild-agent-docs`,
`lodge-agent-docs-feedback`. These **skip both intake questions and run
directly.** They honor dials passed in `$ARGUMENTS` where the dials affect
their work; for pure utilities where no dial applies (`list-skills`,
`lodge-agent-docs-feedback`), the dials are simply inert.
(`lodge-agent-docs-feedback` still asks for the feedback content if none was
given — but not the dial/task intake.) They still honor dials passed in
`$ARGUMENTS`, but they never prompt for them.

Ownership questions use `docs/_meta/ownership.json` (query it; don't
bulk-load it). There is no separate prose ownership guide in agent-docs v1.

## Human Stops

Stop for the user only when an answer changes what should be built, reviewed,
or shipped and the decision cannot be resolved from code, docs, precedent, or
the user's request. Every stop must include the specific decision needed, why
it changes the work, the fewest concrete questions needed to continue, and a
recommended default when one is defensible.

Do not stop with a vague blocker such as "needs input" or "needs product
decision." If you cannot form the concrete questions yet, keep investigating
or run the appropriate planning/review pass until the question is clear.

## Verification Fallbacks

Run the relevant gates whenever practical. If a gate cannot run, report the
exact command attempted, why it failed or was unavailable, what cheaper check
you ran instead, and the residual risk. Do not treat a skipped gate as green.

## Dials

Two axes tune every skill. The user sets them by naming them in their
message; otherwise both default to `medium`.

- **`review-[none|low|medium|high|max]`** — how much the skill stops for human
  review and how hard its AI review pass works.
- **`cost-[low|medium|high|max]`** — how freely to spend on subagent fan-out
  and stronger models.

Only **`review-none`** has a hard meaning: **skip human-review checkpoints.**
It never skips automated verification, drift gates, or the original
questioning needed to make work well-defined. Everything else on both axes is
**vibes, not a rulebook** — higher means "ask a bit more, fan out more,
reach for stronger models when it pays"; lower means "decide it yourself,
stay cheap, do it inline." Do not invent a rigid per-tier spec; read the dial
as intensity and apply judgment.

A skill may declare its own default when `medium` is wrong for it (e.g.
whole-tree sweeps and broad reviews default to `cost-high`). The skill body
states any such override.

Old tag names map in: `skip-review` → `review-none`, `heavy-review` →
`review-high`/`max`, `cheap-agents` → `cost-low`, `no-cost-limit` →
`cost-max`.

## Model Policy

The kit underuses the mid tier; correct toward it. Role-based names —
`cheap`, `mid-tier`, `strong`, `strongest` — keep this adapter-agnostic.

- **Planning and review → strong.** Plan authoring, plan/work review,
  architecture and correctness judgment, red-team passes.
- **Implementation and everything routine → mid-tier.** Code changes,
  tweaks, bounded investigation, verification runs, mechanical doc edits.
  This is the default workhorse; reach above it only when the work is
  genuinely correctness-critical.
- `cost-low` pushes more work down to mid-tier/cheap; `cost-max` permits
  strong subagents freely. `review-high`/`max` adds a strong red-team /
  second-opinion pass that lower review levels skip.

A skill's recommended **launch tier** is recorded in
`v1/skills/registry.md`; planning/review skills want a strong launch model,
implementation and mechanical skills run fine on mid-tier. Delegated
subagents follow the role mapping above regardless of launch tier.

## Modes

- **bootstrap** skills load only enough docs router context to route the next
  user task.
- **planning** skills shape direction, concerns, and plan artifacts. They do
  not implement code.
- **lifecycle orchestration** skills coordinate specialist planning, review,
  implementation, and verification agents while keeping their own context
  small. They do not replace the specialist skills they dispatch.
- **report-only** skills may inspect, verify, and recommend, but they do not
  edit or commit unless their own prompt explicitly has an editing mode and
  the user asks to apply it.
- **capture** skills record a structured entry into a known out-of-repo
  destination (e.g. the kit's upstream feedback inbox). They do not edit the
  current repo and do not commit.
- **mutating** skills edit repo state and finish with verification, doc
  migration when needed, and a local commit when green.
- **review with optional fixes** skills lead with a review. They may make
  obvious non-debatable fixes when that is part of the skill contract, and
  then verify and commit those fixes when green.

## Shared Shipping

Mutating skills finish through the same shape unless they state a narrower
contract:

1. Inspect the diff and confirm the requested outcome is actually present.
2. Update owning architecture/decisions docs for durable facts and rationale.
3. Run targeted verification plus any relevant manifest `drift-gates`.
4. Stage by filename and commit when the tree is green.
5. Do not push unless explicitly told.

The default stance is pro-commit: finished green work should not be handed back
as an uncommitted dirty tree. Report-only skills are the exception because they
do not modify files.

## Registry

`v1/skills/registry.md` is the skill inventory. Each discoverable skill has a
directory under `v1/skills/<name>/`, a `SKILL.md` whose frontmatter `name:`
matches `<name>`, and one registry row that states its mode, action, commit
behavior, intake style, launch tier, and normal input.
