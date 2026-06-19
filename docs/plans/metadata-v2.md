---
status:        active
owner:         unassigned
last_updated:  2026-06-19
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Metadata v2

## Mission

Replace the Markdown manifest and flat ownership map with structured metadata
that can drive the breaking v2 kit, ignored repo-local agent workspaces,
stricter verification, and lower-context agent workflows.

Done means `docs/_meta/manifest.yaml` is the canonical repo config,
`docs/_meta/manifest.md` is deleted, ownership data names concepts with owners,
aliases, referencers, update triggers, and ignored generated-artifact
conventions, and the verifier validates the structure instead of grep-parsing
Markdown tables.

## Current narrowed implementation target

The current implementation target is only the first v2 generated-context proof:
Codex `/plan` against `~/fluid-simulation`. For that proof, v2 tools require
the target repo's `docs/_meta/manifest.yaml`, use it for the ignored agent
workspace root, and do not read the Markdown manifest. This slice does not delete
either repo's Markdown manifest, migrate ownership to v2, add v2 templates, or
change every skill and rule.

The broader metadata-v2 work remains open until structured metadata and
ownership v2 are promoted across the kit.

## Scope

In scope:

- Introduce `docs/_meta/manifest.yaml` as the canonical repo config.
- Retire `docs/_meta/manifest.md` as a live input for this breaking direction.
- Define a constrained YAML profile and checked-in parser or validation helper
  so gates do not rely on ad hoc grep.
- Convert manifest slots into structured fields: repo identity, code root,
  change-to-doc triggers, drift gates, manual verification, decision domains,
  and ignored agent workspace roots.
- Upgrade ownership data from flat `owners[]` into concept records with aliases,
  canonical owners, allowed referencers, update triggers, and generated output
  conventions.
- Create or update v2 templates, rebuild/adoption flow, skills, rules, docs, and
  verifier references to use `manifest.yaml` and ownership v2.
- Add gates that keep metadata valid and generated-context conventions
  functional.

Out of scope:

- Building the generated context system itself; that is owned by
  [`generated-repo-local-agent-context.md`](generated-repo-local-agent-context.md).
- Checking generated Markdown freshness as committed state. Generated workspace
  files live under ignored `.agent-docs/agents/` and are disposable.
- Supporting arbitrary YAML features. The manifest should use a small,
  deterministic subset.
- Fully linting every prose duplicate between docs. Structural ownership and
  metadata checks come first.
- Preserving long-term dual reads from `manifest.md` and `manifest.yaml`.
  Because this is a breaking direction, compatibility should be short and
  explicit when needed for migration only.

## Approach

### 1. Define the manifest schema

Add `docs/_meta/manifest.yaml` with stable top-level sections:

```yaml
schema_version: 2

repo:
  name: agent-docs
  agent_docs_version: v2
  code_root: v2/

metadata:
  ownership: docs/_meta/ownership.json
  agent_workspace:
    root: .agent-docs/agents
    committed: false

change_to_doc:
  - id: generated-agent-context
    changed:
      paths:
        - v2/context/**
        - v2/skills/**/context.yaml
    owning_docs:
      - docs/architecture/workflow-kit.md
      - docs/decisions/agent-docs.md
    required_gates:
      - agent-docs-v2-verify

gates:
  drift:
    - id: agent-docs-v2-verify
      command: bash v2/verify-agent-docs.sh
      cwd: repo
      mutates: false

drift_verification:
  manual:
    - id: copied-skill-adapters
      command: bash v2/copy-skills.sh --check ~/agent-docs
      reason: verifies copied Codex and Claude v2 launchers

decisions:
  domains:
    - id: agent-docs
      doc: docs/decisions/agent-docs.md
      owns:
        - workflow model
        - metadata model
        - generated context rationale
```

Use path or glob based triggers instead of prose-only "changed surface" labels.
Keep gates addressable by stable ids so generated docs and decisions can cite
them without duplicating commands. Do not add `.agent-docs/**` as a
change-to-doc trigger; that tree is ignored disposable output.

### 2. Choose a parser and validation profile

Do not parse YAML with grep. Add a small checked-in helper under a v2 path such
as `v2/lib/metadata/`, that validates the constrained manifest shape and emits
normalized JSON for shell gates and generators.

The YAML profile should allow only what the kit needs:

- mappings, lists, strings, booleans, and simple scalars;
- no anchors, custom tags, executable includes, environment interpolation, or
  implicit command expansion;
- deterministic key ordering in generated normalized output.

The verifier should fail clearly when the parser cannot run.

### 3. Upgrade ownership data

Keep ownership as dependency-light JSON unless implementation finds a stronger
reason to move it to YAML too. Replace `owners[]` with concept records:

```json
{
  "schema_version": 2,
  "concepts": [
    {
      "id": "generated-agent-context",
      "canonical_name": "generated agent context",
      "aliases": ["repo-local context", "agent workspace", ".agent-docs/agents"],
      "owner": {
        "paths": [
          "docs/architecture/workflow-kit.md",
          "v2/context/",
          "v2/skills/*/context.yaml"
        ],
        "kind": "architecture-and-generator"
      },
      "allowed_referencers": [
        {
          "path": "docs/architecture/install-and-adapters.md",
          "mode": "summary-link"
        }
      ],
      "update_triggers": {
        "paths": [
          "v2/context/**",
          "v2/skills/**/context.yaml"
        ],
        "manifest_change_to_doc_id": "generated-agent-context"
      },
      "ignored_artifacts": [
        {
          "path": ".agent-docs/agents/",
          "kind": "generated-context",
          "committed": false
        }
      ]
    }
  ]
}
```

Each concept should have a stable id, aliases for routing/search, one canonical
owner, allowed referencers, and update triggers. Ownership v2 owns the generated
artifact convention and ignored root; it does not try to own each random
generated Markdown file. Full target semantics and generator behavior are owned
by
[`generated-repo-local-agent-context.md`](generated-repo-local-agent-context.md).

### 4. Migrate existing metadata

Migrate the current `docs/_meta/manifest.md` fields into `manifest.yaml`, then
delete `manifest.md`:

- `repo_name`, `agent_docs_version`, and `code_root` become `repo.*`.
- `change-to-doc` table rows become structured `change_to_doc` entries with
  path/glob triggers, owner docs, and gate ids.
- `drift-gates` and `drift-verification` become structured gate lists.
- `decisions-domains` becomes `decisions.domains`.

Migrate the current `docs/_meta/ownership.json` records into ownership v2
concepts. Add aliases and update triggers only where they are clear; leave
unknowns explicit rather than inventing broad triggers that create false
confidence.

### 5. Update consuming rules and skills

Change v2 skills and rules so they read `docs/_meta/manifest.yaml` through the
metadata helper. Create or update:

- `v2/rules/skill-contracts.md`
- `v2/rules/authoring-rules.md`
- `v2/rules/subagent/*`
- `v2/rules/orchestrator/*`
- `v2/skills/*/SKILL.md`
- `v2/skills/*/context.yaml` where skill-local generated-context defaults exist
- `v2/agent-docs-guide.md`
- `v2/template/docs/_meta/`
- `v2/verify-agent-docs.sh`

Because this is breaking, prefer one coherent v2 path over indefinite dual
reads. `v1/` can remain available while v2 is being proven, but v2 workflows
should not read `manifest.md`.

### 6. Strengthen verification

Extend the gate to validate:

- `manifest.yaml` exists and conforms to schema version 2;
- `manifest.md` has been deleted after migration;
- no live v2 workflow reads `manifest.md`;
- every manifest path, owner doc, and decision doc exists;
- every gate has an id, command, cwd, and mutability flag;
- changed paths or globs are covered by change-to-doc or ownership triggers;
- ownership concepts have ids, aliases, owner paths, referencer modes, and
  update triggers;
- aliases are unique unless an explicit conflict record resolves them;
- agent workspace root fields are structurally valid, mark generated Markdown
  as uncommitted, and correspond to a gitignored path;
- template placeholders such as `<!-- fill -->` do not survive in committed v2
  templates.

Start with structural checks. Do not add a generated-prose review gate in this
plan.

### 7. Implementation streams and collision points

| Stream | Likely owned files | Sequencing |
|---|---|---|
| Manifest schema and examples | `docs/_meta/manifest.yaml`, `v2/template/docs/_meta/manifest.yaml` | First. Do not change v2 skill reads until the helper exists. |
| Metadata helper | `v2/lib/metadata/` | First implementation slice; verifier depends on it. |
| Ownership v2 migration | `docs/_meta/ownership.json`, template ownership data | After schema fields are known; serial with verifier checks. |
| Skill and rule reads | `v2/rules/`, `v2/skills/`, `v2/agent-docs-guide.md` | After helper emits normalized metadata. |
| Verifier migration | `v2/verify-agent-docs.sh`, metadata helper checks | After manifest and ownership samples exist. |
| Durable docs migration | `docs/architecture/`, `docs/decisions/`, `docs/repository-layout.md` | Last, when behavior and paths are stable. |

## Exit gate

- `docs/_meta/manifest.yaml` exists and is the canonical metadata source.
- The v2 template scaffold uses `v2/template/docs/_meta/manifest.yaml`.
- `docs/_meta/manifest.md` is removed after migration.
- Ownership data uses schema version 2 concept records.
- A checked-in metadata helper validates and normalizes the manifest and
  ownership data.
- `v2/verify-agent-docs.sh` validates manifest schema, ownership schema,
  owner paths, gate ids, agent workspace root fields, gitignore coverage for
  `.agent-docs/`, and stale `manifest.md` references.
- Every v2 skill and rule reads the new metadata source or generated context
  derived from it.
- `v2/agent-docs-guide.md`, `v2/rules/authoring-rules.md`,
  `docs/architecture/workflow-kit.md`, `docs/repository-layout.md`, and
  `docs/decisions/agent-docs.md` describe the new metadata model.
- `bash v2/verify-agent-docs.sh` or the v2 equivalent passes.

## Discipline rules

- Do not parse metadata with ad hoc grep.
- Do not let Markdown tables remain canonical config.
- Do not add broad update triggers that are not meaningful.
- Do not make generated-context conventions unowned.
- Do not treat ignored generated Markdown as committed metadata.
- Do not support both manifest formats indefinitely.
- Do not hide metadata defaults inside generated prose; put defaults in schema,
  manifest, ownership, or source specs.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts into:

- `architecture/workflow-kit.md` - metadata source, ownership v2 shape, and
  verifier responsibilities.
- `decisions/agent-docs.md` - rationale for breaking from Markdown manifest
  slots to structured YAML metadata and richer ownership.
- `repository-layout.md` - `docs/_meta/manifest.yaml` and ownership v2 entries.
- `_meta/ownership.json` - ownership surface updates for metadata and generated
  context.

## See also

- [`generated-repo-local-agent-context.md`](generated-repo-local-agent-context.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../../v1/plan-template.md`](../../v1/plan-template.md)
