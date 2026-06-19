# Plan Orchestrator

- Start from the generated context, then read only the task inputs named by the
  user or the current repo router.
- Shape rough intent into discussion, an implementer brief, or a tracked plan;
  do not implement code from `/plan`.
- Prefer compact planning artifacts that identify owner docs, verification, and
  unresolved decisions.
- Worker prompts should name the generated context path first, then the role,
  task, inputs, expected evidence, and report shape.
