#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from typing import Any

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parent))

from render import (  # noqa: E402
    ContextRenderError,
    ID_RE,
    generated_paths,
    kit_root,
    load_context_config,
    load_manifest,
    render_context,
)


class VerifyError(Exception):
    pass


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


def load_yaml_documents(path: Path) -> list[dict[str, Any]]:
    try:
        import yaml
    except ImportError as exc:  # pragma: no cover
        raise VerifyError("PyYAML is required for v2 context verification") from exc
    with path.open("r", encoding="utf-8") as handle:
        docs = list(yaml.safe_load_all(handle))
    return [doc for doc in docs if doc is not None]


def assert_no_legacy_manifest_reference() -> None:
    legacy_name = "manifest" + ".md"
    checked_roots = [kit_root() / "v2" / "context", kit_root() / "v2" / "skills"]
    for root in checked_roots:
        for path in root.rglob("*"):
            if not path.is_file() or path.suffix not in {".py", ".md", ".yaml"}:
                continue
            if legacy_name in path.read_text(encoding="utf-8"):
                raise VerifyError(f"v2 context path references legacy manifest: {path}")


def verify_context_recipe(skill: str, adapter: str) -> None:
    config_path, config = load_context_config(skill)
    require(adapter in config.get("supported_adapters", []), "context recipe does not support adapter")
    require((kit_root() / "v2" / "skills" / skill / "SKILL.md").is_file(), "missing v2 skill launcher")
    require(config_path.is_file(), "missing context recipe")


def verify_rendered_file(path: Path, *, max_bytes: int) -> int:
    require(path.is_file(), f"generated file missing: {path}")
    text = path.read_text(encoding="utf-8")
    require("### Source:" in text, "generated context is missing source labels")
    require("## Provenance" in text, "generated context is missing provenance")
    byte_count = len(text.encode("utf-8"))
    require(byte_count <= max_bytes, f"generated context exceeds max bytes: {byte_count}")
    return byte_count


def verify(args: argparse.Namespace) -> list[str]:
    repo = Path(args.repo).expanduser().resolve()
    require(repo.is_dir(), f"target repo missing: {repo}")
    run_git(repo, ["rev-parse", "--show-toplevel"])

    assert_no_legacy_manifest_reference()
    verify_context_recipe(args.skill, args.adapter)

    manifest = load_manifest(repo)
    generated_root, log_path, root_rel, _ = generated_paths(repo, manifest)
    ignore = run_git(repo, ["check-ignore", "-v", f"{root_rel}/test.md"]).stdout.strip()

    first = render_context(
        repo=repo,
        skill=args.skill,
        adapter=args.adapter,
        role="orchestrator",
        max_bytes=args.max_bytes,
    )
    first_bytes = verify_rendered_file(first.file, max_bytes=args.max_bytes)
    require(ID_RE.match(first.id) is not None, f"generated id is not URL-safe: {first.id}")

    second = render_context(
        repo=repo,
        skill=args.skill,
        adapter=args.adapter,
        role="orchestrator",
        max_bytes=args.max_bytes,
    )
    second_bytes = verify_rendered_file(second.file, max_bytes=args.max_bytes)
    require(first.id != second.id, "two generated contexts reused an id")

    log_records = load_yaml_documents(log_path)
    require(len(log_records) >= 2, "generation log did not append records")
    require(log_records[-2]["id"] == first.id, "generation log missing first render id")
    require(log_records[-1]["id"] == second.id, "generation log missing second render id")

    regenerated = render_context(
        repo=repo,
        skill=args.skill,
        adapter=args.adapter,
        role="orchestrator",
        max_bytes=args.max_bytes,
        delete_generated=True,
    )
    regenerated_bytes = verify_rendered_file(regenerated.file, max_bytes=args.max_bytes)

    worker = render_context(
        repo=repo,
        skill=args.skill,
        adapter=args.adapter,
        role="planning-worker",
        max_bytes=args.max_bytes,
    )
    worker_bytes = verify_rendered_file(worker.file, max_bytes=args.max_bytes)

    tracked_generated = run_git(repo, ["ls-files", "--", root_rel]).stdout.strip()
    require(not tracked_generated, f"generated context is tracked: {tracked_generated}")
    staged_generated = run_git(repo, ["diff", "--cached", "--name-only", "--", root_rel]).stdout.strip()
    require(not staged_generated, f"generated context is staged: {staged_generated}")

    status = run_git(repo, ["status", "--short", "--ignored", "--", root_rel]).stdout.strip()
    require(status.startswith("!! "), f"generated context is not reported as ignored: {status}")

    return [
        f"OK manifest: {repo / 'docs/_meta/manifest.yaml'}",
        f"OK ignore: {ignore}",
        f"OK rendered orchestrator: {first.relative_file} ({first_bytes} bytes)",
        f"OK log append: {len(log_records)} records in {first.relative_log}",
        f"OK rendered orchestrator again: {second.relative_file} ({second_bytes} bytes)",
        f"OK delete/regenerate: {regenerated.relative_file} ({regenerated_bytes} bytes)",
        f"OK rendered planning-worker: {worker.relative_file} ({worker_bytes} bytes)",
        f"OK generated artifacts untracked and ignored: {root_rel}",
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
