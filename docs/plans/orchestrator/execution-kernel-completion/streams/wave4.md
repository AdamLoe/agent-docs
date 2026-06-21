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

## Batch 4: fresh-chat, start-session, list-skills, feedback-agent-docs, clear-plans, wrap-up-current-chat, doctor, rebuild-agent-docs

### Classes applied

| Skill | Class | Notes |
|---|---|---|
| `fresh-chat` | A — classifier | Keeps lifecycle.md load; routing/classification preserved |
| `start-session` | A — classifier | Keeps lifecycle.md load; state-driven routing preserved |
| `list-skills` | B — pure utility | Stripped lifecycle.md and dispatch.md loads; lean registry/frontmatter IO |
| `feedback-agent-docs` | B — pure utility | Stripped lifecycle.md and dispatch.md loads; lean capture IO |
| `clear-plans` | C — thin fixed recipe | Profile IDs; no startup lifecycle.md; maintenance.plan |
| `wrap-up-current-chat` | C — thin fixed recipe | Profile IDs; no startup lifecycle.md; maintenance.docs |
| `doctor` | C — thin fixed recipe | Profile IDs; no startup lifecycle.md; verification.readonly + repair profiles |
| `rebuild-agent-docs` | C — thin fixed recipe | Profile IDs; no startup lifecycle.md; maintenance.docs |

### Word counts

| Skill | Before | After |
|---|---:|---:|
| `fresh-chat` | 509 | 538 |
| `start-session` | 622 | 631 |
| `list-skills` | 483 | 375 |
| `feedback-agent-docs` | 709 | 622 |
| `clear-plans` | 662 | 637 |
| `wrap-up-current-chat` | 572 | 535 |
| `doctor` | 594 | 576 |
| `rebuild-agent-docs` | 576 | 576 |

### Shared policy removed

- **Spelled-out worker bundles replaced with profile IDs**: All Class C skills
  previously listed full rule file paths in dispatch (e.g.,
  `~/.agentdocs/rules/subagent/plan-maintenance.md` + `plan-lifecycle.md` +
  `authoring-rules.md` + `repo-rules.md`). Replaced with profile IDs throughout:
  `maintenance.plan`, `maintenance.docs`, `verification.readonly`,
  `implementation.code-docs`.
- **"Do NOT pre-load" prohibition added** to Class C skills: `clear-plans`,
  `wrap-up-current-chat`, `doctor`, and `rebuild-agent-docs` all now explicitly
  prohibit pre-loading `context-profiles.md`, `dispatch.md`, or `lifecycle.md`
  at startup.
- **lifecycle.md and dispatch.md stripped** from Class B: `list-skills` and
  `feedback-agent-docs` no longer load `orchestrator/lifecycle.md` or
  `orchestrator/dispatch.md`. The reads-vs-dispatch boundary is now implicit
  (inline for pure IO utilities).
- **Resolver reference added** to all skills: Workers told to resolve context
  via `bash src/verify-agent-docs.sh --resolve <profile-id>`.
- **References sections added** to Class C skills (where absent) and classifiers.
- **Copied dispatch prose removed**: "dispatch shape follows orchestrator/dispatch.md"
  inline prose removed from worker phase descriptions; pointed to References instead.

### lifecycle.md startup handling

| Skill | Class | Loads orchestrator/lifecycle.md? |
|---|---|---|
| `fresh-chat` | A | Yes — once request is known (deferred, not startup) |
| `start-session` | A | Yes — during bootstrap after Standard Intake |
| `list-skills` | B | No — stripped entirely |
| `feedback-agent-docs` | B | No — stripped entirely |
| `clear-plans` | C | No — "Do NOT pre-load" prohibition; plan-lifecycle.md only as deferred coordination reading |
| `wrap-up-current-chat` | C | No — "Do NOT pre-load" prohibition; plan-lifecycle.md only when chat wrapped a plan |
| `doctor` | C | No — "Do NOT pre-load" prohibition |
| `rebuild-agent-docs` | C | No — "Do NOT pre-load" prohibition |

### Profile IDs used

| Skill | Profiles |
|---|---|
| `fresh-chat` | `review.generic`, `review.docs` |
| `start-session` | `maintenance.plan`, `review.generic`, `verification.readonly` |
| `list-skills` | `verification.readonly` |
| `feedback-agent-docs` | `maintenance.docs`, `verification.readonly` |
| `clear-plans` | `maintenance.plan`, `maintenance.docs`, `verification.readonly` |
| `wrap-up-current-chat` | `maintenance.docs`, `maintenance.plan`, `verification.readonly` |
| `doctor` | `verification.readonly`, `maintenance.docs`, `implementation.code-docs` |
| `rebuild-agent-docs` | `maintenance.docs`, `implementation.code-docs`, `verification.readonly`, `maintenance.plan` |

### Classifier launch measurements

```
bash src/verify-agent-docs.sh --measure-launch fresh-chat
  skill-body             538
  skill-contracts        637
  context-profiles       680
  dispatch               811
  lifecycle              1037
  docs-index             114
  manifest-slots         430
  TOTAL                  4247
MEASURE-LAUNCH PASS

bash src/verify-agent-docs.sh --measure-launch start-session
  skill-body             631
  skill-contracts        637
  context-profiles       680
  dispatch               811
  lifecycle              1037
  docs-index             114
  manifest-slots         430
  TOTAL                  4340
MEASURE-LAUNCH PASS
```

Both classifiers legitimately include lifecycle.md (Class A allowlist).

### Gate results

```
bash src/verify-agent-docs.sh
→ exit 0  ALL AGENT-DOCS GATES PASS

bash src/verify-agent-docs.sh --context-report
→ exit 0  CONTEXT REPORT PASS
```

### Registry rows

No registry row updates required. Mode, worker roles, commits, intake, launch
tier, and normal-input columns remain accurate for all 8 converted skills.
