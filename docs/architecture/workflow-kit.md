# Workflow kit

`v1/` is the stable kit version. `v2/` is a narrow generated-context proof for
Codex `/plan` against `~/fluid-simulation`; it is not a full kit migration.

## Orchestrator/worker model

The kit is **subagent-first**. Every user-facing skill is an *orchestrator entry
point*: it classifies the request, chooses lifecycle phases, dispatches *workers*
with exact rule-file routes, tracks observed evidence, and reports to the human.
Workers do the planning, implementation, review, maintenance, or verification and
report concise evidence back. There is no first-class "direct execution" class;
an orchestrator only does a step inline when it is pure routing/IO under the
reads-vs-dispatch test (read across ≤ a couple of files, no defensible judgment
call, no mutation, no gate). Worker dispatch is expected of the runtime; an
adapter that cannot spawn a worker is an error to report, not a reason to inline.

Rules live at the layer that owns them:

- **Universal** (`v1/rules/*.md`) — what every skill needs regardless of role.
- **Orchestrator** (`v1/rules/orchestrator/`) — workflow control, phase choice,
  the dispatch packet and worker-report shape, the rule bundles, commit
  concurrency, and opt-in run docs. The dispatch packet and bundle table are
  canonical in `dispatch.md`.
- **Subagent** (`v1/rules/subagent/`) — how to perform one assigned role.
- **Skill body** (`v1/skills/<name>/SKILL.md`) — one command's routing surface,
  local context needs, worker phases, the exact rule files it passes, and its
  closeout shape.

The workflow is commit-heavy: editing workers commit their own slice before
reporting, follow-up workers repair or revert with further commits, editing is
serial per working tree, and parallel editing uses worktree isolation or
orchestrator-applied patches. The orchestrator records commit hashes and verifies
the final observed state.

## Main surfaces

| Surface | Owns |
|---|---|
| `v1/skills/*/` | Runnable workflow commands; `SKILL.md` is the prompt entry point and skill-local helper scripts may live beside it. |
| `v1/skills/registry.md` | Skill inventory and mode/action metadata. |
| `v1/copy-skills.sh` | Refreshes copied agent-docs skills in Claude and Codex user skill directories after skill changes. |
| `v1/verify-agent-docs.sh` | Non-mutating drift gate for scaffold, manifest, ownership, registry, adapter, and stale-reference checks. |
| `v1/rules/*.md` | Universal rules shared by every consuming repo: `skill-contracts.md` (skill startup), `repo-rules.md`, `authoring-rules.md`, `coding-style.md`. |
| `v1/rules/skill-contracts.md` | Shared contracts for skill startup intake, the subagent-first expectation, shipping, registry, dials, and model language. |
| `v1/rules/orchestrator/` | Orchestrator-facing workflow control: `lifecycle.md` (classification, phases, dials), `dispatch.md` (packet shape, worker report, rule bundles, commit concurrency), `run-docs.md` (opt-in run folders). |
| `v1/rules/subagent/` | Worker-facing role rules: `planning.md`, `implementation.md`, `review.md`, `docs-maintenance.md`, `plan-maintenance.md`, `verification.md`. |
| `v1/template/docs/` | Scaffold copied by `/rebuild-agent-docs`. |
| `v1/agent-docs-guide.md` | Narrative guide for adopting the doc system. |
| `v1/plan-lifecycle.md`, `v1/plan-template.md` | Plan metadata and plan skeleton. |
| `v2/context/render.py` | Deterministic renderer for the v2 generated-context proof. It reads `v2/skills/plan/context.yaml`, selected kit modules, the target repo's `docs/_meta/manifest.yaml`, selected target repo docs, and inline YAML text. |
| `v2/context/verify.py` | Narrow functional verifier for Codex `/plan` context generation against `~/fluid-simulation`. |
| `v2/context/modules/` | Source-authored Markdown modules used by the v2 renderer. |
| `v2/skills/plan/` | Thin v2 `/plan` launcher shape plus the skill-local context recipe. |

## v2 generated context

The v2 proof lowers agent startup context by rendering one run-local Markdown
file in the consuming repo before the workflow starts. The renderer assembles
only selected source material; it does not call a model and does not summarize
free-form prose at generation time. Compact factual summaries and hard
instructions live in source-authored YAML or Markdown modules and are copied as
selected inputs.

For the Codex `/plan` proof, `v2/context/render.py` requires the target repo's
`docs/_meta/manifest.yaml`. It uses the manifest's
`metadata.generated_context.root` and `.log` fields to write
`docs/.generated/<random-id>.md` and append
`docs/.generated/generations.yaml`. Generated ids are URL-safe and
collision-checked. The generated Markdown and log are ignored disposable
artifacts; deleting the directory, an individual generated Markdown file, or the
log is normal and the next render recreates what it needs.

Includes are explicit in `v2/skills/plan/context.yaml`:

- kit file includes from `v2/context/modules/`
- target repo file includes from `docs/agent-context/`
- target repo Markdown sections selected by heading
- inline YAML text
- target metadata selected from `docs/_meta/manifest.yaml`

The generated file carries compact source labels and provenance digests so an
agent can trace each instruction back to its source. Orchestrator context is
rendered with `--role orchestrator`; planning-worker context is rendered with
`--role planning-worker` and passed in the worker prompt before task-specific
inputs. Workers should read the generated context path they are given instead
of discovering the whole agent-docs workflow tree.

The proof verifier is:

```sh
python3 ~/agent-docs/v2/context/verify.py --repo ~/fluid-simulation --skill plan --adapter codex --max-bytes 16000
```

It checks target YAML metadata, ignored generated output, render size, random id
shape, log append behavior, delete/regenerate behavior, planning-worker context,
and that generated artifacts are neither tracked nor staged.

## Workflow commands

After adding, renaming, or deleting a skill, run
`bash ~/agent-docs/v1/copy-skills.sh ~/agent-docs`, then
`bash ~/agent-docs/v1/copy-skills.sh --check ~/agent-docs`, so Claude and
Codex can discover the updated skill set from their copied user skill
directories.

Before shipping repo changes, run `bash ~/agent-docs/v1/verify-agent-docs.sh`
from any working directory. The verifier owns this repo's non-mutating drift
gate and delegates copied-adapter freshness to `v1/copy-skills.sh --check`.

- `/start-session` checks local git state, active plans, shipped cleanup
  candidates, and orchestration run docs at the start of a day or coding
  session. It routes into the owning skill instead of duplicating workflow
  logic: `clear-plans` for safe disposable plan material,
  `ship-current-work` for dirty coherent work, `ship-plans` or
  `review-shipped-work` for active plan work, and `plan`, `quick-fix`, or
  `orchestrate` for a supplied next task.
- `/fresh-chat` starts ordinary work from the docs router.
- `/doctor` validates scaffold, manifest, ownership, skill
  registry, and stale reference health.
- `/orchestrate` asks for a change request, then coordinates the
  quick-fix or plan/review/implement/review lifecycle through specialist
  agents. Its default state lives in chat, subagent reports, and ordinary
  plans already in play. When the user asks for run docs or grants permission
  after a resume-risk prompt, it may create
  `docs/plans/orchestrator/<run-slug>/` with a required `hub.md`, stream
  notes, and optional findings. The hub carries plan-style lifecycle metadata
  so cleanup tools can treat the run folder as disposable plan material after
  durable facts migrate.
- `/plan` shapes app-state thoughts into implementer briefs, tracked plans,
  docs, or further discussion.
- `/quick-fix` fixes a small problem directly and commits when green.
- `/ship-plans` implements named plans through verification, docs
  migration, plan shipping, and commit.
- `/review-shipped-work` reviews completed or in-progress work against named plans.
- `/review-plans` reviews named plans with a high-level or custom lens.
- `/review-plans-health` reviews the health of `docs/plans/`, including
  orchestration run folders under `docs/plans/orchestrator/`.
- `/review-skills` reviews this kit's skill suite for drift and
  lifecycle gaps.
- `/ship-current-work` finishes ordinary work and commits if gates pass.
- `/rebuild-agent-docs` adopts or repairs a repo's docs tree.
- `/wrap-up-current-chat` captures chat-only durable context.
- `/clear-plans` cleans shipped or abandoned plans and orchestration run
  folders after migration. It deletes only clean tracked plan/run-doc material
  so the latest deleted content remains recoverable from local git history.
- `/feedback-agent-docs` records a kit-level comment or request from a
  consuming repo into the upstream inbox at `~/agent-docs/feedback/inbox.jsonl`.

## Command routing

Use the smallest command that owns the current job:

| Job | Command |
|---|---|
| Start a day/session by checking local git, plans, and cleanup candidates | `/start-session` |
| Start a normal chat and wait for the task | `/fresh-chat` |
| Fix one bounded issue now | `/quick-fix` |
| Shape rough direction into implementer-ready material | `/plan` |
| Coordinate a broad change across planning, implementation, and review | `/orchestrate` |
| Implement existing plan files | `/ship-plans` |
| Verify shipped or in-progress plan work | `/review-shipped-work` |
| Finish the current dirty tree | `/ship-current-work` |
| Check scaffolding and mechanical drift | `/doctor`, `/check-docs`, `/fix-docs-drift` |
| Review doc or plan quality | `/review-docs-shape`, `/review-plans`, `/review-plans-health` |

## See also

- [`../../v1/agent-docs-guide.md`](../../v1/agent-docs-guide.md)
- [`install-and-adapters.md`](install-and-adapters.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
- [`../../v1/rules/orchestrator/`](../../v1/rules/orchestrator/)
- [`../../v1/rules/subagent/`](../../v1/rules/subagent/)
- [`../../v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md)
