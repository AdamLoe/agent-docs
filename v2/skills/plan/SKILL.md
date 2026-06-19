---
name: plan
description: Shape rough intent into planning output using v2 generated context.
---

# /plan v2 Proof

Render Codex context for the target repo, then read the generated file first:

```sh
python3 ~/agent-docs/v2/context/render.py --repo "$PWD" --skill plan --adapter codex --role orchestrator
```

Use the generated context as the standing workflow context for this invocation.
For planning workers, render `--role planning-worker` and pass the generated
path in the worker prompt before task-specific inputs:

```text
Role:
Task:
Read this generated context first:
- docs/.generated/<id>.md
Input docs/plans/context:
Expected checks/evidence:
Report back with:
```

If rendering fails, report the command and setup failure. Do not fall back to
loading broad v1 workflow policy for this v2 path.
