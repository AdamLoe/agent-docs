# Repository layout

Concise inventory for this repo. For install behavior and adapter contracts,
use [`architecture/install-and-adapters.md`](architecture/install-and-adapters.md);
for workflow surfaces, use
[`architecture/workflow-kit.md`](architecture/workflow-kit.md).

| Path | Purpose |
|---|---|
| `.gitattributes` | Git attribute policy for tracked text files. |
| `.gitignore` | Ignores local capture artifacts such as the feedback inbox. |
| `README.md` | User-facing install summary. |
| `AGENTS.md` | Router-only auto-loaded file for agent tools that read it. |
| `CLAUDE.md` | Router-only auto-loaded file for Claude. |
| `docs/` | Dogfood docs for this repo. |
| `docs/_meta/manifest.md` | Repo bindings, change-to-doc map, drift gates, and decision domains. |
| `docs/_meta/ownership.json` | Structured concept ownership data. |
| `docs/architecture/` | Current architecture for install/adapters and workflow kit surfaces. |
| `docs/decisions/` | Current rationale for agent-docs architecture choices. |
| `docs/agent-context/` | Repo-local operating rules for agents working here. |
| `docs/plans/` | Plan router and lifecycle status area. |
| `v1/` | Current versioned agent-docs kit. |
| `v1/agent-docs-guide.md` | Narrative guide for adopting or repairing the docs workflow. |
| `v1/plan-lifecycle.md` | Generic plan and run-doc lifecycle rules. |
| `v1/plan-template.md` | Generic tracked-plan skeleton. |
| `v1/skills/` | Reusable workflow skill directories plus the shared registry. |
| `v1/rules/` | Generic rules shared by every consuming repo. |
| `v1/template/docs/` | Docs scaffold copied by `/rebuild-agent-docs`. |
| `v1/install.sh` | Installer for the neutral checkout and copied skill adapters. |
| `v1/copy-skills.sh` | Refresh/check script for Claude and Codex copied skills. |
| `v1/export-chatgpt-context.sh` | Repo exporter that writes grouped Markdown chunks for ChatGPT planning. |
| `v1/verify-agent-docs.sh` | Non-mutating kit drift gate, plus targetable docs scaffold checks with `--scaffold`. |

## See also

- [`index.md`](index.md)
- [`overview.md`](overview.md)
- [`architecture/workflow-kit.md`](architecture/workflow-kit.md)
- [`../v1/rules/authoring-rules.md`](../v1/rules/authoring-rules.md)
