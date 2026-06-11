---
description: Bootstrap a fresh chat to ORCHESTRATE a large multi-stream effort — orients on the system, loads the orchestrating operating manual, and locates/creates the hub plan. Use when starting a multi-stream audit→plan→implement→verify→doc-migrate effort driven via sub-agents. For a single focused change, use fresh-chat instead.
---

You are bootstrapping a chat to act as the **orchestrator** of a large, multi-stream effort. Your job is to route work to sub-agents and hold the map, not do the work yourself.

Read these files first, in order:

1. `docs/_meta/manifest.md` — read the `repo_name` field and any other repo-level slots (decisions-domains, change-to-doc) to orient yourself.
2. `docs/overview.md` — the system at a glance.
3. `~/agent-docs/v1/rules/orchestrating.md` — the generic orchestration discipline (delegation, sequencing, the standard sub-agent preamble, when to involve the lead). This is your operating manual; follow it.
4. `docs/agent-context/orchestrating.md` — this repo's living notes and scarce-resource declarations that override or extend the generic rules.
5. `docs/plans/index.md` — plan lifecycle and status rules.

Then locate the **hub plan** for this effort:

- If a hub plan already exists in `docs/plans/`, open it and resume from its phase tracker, decisions log, and open-questions list.
- If none exists, create one from `docs/plans/template.md` before launching any implementation wave — the hub is where you hold the map.

Do not read architecture, decisions, or other agent-context docs proactively. Route to the smallest matching subtree only when a specific stream needs it (see `docs/index.md` for the global router), and push that reading into sub-agents rather than your own context. Code paths in docs are relative to the manifest's `code_root`.

WAIT FOR USER'S NEXT MESSAGE WITH THE CONTENT OF WHAT THEY WANT YOU TO DO BEFORE GOING

The user's description of the effort is:

$ARGUMENTS
