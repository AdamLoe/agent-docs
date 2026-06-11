---
status:        draft
owner:         unassigned
last_updated:  2026-06-08
okay_to_delete: false
long_lived:    false
owning_docs:
  - README.md
  - v1/README.md
  - v1/agent-docs-guide.md
  - v1/rules/authoring-rules.md
  - v1/rules/orchestrating.md
---

# Overhaul agent-docs: install model, orchestration, and work lifecycle (HUB)

This is the **hub plan** for a multi-stream overhaul. It holds the map:
the mission, the decisions, the streams table, the sequencing, the
target shape of the reconciled docs, and the exit gate. Each stream has its
own per-stream plan file (see [See also](#see-also)) with owned-file sets and
a ready-to-paste dispatch prompt.

## Mission

Make the kit **tool-neutral, relocatable, and easier to maintain**, and
turn the workflow into a real work lifecycle with a finish line. Today the
kit hardcodes `~/.claude/agent-docs/v1/…` as its single source of truth,
which pretends the kit belongs to Claude. The target model decouples the
checkout location, the neutral self-reference path, and the per-tool
discovery adapters:

```
/path/to/agent-docs/                      # real checkout, anywhere
~/agent-docs  -> /path/to/agent-docs      # neutral canonical alias

# Claude does NOT recurse — discovery is ~/.claude/skills/<name>/SKILL.md:
~/.claude/skills/<name> -> ~/agent-docs/v1/skills/<name>   # per-skill, coexists
#   (whole-dir symlink ~/.claude/skills only when it does not exist yet)

# Codex DOES recurse any depth under ~/.codex/skills:
~/.codex/skills/agent-docs -> ~/agent-docs/v1/skills        # one bucket, coexists
```

The kit references **itself** through `~/agent-docs/v1/…`, never through a
tool-owned path. Both `~/.claude/skills` and `~/.codex/skills` are real
discovery directories scanned by their tools, but they are wired differently
because discovery differs: Claude does not recurse, so each kit skill is
linked individually into `~/.claude/skills/` (whole-dir only when that dir
doesn't exist yet); Codex recurses, so the kit mounts as a single
`~/.codex/skills/agent-docs` bucket. **Neither adapter clobbers a user's
existing skills.** The kit is the one source both point at. Alongside that,
ordinary work gains an explicit finish command
(`/ship-current-work`), `/wrap-up-current-chat` is demoted to chat-memory
capture, and orchestration gains explicit effort levels
(`inline | light | standard | deep | max`).

**Done when** every item in [Exit gate / acceptance criteria](#exit-gate--acceptance-criteria)
is true: the old canonical path is gone, the adapter model is documented,
every skill has `name:`, `/ship-current-work` and `/rebuild-agent-docs`
exist, orchestration levels are documented and used, the authoring rule
allows router-only adapter files, this repo carries a minimal `docs/_meta/`
so it dogfoods its own workflow, README and guide agree, and the work is
committed locally (not pushed).

## This repo dogfoods the kit — read this before the streams

`agent-docs` is the **kit itself**, not a consuming app. Until now it had
**no `docs/_meta/` and no `docs/architecture` / `docs/decisions` tree at
all**, which meant the kit's own flagship commands (`/fresh-chat`,
`/ship-current-work`, `/rebuild-agent-docs`) could not actually run here —
they all read `docs/_meta/manifest.md` as step one. This overhaul fixes that:
Phase 1 adds a **minimal `docs/_meta/`** for this repo so the kit genuinely
dogfoods and the new skills are runnable and testable in their own repo.

This repo still has **no `architecture/` or `decisions/` subtree** — the
owning docs for this repo's own facts are the kit files themselves. The new
manifest's `change-to-doc` table therefore routes surfaces onto those kit
files, not onto a generic `architecture/<doc>.md`:

| Concern | Owning doc in THIS repo |
|---|---|
| Install / relocation / reference convention | [`README.md`](../../README.md) |
| Per-tool adapters, cross-tool contract, skill discovery | [`v1/README.md`](../../v1/README.md) |
| Why the system is shaped this way; workflow lifecycle narrative | [`v1/agent-docs-guide.md`](../../v1/agent-docs-guide.md) |
| Doc-authoring rules (incl. the adapter-file exception) | [`v1/rules/authoring-rules.md`](../../v1/rules/authoring-rules.md) |
| Orchestration discipline + effort levels | [`v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md) |

So "migrate into architecture/decisions at ship time" means **route durable
facts into those kit files**, and the dogfood manifest names them as the
owning docs. The plans live here in `docs/plans/` (this overhaul introduces
that dir, dogfooding the kit's own plan convention). The lifecycle/skeleton
for THIS repo are the kit's own [`v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md)
and [`v1/plan-template.md`](../../v1/plan-template.md).

> **Deviation from the upstream ChatGPT brief, recorded on purpose.** That
> brief targeted `architecture/install-and-adapters.md`,
> `decisions/agent-docs.md`, etc. Those don't exist here; targets are
> retargeted onto the real kit files above. It also called for a
> `clear-plans → clean-plans` rename — **dropped**: the real skill here is
> `clear-plans` and nothing is drifted, so that task and its grep gates are
> out of scope (owner's call). **Codex discovers skills from
> `~/.codex/skills`.**

## Scope

### In scope

- Rewrite the install/reference convention to `~/agent-docs/v1/…`; remove
  every `~/.claude/agent-docs/v1/…` self-reference (Phase 1 sweep).
- Document the three-layer model: neutral alias `~/agent-docs`, Claude
  adapter `~/.claude/skills/<name>` (per-skill, no clobber), Codex adapter
  `~/.codex/skills/agent-docs` bucket (Stream B). Keep `~/.codex/prompts`
  shims only as a documented legacy fallback.
- **Ship a setup-symlink script** (Stream B) that creates `~/agent-docs` plus
  both adapters **without clobbering existing skills** and *verifies
  resolution* — `~/agent-docs` is load-bearing for every self-reference, so its
  creation is a required install step, not a manual nicety.
- **Add a minimal `docs/_meta/` to this repo** (Phase 1) so the kit dogfoods
  its own workflow and the new skills are runnable here: `manifest.md`
  (`code_root: v1/`, a `change-to-doc` table mapping surfaces onto the kit
  files named above, `drift-gates` = the grep gates in the Exit gate) plus a
  matching `ownership.json`.
- Add `name:` frontmatter to every skill; tighten over-long frontmatter
  descriptions; trim hot-path skill bodies; teach `/list-skills` the adapter
  model (Stream C, which now folds in the former Stream G length pass).
- Add explicit orchestration effort levels and fix `/fresh-orchestrator`'s
  `$ARGUMENTS` hard-wait (Stream D).
- Add `/ship-current-work` as the normal finish command; demote
  `/wrap-up-current-chat` to chat-memory capture (Stream E).
- Convert `new-project-prompt.md` into `/rebuild-agent-docs` (Stream F).
- Relax the `AGENTS.md`/`CLAUDE.md` hard ban to "no auto-loaded **facts**;
  router-only adapter files allowed" (Stream H).
- Update README + v1/README + guide for the new model (lead, Phase 4 — from
  the [target skeletons](#target-shape-of-the-reconciled-docs)); run gates;
  commit locally.

### Out of scope

- No `~/.agent-docs/src`, no `~/.agent-docs/current`, no version-switching
  mechanism.
- No `clear-plans → clean-plans` rename (see deviation note above).
- No `architecture/`/`decisions/` subtree for this repo (the minimal
  `docs/_meta/` is the whole dogfood footprint).
- No plugin-system redesign; no consuming-app docs overhaul.
- No `git push`.

## Target decisions

Record these at ship time in the owning docs named above. Each is stated in
the kit's `Decision / Why / Applies to` shape.

1. **Neutral canonical path.** `~/agent-docs` is the neutral alias for the
   kit checkout. *Why:* the kit must reference itself without pretending it
   belongs to Claude, Codex, or any one tool. *Applies to:* `README.md`,
   `v1/README.md`, every skill body.
2. **Tool paths are adapters only.** `~/.claude/skills/<name>` (per-skill,
   since Claude doesn't recurse) and `~/.codex/skills/agent-docs` (one bucket,
   since Codex does) are discovery adapters, not source locations, and neither
   clobbers a user's existing skills. *Why:* each tool scans its own discovery
   dir while the docs model stays neutral. *Applies to:* `README.md`,
   `v1/README.md`, `/list-skills`.
3. **Router-only auto-loaded files are allowed.** `CLAUDE.md` / `AGENTS.md`
   must own no architecture/facts, but a router-only adapter file may exist
   when a tool requires one. *Why:* the real rule is "no auto-loaded fact
   dump," not "no adapter file can exist." *Applies to:*
   `v1/rules/authoring-rules.md`, `v1/README.md` (Codex adapter).
4. **Ordinary work ships through `/ship-current-work`.** It, not
   `/wrap-up-current-chat`, is the default finish command. *Why:* a normal
   task finishes by inspecting the diff, updating owning docs, running
   gates, and committing; chat-memory capture is a separate, rarer op.
   *Applies to:* `v1/README.md`, `v1/agent-docs-guide.md`, the workflow
   skills.
5. **Orchestration effort is explicit.** Large work takes one of
   `inline | light | standard | deep | max`. *Why:* "use subagents" and "go
   cheap" should be first-class controls, not implied by vague wording.
   *Applies to:* `v1/rules/orchestrating.md`, `/fresh-orchestrator`, the
   doc-maintenance skills.
6. **The kit dogfoods itself.** `agent-docs` carries a minimal `docs/_meta/`
   whose owning docs are the kit files. *Why:* a documentation-workflow kit
   that can't run its own workflow on itself can't be tested or trusted.
   *Applies to:* `docs/_meta/manifest.md`, `docs/_meta/ownership.json`.

## Approach — streams

Run this as a **standard/deep** orchestration. Mostly cheap/mid-tier
agents; reserve a strong model for the design red-team and for
contract-heavy reconciliation. **Do not spawn one agent per file — batch by
concern.**

| Stream | Concern | Owned files (primary) | Phase | Model tier |
|---|---|---|---|---|
| (Phase 1) | Mechanical path sweep `~/.claude/agent-docs/v1 → ~/agent-docs/v1` **+** create dogfood `docs/_meta/` | all (`README.md`, `v1/README.md`, all 8 skills); new `docs/_meta/*` | 1 (lead, serial, first) | cheap |
| [B](overhaul-B-install.md) | `install.sh` + the install/adapter contract (README prose comes from the skeleton, applied by the lead) | `v1/install.sh` (new); proposes README/v1-README slots | draft in 2, **applied in 4** | mid |
| [C](overhaul-C-skill-metadata.md) | `name:` frontmatter, tighten descriptions, **trim hot-path bodies** (former Stream G), `/list-skills` adapter model | `v1/skills/*/SKILL.md` | 3 (after behavioral edits) | cheap |
| [D](overhaul-D-orchestration.md) | Effort levels + `/fresh-orchestrator` `$ARGUMENTS` fix | `v1/rules/orchestrating.md`, `skills/{fresh-orchestrator,fix-docs-drift-all,review-docs}` | 2 (parallel) | mid; strong for the levels design |
| [E](overhaul-E-ship-current-work.md) | New `/ship-current-work`; demote `/wrap-up-current-chat` | `skills/ship-current-work` (new), `skills/{wrap-up-current-chat,fresh-chat}` | 2 (parallel) | mid |
| [F](overhaul-F-rebuild-agent-docs.md) | `new-project-prompt.md` → `/rebuild-agent-docs` | `skills/rebuild-agent-docs` (new), `v1/new-project-prompt.md`, `v1/template/` | 2 (parallel) | mid |
| [H](overhaul-H-authoring-adapter.md) | Router-only adapter exception in the ban | `v1/rules/authoring-rules.md` | 2 (parallel) | mid |

> **Cut from the original 8-stream plan.** Old Stream A (a pure 25-line
> string substitution) is now a Phase-1 lead task — too small for its own
> dispatch. Old Stream G (doc-length pass) is **merged into Stream C**: both
> edited every `SKILL.md`, so running them as two "coordinated" agents was
> the exact one-file-two-writers collision the rest of this plan avoids.
> One editorial pass per skill, one agent.

### Collision map (why the phases, not a flat fan-out)

The naive "all in parallel" from the upstream brief collides: many streams
edit the same files. Disjointness drives the sequencing.

- **`v1/skills/*/SKILL.md`** is contended by the Phase-1 path sweep, D/E/F
  (specific skill *behavior*), and C (cross-cutting *metadata + length* over
  **all** skills). So skills are edited in passes, not in parallel: **Phase 1
  paths first**, then **D/E/F** on *disjoint* skill subsets, then **C** as the
  final metadata/length sweep over every skill. C **verifies, not rewrites**,
  the two brand-new skills (E's `ship-current-work`, F's `rebuild-agent-docs`),
  which arrive with correct `name:`+description already — and C must not trim
  the effort-resolution sentences D adds to `fix-docs-drift-all`/`review-docs`.
- **`README.md` / `v1/README.md` / `v1/agent-docs-guide.md`** are contended
  by B, C, E, F, H. These are **lead-reconciled** in Phase 4 against the
  [target skeletons](#target-shape-of-the-reconciled-docs) — parallel agents
  must NOT write them; they return slot content keyed to a skeleton heading.
- **Rules files** (`orchestrating.md`, `authoring-rules.md`) are disjoint
  from each other and from the skills, so D and H parallelize cleanly.

## Sequencing

1. **Phase 1 — recon + foundation (lead, serial, first).**
   (a) Confirm recon (`grep -RIn '~/.claude/agent-docs/v1' v1 README.md` —
   expect 25 hits across `README.md`, `v1/README.md`, all 8 skills; the
   `~/.agent-docs/current` and `~/.agent-docs/src` forms the brief worried
   about **do not exist** here). (b) Substitute
   `~/.claude/agent-docs/v1` → `~/agent-docs/v1` everywhere; in runnable
   shell snippets prefer `"$HOME/agent-docs/v1/…"` over a quoted `~`; leave
   `~/.claude/skills` (the adapter) alone — Streams B/C handle it. (c) Create
   the dogfood `docs/_meta/manifest.md` + `ownership.json`. **Lock the exact
   slot keys now**, because Stream E's `/ship-current-work` and the drift
   skills read them by name and a mismatch fails the Phase-5 dogfood run in
   the most visible place. The manifest MUST define, with these exact keys:
   `code_root` (= `v1/`), `change-to-doc` (the table mapping surfaces onto the
   kit files above), `drift-gates` (= the assertions in the Exit gate),
   `drift-verification`, and `decisions-domains`; `ownership.json` carries the
   owning-doc map. Stream E reads these key names verbatim — do not rename
   them downstream. This de-conflicts everything: later streams edit
   already-corrected files and can rely on a real, contract-stable manifest.
2. **Phase 2 — parallel wave on disjoint files:** D, E, F, H run
   concurrently (orchestrating.md / authoring-rules.md / three disjoint
   skill subsets + two new skills / one rule edit). **B drafts** `install.sh`
   (a real file it DOES write) and returns README/v1-README slot content
   keyed to the skeleton, but does **not** write the README files.
3. **Phase 3 — skill metadata + length sweep (Stream C, after Phase 2).**
   One pass over **all** `v1/skills/*/SKILL.md`: add `name:`, tighten
   frontmatter descriptions, trim hot-path bodies, make `/list-skills`
   adapter-aware. Runs after Phase 2 so it lands on the final skill bodies;
   it verifies (does not rewrite) the two new skills and preserves D's
   effort-resolution prose.
4. **Phase 4 — lead reconciliation** of `README.md`, `v1/README.md`,
   `v1/agent-docs-guide.md` against the
   [target skeletons](#target-shape-of-the-reconciled-docs): drop each
   stream's slot content into the named heading, apply B's install rewrite,
   ship `install.sh`'s pointer, E's lifecycle section, F's rebuild pointer,
   H's authoring cross-ref, C's cross-tool-contract table edit. Enforce
   terminology consistency: `~/agent-docs`, `~/.claude/skills`,
   `~/.codex/skills`, `ship-current-work`, `rebuild-agent-docs`,
   `clear-plans` (kept), router-only `AGENTS.md`,
   `inline/light/standard/deep/max`.
5. **Phase 5 — verification + commit.** Run the gates in
   [Exit gate](#exit-gate--acceptance-criteria); with the dogfood manifest in
   place you may finish via `/ship-current-work` itself (its first real
   exercise) or a manual lead commit. Commit by filename (no `git add -A`, no
   `--no-verify`); **do not push**. Suggested message:
   `Refactor agent-docs install and workflow model`.

## Target shape of the reconciled docs

Phase 4 is **slot-filling, not composition.** Parallel streams return content
keyed to these headings; the lead drops each into place and enforces
terminology. Author/confirm these skeletons before Phase 2 so every stream
writes toward a shared contract.

### `README.md` (root — the install + reference law)

```
# agent-docs                                        [keep]
  one-line tool-neutral description                 [keep]
## Install — REQUIRED                               [B + install.sh]
  run the setup script; it creates ~/agent-docs alias
  + ~/.claude/skills + ~/.codex/skills adapters and
  verifies ~/agent-docs/v1/… resolves
## The three-layer model                            [hub Mission / B]
  checkout anywhere · ~/agent-docs alias · per-tool adapters
## Reference convention                             [B]
  self-reference is absolute via ~/agent-docs/v1/…  (why: read through a
  symlinked discovery dir); relative links inside ordinary repo Markdown ok
## Layout & versioning                              [keep, repathed]
## Per-tool setup → v1/README                       [keep]
```

### `v1/README.md` (the kit + adapters)

```
# agent-docs v1 + layout                            [keep, repathed]
## Per-app binding (docs/_meta)                      [keep]
## Getting it working
  ### Claude Code  -> ~/.claude/skills/<name> per-skill, no recurse [B]
  ### Codex        -> ~/.codex/skills/agent-docs bucket, recurses   [B]
                      ~/.codex/prompts shims = legacy fallback; router-only AGENTS.md [H]
  ### How a skill links back (absolute via ~/agent-docs) [B]
## The cross-tool contract (table)                   [C proposes the edit]
  (drop the old "tool-neutral home (optional)" note — now canonical)
```

### `v1/agent-docs-guide.md` (narrative — additive slots only)

```
## Work lifecycle                                    [E]
  /fresh-chat → work → /ship-current-work;
  /wrap-up-current-chat = chat memory; /clear-plans = sweeps;
  /fresh-orchestrator = big efforts
## Adopting / repairing agent-docs → /rebuild-agent-docs [F]
## No auto-loaded facts (router-only adapter allowed)    [H, aligned w/ rule 8]
## Effort levels pointer → orchestrating.md              [D]
```

## Exit gate / acceptance criteria

Verification commands:

These are **real assertions** — each fails (non-zero exit) when its condition
is not met, so a green run actually means something. Run as one block; the
first failure aborts. (The old draft used `grep … || true`, which can never
fail — those are now hard checks.)

```sh
fail() { echo "GATE FAIL: $*" >&2; exit 1; }

# Old canonical path GONE — assert ZERO hits (grep finding anything is failure)
grep -RIn '~/.claude/agent-docs/v1\|~/.agent-docs/current\|~/.agent-docs/src' v1 README.md \
  && fail "stale canonical path remains" || true
# new-project-prompt may survive ONLY as a deprecation pointer, never as a live entry
grep -RIn 'new-project-prompt' v1 README.md | grep -viE 'deprecat|retired|replaced by|→ /rebuild' \
  && fail "new-project-prompt still referenced as a live entry point" || true
# every skill has name: — assert NONE missing
for f in v1/skills/*/SKILL.md; do sed -n '1,12p' "$f" | grep -qE '^name:' || fail "no name: in $f"; done
# all FIVE effort levels present individually (not just one alternation match)
for lvl in inline light standard deep max; do grep -q "\b$lvl\b" v1/rules/orchestrating.md || fail "effort level '$lvl' missing"; done
# Codex bucket + Claude per-skill model documented
grep -q '~/.codex/skills/agent-docs' v1/README.md || fail "codex bucket adapter undocumented"
# dogfood manifest + ownership present
test -f docs/_meta/manifest.md && test -f docs/_meta/ownership.json || fail "dogfood _meta missing"
# manifest declares the exact slot keys ship-current-work / drift skills read
for k in code_root change-to-doc drift-gates; do grep -q "$k" docs/_meta/manifest.md || fail "manifest missing slot '$k'"; done
# setup script shipped (string gate — does NOT mutate $HOME)
test -e v1/install.sh || test -e v1/setup-symlinks.sh || fail "install script missing"
echo "ALL STRING GATES PASS"

# --- informational only (NOT gates) ---
wc -w v1/skills/*/SKILL.md | sort -n   # skill-body size report

# --- requires deliberately running the installer (mutates $HOME) — run by hand ---
# bash v1/install.sh && readlink -e ~/agent-docs/v1/rules/authoring-rules.md \
#   && readlink -e ~/.claude/skills/fresh-chat/SKILL.md \
#   && readlink -e ~/.codex/skills/agent-docs/fresh-chat/SKILL.md
```

Done when all are true:

- `~/agent-docs/v1/…` is the only canonical absolute self-reference; no doc
  requires `~/.claude/agent-docs`; no `~/.agent-docs/src|current` introduced.
- Claude adapter documented as per-skill `~/.claude/skills/<name>` (no
  recurse); Codex adapter as the `~/.codex/skills/agent-docs` bucket
  (recurses); neither clobbers the user's skills; `~/.codex/prompts` only as
  legacy fallback.
- A setup-symlink script exists and is the documented install path; it
  creates the neutral alias + both adapters and **verifies resolution**.
  ("Script shipped" is a string gate; "alias resolves" requires running the
  installer, which mutates `$HOME` — do it deliberately, not as a silent
  check.)
- This repo has a minimal `docs/_meta/manifest.md` + `ownership.json`; the
  kit's own commands can run here.
- Every skill has `name:` and `description:`.
- `/fresh-orchestrator` proceeds when `$ARGUMENTS` is present.
- `inline|light|standard|deep|max` documented and used by the relevant
  skills.
- `/ship-current-work` exists and is documented as the normal finish
  command; `/wrap-up-current-chat` is scoped to chat-history preservation.
- `/rebuild-agent-docs` exists; `new-project-prompt.md` is retired/deprecated
  with a replacement pointer.
- Authoring rules allow router-only adapter files but still ban auto-loaded
  fact dumps; no contradiction with the README's Codex guidance.
- README and guide agree; the owning kit docs reflect the new model.
- Changes committed locally, not pushed.

## Discipline rules (specific to this overhaul)

- **Parallel agents never write `README.md`, `v1/README.md`, or
  `v1/agent-docs-guide.md`** — they return slot content keyed to the
  [target skeletons](#target-shape-of-the-reconciled-docs); the lead applies
  it in Phase 4.
- **Skill files are edited in passes** (Phase 1 → D/E/F → C), never by two
  agents at once. C verifies (does not rewrite) the two new skills and keeps
  D's effort-resolution prose.
- Keep the **kept** name `clear-plans`; do not introduce `clean-plans`.
- Codex skills mount at `~/.codex/skills/agent-docs` (a bucket — Codex
  recurses); Claude skills link per-skill into `~/.claude/skills/` (no
  recursion). Neither clobbers the user's existing skills.
- Follow [`repo-rules.md`](../../v1/rules/repo-rules.md): branch off `main`
  before committing, stage by filename, no `--no-verify`, no push.

## Migration notes (filled in at ship time)

Before setting `status: shipped`, route every durable fact/decision out of
this hub and the stream files into the owning kit docs (named in the dogfood
table above):

- **`README.md`** — neutral `~/agent-docs` canonical path, the three-layer
  install model, relocation story, reference convention.
- **`v1/README.md`** — per-tool adapters (`~/.claude/skills/<name>` per-skill,
  `~/.codex/skills/agent-docs` bucket), the cross-tool contract table, skill
  discovery, the router-only `AGENTS.md` exception.
- **`v1/agent-docs-guide.md`** — the work lifecycle (`/fresh-chat` →
  `/ship-current-work`; `/wrap-up-current-chat` for chat memory;
  `/clear-plans` for sweeps; `/fresh-orchestrator` for big efforts) and the
  `/rebuild-agent-docs` adoption path.
- **`v1/rules/authoring-rules.md`** — the "no auto-loaded facts; router-only
  adapter allowed" rule wording.
- **`v1/rules/orchestrating.md`** — the effort-level table and agent-use
  policy.

Then set `status: shipped`, `okay_to_delete: true`, `last_updated` to the
ship date — only after migration is complete. Stream files become deletable
once their content is migrated or folded into this hub's notes.

## See also

- Per-stream plans: [B — install](overhaul-B-install.md) ·
  [C — skill metadata + length](overhaul-C-skill-metadata.md) ·
  [D — orchestration](overhaul-D-orchestration.md) ·
  [E — ship-current-work](overhaul-E-ship-current-work.md) ·
  [F — rebuild-agent-docs](overhaul-F-rebuild-agent-docs.md) ·
  [H — authoring adapter](overhaul-H-authoring-adapter.md)
  (Stream A folded into Phase 1; Stream G merged into C.)
- [`v1/plan-lifecycle.md`](../../v1/plan-lifecycle.md),
  [`v1/plan-template.md`](../../v1/plan-template.md) — the lifecycle/skeleton
  this repo's plans follow.
- [`v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md) — the
  operating manual for running this hub.
