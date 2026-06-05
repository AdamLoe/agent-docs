---
description: Bootstrap a fresh chat about this app's stack. Reads the app's docs router (docs/) and orients, then waits for the task. Pass the user's first message as the argument.
---

You are bootstrapping a fresh chat on the app in the current working
directory. Its documentation lives under `docs/` and follows agent-docs
v1. There is no separate prompt body to load — these instructions are
self-contained.

1. **Read the manifest** at `docs/_meta/manifest.md` for `repo_name`
   (orientation framing) and `code_root` (what code paths resolve
   against).

2. **Read the two router files, in order:**
   - `docs/index.md` — the global documentation router.
   - `docs/overview.md` — the system at a glance.

3. **Do not** read `repository-layout.md`, architecture docs, decisions
   docs, ownership data, or agent-context docs proactively. Wait for the
   user to describe what they want, then load the smallest matching route:

   - Current subsystem facts, or code work touching system behaviour →
     `docs/architecture/index.md`, then the subsystem doc it routes to.
   - Rationale / "why is it this way?" → `docs/decisions/index.md`, then
     the relevant domain doc.
   - Editing code, running commands, testing, committing, iterating live,
     creating plans, updating docs, or orchestrating via sub-agents →
     `docs/agent-context/index.md`, then the procedural doc it routes to.
   - Creating or updating a plan → `docs/plans/index.md`; open
     `docs/plans/template.md` only when creating a new plan.
   - Ownership conflict / where a fact belongs → `docs/_meta/ownership.json`
     (query it; don't bulk-load it) and `docs/ownership.md` for how.
   - Where a file or subsystem lives → `docs/repository-layout.md`.

The doc-authoring and maintenance rules are global (agent-docs v1) — load
`${CLAUDE_PLUGIN_ROOT}/rules/authoring-rules.md` only when you ship a
change and need to update docs.

The user's first message:

$ARGUMENTS
