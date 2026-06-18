# agent-docs manifest

repo_name: agent-docs
agent_docs_version: v1
code_root: v1/

## change-to-doc

| Changed surface | Owning doc |
|---|---|
| Install, relocation, canonical self-reference path | README.md, docs/architecture/install-and-adapters.md, v1/install.sh |
| Per-tool adapters, skill discovery, cross-tool contract, skill copy refresh | docs/architecture/install-and-adapters.md, v1/copy-skills.sh |
| Router-only auto-loaded files | AGENTS.md, CLAUDE.md, README.md, docs/architecture/install-and-adapters.md |
| Workflow lifecycle, adopting or repairing agent-docs | docs/architecture/workflow-kit.md, v1/agent-docs-guide.md |
| Skill registry and shared skill contracts | v1/skills/registry.md, v1/rules/skill-contracts.md, docs/architecture/workflow-kit.md |
| Repository layout inventory | docs/repository-layout.md |
| Drift gates and agent-readiness verifier | docs/_meta/manifest.md, v1/verify-agent-docs.sh |
| Doc-authoring rules and adapter-file policy | v1/rules/authoring-rules.md |
| Orchestrator workflow control, dispatch, run docs, and dials | v1/rules/orchestrator/, v1/skills/orchestrate/SKILL.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md |
| Subagent worker-role rules | v1/rules/subagent/, docs/architecture/workflow-kit.md |
| Plan lifecycle and plan skeleton | v1/plan-lifecycle.md, v1/plan-template.md |

## drift-gates

Run from the repository root:

```sh
bash v1/verify-agent-docs.sh
```

## drift-verification

The verifier above is the default non-mutating gate for this repo. Installer
resolution checks are deliberate manual checks because they mutate `$HOME`:

```sh
bash v1/install.sh
bash v1/copy-skills.sh
bash v1/copy-skills.sh --check
readlink -e ~/agent-docs/v1/rules/authoring-rules.md
readlink -e ~/.claude/skills/fresh-chat/SKILL.md
readlink -e ~/.claude/skills/plan/SKILL.md
readlink -e ~/.agents/skills/fresh-chat/SKILL.md
readlink -e ~/.agents/skills/plan/SKILL.md
```

## decisions-domains

| Domain | Owning doc |
|---|---|
| Neutral canonical path and relocation model | docs/decisions/agent-docs.md |
| Tool adapter behavior and discovery contracts | docs/decisions/agent-docs.md |
| Router-only auto-loaded files | docs/decisions/agent-docs.md, docs/architecture/install-and-adapters.md |
| Work lifecycle and rebuild flow | docs/decisions/agent-docs.md |
| Skill registry and shared skill contracts | docs/decisions/agent-docs.md, docs/architecture/workflow-kit.md |
| Authoring invariants | v1/rules/authoring-rules.md |
| Orchestrator/worker model, dials, and run-doc policy | v1/rules/orchestrator/, v1/rules/subagent/, docs/decisions/agent-docs.md |
| Plan lifecycle | v1/plan-lifecycle.md |
