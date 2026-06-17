---
name: rebuild-agent-docs
description: Rebuild or repair an app's docs/ tree into the agent-docs v1 scaffold. Seed missing files from ~/agent-docs/v1/template/, adapt them to the repo, and retire the old one-off new-project prompt.
---

# Rebuild Agent Docs

Use this skill when a repo needs a fresh agent-docs v1 docs tree, a partial
repair of one, or a rebuild that should start from the shared template instead
of improvising a new shape.

This skill runs directly on the docs tree — no intake questions. Read
`~/agent-docs/v1/rules/skill-contracts.md` for the shared dials and model
policy.

## Inputs

- `$ARGUMENTS` may contain, in any order:
  - current docs path, default `docs/`; use this as the source when reading
    and patching, but the v1 destination is `docs/`
  - example docs path, only if explicitly named
  - dials: `cost-[low|medium|high|max]` / `review-[none|low|medium|high|max]`
  - rebuild-vs-patch preference
- Kit path: `~/agent-docs/v1/`
- Template path: `~/agent-docs/v1/template/`

## Workflow

1. Resolve the dials from `$ARGUMENTS`; default to `cost-medium`.
2. Read `<current docs path>/_meta/manifest.md` if it exists, then inventory the
   current docs shape. If the source path is not `docs/`, migrate the v1
   scaffold toward `docs/` rather than preserving a custom docs root.
3. Read `~/agent-docs/v1/agent-docs-guide.md` and compare the repo against the
   v1 scaffold and routing model.
4. Seed any missing docs from `~/agent-docs/v1/template/` before adapting
   them. The scaffold files are copied relative to the current docs path:
   - `<current docs path>/index.md`
   - `<current docs path>/overview.md`
   - `<current docs path>/repository-layout.md`
   - `<current docs path>/architecture/index.md`
   - `<current docs path>/decisions/index.md`
   - `<current docs path>/agent-context/index.md`
   - `<current docs path>/plans/index.md`
   - `<current docs path>/_meta/manifest.md`
   - `<current docs path>/_meta/ownership.json`
5. If an example docs path was named, use it only as a shape reference. Do not
   copy app-specific facts or hardcode that path into the result.
6. Rebuild or patch the docs using the recoverability test: keep map, why, and
   routing facts; collapse recoverable code transcription into pointers.
   If a stale prose ownership guide exists, migrate any durable routing facts
   into `<current docs path>/_meta/ownership.json` and remove the prose file
   when it no longer owns unique information.
7. Choose the amount of fan-out from the resolved `cost` dial:
   - `cost-low`: do the work directly, minimal fan-out.
   - `cost-medium`: normal multi-stream repair.
   - `cost-high`: broad parallel repair with stronger review where needed.
   - `cost-max`: widest practical sweep with the strongest review.
8. Finish with `/ship-current-work` semantics: migrate durable facts into the
   right docs, leave the tree in a reportable state, and clearly say if no docs
   changed.

## Operating rules

- Prefer the shared template and guide over inventing a new scaffold.
- Keep the output app-agnostic; do not introduce one-off project paths.
- Treat `docs/_meta/manifest.md` as the binding for repo-specific facts.
- Treat `docs/_meta/ownership.json` as the tie-breaker when two docs could own
  the same fact.
- Keep manifest and ownership data visible from `docs/index.md` and
  `docs/overview.md`; they are the first stop for app bindings, drift gates,
  and ownership questions.
