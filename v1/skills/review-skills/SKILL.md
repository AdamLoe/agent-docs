---
name: review-skills
description: Review the agent-docs skill set for drift, duplicate policy, adapter assumptions, and lifecycle gaps.
---

You are reviewing the agent-docs skill set itself. This is a report-only
maintenance review over `v1/skills/`, the shared skill registry, and the kit
guide/rules that describe the skills. Do not edit or commit unless the user
explicitly asks you to apply fixes.

This skill runs directly — no intake questions. It honors any dials passed in
`$ARGUMENTS` per `v1/rules/skill-contracts.md` (read below as a review target).

## Bootstrap

1. Read `v1/skills/registry.md`.
2. Read `v1/agent-docs-guide.md`, especially the maintenance and work
   lifecycle sections.
3. Read `v1/rules/skill-contracts.md`, `v1/rules/repo-rules.md`, and
   `v1/rules/orchestrating.md`.
4. Inventory `v1/skills/*/SKILL.md` and compare each directory name,
   frontmatter `name:`, description, and registry row.

## Review Lens

Check for:

- Registry drift: missing skills, stale names, incorrect mode/action/commit
  metadata, or guide text that lists an old command.
- Duplicate policy: repeated bootstrap, shipping, commit, model-tier, or docs
  ownership instructions that should move into a shared rule.
- Mode contradictions: a report-only skill that says to edit, a mutating skill
  that does not say how to verify, or a commit-capable skill that lacks the
  green-tree requirement.
- Adapter leakage: tool-specific roots, hardcoded vendor model names, or
  assumptions about one agent platform that should be generic.
- Lifecycle gaps: missing entry points for common work, confusing overlap
  between skills, or stale handoffs such as a renamed command.
- Argument behavior: missing `$ARGUMENTS`, vague missing-input handling, or a
  skill that should ask before proceeding but does not.

## Report Format

Write a concise findings-first memo:

1. **Verdict** - whether the skill set is coherent enough to trust.
2. **Findings** - ordered by impact, each as `area -> issue -> fix`.
3. **Duplicate Policy To Extract** - repeated rules that should move to
   `v1/rules/skill-contracts.md` or another shared rule.
4. **Registry / Guide Drift** - concrete mismatches.
5. **Leave Alone** - skills or separations that are working and should not be
   churned.
6. **Next Step** - whether to apply small fixes, draft a plan, or leave it.

$ARGUMENTS
