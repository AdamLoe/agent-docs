---
stream: wave6
wave: 6a
status: complete
---

# Wave 6a stream: durable migration to architecture/decisions/manifest/guide

## Files changed

| File | What changed |
|---|---|
| `src/rules/context-profiles.md:47` | Fixed stale "report-only behavioral contract" framing → "source-bound contract gate"; added `bounded-quick-fix` as example scenario; described `--contract-check` gate behavior |
| `docs/architecture/workflow-kit.md` | Added "Execution-kernel model" section (terse); expanded Main surfaces table with `src/verify-fixtures/`, `coding-style-{rust,python,frontend}.md` rows; updated verifier row to list new modes (`--resolve`, `--measure-launch`, `--contract-check`); updated Context profiles bullet to say "enforced budgets" |
| `docs/decisions/agent-docs.md` | Superseded "Context profiles before usage reports" → new "Profiles are the sole worker-context authority"; added 5 new enforced decisions: E3 budget floors, reference-leaf relocation, thin-recipe+classifier-allowlist, plan_closeout grant, source-bound contract-check gate |
| `docs/_meta/manifest.md` | Added 3 change-to-doc rows: verifier modes, verifier fixtures, reference leaves + language overlays; drift-verification section updated with new resolver/contract-check modes |
| `docs/_meta/ownership.json` | Added 5 new ownership surfaces: `context-profiles` (expanded to own enforcement + floors), `verifier-fixtures`, `reference-leaves`, `language-overlays`, `verifier-modes` |
| `src/agent-docs-guide.md` | Added "Execution-kernel model" orientation section (points to runtime rules and resolver, no prose copy); updated `--context-report` description to include `--resolve`, `--measure-launch`, `--contract-check` |

## Durable facts landed

| Fact | Landed in |
|---|---|
| Profiles are sole worker-context authority; role cards defer to resolved profile | decisions/agent-docs.md §Profiles are the sole worker-context authority; workflow-kit.md §Execution-kernel model |
| --resolve, --measure-launch, --contract-check verifier modes | decisions/agent-docs.md §Verifier modes are explicit (existing entry) + workflow-kit.md Main surfaces table; manifest change-to-doc + ownership |
| Scenario contract gates (check 7 is source-bound, not report-only) | context-profiles.md §Scenario Contract (stale prose removed); decisions/agent-docs.md §Source-bound contract-check gate |
| Reference-leaf architecture (*-reference.md leaves + coding-style overlays) | decisions/agent-docs.md §Reference-leaf relocation pattern; workflow-kit.md Main surfaces table |
| E3 enforced budget floors (planning.tracked 1600, review.docs 1200, maintenance.plan 2100; fixed 2000, classifier 3300) | decisions/agent-docs.md §Enforced budgets with correctness floors (E3) |
| Thin skill recipes and classifier allowlist | decisions/agent-docs.md §Thin-recipe skills and classifier allowlist |
| plan_closeout explicit grant for implementation.tracked | decisions/agent-docs.md §plan_closeout grant for implementation.tracked |

## Manifest/ownership coverage added

New surfaces covered in manifest change-to-doc:
- "Verifier modes: --resolve, --measure-launch, --contract-check" → src/verify-agent-docs.sh, workflow-kit.md, decisions
- "Verifier-only fixtures (scenario contract, launch baseline)" → src/verify-fixtures/, verify-agent-docs.sh, workflow-kit.md
- "Reference leaves for runtime rule files" → src/rules/*-reference.md files, workflow-kit.md
- "Conditional language-idiom overlays" → src/rules/coding-style-{rust,python,frontend}.md, context-profiles.md, workflow-kit.md

New ownership surfaces in ownership.json:
- `verifier-fixtures` (workflow-scenarios.json, baseline.md)
- `reference-leaves` (all *-reference.md leaves)
- `language-overlays` (coding-style-rust/python/frontend.md)
- `verifier-modes` (--resolve, --measure-launch, --contract-check)
- `context-profiles` expanded to own enforcement authority, budget floors, launch budget floors

## Superseded policy removed

- `context-profiles.md:47`: "report-only behavioral contract" → corrected to "source-bound contract gate"; the verifier has gated (exit nonzero) since Wave 5b

## Code bug spotted (report only)

None. No code bugs found during this docs-migration wave. (Verifier, profiles, skills, and rule contracts were not changed; all changes are durable docs/manifest/ownership/guide only.)

## Gate

- `bash src/verify-agent-docs.sh` → exit 0, `ALL AGENT-DOCS GATES PASS`
- `bash src/verify-agent-docs.sh --contract-check` → exit 0, `CONTRACT-CHECK TOTAL VIOLATIONS: 0 (enforced; gating)`, `CONTRACT-CHECK PASS`
