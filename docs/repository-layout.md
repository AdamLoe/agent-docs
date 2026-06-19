# Repository layout

Concise inventory for this repo. For install behavior and adapter contracts,
use [`architecture/install-and-adapters.md`](architecture/install-and-adapters.md);
for workflow surfaces, use
[`architecture/workflow-kit.md`](architecture/workflow-kit.md).

| Path | Purpose |
|---|---|
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
| `v1/skills/` | Reusable workflow skill directories plus the shared registry. |
| `v1/rules/` | Generic rules shared by every consuming repo. |
| `v1/template/docs/` | Docs scaffold copied by `/rebuild-agent-docs`. |
| `v1/install.sh` | Installer for the neutral checkout and copied skill adapters. |
| `v1/copy-skills.sh` | Refresh/check script for Claude and Codex copied skills. |
| `v1/verify-agent-docs.sh` | Non-mutating drift gate for this repo. |
| `v2/` | Narrow generated-context proof, currently limited to Codex `/plan` against `~/fluid-simulation`. |
| `v2/context/render.py` | Renders ignored repo-local context files from v2 YAML recipes, kit modules, target `manifest.yaml`, selected repo docs, and inline YAML text. |
| `v2/context/verify.py` | Functional verifier for the current v2 Codex `/plan` proof. |
| `v2/context/modules/` | Source Markdown modules selected by v2 context recipes. |
| `v2/skills/plan/SKILL.md` | Thin source launcher that demonstrates the v2 generated-context startup and worker-dispatch shape. |
| `v2/skills/plan/context.yaml` | Skill-local recipe for Codex `/plan` orchestrator and planning-worker context. |

Consuming repos that use the v2 proof provide `docs/_meta/manifest.yaml` and
ignore `docs/.generated/`; the generated Markdown and
`docs/.generated/generations.yaml` log are disposable and are not committed.

## See also

- [`index.md`](index.md)
- [`overview.md`](overview.md)
- [`architecture/workflow-kit.md`](architecture/workflow-kit.md)
- [`../v1/rules/authoring-rules.md`](../v1/rules/authoring-rules.md)
