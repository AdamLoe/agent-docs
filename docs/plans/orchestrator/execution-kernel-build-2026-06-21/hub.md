---
status:        active
owner:         orchestrator
last_updated:  2026-06-21
okay_to_delete: false
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Run hub — focused execution kernel build

Coordination surface for shipping
[`agent-docs-focused-execution-kernel-build-plan.md`](../../agent-docs-focused-execution-kernel-build-plan.md).
The plan is the authoritative spec; this hub tracks per-wave status, decisions,
commits, gate evidence, and migration so the run is resumable if the chat dies.

**Run shape.** ~10 sub-waves, almost entirely serial (every wave mutates
`src/verify-agent-docs.sh` and/or `src/kernel/*.json`). One mutating worker at a
time on the shared tree; each wave ends with a green
`bash src/verify-agent-docs.sh` and a per-wave commit.

**Hard discipline (from the plan).**
- SOURCE-ONLY until the final migration: never run either installer, refresh
  `~/.agentdocs/`, or touch adapter skill copies until the overhaul is green
  end-to-end AND the user explicitly authorizes the one deliberate migration.
- Preserve the unrelated dirty state (the many deleted `docs/plans/*` files and
  the untracked review plan). Stage only owned files by filename.
- Kernel is JSON (stdlib `json`, zero external deps). `execution.yaml` stays YAML
  with PyYAML optional + graceful degradation.
- Never let Markdown and the kernel both own the same machine fact.
- No quality pack without a proven path/risk trigger. No weakening gates to go
  green.

**User decisions for this run.**
- Run-doc hub: yes (this file).
- Checkpoint cadence: run straight through to the pre-migration gate; stop only
  on a red gate, a blocker, or the final-migration boundary.

## Phase tracker

| Wave | Outcome | Status | Commit | Gate |
|---|---|---|---|---|
| 0 | Lock decisions + freeze baseline fixtures | **done** | 742658f | green (after f606c76) |
| 0-fix | Trim build plan under 2600 plan-budget cap | **done** | f606c76 | green (exit 0) |
| 1a | Kernel JSON shadow + `--equivalence` | **done** | 7aa6298 | green + EQUIVALENCE PASS |
| 1b | Atomic single-authority cutover (one commit) | **done** | f7ff819 | green; VIOLATIONS 0 |
| 1b-review | Independent review of the cutover | **done** | — | found blocking D1 |
| 1b-fix | Drop kernel-duplicated budget tables + honest guard | **done** | bb69545 | green; EQUIVALENCE PASS (honest) |
| 2 | `planning.scope` fixed `/orchestrate` entry | in progress | — | — |
| 3 | `docs.inspect`/`plans.inspect` + exact-context resolver | pending | — | — |
| 4 | `execution.yaml` + all 8 quality packs | pending | — | — |
| 4-review | Independent review of execution binding + packs | pending | — | — |
| 5 | Clean-handoff git invariant + discharge gate | pending | — | — |
| 6a | Skill renames (one commit) | pending | — | — |
| 6b | Per-skill kernel-workflow-ID wiring | pending | — | — |
| 7 | Static gates + scenario traces + docs migration | pending | — | — |
| final-verify | Consolidated drift gate on post-mutation state | pending | — | — |

## Decisions & accepted risks

- Q1: uniform `planning.scope` entry; accepted bounded-`/orchestrate` cost
  regression, measured by a Wave 7 cost-regression budget guard.
- Q2/Q10: single authority via shadow→atomic cutover (Wave 1a/1b), no compat layer.
- Q3: kernel JSON (stdlib), `execution.yaml` YAML with optional PyYAML.
- Q4: `execution.yaml` required immediately in source/template/dogfood; other
  consuming repos deliberately broken until final migration.
- Q6: pack-merge rule `(path-routes ∪ scoper-tags) ∩ execution-allowlist`;
  resolver is sole loader.
- Q7: blocked-handoff discharge gate; constrained checkpoint commits.
- Q8: renames `check-docs`→`check-docs-drift`, `review-plans-health`→`check-plans-health`.
- Q9: bootstrap + secrets layers required in `execution.yaml`/packs.

## Open questions / blockers

- **Decisions doc at cap (watch).** `docs/decisions/agent-docs.md` is pinned at
  2598/2600 after Wave 0. Later waves that add decisions (Wave 1b single-authority
  cutover; Wave 5 clean-handoff superseding "Commit-heavy worker shipping") MUST
  supersede-and-compress, not append, to stay ≤2600.
- **Review note.** Wave 0 worker made meaning-preserving compressions across
  *stable* decisions doc-wide to fit the four new ones — sanity-check those in the
  post-cutover review.
- Pre-existing defect resolved: the committed build plan was 228 words over the
  plan-budget cap (blocked every gate); trimmed to 2553 in f606c76 with no
  normative loss. Same commit reworded Wave 6a plan prose that had tripped the
  retired-name guard.

## Migration targets (filled at Wave 7 / closeout)

- `docs/architecture/workflow-kit.md` — kernel shape, resolver, execution
  binding, packs, clean-handoff git shape.
- `docs/decisions/agent-docs.md` — kernel-as-consolidation (supersedes "Focused
  handoffs over generated context"), uniform `planning.scope` + accepted cost
  regression, single-authority cutover, clean-handoff invariant (supersedes
  "Commit-heavy worker shipping"), rejected alternatives.
- `docs/_meta/{manifest.md,ownership.json}` — `src/kernel/`, `execution.yaml`,
  packs, renamed skills + triggers.
- `src/agent-docs-guide.md`, `src/template/docs/` — consuming-repo contract incl.
  `execution.yaml`.

## See also

- [`../../agent-docs-focused-execution-kernel-build-plan.md`](../../agent-docs-focused-execution-kernel-build-plan.md) — authoritative spec.
- [`../../../../src/plan-lifecycle.md`](../../../../src/plan-lifecycle.md)
