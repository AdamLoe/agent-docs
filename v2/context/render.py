#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import re
import secrets
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ID_RE = re.compile(r"^[A-Za-z0-9_-]{8,64}$")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
GENERATOR_VERSION = "v2-agent-workspace-proof-1"


class ContextRenderError(Exception):
    pass


@dataclass(frozen=True)
class SourceRecord:
    source: str
    label: str
    path: str
    digest: str
    heading: str | None = None


@dataclass(frozen=True)
class RenderResult:
    id: str
    workspace: Path
    relative_workspace: str
    readme: Path
    relative_readme: str
    context: Path
    relative_context: str
    sources_file: Path
    relative_sources_file: str
    workspace_root: Path
    relative_workspace_root: str
    sources: list[SourceRecord]
    byte_count: int


def kit_root() -> Path:
    return Path(__file__).resolve().parents[2]


def load_yaml_file(path: Path) -> dict[str, Any]:
    try:
        import yaml
    except ImportError as exc:  # pragma: no cover - exercised only on lean hosts.
        raise ContextRenderError("PyYAML is required for v2 context rendering") from exc

    if not path.is_file():
        raise ContextRenderError(f"missing YAML input: {path}")

    text = path.read_text(encoding="utf-8")
    reject_unsupported_yaml_profile(path, text)

    loaded = yaml.safe_load(text)
    if not isinstance(loaded, dict):
        raise ContextRenderError(f"YAML root must be a mapping: {path}")
    return loaded


def reject_unsupported_yaml_profile(path: Path, text: str) -> None:
    for line_number, line in enumerate(text.splitlines(), start=1):
        if "\t" in line:
            raise ContextRenderError(f"tabs are not allowed in YAML: {path}:{line_number}")
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("<<:"):
            raise ContextRenderError(f"YAML merge keys are not allowed: {path}:{line_number}")
        if re.search(r"(^|[\s\[{,:])&[A-Za-z0-9_-]+", line):
            raise ContextRenderError(f"YAML anchors are not allowed: {path}:{line_number}")
        if re.search(r"(^|[\s\[{,:])\*[A-Za-z0-9_-]+", line):
            raise ContextRenderError(f"YAML aliases are not allowed: {path}:{line_number}")
        if re.search(r"(^|[\s\[{,:])![A-Za-z]", line):
            raise ContextRenderError(f"YAML tags are not allowed: {path}:{line_number}")


def require_mapping(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ContextRenderError(f"{label} must be a mapping")
    return value


def require_list(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise ContextRenderError(f"{label} must be a list")
    return value


def require_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value:
        raise ContextRenderError(f"{label} must be a non-empty string")
    return value


def safe_relative_path(root: Path, relative_path: str, label: str) -> Path:
    candidate = Path(relative_path)
    if candidate.is_absolute():
        raise ContextRenderError(f"{label} must be relative: {relative_path}")

    resolved_root = root.resolve()
    resolved = (resolved_root / candidate).resolve()
    try:
        resolved.relative_to(resolved_root)
    except ValueError as exc:
        raise ContextRenderError(f"{label} escapes root: {relative_path}") from exc
    return resolved


def relative_to_root(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def sha256_short(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()[:16]


def normalize_heading(value: str) -> str:
    value = value.strip()
    value = re.sub(r"^#{1,6}\s+", "", value)
    value = re.sub(r"\s+#*$", "", value)
    return re.sub(r"\s+", " ", value).strip().casefold()


def extract_heading(text: str, heading: str, path: Path) -> str:
    wanted = normalize_heading(heading)
    lines = text.splitlines()
    start: int | None = None
    level: int | None = None

    for index, line in enumerate(lines):
        match = HEADING_RE.match(line)
        if not match:
            continue
        if normalize_heading(match.group(2)) == wanted:
            start = index
            level = len(match.group(1))
            break

    if start is None or level is None:
        raise ContextRenderError(f"heading not found in {path}: {heading}")

    end = len(lines)
    for index in range(start + 1, len(lines)):
        match = HEADING_RE.match(lines[index])
        if match and len(match.group(1)) <= level:
            end = index
            break

    return "\n".join(lines[start:end]).strip() + "\n"


def load_manifest(repo_root: Path) -> dict[str, Any]:
    manifest_path = repo_root / "docs" / "_meta" / "manifest.yaml"
    manifest = load_yaml_file(manifest_path)
    if manifest.get("schema_version") != 2:
        raise ContextRenderError("docs/_meta/manifest.yaml must set schema_version: 2")

    repo = require_mapping(manifest.get("repo"), "manifest repo")
    require_string(repo.get("name"), "manifest repo.name")
    if repo.get("agent_docs_version") != "v2":
        raise ContextRenderError("manifest repo.agent_docs_version must be v2")
    require_string(repo.get("code_root"), "manifest repo.code_root")

    metadata = require_mapping(manifest.get("metadata"), "manifest metadata")
    workspace = require_mapping(
        metadata.get("agent_workspace"), "manifest metadata.agent_workspace"
    )
    root = require_string(workspace.get("root"), "manifest agent_workspace.root")
    if workspace.get("committed") is not False:
        raise ContextRenderError("manifest agent_workspace.committed must be false")
    if root.rstrip("/") != ".agent-docs/agents":
        raise ContextRenderError("agent workspace root must be .agent-docs/agents")

    return manifest


def workspace_paths(repo_root: Path, manifest: dict[str, Any]) -> tuple[Path, str]:
    workspace = manifest["metadata"]["agent_workspace"]
    root_rel = workspace["root"].rstrip("/")
    root = safe_relative_path(repo_root, root_rel, "agent_workspace.root")
    return root, root_rel


def check_workspace_root_ignored(repo_root: Path, root_rel: str) -> str:
    probe = f"{root_rel.rstrip('/')}/test/README.md"
    result = subprocess.run(
        ["git", "-C", str(repo_root), "check-ignore", "-v", probe],
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        suffix = f": {detail}" if detail else ""
        raise ContextRenderError(f"agent workspace path is not ignored: {probe}{suffix}")
    return result.stdout.strip()


def load_context_config(skill: str) -> tuple[Path, dict[str, Any]]:
    config_path = kit_root() / "v2" / "skills" / skill / "context.yaml"
    config = load_yaml_file(config_path)
    if config.get("schema_version") != 1:
        raise ContextRenderError(f"{config_path} must set schema_version: 1")
    if config.get("skill") != skill:
        raise ContextRenderError(f"{config_path} skill must be {skill}")
    return config_path, config


def validate_adapter(config: dict[str, Any], adapter: str) -> None:
    supported = config.get("supported_adapters", [])
    if adapter not in supported:
        raise ContextRenderError(f"unsupported adapter for this context recipe: {adapter}")


def target_recipe(config: dict[str, Any], role: str) -> dict[str, Any]:
    targets = require_mapping(config.get("targets"), "context targets")
    target = require_mapping(targets.get(role), f"context target {role}")
    require_list(target.get("includes"), f"context target {role}.includes")
    return target


def include_to_text(
    include: dict[str, Any],
    repo_root: Path,
    target_manifest: dict[str, Any],
) -> tuple[str, SourceRecord]:
    source = require_string(include.get("source"), "include.source")
    label = require_string(include.get("label"), "include.label")
    heading = include.get("heading")
    if heading is not None:
        heading = require_string(heading, "include.heading")

    if source == "inline":
        text = require_string(include.get("text"), f"inline include {label}.text")
        record = SourceRecord(
            source=source,
            label=label,
            path="v2/skills/plan/context.yaml",
            digest=sha256_short(text),
            heading=None,
        )
        return text.strip() + "\n", record

    if source == "manifest":
        repo = target_manifest["repo"]
        workspace = target_manifest["metadata"]["agent_workspace"]
        agent_context = target_manifest.get("agent_context", {})
        lines = [
            f"- repo: {repo['name']}",
            f"- agent_docs_version: {repo['agent_docs_version']}",
            f"- code_root: {repo['code_root']}",
            f"- agent_workspace.root: {workspace['root']}",
            "- agent_workspace.committed: false",
        ]
        if isinstance(agent_context, dict):
            index = agent_context.get("index")
            orchestrating = agent_context.get("orchestrating")
            if isinstance(index, str) and index:
                lines.append(f"- agent_context.index: {index}")
            if isinstance(orchestrating, str) and orchestrating:
                lines.append(f"- agent_context.orchestrating: {orchestrating}")
        text = "\n".join(lines) + "\n"
        record = SourceRecord(
            source=source,
            label=label,
            path="docs/_meta/manifest.yaml",
            digest=sha256_short(text),
            heading=None,
        )
        return text, record

    if source == "kit":
        include_path = require_string(include.get("path"), f"kit include {label}.path")
        path = safe_relative_path(kit_root(), include_path, f"kit include {label}.path")
        root = kit_root()
    elif source == "repo":
        include_path = require_string(include.get("path"), f"repo include {label}.path")
        path = safe_relative_path(repo_root, include_path, f"repo include {label}.path")
        root = repo_root
    else:
        raise ContextRenderError(f"unknown include source: {source}")

    if not path.is_file():
        raise ContextRenderError(f"include path does not exist: {path}")
    raw = path.read_text(encoding="utf-8")
    text = extract_heading(raw, heading, path) if heading else raw.strip() + "\n"
    record = SourceRecord(
        source=source,
        label=label,
        path=relative_to_root(path, root),
        digest=sha256_short(text),
        heading=heading,
    )
    return text, record


def allocate_id(workspace_root: Path) -> str:
    workspace_root.mkdir(parents=True, exist_ok=True)
    for _ in range(100):
        candidate = secrets.token_urlsafe(9)
        if not ID_RE.match(candidate):
            continue
        if not (workspace_root / candidate).exists():
            return candidate
    raise ContextRenderError("could not allocate a collision-free agent id")


def created_at_timestamp() -> str:
    return (
        datetime.now(timezone.utc)
        .replace(microsecond=0)
        .isoformat()
        .replace("+00:00", "Z")
    )


def demote_headings(text: str) -> str:
    lines: list[str] = []
    for line in text.strip().splitlines():
        if HEADING_RE.match(line):
            lines.append("#" + line)
        else:
            lines.append(line)
    return "\n".join(lines).strip()


def render_readme(
    *,
    agent_id: str,
    repo_root: Path,
    skill: str,
    adapter: str,
    role: str,
) -> str:
    return "\n".join(
        [
            "# Agent Workspace",
            "",
            f"- agent_id: {agent_id}",
            f"- role: {role}",
            f"- skill: {skill}",
            f"- adapter: {adapter}",
            f"- target_repo: {repo_root}",
            "",
            "## File Order",
            "",
            "1. `README.md` - launch card and file order.",
            "2. `context.md` - standing context for this role.",
            "3. `task.md` - task-specific input when present.",
            "4. `sources.yaml` - source trace for debugging, not standing instructions.",
            "",
        ]
    )


def render_context_markdown(
    *,
    skill: str,
    role: str,
    target: dict[str, Any],
    body_parts: list[tuple[str, str]],
) -> str:
    title = target.get("title", f"{skill} {role} context")
    lines = [f"# {title}", ""]

    for label, text in body_parts:
        stripped = text.strip()
        if HEADING_RE.match(stripped.splitlines()[0]):
            lines.extend([demote_headings(stripped), ""])
        else:
            lines.extend([f"## {label}", "", stripped, ""])

    return "\n".join(lines)


def write_sources_yaml(
    *,
    sources_path: Path,
    agent_id: str,
    relative_workspace: str,
    relative_readme: str,
    relative_context: str,
    relative_sources: str,
    skill: str,
    adapter: str,
    role: str,
    repo_root: Path,
    target_manifest: dict[str, Any],
    created_at: str,
    records: list[SourceRecord],
) -> None:
    try:
        import yaml
    except ImportError as exc:  # pragma: no cover
        raise ContextRenderError("PyYAML is required for v2 context rendering") from exc

    repo = target_manifest["repo"]
    workspace = target_manifest["metadata"]["agent_workspace"]
    payload = {
        "schema_version": 1,
        "agent_id": agent_id,
        "workspace": {
            "root": workspace["root"],
            "path": relative_workspace,
            "committed": False,
        },
        "generated_files": [
            relative_readme,
            relative_context,
            relative_sources,
        ],
        "skill": skill,
        "adapter": adapter,
        "role": role,
        "repo": {
            "root": str(repo_root),
            "name": repo["name"],
            "agent_docs_version": repo["agent_docs_version"],
            "code_root": repo["code_root"],
        },
        "generator": {
            "version": GENERATOR_VERSION,
            "created_at": created_at,
            "kit_root": str(kit_root()),
        },
        "sources": [
            {
                "source": record.source,
                "label": record.label,
                "path": record.path,
                "heading": record.heading,
                "digest": record.digest,
            }
            for record in records
        ],
    }
    sources_path.write_text(yaml.safe_dump(payload, sort_keys=False), encoding="utf-8")


def render_context(
    *,
    repo: str | Path,
    skill: str,
    adapter: str,
    role: str = "orchestrator",
    max_bytes: int | None = None,
    delete_workspace_root: bool = False,
) -> RenderResult:
    repo_root = Path(repo).expanduser().resolve()
    if not repo_root.is_dir():
        raise ContextRenderError(f"target repo does not exist: {repo_root}")

    manifest = load_manifest(repo_root)
    workspace_root, root_rel = workspace_paths(repo_root, manifest)
    check_workspace_root_ignored(repo_root, root_rel)

    if delete_workspace_root and workspace_root.exists():
        if root_rel != ".agent-docs/agents":
            raise ContextRenderError(f"refusing to delete unexpected workspace root: {workspace_root}")
        shutil.rmtree(workspace_root)

    config_path, config = load_context_config(skill)
    validate_adapter(config, adapter)
    target = target_recipe(config, role)

    body_parts: list[tuple[str, str]] = []
    records = [
        SourceRecord(
            source="kit",
            label="skill context recipe",
            path=relative_to_root(config_path, kit_root()),
            digest=sha256_short(config_path.read_text(encoding="utf-8")),
            heading=None,
        )
    ]
    for item in require_list(target.get("includes"), f"context target {role}.includes"):
        include = require_mapping(item, f"context target {role}.include")
        text, record = include_to_text(include, repo_root, manifest)
        body_parts.append((record.label, text))
        records.append(record)

    agent_id = allocate_id(workspace_root)
    workspace = workspace_root / agent_id
    workspace.mkdir(parents=True, exist_ok=False)
    readme_path = workspace / "README.md"
    context_path = workspace / "context.md"
    sources_path = workspace / "sources.yaml"

    readme = render_readme(
        agent_id=agent_id,
        repo_root=repo_root,
        skill=skill,
        adapter=adapter,
        role=role,
    )
    markdown = render_context_markdown(
        skill=skill,
        role=role,
        target=target,
        body_parts=body_parts,
    )
    byte_count = len(markdown.encode("utf-8"))
    if max_bytes is not None and byte_count > max_bytes:
        raise ContextRenderError(
            f"agent context is {byte_count} bytes, above --max-bytes {max_bytes}"
        )

    readme_path.write_text(readme, encoding="utf-8")
    context_path.write_text(markdown, encoding="utf-8")
    relative_workspace = relative_to_root(workspace, repo_root)
    relative_readme = relative_to_root(readme_path, repo_root)
    relative_context = relative_to_root(context_path, repo_root)
    relative_sources = relative_to_root(sources_path, repo_root)
    write_sources_yaml(
        sources_path=sources_path,
        agent_id=agent_id,
        relative_workspace=relative_workspace,
        relative_readme=relative_readme,
        relative_context=relative_context,
        relative_sources=relative_sources,
        skill=skill,
        adapter=adapter,
        role=role,
        repo_root=repo_root,
        target_manifest=manifest,
        created_at=created_at_timestamp(),
        records=records,
    )

    return RenderResult(
        id=agent_id,
        workspace=workspace,
        relative_workspace=relative_workspace,
        readme=readme_path,
        relative_readme=relative_readme,
        context=context_path,
        relative_context=relative_context,
        sources_file=sources_path,
        relative_sources_file=relative_sources,
        workspace_root=workspace_root,
        relative_workspace_root=root_rel,
        sources=records,
        byte_count=byte_count,
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render repo-local v2 agent workspace.")
    parser.add_argument("--repo", required=True, help="Target repository root.")
    parser.add_argument("--skill", required=True, help="Skill name, currently plan.")
    parser.add_argument("--adapter", required=True, help="Adapter target, currently codex.")
    parser.add_argument("--role", default="orchestrator", help="Context target role.")
    parser.add_argument("--max-bytes", type=int, help="Fail if agent context exceeds this size.")
    parser.add_argument(
        "--delete-workspace-root",
        action="store_true",
        help="Delete the target agent workspace root before rendering.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        result = render_context(
            repo=args.repo,
            skill=args.skill,
            adapter=args.adapter,
            role=args.role,
            max_bytes=args.max_bytes,
            delete_workspace_root=args.delete_workspace_root,
        )
    except ContextRenderError as exc:
        print(f"render failed: {exc}", file=sys.stderr)
        return 1

    print(result.relative_readme)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
