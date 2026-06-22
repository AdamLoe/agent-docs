# Context profiles (agent-docs v1)

GENERIC. App-independent. This file is the human-owned contract for worker
context profiles: the column meanings, the read-only-vs-mutating invariant, and
the budget-exception rule. The **machine authority for the profile rows
themselves is the kernel** — `src/kernel/profiles.json` (read by
`src/verify-agent-docs.sh`). Skills and dispatch rules name profile IDs and
resolve them with `bash src/verify-agent-docs.sh --resolve <id>`; they do not
copy profile rows, rule bundles, or mutation policy from anywhere.

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

## Where the rows live

The profile rows (the eleven `id`/`purpose`/`core_rule_paths`/`overlays`/
`mutation_capability`/`budget_words`/`enforcement_status` records) are kernel
data in `src/kernel/profiles.json`, **the sole machine authority**. The global
launch budgets (`fixed_skill_launch`, `classifier_skill_launch`, and the
`classifier_skills` allowlist) live in the same file's `budgets` object. Nothing
duplicates those rows or budgets in this doc — the verifier reads only the kernel
and fails if any profile/budget fact reappears here as data. To see a resolved
profile run `bash src/verify-agent-docs.sh --resolve <id>`; for the whole
inventory run `bash src/verify-agent-docs.sh --context-report`.

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

| Profile | Old budget | New budget | Measured floor |
|---|---:|---:|---:|
| `planning.tracked` | 1300 | 1600 | 1542 |
| `review.docs` | 1000 | 1200 | 1148 |
| `maintenance.plan` | 1800 | 2100 | 2016 |

## Launch budgets

A skill's controlled launch is its body plus the irreducible startup surface:
the shared skill-contracts contract, the docs index, and its requested manifest
slots (a classifier additionally reads `orchestrator/lifecycle.md`). After the
Wave-5b honest `--measure-launch` fix — a `rules/...` path counts as a startup
load only when a sentence genuinely instructs reading it at launch, never when
it appears only in a prohibition, a `load only when/after` deferred-load gloss,
or a References pointer — the enforced launch budgets are E3 measured floors:

| Launch kind | Budget | Honest max | Headroom |
|---|---:|---|---:|
| fixed skill | 2000 | 1922 (`review-app`) | ~4% |
| classifier (`orchestrate`, `fresh-chat`, `start-session`) | 3300 | 3118 (`orchestrate`) | ~6% |

The aspirational 1200/2000 targets are unreachable: the shared startup surface
(skill-contracts 637 + docs index 114 + manifest slots 430 = 1181) loads on
every launch, and a classifier irreducibly reads lifecycle.md (1037). Per E3
these floors are documented target changes, not inflation to hide drift. The
verifier (`src/verify-agent-docs.sh`) holds the operative values and now gates on
them; this table is the human-owned record.

## See also

- [`context-profiles-reference.md`](context-profiles-reference.md) — rationale (do not auto-load).
- [`orchestrator/dispatch.md`](orchestrator/dispatch.md)
- [`orchestrator/lifecycle.md`](orchestrator/lifecycle.md)
- [`../skills/registry.md`](../skills/registry.md)
