# agent-docs manifest

repo_name: agent-docs
agent_docs_version: v1
code_root: v1/

## change-to-doc

| Changed surface | Owning doc |
|---|---|
| Install, relocation, canonical self-reference path | README.md, docs/architecture/install-and-adapters.md, v1/install.sh |
| Per-tool adapters, skill discovery, cross-tool contract, skill copy refresh | docs/architecture/install-and-adapters.md, v1/copy-skills.sh |
| Workflow lifecycle, adopting or repairing agent-docs | docs/architecture/workflow-kit.md, v1/agent-docs-guide.md |
| Skill registry and shared skill contracts | v1/skills/registry.md, v1/rules/skill-contracts.md, docs/architecture/workflow-kit.md |
| Doc-authoring rules and adapter-file policy | v1/rules/authoring-rules.md |
| Orchestration discipline and dials | v1/rules/orchestrating.md |
| Plan lifecycle and plan skeleton | v1/plan-lifecycle.md, v1/plan-template.md |

## drift-gates

Run from the repository root:

```sh
fail() { echo "GATE FAIL: $*" >&2; exit 1; }

grep -RIn '[.]agent-docs/current\|[.]agent-docs/src' v1 README.md docs \
  && fail "stale canonical path remains" || true

grep -RIn 'new-project[-]prompt' v1 README.md docs/_meta docs/index.md docs/overview.md docs/architecture docs/decisions docs/agent-context | grep -viE 'deprecat|retired|replaced by|→ /rebuild' \
  && fail "retired prompt still referenced as a live entry point" || true

grep -RIn 'fresh-planning-chat' v1 README.md docs | grep -viE 'retired|v1/install[.]sh|docs/_meta/manifest[.]md' \
  && fail "renamed planning skill referenced" || true

grep -RIn 'grand-orchestrator\|fresh-orchestrator' v1 README.md docs | grep -v 'docs/_meta/manifest.md' \
  && fail "retired orchestration skill referenced" || true

grep -RIn 'docs/ownership[.]md' v1 README.md docs \
  && fail "ownership prose doc referenced instead of _meta/ownership.json" || true

for f in v1/skills/*/SKILL.md; do
  skill=${f#v1/skills/}
  skill=${skill%/SKILL.md}
  sed -n '1,12p' "$f" | grep -qE "^name: $skill$" || fail "name mismatch in $f"
  grep -q "| \`$skill\` |" v1/skills/registry.md || fail "registry missing $skill"
done

test -f v1/rules/skill-contracts.md || fail "skill contracts missing"

grep -q 'review-\[none|low|medium|high|max\]' v1/rules/skill-contracts.md || fail "review dial vocabulary missing"
grep -q 'cost-\[low|medium|high|max\]' v1/rules/skill-contracts.md || fail "cost dial vocabulary missing"

for dial in cost-low cost-medium cost-high cost-max review-none review-high; do
  grep -q "\b$dial\b" v1/rules/orchestrating.md || fail "orchestration dial '$dial' missing"
done

grep -q '~/.claude/skills/<name>' docs/architecture/install-and-adapters.md || fail "claude copy target undocumented"
grep -q '~/.agents/skills/<name>' docs/architecture/install-and-adapters.md || fail "codex copy target undocumented"

test -f docs/_meta/manifest.md && test -f docs/_meta/ownership.json || fail "dogfood _meta missing"

for k in code_root change-to-doc drift-gates; do
  grep -q "$k" docs/_meta/manifest.md || fail "manifest missing slot '$k'"
done

test -e v1/install.sh || test -e v1/setup-symlinks.sh || fail "install script missing"
test -x v1/copy-skills.sh || fail "copy-skills script missing or not executable"
bash v1/copy-skills.sh --check "$PWD" || fail "copied skill adapters are stale"
echo "ALL STRING GATES PASS"
```

## drift-verification

The string gates above are the default verification for this repo. Installer
resolution checks are deliberate manual checks because they mutate `$HOME`:

```sh
bash v1/install.sh
bash v1/copy-skills.sh
bash v1/copy-skills.sh --check
readlink -e ~/agent-docs/v1/rules/authoring-rules.md
readlink -e ~/.claude/skills/fresh-chat/SKILL.md
readlink -e ~/.claude/skills/plan/SKILL.md
readlink -e ~/.agents/skills/fresh-chat/SKILL.md
readlink -e ~/.agents/skills/plan/SKILL.md
```

## decisions-domains

| Domain | Owning doc |
|---|---|
| Neutral canonical path and relocation model | docs/decisions/agent-docs.md |
| Tool adapter behavior and discovery contracts | docs/decisions/agent-docs.md |
| Work lifecycle and rebuild flow | docs/decisions/agent-docs.md |
| Skill registry and shared skill contracts | docs/decisions/agent-docs.md, docs/architecture/workflow-kit.md |
| Authoring invariants | v1/rules/authoring-rules.md |
| Orchestration dials | v1/rules/orchestrating.md |
| Plan lifecycle | v1/plan-lifecycle.md |
