---
status:        active
owner:         unassigned
last_updated:  2026-06-19
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - architecture/install-and-adapters.md
  - decisions/agent-docs.md
---

# Generated repo-local agent context

## Mission

Replace runtime skill composition with deterministic, repo-local generated
agent context files that are concise, disposable, and specific to the agent
run. The durable goal is that an agent gets exactly the standing context it
needs for its skill, adapter, role, and target repo without reasoning through
generic agent-docs branches or multi-role rule bundles.

Done means the v2 kit can assemble selected snippets and docs from
`~/agent-docs/v2/` and the target repo's `docs/agent-context/` into an ignored
`docs/.generated/<random-id>.md` file. Orchestrator skills load their generated
context directly; subagents receive a prompt from the orchestrator that
references the generated context file they must read. Generated files are not
committed, are not canonical docs, and can be deleted at any time.

## Current narrowed implementation target

The active slice proves only Codex `/plan` against `~/fluid-simulation`. It
creates a minimal `v2/` path with a deterministic renderer, narrow verifier,
source-authored context modules, `v2/skills/plan/context.yaml`, and a thin
`v2/skills/plan/SKILL.md`. It does not implement Claude adapters,
copy-skill/install integration, all skills, v2 templates, full ownership v2, or
mutating workflows.

The generated outputs for this proof live under the target repo's ignored
`docs/.generated/` directory and remain disposable. The broader generated
context plan remains open until more skills and adapters move onto the model.

## Scope

In scope:

- Create a breaking `v2/` implementation path while leaving `v1/` available
  until v2 is ready to promote.
- Generate concise Markdown under `docs/.generated/<random-id>.md` in the
  consuming repo.
- Add or update consuming-repo `.gitignore` entries so `docs/.generated/` is
  ignored.
- Record generated file metadata in an append-only YAML log such as
  `docs/.generated/generations.yaml`.
- Keep generated files and the append-only log disposable; deleting the folder,
  log, or individual generated Markdown files must not break future generation.
- Assemble context deterministically from selected source docs and snippets;
  do not use model-written summarization or prose rewriting in the generator.
- Store reusable skill defaults beside the skill, for example
  `v2/skills/plan/context.yaml`.
- Let the launcher build run-specific context from the active skill, adapter,
  role, target repo, user task, skill defaults, and the target repo's
  `docs/agent-context/` files.
- Start by proving `/plan` through v2 in `../fluid-simulation`.
- Change worker dispatch packets so subagent prompts reference generated
  context files instead of asking workers to discover generic agent-docs
  internals.
- Keep Codex and Claude as supported adapter targets for the breaking pass,
  while proving Codex first.
- Add functional verifier checks for generator behavior, ignored output,
  missing inputs, delete/regenerate behavior, and dispatch references.

Out of scope:

- Committing generated context Markdown.
- Treating generated context as canonical architecture, decisions, or
  recoverable run history.
- Maintaining visible generated docs under `docs/generated/agent-context/`.
- Building arbitrary runtime prompt generation from model-written prose.
- Adding a review gate for generated prose quality.
- Supporting arbitrary agent runtimes beyond Codex and Claude in this pass.
- Moving root `AGENTS.md` or `CLAUDE.md` away from router-only adapter policy.
- Preserving the old runtime-composition plan as the canonical v2 model.

## Approach

### 1. Land the metadata prerequisite

This plan depends on [`metadata-v2.md`](metadata-v2.md). That plan should make
`docs/_meta/manifest.yaml` the structured repo metadata source, delete
`docs/_meta/manifest.md`, enrich ownership data with update triggers, and
reserve the ignored generated-context root.

The generated-context work can start in `v2/` with a narrow generator and the
`../fluid-simulation` test repo, but the stable v2 launcher contract should not
settle until metadata v2 can tell tools where the repo metadata, agent-context
docs, and ignored generated root live.

### 2. Define the disposable generated context contract

Generated context is a per-run artifact, not a committed product.

- **Source inputs**: `docs/_meta/manifest.yaml`, ownership data when needed,
  handwritten docs, `~/agent-docs/v2/` rules and context modules, skill-local
  defaults, adapter target, role, user task metadata, and selected target-repo
  `docs/agent-context/` docs.
- **Generated output**: one concise Markdown file under
  `docs/.generated/<random-id>.md`.
- **Run record**: append-only YAML documents under
  `docs/.generated/generations.yaml`, recording the random id, generated path,
  skill, adapter, role, target repo, source files, source digests when cheap,
  generator version, and any run-specific context options.
- **Durability**: generated Markdown and the run record are disposable. Missing
  generated files or missing logs cause regeneration, not failure.

The random id should be URL-safe and collision-checked. A collision should retry
with a new id rather than overwrite.

Example generated tree:

```text
docs/.generated/
  a7p2czQw8271.md
  generations.yaml
```

Example append-only record:

```yaml
---
id: a7p2czQw8271
file: docs/.generated/a7p2czQw8271.md
skill: plan
adapter: codex
role: orchestrator
target_repo: /home/adamg/fluid-simulation
sources:
  - ~/agent-docs/v2/skills/plan/context.yaml
  - ~/agent-docs/v2/context/orchestrator.md
  - docs/agent-context/index.md
  - docs/agent-context/orchestrating.md
```

The log is for debugging and traceability only. Launchers must not require old
log entries to exist.

### 3. Define context selection and assembly

The generator performs deterministic assembly only. It may concatenate whole
files, include named sections, and include inline skill-default text from YAML,
but it must not ask a model to summarize or rewrite source docs.

Support these include shapes in the first implementation:

- kit file include from `~/agent-docs/v2/...`;
- target-repo file include from `docs/agent-context/...`;
- named Markdown heading include from a selected file;
- inline text from the skill-local `context.yaml`;
- optional run-specific includes supplied by the launcher.

The generated Markdown should be as concise as possible:

- include only context selected for the current skill, adapter, role, and run;
- avoid copying broad architecture or implementation mechanics unless the role
  needs them;
- keep source labels compact so agents can trace where instructions came from;
- do not include the full user prompt by default.

### 4. Store skill defaults beside skills

Each v2 skill can carry context defaults next to the skill:

```text
v2/skills/plan/
  SKILL.md
  context.yaml
```

The `context.yaml` file should define the default context recipe for that skill
and role. It is not a global repo config; the launcher combines it with
run-specific data for the current agent invocation.

Example shape:

```yaml
schema_version: 1
skill: plan
targets:
  orchestrator:
    includes:
      - source: kit
        path: v2/context/orchestrator.md
      - source: kit
        path: v2/context/planning.md
      - source: repo
        path: docs/agent-context/index.md
      - source: repo
        path: docs/agent-context/orchestrating.md
  planning-worker:
    includes:
      - source: kit
        path: v2/context/planning-worker.md
      - source: repo
        path: docs/agent-context/index.md
```

The exact schema can change during implementation, but the first version should
be explicit enough that a reviewer can predict which source files will be
assembled for a target.

### 5. Define orchestrator and subagent use

Orchestrators and subagents use generated context differently:

- **Orchestrator skills** generate or refresh a context file for their own
  invocation and load that file as unique standing context for the skill.
- **Subagents** do not discover generated context on their own. The
  orchestrator includes the generated context path in the subagent user prompt,
  and the subagent reads that file before doing the assigned role.

Subagent dispatch should therefore move toward this shape:

```text
Role:
Task:
Read this generated context first:
- docs/.generated/a7p2czQw8271.md
Input docs/plans/context:
Expected output:
Expected checks/evidence:
Report back with:
```

The orchestrator still names authoritative task inputs, expected evidence, and
the report shape. Workers should not need to know where the upstream
agent-docs checkout lives unless the generated context explicitly tells them.

### 6. Add the v2 generator

Create `v2/context/` for deterministic context assembly:

```text
v2/context/
  schema/
  modules/
  render
  verify
```

The generator should support:

- resolving the target repo root;
- reading skill-local `context.yaml`;
- resolving kit and repo include paths;
- extracting Markdown sections by heading;
- producing a random id and writing `docs/.generated/<id>.md`;
- appending a YAML record to `docs/.generated/generations.yaml`;
- creating `docs/.generated/` when missing;
- treating missing/deleted generated outputs as normal regeneration cases;
- checking that `docs/.generated/` is ignored by git;
- returning the generated path to the launcher.

The generation language should stay declarative. Conditional selection can live
in source specs and launcher code, but the generated Markdown is resolved text.

### 7. Migrate global skills into v2 launchers

Global copied skills should become thin adapter launchers in v2:

- discover the target repo root;
- build run-specific context options;
- call the generator for the skill, adapter, and role;
- load the generated context for the orchestrator skill;
- pass generated context paths in subagent prompts;
- report clear regeneration or setup instructions when context cannot be
  generated;
- avoid carrying workflow policy beyond fallback and error handling.

This preserves tool discovery while moving operational context into the
generated per-run file.

### 8. Dogfood in `../fluid-simulation`

Use `../fluid-simulation` as the first consuming repo.

Ship in this order:

1. Create the v2 context generator and `v2/skills/plan/context.yaml` in
   `agent-docs`.
2. Add or update `../fluid-simulation/.gitignore` so `docs/.generated/` is
   ignored.
3. Generate a Codex `/plan` orchestrator context file in
   `../fluid-simulation/docs/.generated/<random-id>.md`.
4. Make the v2 `/plan` launcher load the generated file for orchestrator
   context.
5. Make a planning-worker dispatch prompt reference a generated context file.
6. Delete `../fluid-simulation/docs/.generated/` and prove the next run
   regenerates successfully.
7. Expand to a small mutating workflow only after `/plan` works.

This proves the open-ended planning workflow before changing every command.

### 9. Functional verification

Do not add a prose-quality review gate. Add functional checks that prove the
generator and launchers work:

- `context-render-smoke`: render a Codex `/plan` orchestrator context file for
  `../fluid-simulation`;
- `context-random-id`: generated filenames use collision-checked random ids;
- `context-log-append`: each generation appends a valid YAML document without
  rewriting earlier records;
- `context-delete-regenerate`: deleting `docs/.generated/` does not break the
  next generation;
- `context-ignore-check`: the consuming repo ignores `docs/.generated/`;
- `context-source-check`: selected source paths exist and missing sources fail
  with clear messages;
- `context-section-check`: named Markdown section includes resolve or fail
  clearly;
- `context-dispatch-reference`: migrated subagent prompts reference generated
  context files instead of generic rule discovery;
- root auto-loaded files remain router-only;
- copied Codex and Claude launchers are fresh after skill changes.

## Exit gate

- [`metadata-v2.md`](metadata-v2.md) has shipped enough for v2 tools to read
  `docs/_meta/manifest.yaml`, ownership v2 data, and the reserved generated
  context root.
- `v2/context/` exists with a deterministic assembler, schema or config
  validation, and functional verification.
- `v2/skills/plan/context.yaml` exists and drives the first `/plan` generation.
- `../fluid-simulation` ignores `docs/.generated/`.
- A Codex `/plan` orchestrator run can generate and load
  `../fluid-simulation/docs/.generated/<random-id>.md`.
- A planning-worker dispatch prompt can reference a generated context file for
  the worker to read.
- Generated Markdown is concise, deterministic assembly from selected source
  docs/snippets, and not committed.
- Deleting `docs/.generated/`, `generations.yaml`, or individual generated
  Markdown files does not prevent the next run from generating fresh context.
- Functional generator checks pass for the migrated `/plan` path.
- `docs/architecture/workflow-kit.md` describes generated run-local context,
  ignored output paths, skill-local defaults, and dispatch changes.
- `docs/architecture/install-and-adapters.md` describes v2 launchers and
  generated context discovery.
- `docs/decisions/agent-docs.md` records why v2 moved from runtime composition
  to deterministic per-run context assembly.
- `docs/_meta/ownership.json` or its v2 successor owns the generator,
  skill-default context files, and generated-context conventions.
- `bash v2/verify-agent-docs.sh` or the v2 equivalent passes.
- If skill launchers change, copied adapter refresh/check commands pass for v2.

## Discipline rules

- Do not commit generated Markdown or generated run logs.
- Do not make generated files canonical workflow truth.
- Do not require generated files or logs to survive deletion.
- Do not use model summarization or rewriting inside the generator.
- Do not include the full user prompt in generated Markdown by default.
- Do not ask subagents to discover agent-docs internals.
- Do not let global launchers regain broad workflow policy after the generated
  context path exists.
- Do not generate every Cartesian-product target; generate only what the
  current run needs.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts into:

- `architecture/workflow-kit.md` - v2 generated context model, ignored output
  paths, skill-local defaults, generator behavior, verifier responsibilities,
  and dispatch changes.
- `architecture/install-and-adapters.md` - v2 copied skill launchers and
  generated context discovery.
- `decisions/agent-docs.md` - rationale for breaking from runtime composition
  to deterministic per-run context assembly.
- `_meta/ownership.json` or its v2 successor - generated context generator,
  skill-default context, and ignored output conventions.
- `repository-layout.md` - `v2/context/`, `v2/skills/*/context.yaml`, and the
  consuming-repo `docs/.generated/` convention.

## See also

- [`metadata-v2.md`](metadata-v2.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../../v1/plan-template.md`](../../v1/plan-template.md)
