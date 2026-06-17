#!/usr/bin/env bash
set -euo pipefail

die() {
  printf 'install.sh: %s\n' "$*" >&2
  exit 1
}

resolve_repo_root() {
  if [ "${1:-}" != "" ]; then
    cd "$1" && pwd
    return
  fi

  git -C "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" rev-parse --show-toplevel
}

require_resolves() {
  local path=$1
  local label=$2
  local resolved

  resolved=$(readlink -e "$path" || true)
  [ -n "$resolved" ] || die "$label did not resolve: $path"
}

repo_root=$(resolve_repo_root "${1:-}")
repo_root=${repo_root%/}

kit_root="$repo_root/v1"
kit_rules="$kit_root/rules/authoring-rules.md"
sample_skill="$kit_root/skills/fresh-chat/SKILL.md"

[ -f "$kit_rules" ] || die "missing $kit_rules"
[ -f "$sample_skill" ] || die "missing $sample_skill"

home_dir=${HOME:?HOME is not set}
home_agent_docs="$home_dir/agent-docs"
if [ "$repo_root" != "$home_agent_docs" ]; then
  if [ -e "$home_agent_docs" ] && [ ! -L "$home_agent_docs" ]; then
    die "$home_agent_docs exists and is not a symlink"
  fi
  ln -sfnT "$repo_root" "$home_agent_docs"
fi

"$repo_root/v1/copy-skills.sh" "$repo_root"

require_resolves "$home_agent_docs/v1/rules/authoring-rules.md" "authoring-rules"
require_resolves "$home_dir/.claude/skills/fresh-chat/SKILL.md" "Claude fresh-chat"
require_resolves "$home_dir/.claude/skills/plan/SKILL.md" "Claude plan"
require_resolves "$home_dir/.agents/skills/fresh-chat/SKILL.md" "Codex fresh-chat"
require_resolves "$home_dir/.agents/skills/plan/SKILL.md" "Codex plan"

printf 'agent-docs install complete\n'
