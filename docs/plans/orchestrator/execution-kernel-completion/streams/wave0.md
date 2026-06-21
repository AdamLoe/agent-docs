# Wave 0 stream — Baseline freeze

## Controlled launch totals

Method: `wc -w` on each file an agent actually reads at skill startup
(exclusive of task-routed source/tests). Files summed = skill body +
`src/rules/skill-contracts.md` + the orchestrator/role rules that skill
reads unconditionally at startup + `docs/index.md` + `docs/_meta/manifest.md`
(the manifest file is read whole to extract named slots).

### `quick-fix` fixed launch — 3,557 words

| File | Words |
|---|---:|
| `src/skills/quick-fix/SKILL.md` | 487 |
| `src/rules/skill-contracts.md` | 831 |
| `src/rules/context-profiles.md` | 892 |
| `src/rules/orchestrator/dispatch.md` | 803 |
| `docs/index.md` | 114 |
| `docs/_meta/manifest.md` | 430 |
| **Total** | **3,557** |

### `orchestrate` classifier launch — 5,796 words

Same set as quick-fix, except skill body is the orchestrate body and
`lifecycle.md` is added (orchestrate reads it unconditionally at startup).

| File | Words |
|---|---:|
| `src/skills/orchestrate/SKILL.md` | 900 |
| `src/rules/skill-contracts.md` | 831 |
| `src/rules/context-profiles.md` | 892 |
| `src/rules/orchestrator/dispatch.md` | 803 |
| `src/rules/orchestrator/lifecycle.md` | 1,826 |
| `docs/index.md` | 114 |
| `docs/_meta/manifest.md` | 430 |
| **Total** | **5,796** |

## Fixture path

`src/verify-fixtures/baseline.md` — frozen plain reference, not wired into the
verifier yet (that is Wave 5). Verifier tolerated the path; no unexpected-file
check in `src/verify-agent-docs.sh`.

## Plan baseline

`docs/plans/agent-docs-execution-kernel-completion-plan.md` §"Current baseline"
updated: pre-refactor figures and italic annotation replaced with measured
current numbers (profiles, launch totals, skill inventory); previous-plan
deletion noted as already-handled.

## Gate result

`bash src/verify-agent-docs.sh` → exit 0, `ALL AGENT-DOCS GATES PASS`.
