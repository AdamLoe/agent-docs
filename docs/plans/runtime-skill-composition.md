---
status:        draft
owner:         unassigned
last_updated:  2026-06-18
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Runtime skill composition

## Mission

After the subagent-first workflow plans ship, replace hand-expanded skill
bodies with a runtime composition layer. Each user-facing skill should keep a
small adapter entry point, load a skill-local configuration file, resolve the
current invocation settings, and generate the runbook or worker brief needed
for that run.

Done means the kit has a clear compiler/resolver path for skill context,
skills no longer need to duplicate shared bootstrap policy, and subagent
dispatches can generate scoped worker context from the same normalized config.

## Scope

In scope:

- Add a skill-local declarative config file beside each migrated `SKILL.md`.
- Add a command that composes a per-invocation runbook from the skill config,
  user arguments, repo manifest, adapter assumptions, dials, and reusable rule
  modules.
- Add the equivalent composition path for subagent or worker briefs.
- Add a normalized parallelism config that changes the generated orchestration
  and worker instructions for sequential work, parallel work in separate
  worktrees, and parallel work on the same branch.
- Define the small composition language used to include reusable snippets,
  conditionally include config-specific instructions, and preserve provenance.
- Keep skill names stable; do not create separate skills for every config
  combination.
- Preserve Codex and Claude Code as the only supported adapter targets for
  this work.
- Add drift checks that make generated or composed surfaces debuggable and
  reproducible enough for normal agent-docs maintenance.

Out of scope:

- Replacing the subagent-first workflow migration. This plan starts after
  `workflow-rule-abstraction.md` and `subagent-first-skill-breakdown.md`
  finish.
- Supporting arbitrary agent runtimes beyond Codex and Claude Code.
- Turning every runbook into a committed artifact. Runtime outputs should be
  temporary by default, with committed run docs reserved for long-running
  orchestration work.
- Using an LLM to freely invent skill prompts from scratch. Composition should
  be deterministic wherever practical.

## Approach

### 1. Define the Composition Contract

Specify the stable inputs and outputs for skill composition:

- skill name and skill-local config
- raw user arguments
- normalized dials such as `review-*` and `cost-*`
- normalized parallelism mode: `sequential`, `worktree-parallel`, or
  `same-branch-parallel`
- repo manifest slots needed by the skill
- adapter target, limited to Codex and Claude Code
- generated runbook path, normalized config path, and source/provenance path

The contract should describe how config precedence works: explicit user
arguments first, then repo or profile defaults, then skill defaults, then kit
defaults.

Parallelism should be a first-class config value because it changes generated
instructions, not just model behavior:

- `sequential` means one worker or phase owns the tree at a time. Generated
  docs should emphasize handoff state, serial gates, and avoiding speculative
  parallel dispatch.
- `worktree-parallel` means independent workers may use separate worktrees.
  Generated docs should include worktree setup, ownership, merge/review, and
  cleanup expectations.
- `same-branch-parallel` means multiple workers may operate against the same
  branch or checkout. Generated docs should include stricter file ownership,
  collision checks, communication cadence, and final consolidation rules.

### 2. Design the Composition Language

Define the smallest template/include language that can assemble runbooks and
worker briefs without turning generation into free-form prompt writing. The
language should support:

- named snippets or modules stored in predictable kit paths
- conditional inclusion based on normalized config values
- skill-local variables such as worker roles, closeout evidence, manifest
  slots, and direct-utility exceptions
- adapter-specific snippets for Codex and Claude Code
- provenance output that records every snippet, config value, and source file
  used to build the generated context

The language should be declarative enough that drift checks can validate
references and conditions. Avoid embedding arbitrary shell or model-generated
logic inside templates unless the behavior is isolated and tested.

Example shape, not final syntax:

```yaml
sections:
  - include: modules/bootstrap.md
  - include: modules/parallel/worktree.md
    when: parallelism == "worktree-parallel"
  - include: modules/review/high.md
    when: review in ["high", "max"]
```

### 3. Add a Narrow Composer Spike

Implement the smallest useful composer around one safe skill or one bounded
orchestrator path. The spike should prove:

- `SKILL.md` can become a tiny bootstrap that runs the composer and reads the
  generated runbook.
- The skill-local config can express routes, worker roles, closeout evidence,
  parallelism behavior, and direct-utility exceptions.
- Conditional snippet imports can alter the generated runbook for at least one
  config axis, preferably parallelism because it materially changes worker
  instructions.
- The generated runbook is inspectable and includes provenance for the files
  and config values that shaped it.
- Existing adapter copying still works when a skill directory contains config
  and helper files beside `SKILL.md`.

### 4. Compose Worker Briefs

Extend the same model to subagent dispatch. Before launching a worker, an
orchestrator should be able to generate a scoped brief from:

- the parent skill's normalized config
- the parent invocation's parallelism mode
- the worker role
- the specific task
- exact rule files selected by the subagent-first model
- expected output and evidence requirements

This should reduce copied prompt text while keeping workers from discovering
the workflow graph themselves.

Parallelism affects worker briefs directly. A same-branch worker brief needs
clear file ownership and collision reporting. A worktree worker brief needs
worktree path, branch, merge, and cleanup expectations. A sequential worker
brief should state what previous phase output it must read and what handoff
evidence it must leave for the next phase.

### 5. Migrate Skills Incrementally

Move skills onto the composition path in small batches:

- Direct utilities first, only if composition reduces duplicated bootstrap
  logic without adding pointless ceremony.
- One small orchestrator next, such as the bounded quick-fix workflow after
  the subagent-first migration has defined its worker roles.
- Broader orchestration skills only after the config and worker-brief model
  has survived real use.

Each migration should preserve the current command name and adapter discovery
path.

### 6. Add Verification

Extend the verifier with cheap checks for the new structure:

- every migrated skill has valid config
- every referenced rule/module path exists
- every conditional snippet reference uses a known config key and valid value
- every supported parallelism mode has an exercised smoke generation path
- generated or composed surfaces can be reproduced for at least a smoke
  invocation
- copied Codex and Claude skill adapters remain fresh after skill changes

Avoid prose-level linting unless a repeated drift issue needs a specific
guard.

## Exit Gate

- The subagent-first workflow and per-skill breakdown plans have shipped or
  this plan has been intentionally revised against their final shape.
- At least one migrated skill uses a tiny `SKILL.md` bootstrap plus a
  skill-local config file.
- A composer command generates an inspectable per-run runbook.
- The same mechanism can generate a scoped worker brief for a subagent role.
- The normalized config includes parallelism, and generation differs for
  `sequential`, `worktree-parallel`, and `same-branch-parallel` where that
  distinction changes worker behavior.
- The composition language supports conditional snippet inclusion with
  verifier-visible references.
- The generated context records enough provenance to debug what was included
  and why.
- `docs/architecture/workflow-kit.md` describes the runtime composition model.
- `docs/decisions/agent-docs.md` records why the kit chose runtime
  composition over skill-name/config explosion.
- `bash v1/verify-agent-docs.sh` passes.
- If skill directories change, `bash v1/copy-skills.sh ~/agent-docs` and
  `bash v1/copy-skills.sh --check ~/agent-docs` pass.

## Discipline Rules

- Do not create one skill per config combination.
- Do not make generated runbooks the canonical source of workflow truth.
- Do not hide important config decisions inside unstructured generated prose.
- Do not treat parallelism as a vague cost hint; it controls branch/worktree
  safety instructions and must be explicit in normalized config.
- Do not let templates execute arbitrary logic when declarative snippet
  inclusion is enough.
- Keep composition deterministic first; use model-generated prose only where
  it is clearly bounded and verified.
- Keep the plan sequenced after the subagent-first rule and skill migration
  unless that migration is explicitly replanned.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, migrate durable facts into:

- `architecture/workflow-kit.md` — runtime composition shape, skill-local
  config placement, composer outputs, worker-brief generation, and verifier
  impact, including parallelism-driven generated instructions.
- `decisions/agent-docs.md` — rationale for runtime composition, stable skill
  names, rejecting config-specific skill explosion, and choosing declarative
  snippet composition over free-form prompt generation.
- `_meta/ownership.json` — only if runtime composition becomes a separately
  owned concept.

## See also

- [`workflow-rule-abstraction.md`](workflow-rule-abstraction.md)
- [`subagent-first-skill-breakdown.md`](subagent-first-skill-breakdown.md)
- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../../v1/plan-template.md`](../../v1/plan-template.md)
