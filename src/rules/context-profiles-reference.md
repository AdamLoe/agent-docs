# Context profiles — expanded rationale (do not auto-load)

GENERIC. App-independent. Reference companion to
[`context-profiles.md`](context-profiles.md). The normative contract — the Owner
Contract field list, the Profiles table, and the scenario-fixture pointer — lives
there. This leaf carries the "why" behind the profile model. **Never
auto-loaded.** No skill, profile, or role card loads it at startup. Read it only
when you want the reasoning behind a rule in `context-profiles.md`.

## Why profiles are the sole worker-context authority

A worker reads exactly its resolved profile: the named `core_rule_paths`, the
conditional overlays whose condition is true, and the task-routed
docs/source/tests the dispatch names. Role cards never silently add a default
rule file, and skills never re-spell a rule bundle inline. Centralizing the rule
set in one table is what keeps the controlled launch budget measurable and keeps
two skills from drifting into two different "implementation worker reads" lists.

A skill or dispatch names a profile **ID**; it does not copy the row. To see the
resolved files, conditions, word totals, and any budget exception for one
profile, run:

```sh
bash ~/.agentdocs/verify-agent-docs.sh --context-report --profile implementation.code
```

## Why the field list is fixed

Each Profiles-table column is machine-checked, so the column meaning is a
contract, not documentation prose:

- `core_rule_paths` are loaded *before* any task-routed source, so they are the
  files that drive the profile's controlled budget. Keep them minimal.
- `overlays` load only when their named condition holds — e.g. authoring rules
  load for a plan edit that touches durable docs, not for every plan edit. This
  is how a profile stays cheap on the common path and complete on the rare one.
- `mutation_capability` is enforced: a `review.*` or `verification.*` profile
  must be `read-only`, and the verifier rejects any review/verification row that
  is not. Write capability lives only in planning.tracked, the implementation
  profiles, and the maintenance profiles.
- `budget_words` is the report target for the core rule files only — it excludes
  task-routed docs, source, and tests, which vary per task and cannot be budgeted
  in advance.
- `enforcement_status` gates whether an over-budget total is a hard failure.
  Under `report-only` the verifier records the overage and a correctness reason;
  under `pilot-enforced` or `enforced` an over-budget total fails the gate.

## Why budget exceptions are explicit

A profile may legitimately exceed its declared budget when correctness requires
every listed core file. That is allowed only when the context report names the
exact files and the correctness reason. Enforcement for a profile is enabled
only after the profile row, the converted skills that use it, the scenario rows
that exercise it, and the verifier checks all agree — never by flipping
`enforcement_status` ahead of the skills and fixtures that prove the contract.

## Why scenarios live in a fixture, not this file

The workflow scenarios are a report-only behavioral contract: each row names the
expected questions, profiles, phases, mutator count, state-basis fields, final
ordering, and budget expectation for one task shape. That matrix is verifier-only
data, so it lives in the never-auto-loaded machine authority
`src/kernel/scenarios.json` rather than on this runtime-loaded
file. Keeping it out of `context-profiles.md` is what lets the profile owner stay
a small, always-resolvable contract while the scenario matrix grows. No skill or
runtime context loads the kernel JSON; only the verifier reads it.

## See also

- [`context-profiles.md`](context-profiles.md) — the normative profile contract.
- [`orchestrator/dispatch.md`](orchestrator/dispatch.md) — how a dispatch names a
  profile ID and overlays.
- [`../skills/registry.md`](../skills/registry.md) — per-skill profile usage.
