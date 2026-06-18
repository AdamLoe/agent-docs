---
status:        draft
owner:         unassigned
last_updated:  2026-06-18
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - architecture/install-and-adapters.md
  - decisions/agent-docs.md
---

# Dogfood docs shape cleanup

## Mission

Make this repo's `docs/` tree read like useful documentation for the
agent-docs checkout, not like a lightly customized copy of the generic
agent-docs scaffold. A fresh agent should be able to understand what this repo
ships, why `docs/` and `v1/` sit beside each other, where to make common
changes, and which commands prove the tree is healthy.

Done means the top-level docs clearly separate repo-specific facts from
generic kit policy, duplicate generic workflow prose has been removed or moved
to the owning `v1/` rule files, and the remaining docs provide a practical map
for changing this repository.

## Scope

In scope:

- Audit `docs/` for generic agent-docs boilerplate that belongs in `v1/rules/`,
  `v1/agent-docs-guide.md`, or nowhere.
- Strengthen `docs/overview.md` with a concise "what this repo ships" and
  "why `docs/` and `v1/` both exist" explanation.
- Keep `docs/repository-layout.md` as a short inventory, but make sure it
  answers newcomer path questions for this checkout.
- Tighten `docs/architecture/workflow-kit.md` and
  `docs/architecture/install-and-adapters.md` around current repo-specific
  surfaces, scripts, invariants, and adapter behavior.
- Keep `docs/decisions/agent-docs.md` focused on current rationale that still
  affects this repo, not historical migration narrative.
- Keep `docs/agent-context/repo-rules.md` as the small local operating recipe:
  gates, skill-copy refresh, commit expectations, and any repo-specific
  caveats.

Out of scope:

- Redesigning the generic agent-docs scaffold for consuming repos.
- Rewriting the subagent-first workflow model or runtime composition plans.
- Adding broad app-style docs that pretend this repository is a normal product
  app. The product here is the versioned workflow kit.
- Maintaining a live inventory of plans or skills in `docs/`; use the registry,
  filesystem, and verifier-owned checks for inventories.

## Approach

### 1. Audit For Repo-Specific Value

Review each file under `docs/` with one question:

```text
Does this sentence help an agent safely change this checkout?
```

Classify findings:

- **Keep** when the content maps this repo's paths, scripts, invariants,
  adapter behavior, or current rationale.
- **Move** when the content is generic workflow policy that belongs under
  `v1/rules/` or `v1/agent-docs-guide.md`.
- **Delete** when the content is scaffold filler, stale migration framing, or
  a list that can drift without a verifier.
- **Replace with pointer** when the authoritative truth is already a script,
  registry, manifest slot, or rule file.
- **Add missing repo fact** when a fresh agent would otherwise have to inspect
  multiple files to learn a common change path.

### 2. Make The Top-Level Shape Obvious

Rewrite `docs/overview.md` so it explains the unusual shape directly:

- `docs/` is the dogfood agent-docs tree for this checkout.
- `v1/` is the stable reusable kit shipped to consuming repos.
- Future adjacent version folders such as `v2/` are versioned kit experiments
  or successors, not replacements for `docs/`.
- The repo's implementation root is whatever `docs/_meta/manifest.md` names;
  for this repo, that is currently `v1/`.

Add a short "What this repo ships" section that names the important shipped
surfaces: skills, rules, templates, installer/copy scripts, verifier, and
adapter files.

### 3. Add A Practical Change Map

Add or strengthen a compact "How to change this repo" section in the overview
or workflow architecture doc. It should answer common routing questions:

- skill behavior changes usually start in `v1/skills/<name>/`
- generic workflow policy changes usually start in `v1/rules/`
- install and adapter changes start in `v1/install.sh`, `v1/copy-skills.sh`,
  and `docs/architecture/install-and-adapters.md`
- scaffold changes start in `v1/template/docs/`
- skill edits require copied adapter refresh
- finished changes require `bash v1/verify-agent-docs.sh`

Keep this as a map, not a second implementation guide.

### 4. Trim Architecture And Decisions

Review architecture and decision docs for generic policy duplication:

- `docs/architecture/workflow-kit.md` should describe how this repo's kit
  surfaces fit together and point to rule files for detailed generic workflow
  rules.
- `docs/architecture/install-and-adapters.md` should own concrete paths,
  scripts, adapter markers, and install/copy invariants.
- `docs/decisions/agent-docs.md` should keep only current decisions and
  tradeoffs. Historical "we used to" framing should be removed unless it still
  explains a live constraint.

Where a paragraph could be true in any repo using agent-docs, move it out of
this repo-specific docs tree or replace it with a pointer.

### 5. Verify And Migrate

Run the repo drift gate after edits:

```sh
bash v1/verify-agent-docs.sh
```

If the cleanup changes `v1/skills/`, also refresh copied adapters:

```sh
bash v1/copy-skills.sh ~/agent-docs
bash v1/copy-skills.sh --check ~/agent-docs
```

Before marking this plan shipped, migrate any durable conclusions into the
edited architecture and decision docs, then mark the plan disposable only if a
fresh agent no longer needs it.

## Exit Gate

- `docs/overview.md` clearly explains `docs/` vs `v1/` and what this repo
  ships.
- `docs/repository-layout.md` remains a concise inventory with no generic
  policy dump.
- `docs/architecture/workflow-kit.md` describes repo-specific kit surfaces and
  points to `v1/rules/` for generic workflow details.
- `docs/architecture/install-and-adapters.md` clearly owns concrete install,
  copy, and adapter behavior.
- `docs/decisions/agent-docs.md` contains current rationale only.
- Generic policy duplicated in `docs/` is moved, deleted, or replaced with
  pointers to its canonical owner.
- `bash v1/verify-agent-docs.sh` passes.

## Discipline Rules

- Do not make `docs/` a tutorial for all agent-docs consumers.
- Do not add a top-level `app/` directory just to satisfy a generic app shape;
  this repo's implementation root is versioned kit code.
- Do not maintain hand-written inventories that drift unless a verifier checks
  them.
- Do not preserve historical explanation when current state plus git history is
  enough.
- Keep docs short enough that a fresh agent can actually read the routed file.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts into:

- `architecture/workflow-kit.md` — current kit surfaces, versioned kit layout,
  and repo-specific workflow map.
- `architecture/install-and-adapters.md` — concrete install/copy/adapter
  behavior.
- `decisions/agent-docs.md` — rationale for keeping `docs/` as the dogfood
  docs tree and `v1/` as the current implementation root.
- `_meta/ownership.json` — only if the cleanup creates a new owned concept.

## See also

- [`../overview.md`](../overview.md)
- [`../repository-layout.md`](../repository-layout.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
