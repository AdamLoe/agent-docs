#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from render import (  # noqa: E402
    ContextRenderError,
    ID_RE,
    kit_root,
    load_context_config,
    load_manifest,
    render_context,
    workspace_paths,
)


class VerifyError(Exception):
    pass


GENERATED_MARKDOWN_BANNED = [
    ("../architecture/", "source-relative architecture link"),
    ("../decisions/", "source-relative decisions link"),
    ("../_meta/", "source-relative metadata link"),
    ("simulation_contract.md", "stale migration-history doc name"),
    ("decisions.md` planning docs have been migrated", "stale migration-history wording"),
    ("decisions.md planning docs have been migrated", "stale migration-history wording"),
]
MARKDOWN_LINK_RE = re.compile(r"!?\[[^\]]*]\(([^)]+)\)")
URI_SCHEME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9+.-]*:")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise VerifyError(message)


def run_git(repo: Path, args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        text=True,
        capture_output=True,
        check=False,
    )
    if check and result.returncode != 0:
        detail = (result.stderr or result.stdout).strip()
        raise VerifyError(f"git {' '.join(args)} failed: {detail}")
    return result


def load_yaml_mapping(path: Path) -> dict[str, Any]:
    try:
        import yaml
    except ImportError as exc:  # pragma: no cover
        raise VerifyError("PyYAML is required for v2 context verification") from exc
    with path.open("r", encoding="utf-8") as handle:
        loaded = yaml.safe_load(handle)
    require(isinstance(loaded, dict), f"YAML root must be a mapping: {path}")
    return loaded


def assert_no_legacy_manifest_reference() -> None:
    legacy_name = "manifest" + ".md"
    checked_roots = [kit_root() / "v2" / "context", kit_root() / "v2" / "skills"]
    for root in checked_roots:
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in {".py", ".md", ".yaml"}:
                continue
            if legacy_name in path.read_text(encoding="utf-8"):
                raise VerifyError(f"v2 context path references legacy manifest: {path}")


def assert_no_legacy_output_reference() -> None:
    checked_roots = [kit_root() / "v2" / "context", kit_root() / "v2" / "skills"]
    legacy_root = "docs/" + ".generated"
    legacy_field = "generated" + "_context"
    legacy_log = "generations" + ".yaml"
    banned = [legacy_root, legacy_field, legacy_log]
    for root in checked_roots:
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in {".py", ".md", ".yaml"}:
                continue
            text = path.read_text(encoding="utf-8")
            for value in banned:
                if value in text:
                    raise VerifyError(f"v2 context path references legacy generated output: {path}")


def verify_context_recipe(skill: str, adapter: str) -> None:
    config_path, config = load_context_config(skill)
    require(adapter in config.get("supported_adapters", []), "context recipe does not support adapter")
    require((kit_root() / "v2" / "skills" / skill / "SKILL.md").is_file(), "missing v2 skill launcher")
    require(config_path.is_file(), "missing context recipe")


def verify_markdown(path: Path, *, max_bytes: int | None = None) -> int:
    require(path.is_file(), f"workspace Markdown missing: {path}")
    text = path.read_text(encoding="utf-8")
    require("### Source:" not in text, f"Markdown contains source wrapper: {path}")
    require("## Provenance" not in text, f"Markdown contains provenance block: {path}")
    require("digest" not in text.casefold(), f"Markdown contains digest text: {path}")
    for banned, label in GENERATED_MARKDOWN_BANNED:
        require(banned not in text, f"Markdown contains {label}: {path}")
    verify_relative_markdown_links(path, text)
    byte_count = len(text.encode("utf-8"))
    if max_bytes is not None:
        require(byte_count <= max_bytes, f"agent context exceeds max bytes: {byte_count}")
    return byte_count


def markdown_link_path(target: str) -> str | None:
    target = target.strip()
    if not target:
        return None
    if target.startswith("<") and target.endswith(">"):
        target = target[1:-1].strip()
    if not target or target.startswith("#") or target.startswith("/"):
        return None
    if URI_SCHEME_RE.match(target):
        return None
    target = target.split("#", 1)[0].split("?", 1)[0].strip()
    return target or None


def verify_relative_markdown_links(path: Path, text: str) -> None:
    for match in MARKDOWN_LINK_RE.finditer(text):
        link_path = markdown_link_path(match.group(1))
        if link_path is None:
            continue
        resolved = (path.parent / link_path).resolve()
        require(resolved.exists(), f"Markdown relative link is broken in {path}: {match.group(1)}")


def verify_workspace(result, *, max_bytes: int) -> tuple[int, int, dict[str, Any]]:
    require(result.workspace.is_dir(), f"workspace missing: {result.workspace}")
    expected = {result.readme, result.context, result.sources_file}
    actual = {path for path in result.workspace.iterdir() if path.is_file()}
    require(expected == actual, f"workspace files mismatch: {sorted(path.name for path in actual)}")
    readme_bytes = verify_markdown(result.readme)
    context_bytes = verify_markdown(result.context, max_bytes=max_bytes)
    sources = load_yaml_mapping(result.sources_file)
    require(sources.get("agent_id") == result.id, "sources.yaml has wrong agent id")
    require(sources.get("skill") == "plan", "sources.yaml has wrong skill")
    require(sources.get("adapter") == "codex", "sources.yaml has wrong adapter")
    require(sources.get("role") in {"orchestrator", "planning-worker"}, "sources.yaml has wrong role")
    generated_files = sources.get("generated_files")
    require(isinstance(generated_files, list), "sources.yaml generated_files must be a list")
    for file_path in [result.relative_readme, result.relative_context, result.relative_sources_file]:
        require(file_path in generated_files, f"sources.yaml missing generated file: {file_path}")
    source_records = sources.get("sources")
    require(isinstance(source_records, list) and source_records, "sources.yaml missing source records")
    for record in source_records:
        require(isinstance(record, dict), "sources.yaml source record must be a mapping")
        require("path" in record, "sources.yaml source record missing path")
        require("digest" in record, "sources.yaml source record missing digest")
    return readme_bytes, context_bytes, sources


def legacy_generated_snapshot(repo: Path) -> dict[str, tuple[int, int]]:
    legacy_root = repo / "docs" / ".generated"
    if not legacy_root.exists():
        return {}
    snapshot: dict[str, tuple[int, int]] = {}
    for path in sorted(legacy_root.rglob("*")):
        if path.is_file():
            stat = path.stat()
            snapshot[path.relative_to(legacy_root).as_posix()] = (stat.st_size, stat.st_mtime_ns)
    return snapshot


def verify(args: argparse.Namespace) -> list[str]:
    repo = Path(args.repo).expanduser().resolve()
    require(repo.is_dir(), f"target repo missing: {repo}")
    run_git(repo, ["rev-parse", "--show-toplevel"])

    assert_no_legacy_manifest_reference()
    assert_no_legacy_output_reference()
    verify_context_recipe(args.skill, args.adapter)

    manifest = load_manifest(repo)
    workspace_root, root_rel = workspace_paths(repo, manifest)
    ignore = run_git(repo, ["check-ignore", "-v", f"{root_rel}/test/README.md"]).stdout.strip()
    legacy_before = legacy_generated_snapshot(repo)

    first = render_context(
        repo=repo,
        skill=args.skill,
        adapter=args.adapter,
        role="orchestrator",
        max_bytes=args.max_bytes,
    )
    _, first_bytes, first_sources = verify_workspace(first, max_bytes=args.max_bytes)
    require(ID_RE.match(first.id) is not None, f"generated id is not URL-safe: {first.id}")
    require(first_sources["role"] == "orchestrator", "first workspace has wrong role")

    second = render_context(
        repo=repo,
        skill=args.skill,
        adapter=args.adapter,
        role="orchestrator",
        max_bytes=args.max_bytes,
    )
    _, second_bytes, second_sources = verify_workspace(second, max_bytes=args.max_bytes)
    require(first.id != second.id, "two agent workspaces reused an id")
    require(second_sources["role"] == "orchestrator", "second workspace has wrong role")

    regenerated = render_context(
        repo=repo,
        skill=args.skill,
        adapter=args.adapter,
        role="orchestrator",
        max_bytes=args.max_bytes,
        delete_workspace_root=True,
    )
    _, regenerated_bytes, regenerated_sources = verify_workspace(regenerated, max_bytes=args.max_bytes)
    require(regenerated_sources["role"] == "orchestrator", "regenerated workspace has wrong role")
    require(not first.workspace.exists(), "delete/regenerate left first workspace behind")
    require(not second.workspace.exists(), "delete/regenerate left second workspace behind")

    worker = render_context(
        repo=repo,
        skill=args.skill,
        adapter=args.adapter,
        role="planning-worker",
        max_bytes=args.max_bytes,
    )
    _, worker_bytes, worker_sources = verify_workspace(worker, max_bytes=args.max_bytes)
    require(worker_sources["role"] == "planning-worker", "worker workspace has wrong role")

    legacy_after = legacy_generated_snapshot(repo)
    legacy_label = "docs/" + ".generated"
    require(legacy_before == legacy_after, f"legacy {legacy_label} changed during verification")

    tracked_workspace = run_git(repo, ["ls-files", "--", root_rel]).stdout.strip()
    require(not tracked_workspace, f"agent workspace is tracked: {tracked_workspace}")
    staged_workspace = run_git(repo, ["diff", "--cached", "--name-only", "--", root_rel]).stdout.strip()
    require(not staged_workspace, f"agent workspace is staged: {staged_workspace}")

    status = run_git(repo, ["status", "--short", "--ignored", "--", root_rel]).stdout.strip()
    require(status, "agent workspace status is empty")
    for line in status.splitlines():
        require(line.startswith("!! "), f"agent workspace is not reported as ignored: {status}")

    return [
        f"OK manifest: {repo / 'docs/_meta/manifest.yaml'}",
        f"OK ignore: {ignore}",
        f"OK rendered orchestrator workspace: {first.relative_workspace} ({first_bytes} context bytes)",
        f"OK rendered unique orchestrator workspace: {second.relative_workspace} ({second_bytes} context bytes)",
        f"OK delete/regenerate workspace: {regenerated.relative_workspace} ({regenerated_bytes} context bytes)",
        f"OK rendered planning-worker workspace: {worker.relative_workspace} ({worker_bytes} context bytes)",
        f"OK legacy {'docs/' + '.generated'} unchanged",
        f"OK agent workspace artifacts untracked and ignored: {root_rel}",
    ]


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Verify the narrow v2 context proof.")
    parser.add_argument("--repo", required=True, help="Target repository root.")
    parser.add_argument("--skill", required=True, choices=["plan"])
    parser.add_argument("--adapter", required=True, choices=["codex"])
    parser.add_argument("--max-bytes", type=int, default=16000)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    try:
        lines = verify(args)
    except (ContextRenderError, VerifyError) as exc:
        print(f"VERIFY FAIL: {exc}", file=sys.stderr)
        return 1

    for line in lines:
        print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
