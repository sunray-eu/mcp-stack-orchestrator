#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import pathlib
import subprocess
import tomllib
from typing import Any


def run(cmd: list[str], cwd: pathlib.Path) -> str:
    result = subprocess.run(cmd, cwd=str(cwd), check=False, capture_output=True, text=True)
    return (result.stdout or "").strip()


def detect_language(repo_root: pathlib.Path) -> str:
    if (repo_root / "package.json").exists():
        if (repo_root / "tsconfig.json").exists() or (repo_root / "tsconfig.build.json").exists():
            return "typescript"
        return "javascript"
    if (repo_root / "pyproject.toml").exists() or (repo_root / "requirements.txt").exists():
        return "python"
    return "polyglot"


def load_json(path: pathlib.Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def load_toml(path: pathlib.Path) -> dict[str, Any]:
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}


def list_top_level(repo_root: pathlib.Path) -> tuple[list[str], list[str]]:
    ignore = {
        ".git",
        "node_modules",
        ".venv",
        "venv",
        "dist",
        "build",
        "coverage",
        ".pytest_cache",
        ".mcp-uv-cache",
        ".semantic-search",
        ".sourcerer",
        ".code-graph-rag",
        "in-memoria-vectors.db",
        "lancedb",
        "logs_llm",
    }
    ignore_files = {
        ".env",
        ".secrets.env",
        ".secrets.env.runtime",
        "debug.log",
    }
    dirs: list[str] = []
    files: list[str] = []
    for entry in sorted(repo_root.iterdir(), key=lambda p: p.name):
        if entry.name in ignore:
            continue
        if entry.is_dir():
            dirs.append(entry.name)
        elif entry.is_file():
            if entry.name in ignore_files or entry.name.startswith("background-indexing-"):
                continue
            files.append(entry.name)
    return dirs[:40], files[:40]


def detect_entrypoints(repo_root: pathlib.Path, language: str) -> list[str]:
    candidates = [
        "src/main.ts",
        "src/index.ts",
        "src/app.ts",
        "main.ts",
        "src/main.py",
        "src/app.py",
        "main.py",
        "app.py",
        "manage.py",
    ]
    out: list[str] = []
    for rel in candidates:
        path = repo_root / rel
        if path.exists():
            out.append(rel)

    if language in {"typescript", "javascript"}:
        pkg = load_json(repo_root / "package.json")
        scripts = pkg.get("scripts", {}) if isinstance(pkg.get("scripts"), dict) else {}
        for key in ("start:dev", "start", "build", "test", "lint", "typecheck"):
            if key in scripts:
                out.append(f"package.json:scripts.{key}")
    if language == "python":
        pyproject = load_toml(repo_root / "pyproject.toml")
        if pyproject:
            out.append("pyproject.toml")
    return out[:30]


def detect_commands(repo_root: pathlib.Path, language: str) -> dict[str, str]:
    commands: dict[str, str] = {}

    if language in {"typescript", "javascript"} and (repo_root / "package.json").exists():
        pkg = load_json(repo_root / "package.json")
        scripts = pkg.get("scripts", {}) if isinstance(pkg.get("scripts"), dict) else {}
        package_manager = "pnpm" if (repo_root / "pnpm-lock.yaml").exists() else "npm"
        commands["install"] = f"{package_manager} install"
        for key in ("start:dev", "build", "test", "lint:check", "lint", "typecheck", "format:check", "format"):
            if key in scripts:
                commands[key] = f"{package_manager} run {key}"

    if language == "python":
        if (repo_root / "pyproject.toml").exists():
            pyproject = load_toml(repo_root / "pyproject.toml")
            scripts = pyproject.get("project", {}).get("scripts", {}) if isinstance(pyproject.get("project"), dict) else {}
            commands["install"] = "pip install -e ."
            for key in ("test", "lint", "typecheck", "format"):
                if isinstance(scripts, dict) and key in scripts:
                    commands[key] = f"python -m {scripts[key]}"
        if "test" not in commands:
            commands["test"] = "pytest"

    taskfile = None
    for name in ("Taskfile.yml", "Taskfile.yaml", "taskfile.yml", "taskfile.yaml"):
        candidate = repo_root / name
        if candidate.exists():
            taskfile = candidate
            break
    if taskfile:
        commands["task:help"] = "task --list-all"

    return commands


def detect_docs(repo_root: pathlib.Path) -> list[str]:
    docs: list[str] = []
    docs_dir = repo_root / "docs"
    if docs_dir.exists():
        for path in sorted(docs_dir.rglob("*.md")):
            docs.append(str(path.relative_to(repo_root)))
    for rel in ("README.md", "AGENTS.md"):
        if (repo_root / rel).exists():
            docs.append(rel)
    # keep stable and bounded
    docs = sorted(set(docs))
    return docs[:80]


def build_memory_seeds(repo_root: pathlib.Path, language: str, commands: dict[str, str], entrypoints: list[str], docs: list[str]) -> list[str]:
    project_name = repo_root.name
    seeds = [
        f"{project_name}: primary language is {language}",
        f"{project_name}: key entrypoints are {', '.join(entrypoints[:5]) if entrypoints else 'not detected'}",
        f"{project_name}: validation commands include {', '.join(f'{k}={v}' for k, v in list(commands.items())[:6])}",
        f"{project_name}: major documentation sources include {', '.join(docs[:8]) if docs else 'README only'}",
    ]
    return seeds


def generate_markdown(
    repo_root: pathlib.Path,
    company: str,
    project: str,
    language: str,
    branch: str,
    dirty: bool,
    dirs: list[str],
    files: list[str],
    entrypoints: list[str],
    commands: dict[str, str],
    docs: list[str],
) -> str:
    now = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M:%S %Z")
    seeds = build_memory_seeds(repo_root, language, commands, entrypoints, docs)

    command_lines = "\n".join(f"- `{k}`: `{v}`" for k, v in commands.items()) or "- none detected"
    docs_lines = "\n".join(f"- `{doc}`" for doc in docs) or "- none detected"
    entry_lines = "\n".join(f"- `{item}`" for item in entrypoints) or "- none detected"
    dir_lines = "\n".join(f"- `{d}/`" for d in dirs) or "- none detected"
    file_lines = "\n".join(f"- `{f}`" for f in files) or "- none detected"
    seed_lines = "\n".join(f"- {seed}" for seed in seeds)

    return (
        f"# Repository Context Map\n\n"
        f"## Metadata\n"
        f"- Company: `{company}`\n"
        f"- Project: `{project}`\n"
        f"- Repository: `{repo_root}`\n"
        f"- Generated: `{now}`\n"
        f"- Branch: `{branch or 'unknown'}`\n"
        f"- Working tree dirty: `{'yes' if dirty else 'no'}`\n"
        f"- Detected language: `{language}`\n\n"
        f"## Top-Level Structure\n\n"
        f"### Directories\n"
        f"{dir_lines}\n\n"
        f"### Files\n"
        f"{file_lines}\n\n"
        f"## Entrypoints and Operational Surfaces\n"
        f"{entry_lines}\n\n"
        f"## Primary Commands\n"
        f"{command_lines}\n\n"
        f"## Docs to Index / Ingest\n"
        f"{docs_lines}\n\n"
        f"## Recommended Memory Seeds\n"
        f"{seed_lines}\n\n"
        f"## Bootstrap Checklist\n"
        f"1. Confirm stack profile and health (`task infra:status`, `task quality:doctor PROFILE=core`).\n"
        f"2. Load `AGENTS.md`, this file, and `.ai/guidelines/project.md` before edits.\n"
        f"3. Resolve symbols with `mcpx-lsp` before refactors.\n"
        f"4. Store durable decisions to `mcpx-qdrant` and `mcpx-basic-memory`.\n"
        f"5. Keep this file updated after architecture/tooling changes.\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate reusable repo onboarding context map.")
    parser.add_argument("--repo", required=True, help="Repository root path")
    parser.add_argument("--company", default="unknown-company", help="Company/organization label")
    parser.add_argument("--project", default="", help="Project label (defaults to folder name)")
    parser.add_argument("--language", default="auto", help="Language override (or 'auto')")
    parser.add_argument("--output", default=".ai/context/repo_context.md", help="Output path relative to repo")
    parser.add_argument("--force", action="store_true", help="Overwrite existing output")
    parser.add_argument("--stdout", action="store_true", help="Print output to stdout")
    args = parser.parse_args()

    repo_root = pathlib.Path(args.repo).expanduser().resolve()
    if not repo_root.exists() or not repo_root.is_dir():
        raise NotADirectoryError(f"invalid repo path: {repo_root}")

    project = args.project or repo_root.name
    language = detect_language(repo_root) if args.language == "auto" else args.language
    dirs, files = list_top_level(repo_root)
    entrypoints = detect_entrypoints(repo_root, language)
    commands = detect_commands(repo_root, language)
    docs = detect_docs(repo_root)

    branch = run(["git", "branch", "--show-current"], repo_root)
    status = run(["git", "status", "--porcelain"], repo_root)
    dirty = bool(status.strip())

    markdown = generate_markdown(
        repo_root=repo_root,
        company=args.company,
        project=project,
        language=language,
        branch=branch,
        dirty=dirty,
        dirs=dirs,
        files=files,
        entrypoints=entrypoints,
        commands=commands,
        docs=docs,
    )

    if args.stdout:
        print(markdown, end="")
        return 0

    out_path = pathlib.Path(args.output)
    if not out_path.is_absolute():
        out_path = repo_root / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if out_path.exists() and not args.force:
        raise FileExistsError(f"output already exists: {out_path} (use --force to overwrite)")
    out_path.write_text(markdown, encoding="utf-8")
    print(f"Wrote context map: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
