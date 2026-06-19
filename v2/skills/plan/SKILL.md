---
name: plan
description: Shape rough intent into planning output using a v2 agent workspace.
---

# /plan v2 Proof

Render a Codex agent workspace for the target repo, then read its `README.md`
first:

```sh
python3 ~/agent-docs/v2/context/render.py --repo "$PWD" --skill plan --adapter codex --role orchestrator
```

Use the workspace `README.md`, then `context.md`, as the standing workflow
context for this invocation. For planning workers, render `--role
planning-worker` and pass the worker workspace `README.md` or `context.md` path
in the worker prompt before task-specific inputs:

```text
Role:
Task:
Read this agent workspace first:
- .agent-docs/agents/<agent-id>/README.md
Input docs/plans/context:
Expected checks/evidence:
Report back with:
```

If rendering fails, report the command and setup failure. Do not fall back to
loading broad v1 workflow policy for this v2 path.
