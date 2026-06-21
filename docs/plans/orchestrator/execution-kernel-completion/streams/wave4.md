---
stream: wave4
skill: review-app, quick-fix, plan, ship-current-work, ship-plans
status: complete
---

# Wave 4 stream: thin recipe conversions

## Batch 1: review-app (previously recorded)

- Before: 776 words / After: 741 words
- lifecycle.md: not loaded at startup (conditional post-approval load only)
- Profile IDs used: `review.generic`, `review.docs`, `review.plan`, `planning.tracked`

## Batch 2: quick-fix, plan, ship-current-work, ship-plans

### Word counts

| Skill | Before | After |
|---|---:|---:|
| `quick-fix` | 487 | 502 |
| `plan` | 619 | 618 |
| `ship-current-work` | 407 | 373 |
| `ship-plans` | 464 | 483 |

### Shared policy removed

- **Eager startup loads removed**: Bootstrap sections no longer load
  `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at startup. Each
  skill's Bootstrap now says "Do NOT pre-load" these files explicitly.
- **References section trimmed**: Full paths to `context-profiles.md` and
  `dispatch.md` removed from inline References sections; replaced with pointer
  to `skill-contracts.md` Owner Pointers (which already links both). This
  prevents measure-launch from counting them as launch files.
- **Inline dispatch prose removed** from ship-current-work and ship-plans:
  removed restated "editing workers are serial on the shared tree" and similar
  prose that duplicates `dispatch.md`. Workers are now directed to the reference
  only.
- **Generic model/dial policy not restated**: Dials and model policy referenced
  via skill-contracts.md only.

### lifecycle.md startup load

Removed from all 4 skills. Occurrences by skill:
- `quick-fix`: line in "Do NOT pre-load" prohibition only
- `plan`: line in "Do NOT pre-load" prohibition only
- `ship-current-work`: line in "Do NOT pre-load" prohibition only
- `ship-plans`: "Do NOT pre-load" prohibition + conditional deferred load
  (`~/.agentdocs/plan-lifecycle.md` loaded only when plan status/migration
  decisions require it) + pointer in References section

### Profile IDs used

| Skill | Profiles |
|---|---|
| `quick-fix` | `planning.brief` (optional), `implementation.code` / `implementation.code-docs`, `verification.readonly`, `review.generic` |
| `plan` | `planning.brief`, `planning.tracked`, `review.plan`, `maintenance.docs` |
| `ship-current-work` | `review.generic`, `maintenance.docs`, `maintenance.plan`, `implementation.code-docs`, `verification.readonly` |
| `ship-plans` | `planning.tracked`, `implementation.tracked` (with `plan_closeout` grant), `review.plan`, `review.generic`, `maintenance.plan`, `verification.readonly` |

### Quick-fix launch measurement

```
bash src/verify-agent-docs.sh --measure-launch quick-fix
  skill-body             502
  skill-contracts        637
  docs-index             114
  manifest-slots         430
  TOTAL                  1683
MEASURE-LAUNCH PASS
```

Before (pre-batch-2): 3012 words. After: 1683 words. Drop: 1329 words (44%).
context-profiles (680) and dispatch (811) no longer detected as startup loads.

### Gate results

```
bash src/verify-agent-docs.sh
→ exit 0  ALL AGENT-DOCS GATES PASS

bash src/verify-agent-docs.sh --measure-launch quick-fix
→ exit 0  MEASURE-LAUNCH PASS  TOTAL 1683
```

### Registry rows

No registry row updates required. Mode, worker roles, commits, intake, launch
tier, and normal-input columns remain accurate for all 4 converted skills.

## Batch 3: check-docs, fix-docs-drift, review-docs-shape, review-plans, review-plans-health, review-shipped-work, review-skills

### Word counts

| Skill | Before | After |
|---|---:|---:|
| `check-docs` | 510 | 485 |
| `fix-docs-drift` | 656 | 645 |
| `review-docs-shape` | 567 | 565 |
| `review-plans` | 453 | 477 |
| `review-plans-health` | 605 | 607 |
| `review-shipped-work` | 391 | 377 |
| `review-skills` | 499 | 508 |

### Shared policy removed

- **Eager startup loads removed**: All 7 Bootstrap sections now include "Do NOT
  pre-load `context-profiles.md`, `dispatch.md`, or `lifecycle.md` at startup."
- **Spelled-out worker bundles replaced with profile IDs**: Every worker
  dispatch now names a profile ID (e.g. `maintenance.docs`, `review.generic`,
  `review.plan`, `review.docs`, `maintenance.plan`, `implementation.code-docs`,
  `verification.readonly`). The old pattern of listing
  `~/.agentdocs/rules/subagent/docs-maintenance.md` + `authoring-rules.md` +
  `repo-rules.md` inline in dispatch descriptions is removed.
- **Generic dispatch/lifecycle prose removed**: Inline "dispatch shape follows
  `orchestrator/dispatch.md`", model-tier policy, and serial-editing prose that
  duplicates `dispatch.md` removed. Pointed to `skill-contracts.md` Owner
  Pointers instead.
- **References sections added** to all 7 skills (previously absent from most),
  with "do not auto-load" markers.

### lifecycle.md startup load

Removed from all 7 skills. Every skill has "Do NOT pre-load ... `lifecycle.md`"
in Bootstrap. Two plan-focused skills (`review-plans`, `review-plans-health`)
retain `plan-lifecycle.md` as deferred coordination reading (before dispatch,
not at startup) — matching the established pattern from `review-app`.

### Profile IDs used

| Skill | Profiles |
|---|---|
| `check-docs` | `maintenance.docs` (read-only drift lens), `verification.readonly` |
| `fix-docs-drift` | `maintenance.docs`, `review.generic`, `verification.readonly`, `implementation.code-docs` |
| `review-docs-shape` | `review.docs`, `review.generic` |
| `review-plans` | `review.plan`, `planning.tracked` |
| `review-plans-health` | `maintenance.plan`, `review.generic` |
| `review-shipped-work` | `review.generic`, `implementation.code-docs`, `maintenance.docs`, `maintenance.plan`, `verification.readonly` |
| `review-skills` | `review.generic`, `review.docs`, `verification.readonly` |

### Gate results

```
bash src/verify-agent-docs.sh
→ exit 0  ALL AGENT-DOCS GATES PASS

bash src/verify-agent-docs.sh --context-report
→ exit 0  CONTEXT REPORT PASS
```

### Registry rows

No registry row updates required. Mode, worker roles, commits, intake, and
launch tier columns remain accurate for all 7 converted skills.
