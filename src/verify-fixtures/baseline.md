# Wave-0 baseline fixture

Frozen reference measured at the start of execution for
`docs/plans/agent-docs-execution-kernel-completion-plan.md`. Numbers were
taken against the current `src/` tree (post v1→src rename, post `~/.agentdocs/`
relocation). This is NOT a generated report; it is a manually frozen snapshot.

Commit at measurement: HEAD on branch `overhaul-agent-docs-install-workflow`
(captured in Wave 0 commit).

## Profile totals vs budget

Source: `bash src/verify-agent-docs.sh --context-report`

| Profile | Words | Budget | Status |
|---|---:|---:|---|
| `planning.brief` | 417 | 700 | within |
| `planning.tracked` | 2069 | 1300 | OVER |
| `implementation.code` | 1820 | 1700 | OVER |
| `implementation.code-docs` | 3248 | 2500 | OVER |
| `implementation.tracked` | 3901 | 2500 | OVER |
| `review.generic` | 319 | 700 | within |
| `review.docs` | 1747 | 1000 | OVER |
| `review.plan` | 972 | 1000 | within |
| `maintenance.docs` | 2528 | 1700 | OVER |
| `maintenance.plan` | 3199 | 1800 | OVER |
| `verification.readonly` | 309 | 500 | within |

7/11 over budget; 4/11 within. All 11 `enforcement_status: report-only`.

## Skill inventory

Source: manual inspection of `src/skills/*/SKILL.md`

- Total skills: 21
- Skills loading `lifecycle.md` at startup: 18/21
- Skills spelling out `rules/subagent/` bundles explicitly: 15/21
- Profiles remaining `report-only`: 11/11 (all)

## Controlled launch totals

Source: `wc -w` on startup files per skill (see Wave-0 stream note for method).

| Launch | Words | Target |
|---|---:|---:|
| `quick-fix` fixed launch | 3,557 | <=1,200 |
| `orchestrate` classifier launch | 5,796 | <=2,000 |

Files summed for `quick-fix`: `src/skills/quick-fix/SKILL.md` (487),
`src/rules/skill-contracts.md` (831), `src/rules/context-profiles.md` (892),
`src/rules/orchestrator/dispatch.md` (803), `docs/index.md` (114),
`docs/_meta/manifest.md` (430). Total: 3,557.

Files summed for `orchestrate`: same set with `src/skills/orchestrate/SKILL.md`
(900) replacing the quick-fix body (487), plus
`src/rules/orchestrator/lifecycle.md` (1,826) added. Total: 5,796.
