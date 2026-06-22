# agent-docs manifest

repo_name: agent-docs
agent_docs_version: v1
code_root: src/

## change-to-doc

| Changed surface | Owning doc |
|---|---|
| Install, update, runtime path, source/runtime split | README.md, docs/architecture/install-and-adapters.md, install-agentdocs-local.sh, src/install-agentdocs.sh |
| Adapters, skill discovery, cross-tool contract, managed refresh | docs/architecture/install-and-adapters.md, install-agentdocs-local.sh, src/install-agentdocs.sh |
| Router-only auto-loaded files | AGENTS.md, CLAUDE.md, README.md, docs/architecture/install-and-adapters.md |
| Workflow lifecycle, adopting/repairing agent-docs | docs/architecture/workflow-kit.md, src/agent-docs-guide.md |
| Skill registry, command bodies, shared skill contracts | src/skills/, src/skills/registry.md, src/rules/skill-contracts.md, docs/architecture/workflow-kit.md |
| Repository layout inventory | docs/repository-layout.md |
| ChatGPT context export | docs/repository-layout.md, export-chatgpt-context.sh |
| Drift gates, budget checks, context reports, and agent-readiness verifier | docs/_meta/manifest.md, src/verify-agent-docs.sh |
| Verifier modes: --resolve/--measure-launch/--contract-check | src/verify-agent-docs.sh, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md |
| Verifier-only fixtures (scenario, launch baseline) | src/verify-fixtures/, src/verify-agent-docs.sh, docs/architecture/workflow-kit.md |
| Docs scaffold template and consuming-repo scaffold checks | src/template/docs/, src/verify-agent-docs.sh, src/skills/rebuild-agent-docs/SKILL.md, src/skills/doctor/SKILL.md, src/agent-docs-guide.md, docs/architecture/workflow-kit.md |
| Execution binding (execution.yaml schema, operational + Q9 fields) | docs/_meta/execution.yaml, src/template/docs/_meta/execution.yaml, src/verify-agent-docs.sh, src/agent-docs-guide.md |
| Kernel machine authority (profiles/scenarios/workflows/packs) | src/kernel/, src/verify-agent-docs.sh, docs/architecture/workflow-kit.md |
| Doc-authoring rules, adapter-file policy | src/rules/authoring-rules.md |
| Reference leaves for runtime rules | src/rules/authoring-rules-reference.md, src/rules/skill-contracts-reference.md, src/rules/context-profiles-reference.md, src/rules/repo-rules-reference.md, src/rules/orchestrator/lifecycle-reference.md, src/rules/orchestrator/dispatch-reference.md, docs/architecture/workflow-kit.md |
| Conditional language-idiom overlays | src/rules/coding-style-rust.md, src/rules/coding-style-python.md, src/rules/coding-style-frontend.md, src/rules/context-profiles.md, docs/architecture/workflow-kit.md |
| Orchestrator workflow control, dispatch, run docs, dials | src/rules/orchestrator/, src/skills/orchestrate/SKILL.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md |
| Subagent worker-role rules | src/rules/subagent/, docs/architecture/workflow-kit.md |
| Plan lifecycle, plan skeleton | src/plan-lifecycle.md, src/plan-template.md |
| Context efficiency, profiles, and documentation budgets | src/rules/context-profiles.md, src/rules/authoring-rules.md, src/rules/skill-contracts.md, src/rules/orchestrator/dispatch.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md, src/verify-agent-docs.sh |
| Runtime usage reporting when raw counts are exposed | src/rules/orchestrator/dispatch.md, src/rules/subagent/, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md |
| Command families and skill inventory | src/skills/registry.md, docs/architecture/workflow-kit.md |
| Feedback capture inbox, ignore policy | src/skills/feedback-agent-docs/SKILL.md, docs/architecture/workflow-kit.md, docs/decisions/agent-docs.md, .gitignore |

## drift-gates

Run from the repository root:

```sh
bash src/verify-agent-docs.sh
```

## drift-verification

The verifier above is the default non-mutating gate for this repo. The two
installers preview their planned actions without mutating `$HOME`:

```sh
bash install-agentdocs-local.sh --dry-run
bash src/install-agentdocs.sh --dry-run
```

Live install mutates `$HOME`; run it deliberately, then confirm the runtime
bundle and copied adapters resolved under `~/.agentdocs/`:

```sh
bash install-agentdocs-local.sh
[ -f ~/.agentdocs/rules/authoring-rules.md ]
[ -f ~/.agentdocs/skills/fresh-chat/SKILL.md ]
[ -d ~/.claude/skills/fresh-chat ]
[ -d ~/.agents/skills/fresh-chat ]
```

Context profile reports, resolver, and contract-check gate are read-only and deterministic:

```sh
bash src/verify-agent-docs.sh --context-report
bash src/verify-agent-docs.sh --context-report --profile implementation.code
bash src/verify-agent-docs.sh --resolve implementation.tracked
bash src/verify-agent-docs.sh --measure-launch quick-fix
bash src/verify-agent-docs.sh --contract-check
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
