---
status:        draft
owner:         unassigned
last_updated:  2026-06-08
okay_to_delete: false
long_lived:    false
owning_docs:
  - README.md
  - v1/README.md
---

# Stream B — install script + adapter contract

Part of [overhaul-agent-docs.md](overhaul-agent-docs.md). **Phase 2: write
`v1/install.sh` (a real file) and return slot content for the README
skeleton. The lead applies the README/v1-README prose in Phase 4** against
the [target skeletons](overhaul-agent-docs.md#target-shape-of-the-reconciled-docs)
— because B, C, E, F, and H all touch those files.

> **Scoped down from the original Stream B.** The hub now fully specifies the
> adapter model and the target README shape, so B no longer *drafts README
> prose* as a separate creative act. B ships the script and returns short
> slot content (a sentence or two per skeleton heading); the lead composes
> the final README from the skeleton.

## Mission

Replace the "kit must live at `~/.claude/agent-docs`" contract with the
three-layer model: a checkout anywhere, a neutral alias, and per-tool
discovery adapters — and ship the script that makes it real. After this
stream a reader can answer where the repo may live, what the canonical
self-reference path is, what Claude and Codex scan, and what to do if they
already have other global skills.

## The target install contract

```
The real checkout may live anywhere.

Canonical alias:
- ~/agent-docs        -> /path/to/agent-docs

Tool discovery adapters (must NOT clobber the user's existing skills —
the two tools discover differently, so they are wired differently):

- Claude does NOT recurse: it reads ~/.claude/skills/<name>/SKILL.md only.
    -> link each kit skill individually: ~/.claude/skills/<name> -> .../skills/<name>
       (whole-dir symlink ~/.claude/skills only when it does not exist yet)
- Codex DOES recurse any depth under ~/.codex/skills.
    -> one bucket symlink: ~/.codex/skills/agent-docs -> ~/agent-docs/v1/skills

The kit references itself through ~/agent-docs/v1/...  (never a tool path).
~/.codex/prompts/*.md shims remain only as a documented legacy fallback.
```

## Scope

- **In:** create `v1/install.sh` (the real, runnable script). Return slot
  content for the README and v1/README skeleton headings (install, three-layer
  model, reference convention; Claude + Codex adapters; "how a skill links
  back").
- **Out:** writing `README.md` / `v1/README.md` directly (lead applies in
  Phase 4). Out: the authoring-rule wording for adapter files (Stream H). Out:
  skill behavior text.

### Owned files

```
v1/install.sh   (new — write it)
```

## Approach

1. **Write `v1/install.sh`.** The neutral alias `~/agent-docs` is what every
   self-reference resolves through, so the install MUST NOT leave it optional
   or hand-rolled. **Verified discovery facts the script must respect:** Claude
   Code does *not* recurse — personal skills are read strictly from
   `~/.claude/skills/<name>/SKILL.md`, so a nested bucket
   (`~/.claude/skills/agent-docs/<name>/`) is NOT discovered. Codex *does*
   recurse any depth under `~/.codex/skills`. The two adapters are therefore
   asymmetric, and **neither may clobber the user's existing skills.** The
   script:
   - reads the real checkout path (arg or `git rev-parse --show-toplevel`);
   - creates `~/agent-docs -> <checkout>` (idempotent, `ln -sfn`);
   - **Claude adapter (adaptive, never clobbers):** if `~/.claude/skills`
     does not exist, whole-dir symlink it to `~/agent-docs/v1/skills` (clean,
     auto-syncs new skills); otherwise (a real dir the user owns) link each
     kit skill individually into `~/.claude/skills/<name>` and touch nothing
     else;
   - **Codex adapter (one bucket):** `~/.codex/skills/agent-docs ->
     ~/agent-docs/v1/skills` — Codex recurses, so this coexists with the
     user's skills and auto-syncs new ones with no per-skill list;
   - **verifies resolution**, not just creation: fails loudly if
     `~/agent-docs/v1/rules/authoring-rules.md`, a sample skill through the
     Claude adapter, and the same skill through the Codex bucket do not all
     resolve to real files.
   The link styles, for the README skeleton's reference:

   ```sh
   AGENT_DOCS_REPO="/path/to/agent-docs"
   ln -sfn "$AGENT_DOCS_REPO" "$HOME/agent-docs"

   # Claude — whole-dir only if the user has no skills dir yet…
   if [ ! -e "$HOME/.claude/skills" ]; then
     mkdir -p "$HOME/.claude"
     ln -sfn "$HOME/agent-docs/v1/skills" "$HOME/.claude/skills"
   else
     # …otherwise link per-skill INTO the existing dir, clobbering nothing
     for d in "$HOME/agent-docs/v1/skills"/*/; do
       ln -sfn "$d" "$HOME/.claude/skills/$(basename "$d")"
     done
   fi

   # Codex — one bucket symlink (Codex recurses), coexists + auto-syncs
   mkdir -p "$HOME/.codex/skills"
   ln -sfn "$HOME/agent-docs/v1/skills" "$HOME/.codex/skills/agent-docs"
   ```

2. **Return slot content for the README skeleton.** Short text per heading:
   - **Install — REQUIRED:** point at `v1/install.sh` as the canonical install
     path; the manual `ln` snippets stay only as "what the script does."
   - **Three-layer model / reference convention:** self-reference uses
     `~/agent-docs/v1/…`. Keep the rationale that absolute (not `../../`) is
     required because a skill is read through a symlinked discovery dir — but
     the absolute base is now the neutral alias, not the Claude path.
   - **Claude adapter:** per-skill links in `~/.claude/skills/<name>` (Claude
     doesn't recurse); whole-dir `~/.claude/skills` only on a fresh install.
     Either way it coexists with the user's own skills.
   - **Codex adapter:** `~/.codex/skills/agent-docs` — a single bucket symlink
     (Codex recurses, so it coexists and auto-syncs). Keep `~/.codex/prompts`
     shims only as a documented legacy fallback; keep the router-only
     `AGENTS.md` description, consistent with Stream H.
   Tag each snippet with the skeleton heading it fills.

## Exit gate

**Script shipped (string gate — does not touch `$HOME`):**

```sh
test -e v1/install.sh && echo "script shipped"
```

**Alias resolves (only after deliberately running the installer — this
mutates `$HOME`):**

```sh
bash v1/install.sh                 # creates ~/agent-docs + both adapters
readlink -e ~/agent-docs/v1/rules/authoring-rules.md && echo "alias resolves"
readlink -e ~/.claude/skills/fresh-chat/SKILL.md && echo "claude adapter resolves"
readlink -e ~/.codex/skills/agent-docs/fresh-chat/SKILL.md && echo "codex bucket resolves"
```

After the lead applies the slots, `README.md` + `v1/README.md` answer:

```
Where can the real repo live?            -> anywhere
What is the canonical self-reference?    -> ~/agent-docs/v1/...
What does Claude scan?                   -> ~/.claude/skills/<name> (no recurse)
What does Codex scan?                    -> ~/.codex/skills/agent-docs (recurses)
What if I already have global skills?    -> installer coexists: per-skill on
                                            Claude, agent-docs bucket on Codex
How do I set the symlinks up?            -> run v1/install.sh
```

No remaining claim that `~/.claude/skills` is a whole-dir symlink to
`~/.claude/agent-docs/v1/skills`; the installer never clobbers an existing
`~/.claude/skills`.

## Dispatch prompt

```
Task:        Write v1/install.sh (real file) AND return slot content for the README skeleton (not full prose).
Scope:       v1/install.sh is the only file you WRITE. For README/v1-README, return short text per skeleton heading; do NOT edit those files.
Files you MAY touch: v1/install.sh (new)
Files you must NOT touch: README.md, v1/README.md (lead applies in Phase 4), any skill body
Authoritative source of truth: the target install contract here + the README skeleton in the hub
Gate:        install.sh creates ~/agent-docs, the Claude adapter (per-skill links into ~/.claude/skills/, or whole-dir only if that dir is absent), and the Codex bucket ~/.codex/skills/agent-docs; it NEVER clobbers an existing ~/.claude/skills; it verifies ~/agent-docs/v1/rules/authoring-rules.md AND a sample skill through BOTH adapters RESOLVE (not just string-swapped)
Codex path:  ~/.codex/skills/agent-docs (Codex recurses). ~/.codex/prompts shims are legacy fallback only.
Discovery facts: Claude does NOT recurse (skills are ~/.claude/skills/<name>/SKILL.md — a nested bucket is NOT found); Codex DOES recurse under ~/.codex/skills.
Report back: the script + slot content tagged with the skeleton heading each fills + which existing paragraphs each replaces
Fallback:    if a current paragraph's intent is unclear, quote it and flag for the lead
```

## See also

- [overhaul-agent-docs.md](overhaul-agent-docs.md) — hub (Phase 4 reconcile,
  target skeletons).
- [overhaul-C-skill-metadata.md](overhaul-C-skill-metadata.md) — updates
  `/list-skills` to the same adapter model.
- [overhaul-H-authoring-adapter.md](overhaul-H-authoring-adapter.md) — keeps
  the router-only `AGENTS.md` rule consistent with this README guidance.
