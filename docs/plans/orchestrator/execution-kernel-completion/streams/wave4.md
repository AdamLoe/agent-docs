---
stream: wave4
skill: review-app
status: complete
---

# Wave 4 stream: review-app thin recipe conversion

## Word count

- Before: 776 words
- After: 741 words

## Shared policy removed

- **Eager startup loads removed**: Bootstrap no longer pre-loads `context-profiles.md`,
  `dispatch.md`, `run-docs.md`, or `plan-lifecycle.md`. These were loaded for every run
  regardless of whether run docs or plan creation was triggered.
- **Pre-audit confirmation stop removed**: The old "repeat the exact run shape and wait
  for approval before worker spend" gate is gone. Supplied values are now final; the skill
  proceeds directly.
- **Worker model/dial policy**: Removed restated dial defaults from the configuration
  section (they now point to `skill-contracts.md`). Dials default silently to medium.
- **Serial-editing prose**: Removed restated "serialize writes on the shared tree" in
  dispatch-level detail; now references `dispatch.md`.
- **Generic final-gate prose**: Consolidated closeout into a brief pointer to
  `dispatch.md`'s commit contract.
- **Run-doc layout**: Removed inline run-doc folder description; now says load
  `orchestrator/run-docs.md` only after user opts in.

## Profile IDs used (replacing rule-file lists)

- Audit workers: `review.generic`, `review.docs`, `review.plan`
- Plan creation: `planning.tracked`
- Workers resolve via `bash src/verify-agent-docs.sh --resolve <profile-id>`

## Concrete defaults encoded

- Dials (`review-*` / `cost-*`): `medium`
- Run state: chat-only
- App startup: off
- Screenshots: off
- Approved-plan status: `draft`
- No pre-audit "confirm this run shape" stop
- Ask only for missing choice that materially changes scope/risk/authority/irreversible work
- Normal approval gate: findings first, then user-approved plan creation
- `run-docs.md` loaded only after user opts in to run docs
- `plan-lifecycle.md` loaded only after findings approved for planning

## lifecycle.md startup load

Removed. The word `lifecycle.md` appears only in:
- Line 19–21: explicit "do NOT pre-load" / "only after" instruction
- Line 98: conditional post-approval load
- Line 120: References section (non-loading pointer)

## Gate results

```
bash src/verify-agent-docs.sh
→ exit 0  ALL AGENT-DOCS GATES PASS

bash src/verify-agent-docs.sh --context-report
→ exit 0  CONTEXT REPORT PASS
```

## Registry row

No update required. The registry row description, mode, worker roles, commits,
intake, launch, and normal-input columns remain accurate for the converted skill.
