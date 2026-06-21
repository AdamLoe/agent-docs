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

- Eager startup loads of `context-profiles.md`/`dispatch.md`/`lifecycle.md`
  removed; Bootstrap now says "Do NOT pre-load" them.
- References trimmed to a `skill-contracts.md` Owner Pointers reference (so
  measure-launch stops counting context-profiles/dispatch as launch files).
- Inline serial-editing/dispatch prose in ship-current-work/ship-plans and the
  restated model/dial policy removed — pointer to the reference only.

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

## Batch 4: classifiers, utilities, thin recipes

| Skill | Class | Before | After | lifecycle.md | Profiles |
|---|---|---:|---:|---|---|
| `fresh-chat` | A classifier | 509 | 538 | Yes (deferred, after request known) | `review.generic`, `review.docs` |
| `start-session` | A classifier | 622 | 631 | Yes (bootstrap) | `maintenance.plan`, `review.generic`, `verification.readonly` |
| `list-skills` | B utility | 483 | 375 | No — stripped | `verification.readonly` |
| `feedback-agent-docs` | B utility | 709 | 622 | No — stripped | `maintenance.docs`, `verification.readonly` |
| `clear-plans` | C recipe | 662 | 637 | No — prohibited at startup | `maintenance.plan`, `maintenance.docs`, `verification.readonly` |
| `wrap-up-current-chat` | C recipe | 572 | 535 | No — prohibited at startup | `maintenance.docs`, `maintenance.plan`, `verification.readonly` |
| `doctor` | C recipe | 594 | 576 | No — prohibited at startup | `verification.readonly`, `maintenance.docs`, `implementation.code-docs` |
| `rebuild-agent-docs` | C recipe | 576 | 576 | No — prohibited at startup | `maintenance.docs`, `implementation.code-docs`, `verification.readonly`, `maintenance.plan` |

### Changes made

- **Class A**: Replaced spelled-out worker rule paths with profile IDs for dispatch;
  kept `orchestrator/lifecycle.md` load (classifier allowlist); added References section.
- **Class B**: Stripped `orchestrator/lifecycle.md` and `orchestrator/dispatch.md` startup
  loads entirely; lean registry/IO only; worker dispatch uses profile IDs.
- **Class C**: Added "Do NOT pre-load lifecycle.md/dispatch.md/context-profiles.md"
  prohibition; replaced all spelled-out bundles with profile IDs; added resolver
  reference and References sections.

### Classifier launch measurements

```
bash src/verify-agent-docs.sh --measure-launch fresh-chat
  TOTAL 4247  MEASURE-LAUNCH PASS

bash src/verify-agent-docs.sh --measure-launch start-session
  TOTAL 4340  MEASURE-LAUNCH PASS
```

Both classifiers legitimately include lifecycle.md (Class A allowlist).

### Gate results

```
bash src/verify-agent-docs.sh          → exit 0  ALL AGENT-DOCS GATES PASS
bash src/verify-agent-docs.sh --context-report  → exit 0  CONTEXT REPORT PASS
```

Registry rows: no updates required for all 8 skills.

## Batch 5 (orchestrate)

Central Class-A classifier, converted last. Words 900 → 900 (body held at cap;
cuts paid for explicit profile IDs + References).

- **Copied policy removed**: dispatch-packet/worker-report fields, model/dial
  policy, profile tables, spelled-out subagent bundles, and restated
  worker-internal behavior — all replaced by pointers to the dispatch contract /
  `skill-contracts.md`. Commit-concurrency cut to one pointer line.
- **Profile IDs (all 11, no bundles)**: `planning.brief`/`.tracked`,
  `review.plan`, `implementation.code`/`.code-docs`/`.tracked` (`plan_closeout`
  grant), `review.generic`/`.docs`/`.plan`, `maintenance.docs`/`.plan`,
  `verification.readonly`. Workers self-resolve via `--resolve`.

**Launch**: 4609 → 3118 (−1491). dispatch (811) + context-profiles (680)
deferred; lifecycle (1037) retained. Floor = 637+1037+114+430+900 = 3118.

**Gate**: `verify-agent-docs.sh` exit 0 ALL PASS; `--measure-launch orchestrate`
exit 0 TOTAL 3118. Registry row: no update.

## Batch 6: classifier deferral parity (fresh-chat, start-session)

Deferred `dispatch.md` + `context-profiles.md` off startup for both remaining
classifiers. Removed literal `rules/orchestrator/dispatch.md` and
`rules/context-profiles.md` strings from Bootstrap and References; replaced
with skill-contracts.md Owner Pointers pointer. `lifecycle.md` retained.

| Skill | Words before→after | Launch before→after |
|---|---|---|
| `fresh-chat` | 538 → 560 | 4247 → 2778 (−1469) |
| `start-session` | 631 → 644 | 4340 → 2862 (−1478) |

All 3 classifiers now floor at ~2800–3100. Gate: exit 0 ALL AGENT-DOCS GATES PASS.
