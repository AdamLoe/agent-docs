---
status:        shipped
owner:         codex
last_updated:  2026-06-17
okay_to_delete: true
long_lived:    false
owning_docs:
  - architecture/workflow-kit.md
  - decisions/agent-docs.md
  - ../v1/agent-docs-guide.md
  - ../v1/rules/skill-contracts.md
  - ../v1/rules/orchestrating.md
  - ../v1/skills/registry.md
---

# Command surface cleanup

## Mission

Make the workflow command set easier for agents to choose from without
changing the core agent-docs model. The work is done when command names,
registry rows, guide text, stale-name checks, and copied adapters agree.

## Scope

In scope:

- Rename the agreed commands to clearer names.
- Fold the custom plan-review command into the general plan-review command.
- Group the skill registry by command family.
- Add concise "when not to use agent-docs" guidance.
- Move the concrete human-stop rule into shared skill contracts.
- Add compact verification-fallback guidance.
- Record future roadmap items without implementing them.

Out of scope:

- Refactoring skill files into shared standard sections.
- Adding CI, fixtures, adoption smoke tests, or template-placeholder gates.
- Expanding ownership data into a routing API now.
- Reworking orchestration plan storage.

## Target command set

- Start and plan: `fresh-chat`, `plan`, `orchestrate`.
- Implement and finish: `quick-fix`, `ship-plans`, `ship-current-work`,
  `clear-plans`, `rebuild-agent-docs`, `wrap-up-current-chat`.
- Review and maintain: `review-shipped-work`, `review-plans`,
  `review-plans-health`, `review-docs-shape`, `review-skills`, `check-docs`,
  `fix-docs-drift`, `doctor`, `list-skills`, `lodge-agent-docs-feedback`.

The general plan-review command owns both the standard high-level critique and
custom review lenses.

## Exit gate

Run:

```sh
bash v1/copy-skills.sh ~/agent-docs
bash v1/copy-skills.sh --check ~/agent-docs
bash v1/verify-agent-docs.sh
```

## Migration notes (filled in at ship time)

- Updated workflow architecture and the kit guide with the new command set.
- Recorded the command naming rationale in `docs/decisions/agent-docs.md`.
- Moved shared human-stop and verification-fallback guidance into
  `v1/rules/skill-contracts.md`.
- Folded custom plan-review behavior into `review-plans`.
- Added verifier checks for retired command names and refreshed copied skill
  adapters.

## See also

- [`../architecture/workflow-kit.md`](../architecture/workflow-kit.md)
- [`../decisions/agent-docs.md`](../decisions/agent-docs.md)
- [`../../v1/skills/registry.md`](../../v1/skills/registry.md)
- [`../../v1/rules/skill-contracts.md`](../../v1/rules/skill-contracts.md)
