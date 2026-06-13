# Skill contracts (agent-docs v1)

GENERIC. App-independent. These are the shared workflow contracts for
`v1/skills/*/SKILL.md`, so individual skills do not each carry their own copy
of suite-wide policy.

## Registry

`v1/skills/registry.md` is the skill inventory. Each discoverable skill has a
directory under `v1/skills/<name>/`, a `SKILL.md` whose frontmatter `name:`
matches `<name>`, and one registry row that states its mode, action, commit
behavior, and normal input.

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

## Shared Bootstrap

When a skill needs app context, prefer the smallest useful read:

1. `docs/_meta/manifest.md` for `repo_name`, `code_root`, and the slots the
   skill names.
2. `docs/index.md` and `docs/overview.md` for orientation.
3. The smallest routed architecture, decisions, agent-context, plan, ownership,
   git, or source context needed for the task.

Front-load only steps 1–2. Defer rule files, lifecycle and template docs, and
the named plan, work, or source files until the task and its inputs are
confirmed. A skill that bootstraps then waits for the user must not read those
heavier files before the user has described what they want — read manifest,
`index.md`, and `overview.md`, ask the batched question, then load the rest
against the actual task.

Ownership questions use `docs/_meta/ownership.json`. There is no separate
prose ownership guide contract in agent-docs v1.

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

## Shared Model Language

Use role-based model names in generic skills: `cheap`, `mid-tier`, `strong`,
or `strongest`. Adapter-specific model names belong only in adapter-local
notes or concrete user instructions.

## Missing Inputs

If a required path, plan, doc, or custom lens is missing, bootstrap only enough
to ask a batched question, then wait. If `$ARGUMENTS` already contains
substantive context, treat it as the user's first answer.
