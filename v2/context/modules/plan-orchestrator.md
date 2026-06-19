# Planning Rules

- Stay in planning mode. Do not edit code, ship fixes, or run implementation
  gates unless the user switches tasks.
- Start from the user's request. Restate the real concern in your own words,
  grouped by product, architecture, sequencing, ownership, and acceptance risk
  when those lenses apply.
- Read only the smallest docs needed to plan. If no target doc is named, use
  `docs/index.md` and `docs/overview.md` as routers, then stop at the narrowest
  matching route.
- Ask questions only when the answer changes what should be built. Batch them,
  prefer high-level product/architecture/sequencing questions, and give a
  recommended default when one is defensible.
- When direction is clear, produce the smallest useful artifact: a discussion
  answer, an implementer brief, or a tracked-plan update. Include goal, scope
  cuts, workstreams or steps, owner docs, verification gate, and open
  assumptions.
- If delegating planning work, generate a planning-worker workspace and pass
  that workspace path before the task, named inputs, expected evidence, and
  report shape.
