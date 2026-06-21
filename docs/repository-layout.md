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
| `src/` | Current versioned agent-docs kit. |
| `src/agent-docs-guide.md` | Narrative guide for adopting or repairing the docs workflow. |
| `src/plan-lifecycle.md` | Generic plan and run-doc lifecycle rules. |
| `src/plan-template.md` | Generic tracked-plan skeleton. |
| `src/skills/` | Reusable workflow skill directories plus the shared registry. |
| `src/rules/` | Generic rules shared by every consuming repo. |
| `src/template/docs/` | Docs scaffold copied by `/rebuild-agent-docs`. |
| `src/install.sh` | Installer for the neutral checkout and copied skill adapters. |
| `src/copy-skills.sh` | Refresh/check script for Claude and Codex copied skills. |
| `src/export-chatgpt-context.sh` | Repo exporter that writes grouped Markdown chunks for ChatGPT planning. |
| `src/verify-agent-docs.sh` | Non-mutating kit drift gate, plus targetable docs scaffold checks with `--scaffold`. |

## See also

- [`index.md`](index.md)
- [`overview.md`](overview.md)
- [`architecture/workflow-kit.md`](architecture/workflow-kit.md)
- [`../src/rules/authoring-rules.md`](../src/rules/authoring-rules.md)
