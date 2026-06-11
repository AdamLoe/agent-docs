---
status:        draft
owner:         unassigned
last_updated:  2026-06-08
okay_to_delete: false
long_lived:    false
owning_docs:
  - v1/rules/orchestrating.md
---

# Stream D — orchestration effort levels

Part of [overhaul-agent-docs.md](overhaul-agent-docs.md). **Phase 2,
parallel** — owns `orchestrating.md` plus three orchestration-related skills,
all disjoint from the other Phase-2 streams.

## Mission

Make orchestration effort a first-class, explicit control. The model/effort
guidance is **already in `orchestrating.md` as scattered prose** (per-role
model defaults, "cheapest sufficient gate", "a fresh agent is cheaper");
this stream **integrates** a single named effort dial
(`inline | light | standard | deep | max`) that sits *above* that prose as
the master control, edits the existing sentences to reference the dial
instead of restating tiers, makes the three orchestration skills resolve to
a level, and fixes the `/fresh-orchestrator` `$ARGUMENTS` contract. This is
a reconciliation, **not an append** — see the Approach.

## Scope

- **In:** one effort table + resolution rule folded into
  [`v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md) as the
  master dial, with the existing per-role/per-gate prose edited to point at
  it; making `/fresh-orchestrator`, `/fix-docs-drift-all`, `/review-docs`
  resolve a level.
- **Out:** README narrative (propose for the lead if needed); skill metadata
  / `name:` frontmatter (Stream C). Both Claude and Codex are first-class
  consumers — do **not** strip any Codex-facing path or phrasing.

### Owned files

```
v1/rules/orchestrating.md
v1/skills/fresh-orchestrator/SKILL.md
v1/skills/fix-docs-drift-all/SKILL.md
v1/skills/review-docs/SKILL.md
```

## Approach

### 1. Integrate the effort dial into `orchestrating.md` (reconcile, don't append)

`orchestrating.md` **already encodes effort as prose, scattered across four
sections.** The dial does not replace this content — it becomes the single
named control that the existing sentences then *reference* instead of
restating. Read these lines before editing; they are what you reconcile
against:

- **"How to delegate"** ([orchestrating.md:43–55](../../v1/rules/orchestrating.md))
  — already states the per-role model defaults: *"Implement — … Default
  model: the faster mid-tier model"* and *"Plan / red-team — … Default
  model: the strongest model, for planning, audit, and correctness-critical
  work."* **These per-role defaults are the source of truth for the table's
  `Model policy` column** — the column summarizes them per level, it must not
  contradict them.
- **"Resuming vs. spawning agents"** ([orchestrating.md:57–68](../../v1/rules/orchestrating.md))
  — *"don't resume an agent whose context is bloated … a fresh agent is
  cleaner and cheaper there."* This is the cost rule behind the `Agents`
  column. **Keep verbatim.**
- **Standard preamble** ([orchestrating.md:86–88](../../v1/rules/orchestrating.md))
  — *"State the cheapest sufficient gate … Explicitly forbid the full suite
  and any scarce-resource smoke per stream; those run once, as the
  consolidated end gate."* This is the gate rule the resolution note points
  back to. **Keep verbatim.**
- **"Bringing in second opinions"** ([orchestrating.md:137–145](../../v1/rules/orchestrating.md))
  — *"red-team … This is the exception, not a per-stream default — a review
  agent is a full cold-context spawn, so don't pay that cost on routine
  streams."* This is what scopes strong-model spend to `deep`/`max`.
  **Keep verbatim.**
- **"What NOT to do"** ([orchestrating.md:168–179](../../v1/rules/orchestrating.md))
  — *"Don't gate every stream with the full suite."* **Keep verbatim.**

**Fold-in decision: the table is the master dial; the existing prose is its
detail.** Add a new short section **"Effort levels"** immediately after
"When does this apply" ([after orchestrating.md:23](../../v1/rules/orchestrating.md)),
so a reader meets the dial before the mechanics. It contains exactly this
table and resolution rule:

   | Level | Meaning | Agents | Model policy |
   |---|---|---|---|
   | `inline` | do it directly | 0 | current model |
   | `light` | cheap pass | 0–1 | cheap/read-only unless clearly needed |
   | `standard` | normal multi-stream | 2–4 | mid-tier most, strong only for hard review |
   | `deep` | thorough parallel | 4–8 | mid-tier implementers, strong planner/red-team |
   | `max` | spend heavily | bounded by overlap/resources | strongest planner/red-team, broad parallelism where useful |

   Resolution rule: explicit wording wins; "cheap/quick/light" caps at
   `light`; "thorough/deep/use subagents" floors at `deep`; "all out / max /
   spend tokens" → `max`; **default `standard`** for orchestration skills.
   The `Model policy` column is a per-level summary of the per-role defaults
   in **"How to delegate"** — when they differ, that section wins. Never
   spawn agents for sequential same-file work; never run scarce-resource
   gates per stream — that is the same "cheapest sufficient gate" /
   consolidated-end-gate rule already in the **standard preamble** and **"What
   NOT to do"**, now phrased once.

**Edits to existing sentences (the reconciliation — do these, don't skip):**

- In **"How to delegate"**, append to the Implement and Plan/red-team bullets
  a back-reference so the dial owns the override, e.g. *"(this is the
  `standard` default; `deep`/`max` may raise implementers' tier or add a
  red-team — see Effort levels)."* Do **not** restate the tiers a second
  time.
- In **"Bringing in second opinions"**, prefix the red-team guidance with
  *"At `deep`/`max`,"* so the level gates the spend explicitly rather than
  by vibe. Keep the rest verbatim.
- Leave the standard-preamble gate sentence and the "What NOT to do" gate
  bullet **as-is**; the resolution note above now points back to them, so
  they are not duplicated.

Net effect: one dial, referenced from the four places that already implied
it — no new contradictory tier list.

### 2. Define the `/fresh-orchestrator` `$ARGUMENTS` contract (a UX contract, not just a removed wait)

Today the skill renders an **unconditional** wait
([SKILL.md:22](../../v1/skills/fresh-orchestrator/SKILL.md#L22), "WAIT FOR
USER'S NEXT MESSAGE …") and then immediately interpolates `$ARGUMENTS`
(line 26). That is incoherent: when the user already passed an effort
description, the skill tells the model to wait for a message that has
already arrived. The fix **defines the contract for both paths**, not just
deletes a line:

- **No-args path (`$ARGUMENTS` empty):** after the orientation reads, **ask
  the user for the effort level + a one-line description, then wait.** Offer
  the levels (`inline | light | standard | deep | max`, default `standard`)
  in the prompt so the user can pick one.
- **Args path (`$ARGUMENTS` non-empty):** treat the whole argument as the
  effort description. **Parse any leading effort level** off the front (e.g.
  `deep audit the auth streams` → level `deep`, description "audit the auth
  streams"); if no level word is present, **default `standard`** per the
  resolution rule. Then **proceed without waiting** — locate/create the hub
  and begin, do not re-ask.

Replace the unconditional `WAIT FOR …` line with this two-branch contract,
keep the `$ARGUMENTS` interpolation at the end (it feeds the args path), and
keep all orientation reads (manifest, overview, `orchestrating.md`,
repo `agent-context/orchestrating.md`, plans index) unchanged. The reads
are Claude/Codex-neutral and stay.

### 3. Per-skill effort resolution — tie each to the master dial

Keep both patches; each must say **which level it resolves to and from
what**, so the dial is the single source and the skills are consumers.

- **`/fix-docs-drift-all`** currently hardcodes *"Aim for ~5–8 agents total,
  run in parallel"* ([SKILL.md:71](../../v1/skills/fix-docs-drift-all/SKILL.md#L71)).
  Reframe that as the **`deep`** band (4–8 agents) and make it the *default
  for a whole-tree sweep*, while letting the dial scale down: a small/targeted
  `$ARGUMENTS` scope resolves to `standard` (2–4 agents) and an explicit
  "quick" to `light`. Keep the Sonnet-vs-Opus per-cluster tiering exactly as
  written — that is the `Model policy` detail for this skill — and keep the
  full/scarce-resource gates consolidated at the end (the existing
  Phase-3-commit flow already does this; do not move gates per-cluster).
- **`/review-docs`** already branches on scope in **"How to run it"**
  ([SKILL.md:93–98](../../v1/skills/review-docs/SKILL.md#L92)). Map that
  scope onto the dial explicitly: **one doc → `inline`/`light`** (read
  inline, no fan-out); **a subtree → `standard`** (sample + a few
  sub-agents); **the whole tree → `deep`** (fan out a sub-agent per cluster,
  stronger model). State it as "pick the level from scope" so it reads as a
  dial resolution, not a second unrelated heuristic.

> **Hand-off to Stream C.** The level mappings you add to
> `fix-docs-drift-all` and `review-docs` must survive the Phase-3 length pass.
> [Stream C](overhaul-C-skill-metadata.md) is instructed not to trim these
> effort-resolution sentences — keep them phrased tightly so there's nothing
> for C to "clean up."

## Exit gate

A fresh agent can answer from the docs alone: what "cheap"/"all out" mean,
how many agents each level uses, when to avoid agents, and — for both
`$ARGUMENTS` branches — what `/fresh-orchestrator` does when arguments are
passed (parse level, proceed) versus absent (ask, then wait). And: the dial
is **one** control — `orchestrating.md` has no second, contradictory tier
table; the per-role/per-gate prose now references the dial rather than
restating it.

Real assertions (each fails non-zero when unmet):

```sh
fail() { echo "GATE FAIL: $*" >&2; exit 1; }
# exactly one Effort levels section, sited near the top
[ "$(grep -c 'Effort levels' v1/rules/orchestrating.md)" -ge 1 ] || fail "no Effort levels section"
# all FIVE levels present individually (not just one alternation match)
for lvl in inline light standard deep max; do grep -q "\b$lvl\b" v1/rules/orchestrating.md || fail "level '$lvl' missing"; done
# existing tier/gate prose KEPT and back-referencing the dial
for p in 'faster mid-tier model' 'cheapest sufficient gate' 'cleaner and cheaper'; do grep -q "$p" v1/rules/orchestrating.md || fail "lost existing prose: $p"; done
# no-args branch documented AND the unconditional wait REMOVED
grep -q 'empty' v1/skills/fresh-orchestrator/SKILL.md || fail "no-args path undocumented"
grep -q 'WAIT FOR USER' v1/skills/fresh-orchestrator/SKILL.md && fail "unconditional WAIT still present" || true
# per-skill levels resolved from the dial
grep -qE '\b(deep|standard|light)\b' v1/skills/fix-docs-drift-all/SKILL.md || fail "fix-docs-drift-all has no level"
grep -qE '\b(inline|standard|deep)\b' v1/skills/review-docs/SKILL.md || fail "review-docs has no level"
echo "D GATES PASS"
```

## Dispatch prompt

```
Task:        Integrate one orchestration effort dial (inline|light|standard|deep|max) INTO orchestrating.md's existing tier/gate prose (reconcile, do not append a second table), define fresh-orchestrator's $ARGUMENTS contract (no-args: ask+wait; args: parse level, proceed), and make fix-docs-drift-all / review-docs resolve a level.
Scope:       orchestrating.md + the three named skills only. Reconcile against the prose in How-to-delegate / Resuming-vs-spawning / Standard-preamble / Second-opinions / What-NOT-to-do; do not duplicate or contradict it.
Files you MAY touch: v1/rules/orchestrating.md, v1/skills/{fresh-orchestrator,fix-docs-drift-all,review-docs}/SKILL.md
Files you must NOT touch: README.md (note requests instead), other skills, skill name: frontmatter (Stream C owns it). Do NOT strip Codex/OpenAI-facing paths or phrasing — both tools are first-class.
Authoritative source of truth: the effort table + resolution rule + reconciliation edits in this stream file's Approach. The per-role model defaults in orchestrating.md's "How to delegate" win for the Model policy column.
Gate:        grep shows ONE "Effort levels" section with all five levels; existing tier/gate prose kept and back-referencing the dial; fresh-orchestrator has both $ARGUMENTS branches and no unconditional WAIT; fix-docs-drift-all and review-docs name their levels. (see Exit gate)
Report back: the dial integration (what prose was edited vs kept), the fresh-orchestrator contract for both paths, per-skill level mappings, any ambiguity.
Fallback:    if a reconciliation is genuinely ambiguous, add the dial section + resolution rule, leave the existing prose in place with a TODO back-reference, and flag the unreconciled sentences — do not bolt on a contradictory second table.
```

## See also

- [overhaul-agent-docs.md](overhaul-agent-docs.md) — hub.
- [overhaul-F-rebuild-agent-docs.md](overhaul-F-rebuild-agent-docs.md) — the
  new `/rebuild-agent-docs` skill consumes these effort levels.
- [`v1/rules/orchestrating.md`](../../v1/rules/orchestrating.md) — the doc
  this stream owns.
