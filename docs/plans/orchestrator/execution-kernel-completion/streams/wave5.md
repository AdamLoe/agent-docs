---
stream: wave5
skill: verify-agent-docs.sh
status: 5a complete (report-only); 5b pending (flip enforcement)
---

# Wave 5 stream: source-bound contract + launch-budget checks

## Wave 5a — checks added (report-only)

All eight checks are SOURCE-BOUND assertions over actual files (skill bodies,
role cards, profile owner, scenario fixture), not phrase matches on a
self-authored table. They emit `WARN` + a total violation count and exit 0.
Invoke with `bash src/verify-agent-docs.sh --contract-check`; also embedded as a
section in `--context-report` (full report, no `--profile`).

Documented report-only budgets (E3 floors):

- Fixed-skill controlled launch: **1800** (measured floor ~1683, quick-fix).
- Classifier controlled launch: **3200** (allowlist: orchestrate, fresh-chat,
  start-session; floor ~3118 orchestrate).

1. **Launch budgets** — per skill, compute `--measure-launch` total; warn if a
   fixed skill > 1800 or a classifier > 3200.
2. **Fixed skills must not startup-load `orchestrator/lifecycle.md`** —
   sentence/line with the lifecycle path + a read/load verb, excluding
   prohibitions ("do not"/"never"/"n't"), `- \`x\` —` reference pointers, and the
   3 classifiers.
3. **No spelled-out subagent bundles** — warn on any literal `rules/subagent/`
   path in a skill body.
4. **Review/verification read-only** — warn if `subagent/review.md` or
   `verification.md` grants edit/stage/commit authority; matches
   authority-granting wording only, excludes "Never edit, stage, or commit".
5. **Closeout authority consistency** — `plan_closeout` must appear in
   `subagent/implementation.md`, the `context-profiles.md`
   `implementation.tracked` row, and `dispatch.md`.
6. **review-app: no pre-audit confirm / no eager run-doc+plan load** —
   sentence-aware (markdown wraps mid-sentence); a violation is a sentence that
   reads/loads `run-docs.md`/`plan-lifecycle.md` (or confirms the run shape) with
   no negation or gating phrase ("only after", "after approval", "if chosen",
   "opts in", etc.).
7. **Scenario source-binding** — for each scenario row that maps cleanly to a
   skill, assert its `expected_profiles` are named in that skill body; unmappable
   rows listed as `UNMAPPED`, not failed.
8. **Report-field + final-ordering presence** — warn if `dispatch.md` Worker
   Reports lacks any required field (observed commit/dirty, sources+precedence,
   evidence, touched paths, commits, invalidation conditions) or `lifecycle.md`
   lacks the "final gate after last mutation" rule.

## FULL violation report (state basis HEAD 9e6b777, this branch)

Total: **7 violations**, all in Check 1 (launch budgets). Checks 2–8 CLEAN.

### Check 1 — launch budgets: 7 WARN (must fix for 5b)

Over the fixed-skill 1800 budget. All overruns are caused by the skill
startup-loading `context-profiles.md` (680) + `orchestrator/dispatch.md` (811)
in addition to skill-body + skill-contracts + docs-index + manifest-slots:

| Skill | launch | budget | over by |
|---|---:|---:|---:|
| `review-app` | 3413 | 1800 | 1613 |
| `clear-plans` | 3309 | 1800 | 1509 |
| `doctor` | 3248 | 1800 | 1448 |
| `rebuild-agent-docs` | 3248 | 1800 | 1448 |
| `wrap-up-current-chat` | 3207 | 1800 | 1407 |
| `fix-docs-drift` | 1826 | 1800 | 26 |
| `feedback-agent-docs` | 1803 | 1800 | 3 |

Within budget (no action): check-docs 1666, list-skills 1556, plan 1799,
quick-fix 1683, review-docs-shape 1746, review-plans-health 1788, review-plans
1658, review-shipped-work 1558, review-skills 1689, ship-current-work 1554,
ship-plans 1664. Classifiers within 3200: orchestrate 3118, fresh-chat 2778,
start-session 2862.

NOTE: review-app passes Check 6 (no eager load), yet still busts Check 1 — its
measured 3413 comes from `--measure-launch` counting `context-profiles.md` +
`dispatch.md` because their `rules/...` paths appear in its body (References +
"Do NOT pre-load" line). 5b must decide whether the measurement formula should
discount prohibition/reference mentions, or whether these skills must drop those
path strings from their bodies, before enforcement is fair.

### Checks 2–8 — CLEAN

- **2 lifecycle startup-load:** clean. Only the 3 classifiers reference
  `orchestrator/lifecycle.md`; their refs are reads + a `- … —` pointer; all
  allowlisted.
- **3 subagent bundles:** clean. No skill body contains a `rules/subagent/` path.
- **4 read-only role cards:** clean. review.md / verification.md only carry the
  "Never edit, stage, or commit" prohibition and a "commit/safety discipline"
  pointer.
- **5 plan_closeout:** clean. Present in implementation.md (L29,39),
  context-profiles.md implementation.tracked row (L37), dispatch.md (L77–78).
- **6 review-app pre-audit/eager-load:** clean. All run-doc/plan loads are gated
  ("only after the user opts in", "before creating any folder" under "if chosen",
  "After approval"); the startup line is "Do NOT pre-load"; no confirm-run-shape
  stop (only "Do not stop to reconfirm").
- **7 scenario source-binding:** clean. Mapped: bounded-quick-fix→quick-fix,
  medium-brief-plan→plan, tracked-change-plan→plan,
  dirty-tree-shipping→ship-current-work, named-plan-shipping→ship-plans,
  docs-repair→fix-docs-drift, configured-app-review→review-app — all expected
  profiles named. UNMAPPED (no clean 1:1 skill): unclear-small-work,
  report-only-review, failed-verification, resume-invalidated.
- **8 report fields + final ordering:** clean. dispatch.md Worker Reports lists
  all six required fields; lifecycle.md carries the green-gate / final-gate rule.

## 5b backlog (flip enforcement)

To make these gating, fix the 7 launch overruns first — remove eager
`context-profiles.md`/`dispatch.md` startup loads from clear-plans, doctor,
rebuild-agent-docs, wrap-up-current-chat, fix-docs-drift, feedback-agent-docs,
and resolve the review-app measurement question above. Then convert the WARN
lines to FAIL and stop the report-only carve-out.

## Gate proof

- `bash src/verify-agent-docs.sh` → exit 0, `ALL AGENT-DOCS GATES PASS` (still
  green; checks are report-only).
- `bash src/verify-agent-docs.sh --contract-check` → exit 0,
  `CONTRACT-CHECK TOTAL VIOLATIONS: 7 (report-only; not gating)`.
