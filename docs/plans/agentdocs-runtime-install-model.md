---
status:        draft
owner:         unassigned
last_updated:  2026-06-21
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/install-and-adapters.md
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Agentdocs Runtime Install Model

## Mission

Separate the editable `agent-docs` source checkout from the runtime files that
agents actually use. Done means runtime instructions, rules, templates, and
skills resolve through `~/.agentdocs/`; local source edits do not affect other
projects until explicitly installed; GitHub installs can update the same
runtime path; and Claude/Codex copied skills are refreshed from the installed
runtime bundle.

## Scope

In scope:

- Rename the exported kit source from `v1/` to `src/`.
- Make `~/.agentdocs/` the only runtime self-reference path used by skills,
  rules, templates, and consuming repo docs.
- Remove the old `~/agent-docs/v1/...` canonical runtime model.
- Replace the public `v1/install.sh` and `v1/copy-skills.sh` flow with two
  installer entry points:
  - top-level `install-agentdocs-local.sh`
  - bundled `src/install-agentdocs.sh`
- Drop `update-agentdocs.sh` as a separate public script for now; update is the
  same operation as install.
- Install or update Claude and Codex user skill copies from
  `~/.agentdocs/skills/`.
- Remove stale managed agent-docs skills from Claude/Codex destinations when a
  skill is removed from the runtime bundle.
- Rewrite old runtime references in this repo and sibling repos under `../` to
  use `~/.agentdocs/...`.
- Keep `export-chatgpt-context.sh` in the runtime bundle because agents may use
  it from consuming projects.
- Decide whether `verify-agent-docs.sh` remains bundled whole, is split, or is
  replaced by a runtime-only verifier plus source-repo development checks.

Out of scope:

- Per-project runtime bundles. The runtime is global per user.
- A compatibility symlink from `v1` to `src`.
- Preserving `~/agent-docs` as a runtime path.
- Multiple installed runtime channels in this phase.

## Target Shape

Source checkout:

```text
agent-docs/
  install-agentdocs-local.sh
  src/
    skills/
    rules/
    template/
    agent-docs-guide.md
    plan-lifecycle.md
    plan-template.md
    export-chatgpt-context.sh
    install-agentdocs.sh
    verify-agent-docs.sh
  scripts/
  docs/
```

Installed runtime:

```text
~/.agentdocs/
  skills/
  rules/
  template/
  agent-docs-guide.md
  plan-lifecycle.md
  plan-template.md
  export-chatgpt-context.sh
  install-agentdocs.sh
  verify-agent-docs.sh
  .agentdocs-install-manifest
```

Tool adapters:

```text
~/.claude/skills/<skill-name>/
~/.agents/skills/<skill-name>/
```

Use `~/.agents/skills` as the Codex destination unless implementation verifies a
newer correct Codex skill path.

## Installer Behavior

### `install-agentdocs-local.sh`

This script lives at the source repo top level and is the dogfood/development
path. It must:

1. Resolve its own checkout root.
2. Validate that `src/skills`, `src/rules`, and core runtime files exist.
3. Replace the contents of `~/.agentdocs/` with local `src/` contents.
4. Write install metadata, including source kind `local`, source path, and
   install timestamp.
5. Refresh Claude and Codex copied skills from `~/.agentdocs/skills/`.
6. Remove stale managed agent-docs skills from Claude/Codex destinations.

Local install can replace `~/.agentdocs/` directly. It is intentionally an
explicit command so editing files in the source checkout does not change other
projects until this command runs.

### `src/install-agentdocs.sh`

This script is the normal user install/update path. Running it from a checked
out source repo still installs from GitHub, not from the local checkout. It
must:

1. Accept an optional tag/version argument; default to latest.
2. Download the GitHub tag archive or simplest available release source.
3. Stage the bundle in a temporary directory.
4. Validate expected runtime bundle shape.
5. Atomically replace `~/.agentdocs/`.
6. Write install metadata, including source kind `github` and tag/version.
7. Refresh Claude and Codex copied skills from `~/.agentdocs/skills/`.
8. Remove stale managed agent-docs skills from Claude/Codex destinations.

Because install and update have the same behavior, do not add a separate
`update-agentdocs.sh` in this phase.

## Skill Adapter Ownership

The installer owns only agent-docs managed skill copies. It should continue to
mark copied skills, and it should also keep a runtime install manifest so it can
delete skills that existed in a previous agent-docs install but no longer exist
in the new bundle.

Required behavior:

- Copy every skill directory from `~/.agentdocs/skills/` into each supported
  tool destination.
- Refresh copied skills by replacing the managed destination directory.
- Remove previously managed agent-docs skills that no longer exist in the
  runtime bundle.
- Leave unrelated personal skills alone.
- Treat destination skill-root symlinks as conflicts unless an explicit future
  decision changes adapter ownership.

If a new agent-docs skill name collides with an unmanaged personal skill, the
implementation should stop with a clear error rather than silently deleting
unowned user content. Add a force mode only if implementation needs one.

## Reference Migration

Rewrite runtime references everywhere practical:

- `~/agent-docs/v1/rules/...` -> `~/.agentdocs/rules/...`
- `~/agent-docs/v1/skills/...` -> `~/.agentdocs/skills/...`
- `~/agent-docs/v1/template/...` -> `~/.agentdocs/template/...`
- `~/agent-docs/v1/plan-lifecycle.md` -> `~/.agentdocs/plan-lifecycle.md`
- `~/agent-docs/v1/plan-template.md` -> `~/.agentdocs/plan-template.md`
- `~/agent-docs/v1/agent-docs-guide.md` ->
  `~/.agentdocs/agent-docs-guide.md`

Source-repo references should use `src/...` when they refer to editable files in
this checkout. Runtime references in skill bodies and consuming repo docs should
use `~/.agentdocs/...`.

Search and update:

- this repo's docs, plans, manifest, ownership data, scripts, templates, and
  skill bodies
- sibling repos under `../`, excluding dependency/build/cache directories
- installed managed skill copies after the new installer refreshes them

Historical shipped or abandoned plans can be rewritten too. The goal is to
remove stale `~/agent-docs/v1` guidance from every doc agents may read.

## Workstreams

### 1. Source Tree Rename

Owned files:

- `v1/` -> `src/`
- root router files
- `docs/repository-layout.md`
- `docs/_meta/manifest.md`
- `docs/_meta/ownership.json`

Tasks:

- Rename the exported kit directory.
- Update source-layout docs and metadata from `v1/` to `src/`.
- Update source-repo drift gates to call the correct verifier path.
- Remove any `v1` terminology that now describes runtime versioning.

### 2. Installer Rewrite

Owned files:

- `install-agentdocs-local.sh`
- `src/install-agentdocs.sh`
- installer-related docs

Tasks:

- Replace the old public install/copy split.
- Implement local source install.
- Implement GitHub tag/latest install.
- Include shared internal skill refresh logic inside installer scripts.
- Track managed skill state so removed skills are removed from tool
  destinations.
- Validate bundle shape before replacing runtime, especially for GitHub
  installs.

### 3. Runtime Reference Rewrite

Owned files:

- `src/skills/**`
- `src/rules/**`
- `src/template/**`
- `docs/**`
- sibling repo docs under `../`

Tasks:

- Replace runtime paths with `~/.agentdocs/...`.
- Replace source paths with `src/...` where the doc is about this checkout.
- Update template docs so newly scaffolded consuming repos point to
  `~/.agentdocs/...`.
- Update all active and historical plan docs with old runtime path guidance.

### 4. Verifier Split

Owned files:

- `src/verify-agent-docs.sh`
- possible new top-level `scripts/` checks
- manifest drift gate docs

Tasks:

- Decide which verifier behavior agents need at runtime.
- Keep runtime/scaffold checks in `src/` if consuming projects or skills call
  them.
- Move source-only repo drift checks to top-level scripts if they should not be
  exported.
- Update manifest gates and docs to match the split.

### 5. Documentation And Decisions

Owned files:

- `README.md`
- `docs/architecture/install-and-adapters.md`
- `docs/architecture/workflow-kit.md`
- `docs/decisions/agent-docs.md`
- `docs/agent-context/repo-rules.md`

Tasks:

- Document the source/runtime split.
- Document the two install entry points.
- Record the decision to use `~/.agentdocs/` as the runtime path.
- Record the decision to remove `v1` as runtime terminology.
- Update workflow command docs that previously mentioned `copy-skills.sh`.

## Exit Gate

The plan is done when:

- No tracked source file in this repo contains stale `~/agent-docs/v1` runtime
  guidance.
- No relevant sibling repo doc under `../` contains stale `~/agent-docs/v1`
  runtime guidance.
- `install-agentdocs-local.sh` installs local `src/` into `~/.agentdocs/` and
  refreshes Claude/Codex managed skill copies.
- `src/install-agentdocs.sh` installs from GitHub tag/latest into
  `~/.agentdocs/` and refreshes Claude/Codex managed skill copies.
- Removing a skill from `src/skills/` removes the corresponding managed copied
  skill on the next install.
- The final source-repo drift gate passes.
- The installed runtime contains the expected bundle files and copied skill
  adapters match `~/.agentdocs/skills/`.

Suggested checks:

```sh
bash -n install-agentdocs-local.sh
bash -n src/install-agentdocs.sh
bash install-agentdocs-local.sh
bash ~/.agentdocs/install-agentdocs.sh --dry-run
bash src/verify-agent-docs.sh
rg -n "~/agent-docs/v1|/home/adamg/agent-docs/v1" . ../ --glob '!**/.git/**'
```

Adjust verifier commands after the verifier split is implemented.

## Discipline Rules

- Do not preserve `v1` as a compatibility symlink.
- Do not make local source edits active implicitly; only
  `install-agentdocs-local.sh` publishes local source to runtime.
- Do not push tags or publish GitHub releases unless the user explicitly asks.
- Do not delete unrelated personal skills. Only remove skills proven to be
  agent-docs managed or recorded by the prior agent-docs install manifest.
- Keep the global runtime path stable: `~/.agentdocs/`.

## Open Decisions

- Exact GitHub latest-version resolution: GitHub latest release API, newest tag,
  or a fixed default branch archive. Use the simplest reliable option first.
- Whether source-only drift checks remain inside `src/verify-agent-docs.sh` or
  move to top-level `scripts/`.
- Whether a force flag is needed for unmanaged same-name skill conflicts.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts and rationale into:

- `architecture/install-and-adapters.md` for runtime path, installer behavior,
  and adapter destinations.
- `architecture/workflow-kit.md` for `src/` as the source kit and
  `~/.agentdocs/` as the runtime kit.
- `decisions/agent-docs.md` for the source/runtime split, removal of `v1`
  runtime terminology, installer script model, and managed skill deletion
  policy.
- `_meta/ownership.json` for any renamed concept ownership.

Record exact migration targets and final verification evidence here before
marking the plan shipped.

## See also

- [`index.md`](index.md)
- [`../architecture/install-and-adapters.md`](../architecture/install-and-adapters.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
