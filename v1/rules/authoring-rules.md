# Doc authoring rules (agent-docs v1)

GENERIC. App-independent. Every app on agent-docs v1 follows these rules
unchanged. Anything that needs an app fact (a file path, a constant, the
change→doc table) is **not** here — it lives in the app's
`docs/_meta/manifest.md`, and this doc points at the slot.

> Agent-docs v1 fixes the docs root at `docs/` for every app (no
> per-app docs-root parameter). "the manifest" means
> `docs/_meta/manifest.md`; "the ownership data" means
> `docs/_meta/ownership.*`.

## When does this apply

You shipped a code change that touched any surface named in the app's
ownership data (`docs/_meta/ownership.*`). Or you're orchestrating a
plan and need to update the snapshot. Or you found yourself wanting to
write a "v1.X introduced…" sentence into an architecture doc — stop and
read this first.

## The rules

1. **Every doc has explicit ownership.** The ownership data
   (`docs/_meta/ownership.*`) names one canonical owner per concept.
   Edit the owner. Non-owners may *reference* the concept by linking;
   they must not redefine it. If a non-owner doc starts to grow
   substantive content on a concept it doesn't own, that's drift — move
   the content to the owner and link back.

2. **Architecture docs describe what IS, not what changed.** No
   "slice 7 introduced…" / "post-ship we added…" / "as of v1.0.1…"
   framing. When a subsystem changes, the architecture doc gets
   **rewritten in place** — the history lives in the git log and (for
   the in-flight pass) in `plans/`. Rationale for *why* the new shape
   exists goes in `decisions/<domain>.md`.

3. **Reference code by path; do not transcribe implementation code.**
   Code is authoritative for behaviour; docs are authoritative for
   what's-where and why. Docs carry the **map + invariants + gotchas +
   rationale** — never the code itself.

   **The recoverability test for every sentence:** "Could an agent
   recover this by reading the named code file in ~30s? If yes, it's
   transcription — replace it with a `path → symbol` pointer. If no
   (map/invariant/gotcha/why), keep it."

   **Banned forms (always transcription):** full DDL / `CREATE TABLE`
   bodies, struct/enum field dumps, multi-line implementation or
   pseudocode, exhaustive enumerations of columns, fields, routes, or
   variants. Replace each with a `path → symbol` pointer (NOT
   `path:line` — line numbers drift) plus only the non-obvious notes:
   the invariant, the gotcha, the why.

   **Short-interface-snippet exception (capped):** a *single* function
   signature or a small payload shape (~≤8 lines) may sit inline when
   it's a stable contract. That is the ceiling. When in doubt, point to
   the symbol.

   **Exception: runnable agent-context recipes may repeat canonical
   commands.** A procedural doc may duplicate a command from an
   architecture doc when the reader needs a directly runnable checklist.
   It must link the canonical owner and stay in sync with it.

3a. **Do not assert a literal count of anything** — tables, endpoints,
   routes, variants, kinds, version constants — UNLESS a named CI test
   or drift gate fails when the number is wrong, and then **cite that
   gate inline**. Otherwise point to the code symbol that is the
   authoritative list and let the reader count.

4. **Each architecture doc is ~1–2k tokens, one file per subsystem.**
   Bigger burns context; smaller is a navigation tax. Split past ~2k.

5. **`decisions/` is sectioned by architecture domain, not by date.**
   Each entry has three **mandatory** fields — `Decision` (one sentence
   of what we believe), `Why` (the reason, one line is fine),
   `Applies to` (which architecture doc(s) it constrains) — and four
   **optional** fields included only when they add value:
   `Alternatives considered`, `Tradeoffs`, `Code anchors`
   (`path → symbol_name`, NOT `path:line`), `Revisit when`.
   **No `Date:` field** — the git log is the date authority. **Only
   carry forward decisions that still apply;** superseded rationale
   stays in git.

   > The set of decision-domain files is per-app. See the manifest's
   > `decisions-domains` slot for this app's domains.

6. **Cross-link liberally.** Each architecture doc has a `See also`
   pointing to related architecture docs, the relevant
   `decisions/<domain>.md`, and any procedural doc with overlap.
   **Every architecture doc must reference this rules doc in its
   `See also`** so a fresh agent always finds the maintenance rules.

7. **Plans live in `docs/plans/` and carry status metadata.**
   The lifecycle rules are owned by the kit file
   `~/agent-docs/v1/plan-lifecycle.md`; the skeleton by
   `~/agent-docs/v1/plan-template.md`. A repo's `docs/plans/index.md`
   is only a router and reminder, not a live inventory. **Migrate as
   much context as possible into architecture/decisions before the plan
   is closed** — the goal is for new chats to not need plan history to
   understand the current system.

8. **No auto-loaded facts.** `CLAUDE.md`, `AGENTS.md`, and equivalent
   auto-loaded files may exist only as a router-only adapter: they point
   to `docs/index.md`, `docs/overview.md`, and the relevant skill entry
   points. They must not carry architecture, decisions, or app-specific
   facts. `docs/` owns facts; adapters own no facts.

## What changes trigger a doc update

This is the table to consult before declaring a commit "done." It maps
"if you changed file X → update doc Y," and it is **entirely
app-specific**. It does **not** live here.

➜ **Load the `change-to-doc` slot from the manifest**
(`docs/_meta/manifest.md`). If your change touches a surface and
you're unsure which doc owns it, query the ownership data
(`docs/_meta/ownership.*`).

## Workflow when shipping a plan

1. Make the code change.
2. Run the per-commit gates (manifest `drift-gates` slot).
3. **Update the architecture doc(s)** that own the touched surfaces.
   Rewrite in place — don't append a version-flavoured section.
4. **Update `decisions/<domain>.md`** if the change introduces a new
   decision. Use the three mandatory + four optional fields.
5. **Migrate any plan-prose context worth preserving** into
   architecture/decisions so the plan can be `okay_to_delete: true`.
6. Commit code + doc updates together (or two adjacent commits in one
   PR).
7. Update the plan frontmatter: `status: shipped`, `okay_to_delete`
   truthfully.

## Anti-patterns to refuse

- **"Just add a quick note in a status / changelog doc."** No such doc
  exists. Route to `decisions/<domain>.md` (rationale) or
  `architecture/<doc>.md` (current state).
- **"Add a `## v1.0.1` section to the architecture doc."** Rewrite in
  place. Version-flavoured framing is what makes doc trees drift.
- **"Start every plan with an in-flight/disclaimer paragraph."** Use
  the status frontmatter.
- **"It's faster to put the launch command in this prompt too."**
  Prompts own no facts. Link to the canonical owner.
- **"Let me drop a one-liner in an auto-loaded instructions file."**
  No fact dump belongs there. If a tool requires an auto-loaded file,
  keep it as a router-only adapter and put the fact in `agent-context/<doc>`
  if procedural, `architecture/<doc>` if a fact, `decisions/<domain>` if a
  choice.
- **"This decision is superseded but I'll keep the old text."** The git
  log is the context. Delete superseded decisions.
- **"Leave this plan `long_lived` so future readers find it."** First
  migrate the context into architecture/decisions. `long_lived` is a
  rare escape hatch.

## See also (generic — resolved relative to this kit)

- The maintenance skills that route into these rules — `fix-docs-drift-all`,
  `check-docs-consistency-some`, `review-docs` (each is a self-contained
  skill under `~/.claude/skills/`; there is no separate prompt-body layer).
- `./plan-lifecycle.md` — plan status metadata and migration rules.
- `./agent-docs-guide.md` — why the system is shaped this way.

## App bindings this doc reads (from the manifest)

| Slot | What it supplies |
|---|---|
| `code_root` | the path all doc code-anchors are relative to (e.g. `app/`) |
| `change-to-doc` | the "changed file → update doc" table |
| `drift-gates` | the per-commit gate commands |
| `decisions-domains` | the app's `decisions/<domain>.md` file set |

> **Code anchors are relative to the manifest's `code_root`.** When you
> write `crates/foo/src/bar.rs → symbol`, it resolves under `code_root`,
> not the repo root and not `docs/`. State `code_root` once in the
> manifest; never repeat a code-root prefix in individual anchors.
