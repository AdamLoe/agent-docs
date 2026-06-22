# Doc authoring rules (agent-docs v1)

GENERIC. App-independent. Every app on agent-docs v1 follows these rules
unchanged. Anything that needs an app fact (a file path, a constant, the
change→doc table) is **not** here — it lives in the app's
`docs/_meta/manifest.md`, and this doc points at the slot.

> Agent-docs v1 fixes the docs root at `docs/` for every app. "the manifest"
> means `docs/_meta/manifest.md`; "the ownership data" means
> `docs/_meta/ownership.*`.

Anti-patterns catalogue, workflow walk-through, banned-form examples, and
app-binding slot table (do not auto-load):
[`authoring-rules-reference.md`](authoring-rules-reference.md).

## When does this apply

You shipped a code change that touched any surface named in the app's
ownership data. Or you're orchestrating a plan and need to update the
snapshot. Or you found yourself wanting to write a "v1.X introduced…"
sentence into an architecture doc — stop and read this first.

## The rules

1. **Every doc has explicit ownership.** The ownership data names one canonical
   owner per concept. Edit the owner. Non-owners may *reference* by linking;
   they must not redefine. Content on a concept a doc doesn't own is drift —
   move it to the owner and link back.

2. **Architecture docs describe what IS, not what changed.** No version-flavoured
   framing ("slice 7 introduced…", "as of v1.0.1…"). When a subsystem changes,
   rewrite the architecture doc in place — history lives in git and plans.
   Rationale for *why* goes in `decisions/<domain>.md`.

3. **Reference code by path; do not transcribe implementation code.**
   Docs carry the **map + invariants + gotchas + rationale** — never the
   code itself.

   **Recoverability test:** "Could an agent recover this by reading the named
   code file in ~30s?" If yes → transcription; replace with a `path → symbol`
   pointer. If no (map/invariant/gotcha/why) → keep it.

   **Banned forms:** full DDL, struct/enum field dumps, multi-line
   implementation or pseudocode, exhaustive enumerations. Replace with
   `path → symbol` plus only the non-obvious notes. (NOT `path:line` — line
   numbers drift.) See banned-form examples in the reference leaf.

   **Short-interface-snippet exception:** a single function signature or small
   payload shape (~≤8 lines) may sit inline for stable contracts. That is the
   ceiling.

   **Agent-context recipe exception:** a procedural doc may duplicate a
   canonical command when the reader needs a runnable checklist. Link the
   canonical owner; keep it in sync.

3a. **Do not assert a literal count of anything** unless a named CI test or
   drift gate fails when the number is wrong — then cite that gate inline.
   Otherwise point to the authoritative code symbol.

4. **Respect context layers and class budgets.** Keep always-loaded files small;
   route to the exact owner for the task.

   **Cache-stable layer:** router-only adapters, `skill-contracts.md`, manifest
   startup slots, `docs/index.md`, subtree indexes, and worker role cards.

   **Task-specific layer:** one architecture leaf, one decisions domain, one
   agent-context procedure, selected plan/run-doc, and selected source/test
   files.

   **Never-auto-loaded layer:** architecture leaves, decisions, plans, run docs,
   `agent-docs-guide.md`, full ownership JSON, repo layout, source files,
   verifier output.

   **Documentation class budgets:** routers/indexes `<=250`; overview `<=350`;
   architecture leaves `<=1,500`; decision domains/plans/run hubs `<=2,600`;
   run findings `<=1,200`; skill bodies `<=900`; role cards `<=500`. The
   verifier owns the hard word-count checks. Full budget table and layer
   rationale: reference leaf.

5. **`decisions/` is sectioned by domain, not by date.** Three mandatory fields:
   `Decision`, `Why`, `Applies to`. Four optional: `Alternatives considered`,
   `Tradeoffs`, `Code anchors` (`path → symbol_name`, NOT `path:line`),
   `Revisit when`. No `Date:` field — git log is the authority. Delete
   superseded decisions.

   > The set of decision-domain files is per-app. See the manifest's
   > `decisions-domains` slot.

6. **Cross-link liberally.** Every architecture doc must reference this rules
   doc in its `See also` so a fresh agent always finds the maintenance rules.

7. **Plans live in `docs/plans/` and carry status metadata.** Lifecycle rules:
   `~/.agentdocs/plan-lifecycle.md`; skeleton: `~/.agentdocs/plan-template.md`.
   The index is a router only. Migrate context into architecture/decisions before
   closing a plan. `okay_to_delete: true` means durable context is migrated or
   absent.

8. **No auto-loaded facts.** `CLAUDE.md`/`AGENTS.md` exist only as router-only
   adapters — no architecture, decisions, or app-specific facts. `docs/` owns
   facts; adapters own no facts.

## What changes trigger a doc update

App-specific. **Load the `change-to-doc` slot from the manifest**
(`docs/_meta/manifest.md`). For uncertain ownership, query
`docs/_meta/ownership.*`.

## Workflow when shipping a plan

1. Make the code change.
2. Update architecture doc(s) for touched surfaces. Rewrite in place.
3. Update `decisions/<domain>.md` for new decisions (three mandatory fields).
4. Migrate plan-prose context worth preserving into architecture/decisions.
5. Update frontmatter: `status`, `last_updated`, `okay_to_delete` truthfully.
6. Run the final drift gate after all mutations (`drift-gates` manifest slot).
7. Commit the verified final state. Report from that state, not pre-migration.

See the reference leaf for the detailed workflow and anti-patterns to refuse.

## See also

- Maintenance skills: `fix-docs-drift`, `check-docs-drift`, `review-docs-shape`.
- `../plan-lifecycle.md` — plan status metadata and migration rules.
- `../agent-docs-guide.md` — why the system is shaped this way.
- [`authoring-rules-reference.md`](authoring-rules-reference.md) — anti-patterns,
  worked detail, app-binding slots (do not auto-load).
