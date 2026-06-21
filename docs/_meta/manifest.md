# agent-docs manifest

repo_name: agent-docs
agent_docs_version: v1
code_root: src/

## change-to-doc

| Changed surface | Owning doc |
|---|---|
| Install, relocation, canonical self-reference path | README.md, docs/architecture/install-and-adapters.md, src/install.sh |
| Per-tool adapters, skill discovery, cross-tool contract, skill copy refresh | docs/architecture/install-and-adapters.md, src/copy-skills.sh |
| Router-only auto-loaded files | AGENTS.md, CLAUDE.md, README.md, docs/architecture/install-and-adapters.md |
| Workflow lifecycle, adopting or repairing agent-docs | docs/architecture/workflow-kit.md, src/agent-docs-guide.md |
| Skill registry, command bodies, and shared skill contracts | src/skills/, src/skills/registry.md, src/rules/skill-contracts.md, docs/architecture/workflow-kit.md |
| Repository layout inventory | docs/repository-layout.md |
| ChatGPT context export utility | docs/repository-layout.md, src/export-chatgpt-context.sh |
| Drift gates, budget checks, context reports, and agent-readiness verifier | docs/_meta/manifest.md, src/verify-agent-docs.sh |
| Docs scaffold template and consuming-repo scaffold checks | src/template/docs/, src/verify-agent-docs.sh, src/skills/rebuild-agent-docs/SKILL.md, src/skills/doctor/SKILL.md, src/agent-docs-guide.md, docs/architecture/workflow-kit.md |
| Doc-authoring rules and adapter-file policy | src/rules/authoring-rules.md |
| Orchestrator workflow control, dispatch, run docs, and dials | src/rules/orchestrator/, src/skills/orchestrate/SKILL.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md |
| Subagent worker-role rules | src/rules/subagent/, docs/architecture/workflow-kit.md |
| Plan lifecycle and plan skeleton | src/plan-lifecycle.md, src/plan-template.md |
| Context efficiency, profiles, and documentation budgets | src/rules/context-profiles.md, src/rules/authoring-rules.md, src/rules/skill-contracts.md, src/rules/orchestrator/dispatch.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md, src/verify-agent-docs.sh |
| Runtime usage reporting when raw counts are exposed | src/rules/orchestrator/dispatch.md, src/rules/subagent/, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md |
| Command families and skill inventory | src/skills/registry.md, docs/architecture/workflow-kit.md |
| Feedback capture inbox and ignore policy | src/skills/feedback-agent-docs/SKILL.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md, .gitignore |

## drift-gates

Run from the repository root:

```sh
bash src/verify-agent-docs.sh
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

Context profile reports are read-only and deterministic:

```sh
bash v1/verify-agent-docs.sh --context-report
bash v1/verify-agent-docs.sh --context-report --profile implementation.code
```

## decisions-domains

| Domain | Owning doc |
|---|---|
| Neutral canonical path and relocation model | docs/decisions/agent-docs.md |
| Tool adapter behavior and discovery contracts | docs/decisions/agent-docs.md |
| Router-only auto-loaded files | docs/decisions/agent-docs.md, docs/architecture/install-and-adapters.md |
| Work lifecycle and rebuild flow | docs/decisions/agent-docs.md |
| Skill registry and shared skill contracts | docs/decisions/agent-docs.md, docs/architecture/workflow-kit.md |
| Authoring invariants | src/rules/authoring-rules.md |
| Context efficiency, profiles, documentation budgets, and runtime usage reporting | docs/decisions/agent-docs.md, docs/architecture/workflow-kit.md, src/rules/authoring-rules.md |
| Orchestrator/worker model, dials, and run-doc policy | src/rules/orchestrator/, src/rules/subagent/, docs/decisions/agent-docs.md |
| Plan lifecycle | src/plan-lifecycle.md |
| Feedback capture inbox and ignore policy | docs/decisions/agent-docs.md, docs/architecture/workflow-kit.md |
