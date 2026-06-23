---
status:        active
owner:         orchestrator
last_updated:  2026-06-23
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
| 2 | `planning.scope` fixed `/orchestrate` entry | **done** | d7c544c | green; check 9 gates ordering |
| 3 | `docs.inspect`/`plans.inspect` + exact-context resolver | **done** | e471881 | green; merge mode references-only |
| 4a | execution.yaml + schema + scaffold/doctor/manifest/ownership | **done** | f6ff752 | green; PyYAML-optional, both branches verified |
| 4b | 8 quality packs + pack-merge rule + pack gates | **done** | 0d45779 | green; 4 pack gates probed |
| 4-review | Independent review of execution binding + packs | **done** | — | adversarial; no defects |
| 5 | Clean-handoff git invariant + discharge gate | **done** | 4035be6 | green; check 10 gates consistency |
| 6a | Skill renames (one commit) | **done** | 8295ffb | green; substring-safe guards probed |
| 6b | Per-skill kernel-workflow-ID wiring | **done** | 8ea5a5f | green; referential gate probed |
| 7a | Exit-gate audit + cost-regression guard + scenario traces | **done** | ced8ff4 | green; all exit-gate items gated |
| 7b | Durable-fact migration (workflow-kit/decisions/manifest/guide) | **done** | 37d6b9f | green; plan source-complete (not shipped) |
| final-verify | Consolidated drift gate on post-mutation state | **done** | (37d6b9f) | SOURCE BUILD GREEN |

## Closeout — SOURCE BUILD GREEN (final migration user-gated, pending)

All source waves 0–7b shipped and verified green on the post-mutation state
(HEAD `37d6b9f`): `bash src/verify-agent-docs.sh` exit 0 ("ALL AGENT-DOCS GATES
PASS"), `--contract-check` 0 violations, `--equivalence` PASS, all profile
budgets + classifier launch floors green, both installer `--dry-run`s exit 0,
git tree clean except the expected unrelated dirt.

**Commits (this run, on `overhaul-agent-docs-install-workflow`):** c2c726b (hub) ·
742658f (W0) · f606c76 (plan-budget fix) · 7aa6298 (W1a) · f7ff819 (W1b cutover) ·
bb69545 (W1b D1 fix) · d7c544c (W2) · e471881 (W3) · f6ff752 (W4a) · 0d45779 (W4b) ·
4035be6 (W5) · 8295ffb (W6a) · 8ea5a5f (W6b) · ced8ff4 (W7a) · 37d6b9f (W7b) · plus
hub checkpoints. Two independent reviews (W1b caught blocking D1; W4 clean).

**Durable facts migrated** → `docs/architecture/workflow-kit.md` (kernel/resolver/
execution-binding/packs/clean-handoff shape), `docs/decisions/agent-docs.md` (5
decisions, recorded incrementally in W0+W5), `docs/_meta/{manifest.md,
ownership.json}`, `src/agent-docs-guide.md`, `src/template/docs/`. The build plan
is `status: active`, `okay_to_delete: false` — SOURCE-COMPLETE, not shipped.

**Kernel bundling — RESOLVED by no-install test (2026-06-23): NO change needed.**
A simulated installed (flat) layout in `/tmp` showed: the installed runtime's only
job is `--scaffold` (no-arg run prints the `--scaffold` directive), and `--scaffold`
validates a consuming repo's `docs/` and NEVER reads `src/kernel/`. `--resolve` and
the full gate are source-checkout-only tools (they need `src/kernel/` relative to a
real repo root, absent post-install) — this was true before the kernel too. So both
installers' `bundle_dirs=(skills rules template)` are correct as-is; the earlier
"must bundle kernel/" flag (and the final-verify worker's "no gap") are both
superseded by this test: no gap, and no bundle change. Open for the canary only:
whether a *consuming-repo* dispatch should resolve a profile→rules mapping at
runtime (today it reads the named rule files directly per dispatch).

**REMAINING — user-gated FINAL migration only (do NOT run without authorization):**
1. Run an installer; refresh `~/.agentdocs/` + Claude/Codex adapter skill copies;
   prune the renamed `check-docs`/`review-plans-health` dirs via `remove_stale_managed`.
2. Roll `execution.yaml` out to other consuming repos (deliberately broken until now).
3. Run the two live canaries (ordinary feature + UI feature) per adapter; the canary
   answers the consuming-repo profile-resolution question above.
After that succeeds: build plan → `status: shipped`, `okay_to_delete: true`; this
hub → same; then `/clear-plans`. **No source changes remain** — only the install.

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

## Tight-budget hotspots (warn future-wave workers)

- `src/skills/orchestrate/SKILL.md` = 900/900 (AT cap). Wave 6b touches every skill
  body — orchestrate has zero headroom; the workflow-ID wiring must replace, not add.
- `src/rules/subagent/planning.md` = 498/500 (AT cap).
- orchestrate controlled launch = 3288/3300 (12 words). lifecycle.md and dispatch.md
  are classifier startup loads — any growth in Waves 3/5 risks pushing orchestrate/
  fresh-chat/start-session launch over 3300. Workers touching those rules MUST
  re-check `--measure-launch orchestrate` and trim to stay green.
- **Manifest = classifier launch load (escalating).** After Wave 4a: orchestrate
  3298/3300, review-app 1997/2000 — ~2 words headroom. The manifest change-to-doc
  slot is a classifier startup load, so every new route (4b packs, 6a renames, 7
  migration) grows it. Workers adding manifest routes MUST fold into an existing
  row or one concise row, re-measure `--measure-launch
  {orchestrate,review-app,fresh-chat,start-session}`, and trim non-pinned verbosity
  to stay ≤ floors WITHOUT weakening them. Stop + report only if truly impossible.

## Wave 7 migration constraint

`docs/decisions/agent-docs.md` is at **2600/2600** (zero headroom) after Wave 5.
Most decision migration is ALREADY done incrementally: kernel-as-consolidation +
uniform planning.scope + source-only (Wave 0), clean-handoff invariant (Wave 5).
Wave 7 must VERIFY coverage and only add a decision if something material is
genuinely missing — and if so, compress to fit (do not exceed 2600). The bulk of
NEW Wave 7 migration goes to `docs/architecture/workflow-kit.md` (1500 cap), not
decisions. `implementation.tracked` profile is at 2499/2500 (1 word) — avoid
growing its core rules.

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
