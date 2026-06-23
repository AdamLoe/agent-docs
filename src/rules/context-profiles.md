# Context profiles (agent-docs v1)

GENERIC. App-independent. This file is the human-owned contract for worker
context profiles: the column meanings, the read-only-vs-mutating invariant, and
the budget-exception rule. The **machine authority for the profile rows
themselves is the kernel** — `src/kernel/profiles.json` (read by
`src/verify-agent-docs.sh`). At runtime a dispatch names a profile ID and hands
the worker that profile's core rule files **by name** (the bundled
`~/.agentdocs/rules/...` paths); the worker reads them directly. There is no
kernel and no resolver at runtime, so a runtime worker never runs `--resolve`.
`bash src/verify-agent-docs.sh --resolve <id>` is a **source-checkout-only**
authoring/verification aid the kit author uses to inspect or confirm a profile's
resolved paths; it needs the kernel. Nobody copies profile rows, rule bundles, or
mutation policy from anywhere.

Expanded rationale (do not auto-load):
[`context-profiles-reference.md`](context-profiles-reference.md).

## Owner Contract

Each profile row defines:

- `id` - stable profile ID used by skills and dispatches.
- `purpose` - the work shape the profile supports.
- `core_rule_paths` - exact rule files loaded before task-routed sources.
- `overlays` - conditional files loaded only when the named condition is true.
- `mutation_capability` - `read-only`, `mutating`, or `conditional` (`review.*`
  and `verification.*` are always `read-only`).
- `budget_words` - report target for core rule files, excluding task-routed
  docs/source/tests.
- `enforcement_status` - `report-only`, `pilot-enforced`, or `enforced`
  (only the latter two make an over-budget total a hard failure).

Budget exceptions must name the exact files and the correctness reason in the
context report. Enforcement is enabled only after the profile, converted skills,
scenario rows, and verifier checks agree.

Two read-only inspection profiles — `docs.inspect` (doc drift/shape inspection)
and `plans.inspect` (plan-health inspection) — let the read-only inspection
skills name a genuinely read-only profile instead of selecting a mutating
maintenance profile and then subtracting authority in prose. Their rows live in
the kernel like every other profile; the kit author can inspect them with the
source-only aid `bash src/verify-agent-docs.sh --resolve <id>`.

## Resolver merge mode (source-only authoring aid)

`--resolve` is a **source-checkout-only** authoring/verification aid — it reads
the kernel, which is never bundled to a runtime, so it does not run at runtime.
`--resolve <profile-id>` resolves one profile. `--resolve` with
`--skill`/`--phase`/`--repo`/`--risk` flags runs the exact-context **merge**: it
joins the kernel profile (core rules + overlays + budget + exact resolved size)
with the repo's manifest fields, `execution.yaml` fields (a notice when absent),
task-routed doc and source/test hints, allowed packs from
`src/kernel/packs.json`, and the named checks. The merge is references-only and
read-only: it emits paths, heading hints, and sizes — never a rule/doc/source
body — and writes no artifact. A read-only profile is never resolved into a
mutation capability or a mutator pack; the no-self-upgrade rule lives in
[`orchestrator/dispatch.md`](orchestrator/dispatch.md). The kit author uses this
to confirm what a dispatch will name; a runtime worker reads the named rule files
directly instead.

## Where the rows live

The profile rows (the eleven `id`/`purpose`/`core_rule_paths`/`overlays`/
`mutation_capability`/`budget_words`/`enforcement_status` records) are kernel
data in `src/kernel/profiles.json`, **the sole machine authority**. The global
launch budgets (`fixed_skill_launch`, `classifier_skill_launch`, and the
`classifier_skills` allowlist) live in the same file's `budgets` object. Nothing
duplicates those rows or budgets in this doc — the verifier reads only the kernel
and fails if any profile/budget fact reappears here as data. In the source
checkout the kit author can see a resolved profile with
`bash src/verify-agent-docs.sh --resolve <id>`, or the whole inventory with
`bash src/verify-agent-docs.sh --context-report` (both source-only; they need the
kernel).

## Scenario Contract

Workflow scenarios are a source-bound contract gate (expected profiles, phases,
mutator count, state-basis fields, final ordering, and budget expectation per
task shape). The verifier checks that each scenario's `expected_profiles` are
named in the matching skill body — this GATES (exit nonzero on any violation).
The scenario rows are kernel data in the never-auto-loaded
`src/kernel/scenarios.json`, **the sole machine authority**; no skill or runtime
context loads them and this doc carries no scenario data. Run
`bash src/verify-agent-docs.sh --contract-check` to execute the gate, or
`bash src/verify-agent-docs.sh --context-report` to see the scenario rows.

## Budget floors

Three profiles were raised to their measured correctness floors after Wave-3
relocation removed all relocatable content with zero correctness loss (Decision
E3). The residual is irreducible normative contract — deleting rules to hit the
original aspirational targets would reduce correctness, not improve context
economy. Raising the budgets is a documented target change per E3, not inflation
to hide drift.

The *measured floor* below is the resolved word total of each profile's core
rule files — a human-owned observation, NOT a kernel fact (the kernel holds the
enforced `budget_words`, never the measured floor). The enforced budget for each
profile lives only in `src/kernel/profiles.json`; in the source checkout the kit
author can read it with `bash src/verify-agent-docs.sh --resolve <id>` or
`--context-report` (source-only; they need the kernel).

| Profile | Measured floor |
|---|---:|
| `planning.tracked` | 1542 |
| `review.docs` | 1148 |
| `maintenance.plan` | 2016 |

## Launch budgets

A skill's controlled launch is its body plus the irreducible startup surface:
the shared skill-contracts contract, the docs index, and its requested manifest
slots (a classifier additionally reads `orchestrator/lifecycle.md`). After the
Wave-5b honest `--measure-launch` fix — a `rules/...` path counts as a startup
load only when a sentence genuinely instructs reading it at launch, never when
it appears only in a prohibition, a `load only when/after` deferred-load gloss,
or a References pointer — the enforced launch budgets sit at their E3 measured
floors.

The two enforced launch budgets (one for fixed skills, one for the allowlisted
classifiers) and the classifier allowlist itself are kernel facts in
`src/kernel/profiles.json` (`budgets`). Read the operative numbers and the
allowlist with `bash src/verify-agent-docs.sh --context-report`; the
`--measure-launch` mode reports each skill's actual launch total.

The aspirational targets are unreachable: the shared startup surface
(skill-contracts 637 + docs index 114 + manifest slots 430 = 1181) loads on
every launch, and a classifier irreducibly reads lifecycle.md (1037). The honest
measured maxima are ~1922 for the heaviest fixed skill (`review-app`) and ~3118
for the heaviest classifier (`orchestrate`), each leaving only a few percent of
headroom against the enforced floor — which is why the budgets were set there.
Per E3 these floors are documented target changes, not inflation to hide drift.
The verifier (`src/verify-agent-docs.sh`) holds the operative values and gates on
them; this prose is the human-owned rationale, not a second copy of the budgets.

## See also

- [`context-profiles-reference.md`](context-profiles-reference.md) — rationale (do not auto-load).
- [`orchestrator/dispatch.md`](orchestrator/dispatch.md)
- [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md)
- [`../skills/registry.md`](../skills/registry.md)
