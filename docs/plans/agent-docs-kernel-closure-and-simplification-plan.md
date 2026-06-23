---
status:        shipped
owner:         implementation
last_updated:  2026-06-23
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
---

# Kernel closure, fast path, and dogfood simplification

> **Follows** `agent-docs-focused-execution-kernel-build-plan.md` (SOURCE-COMPLETE).
> That plan built the kernel; this plan hardens it against a three-LLM external
> review, reverses the one shipped decision the review and the repo both
> indict, and simplifies the machinery for a single-author dogfood kit — all
> **source-only**. It does **not** run the user-gated install; see Discipline rules.

## Mission

Three external LLM reviews of the exported repo converged (and were verified
against HEAD) on a short list: the mandatory `planning.scope`-first entry taxes
every bounded `/orchestrate` run; the verifier is over-built yet false-green in
places (it missed live drift and passes when `execution.yaml` can't be parsed);
the docs still tell runtime workers to run `--resolve`, which a consuming repo
can't do; and the system is validated only by proxies it authored, with no
ground-truth canary run. Done means: those correctness gaps are closed in
source, the bounded fast path is restored, the enforcement layer is trimmed to
the gates that catch real defects, and one real-task canary has run in a
disposable temp-HOME sandbox — **with the user's actual installed runtime never
touched**.

This plan bakes in three user decisions (2026-06-23): audience is **a
single-author dogfood kit** (prefer deletion over new machinery); a **thin
real-task eval** is wanted; and the **real install stays user-gated** — never
run here.

## Reconciliation with HEAD (read before working)

The reviews were generated from a ChatGPT export that slightly predates HEAD.
HEAD commit `ecca6a9` (2026-06-23, "no-install runtime test") already resolved
the reviewers' headline "bundle the kernel" fix as **not needed**: a temp-`/tmp`
layout sim showed the installed runtime only ever runs `--scaffold` (which never
reads `src/kernel/`); `--resolve` and the full gate are source-checkout-only
authoring/verification tools. So **do not bundle the kernel** — it would
contradict that decision. What the no-bundling commit left explicitly open, and
what this plan owns, is the *residue*: the docs still instruct runtime workers to
run `--resolve`, and the hub's own open question — "whether a consuming-repo
dispatch should resolve a profile→rules mapping at runtime (today it reads the
named rule files directly per dispatch)" — is unanswered.

## Scope

In scope (all source-only):

- Fix the verified live drift in `docs/repository-layout.md` and close the
  gate gap that let it survive a green build.
- Remove the `execution.yaml` false-green (can't-parse must fail, not pass with
  empty packs).
- Make the docs match the real runtime: stop telling runtime workers to run
  `--resolve`; answer the hub's open consuming-repo profile-resolution question
  by temp-HOME sim.
- Reverse the Q1 disposition: replace mandatory `planning.scope`-first with a
  conditional bounded fast path (still subagent-first; just not planner-always).
- Dogfood simplification: defer the unused packs, downgrade the low-value
  scenario-contract gate and the zero-headroom budget treadmill, re-merge the
  `*-reference.md` splits that can't be applied without their exiled examples.
- One thin real-task canary run in a **disposable temp-HOME sandbox**.

Out of scope (explicitly, and **never run from this plan**):

- The real installer, refreshing `~/.agentdocs/` / `~/.claude/skills/` /
  `~/.agents/skills/`, or rolling `execution.yaml` to real consuming repos —
  these stay the user-gated FINAL migration in the kernel build plan.
- Bundling the kernel (superseded — see Reconciliation).
- A Python rewrite of the verifier, a vector/semantic index, ephemeral
  git-ignored trace files (review proposals that add machinery; rejected for a
  dogfood kit).

## Approach

Waves are ordered by risk: correctness fixes first (low blast radius), the
architectural reversal next, simplification third, the canary last. Each wave
names its owned files and an exit gate.

### Wave 1 — Source closure (correctness)

- **1a (DONE as down payment):** fix `docs/repository-layout.md:33-34` — retired
  `src/install.sh` / `src/copy-skills.sh` rows replaced with the real
  `src/install-agentdocs.sh` (embeds skill refresh) and the top-level dev
  installer.
- **1b:** find why the stale-reference gate let 1a survive a green build — gap or
  not-run-pre-commit — and add coverage so doc-referenced repo paths are checked
  for existence.
- **1c:** kill the `execution.yaml` false-green: when the binding can't be parsed
  (no PyYAML / malformed) the gate must fail loudly. Decide stdlib-JSON binding
  vs. a hard parser prereq; "can't parse → green with no packs" must not ship.
- **1d:** make docs match runtime. `context-profiles.md` and the role cards tell
  workers `bash src/verify-agent-docs.sh --resolve <id>`; a consuming runtime has
  neither that path nor the kernel. Reword to what HEAD actually does (dispatch
  names exact rule files directly; `--resolve` is a source-only aid), and answer
  the hub's open question via a temp-HOME sim of a consuming-repo dispatch.
- Owned: `docs/repository-layout.md`, `src/verify-agent-docs.sh`,
  `src/rules/context-profiles.md`, the worker role cards under
  `src/rules/subagent/`, plus `docs/architecture/*` / `docs/decisions/*` touched.
- Exit gate: `bash src/verify-agent-docs.sh` green; a temp-HOME sim shows a
  consuming-repo worker can name and read its profile's rule files with no kernel
  present; no doc instructs a *runtime* worker to run `--resolve`.

### Wave 2 — Conditional bounded fast path (reverse Q1)

- Replace "always `planning.scope` first, no short-circuit" with: the
  orchestrator dispatches `implementation.*` directly when the request already
  states a bounded outcome + acceptance + likely check; `planning.scope` only
  when classification, decomposition, or a user decision is genuinely unresolved.
  Subagent-first is preserved (still a worker; just not the planner).
- Owned: `src/skills/orchestrate/SKILL.md`, `src/rules/orchestrator/lifecycle.md`,
  `src/rules/orchestrator/dispatch.md`, `src/kernel/{scenarios,workflows}.json`,
  `docs/decisions/agent-docs.md` (reverse the Q1 disposition + record why).
- Exit gate: contract-check green with a bounded-fast-path scenario; a bounded
  `/orchestrate` resolves with no scope hop in a temp-HOME sim; the decision
  reversal is recorded in `decisions/agent-docs.md`.

### Wave 3 — Dogfood simplification

- Defer the unused packs: keep the ones the dogfood repo routes; mark the rest
  not-shipped and stop gating their prose. **Log what was deferred** (no silent
  cap).
- Downgrade the scenario-contract gate (asserts skill prose names fixture
  profiles — low ground-truth value) to advisory or remove; convert per-word
  launch budgets from zero-headroom hard floors to advisory-with-ceiling.
- Re-merge `*-reference.md` splits where the loaded normative file can't be
  applied without its exiled examples (start with `skill-contracts`).
- Owned: `src/kernel/packs.json`, `src/rules/packs/*`, `src/verify-agent-docs.sh`
  (budget + contract-check modes), `src/rules/*-reference.md` (+ merge targets),
  `src/rules/context-profiles.md`, `docs/decisions/agent-docs.md`.
- Exit gate: verifier green with the reduced gate set; budget overage is a
  warning (except a sane ceiling); deferred packs are listed in the decision doc.

### Wave 4 — Thin real-task canary (sandbox only)

- Build a disposable temp-HOME, simulate the installed runtime (copy
  `bundle_dirs` into a throwaway `$HOME/.agentdocs`), and run one ordinary and
  one UI-shaped bounded task kit-on; ideally a tiny kit-on vs kit-off compare.
  Capture: does dispatch resolve profile rules with no kernel; does the fast path
  fire; output-quality notes. Delete the sandbox after.
- This is the **stand-in** for the kernel plan's "run the installer + canaries."
  The real install stays user-gated.
- Owned: a throwaway harness (not bundled), findings recorded in the run hub.
- Exit gate: sim runs green; findings recorded; an explicit list of what only a
  real install can prove is handed to the user.

## Exit gate

`bash src/verify-agent-docs.sh` green after every wave; the temp-HOME sims in
Waves 1d/2/4 pass; `docs/decisions/agent-docs.md` records the Q1 reversal and the
pack-deferral list; and **no command in this plan has written outside the source
checkout** (verified: `~/.agentdocs/`, `~/.claude/skills/`, `~/.agents/skills/`
unchanged).

## Discipline rules

- **NEVER INSTALL — hard rule.** Do not run `install-agentdocs.sh`,
  `install-agentdocs-local.sh`, or any command that writes to `~/.agentdocs/`,
  `~/.claude/skills/`, `~/.agents/skills/`, or any real consuming repo. All
  runtime validation uses a **disposable temp-HOME sandbox** that is deleted
  after use. The user's actually-used docs and runtime must end this plan
  byte-identical to how they started it. This overrides any skill default that
  would refresh adapters or publish the runtime.
- **SOURCE-ONLY** (inherited): nothing migrates to consuming repos until the
  separate user-gated FINAL migration.
- **Dogfood bias:** prefer deleting or merging over adding machinery; reject new
  infrastructure (no parser rewrite, index layer, or per-run trace files).

## Migration notes (filled in at ship time)

What moved where (all confirmed present in owning docs):

- **Q1 fast-path reversal + rationale** → `docs/decisions/agent-docs.md` §
  "Conditional bounded fast path for `/orchestrate`" (Wave 2; supersedes the prior
  mandatory scope-first disposition).
- **Trimmed gate set, deferred-packs list, advisory-with-ceiling budget policy,
  runtime profile-resolution answer** → `docs/architecture/workflow-kit.md` §
  "Runtime profile resolution" and § "Workflow commands" advisory-with-ceiling
  text (Waves 1/3). Deferred pack list also in `docs/decisions/agent-docs.md` §
  "Deferred quality packs".
- **Runtime canary caveat** ("what only a real install can prove") → `docs/
  architecture/workflow-kit.md` § "Runtime canary caveat" paragraph (added at
  closeout): the source-only sim confirmed direct rule-file naming works without
  the kernel, but validating live profile resolution in a real consuming repo
  requires the user-gated real-install canary.
- **Wave 4 canary findings** → run hub (disposable temp-HOME sandbox, findings
  reported to the orchestrator, sandbox deleted after). The "what only a real
  install can prove" list was handed to the user at Wave 4 closeout.

No new `_meta/ownership.json` entries required; all migrated facts route to
existing owners.

## See also

- `agent-docs-focused-execution-kernel-build-plan.md` — the build this hardens;
  owns the user-gated FINAL install.
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md),
  [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md) — owners.
- [`../../src/plan-lifecycle.md`](../../src/plan-lifecycle.md) — status + ship rules.
</content>
</invoke>
