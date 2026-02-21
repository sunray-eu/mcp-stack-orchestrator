#!/usr/bin/env python3
from __future__ import annotations

import argparse
import pathlib
import re
import tomllib
from typing import Dict


SCRIPT_PATH = pathlib.Path(__file__).resolve()
STACK_ROOT = SCRIPT_PATH.parent.parent
TEMPLATES_DIR = STACK_ROOT / "templates" / "agents"


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.strip().lower())
    slug = re.sub(r"-{2,}", "-", slug).strip("-")
    return slug or "project"


def read_template(name: str) -> str:
    path = TEMPLATES_DIR / name
    if not path.exists():
        raise FileNotFoundError(f"missing template: {path}")
    return path.read_text(encoding="utf-8")


def fill_tokens(content: str, tokens: Dict[str, str]) -> str:
    output = content
    for key, value in tokens.items():
        output = output.replace(f"{{{{{key}}}}}", value)
    return output


def write_if_missing(path: pathlib.Path, content: str, force: bool = False) -> bool:
    if path.exists() and not force:
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return True


def render_guideline(path: pathlib.Path) -> str:
    if not path.exists():
        return f"_Missing file: `{path}`_"
    return path.read_text(encoding="utf-8").rstrip()


def resolve_config_path(repo_root: pathlib.Path) -> pathlib.Path:
    return repo_root / ".ai" / "agents.toml"


def load_config(repo_root: pathlib.Path) -> dict:
    config_path = resolve_config_path(repo_root)
    if not config_path.exists():
        raise FileNotFoundError(
            f"missing config: {config_path}. Run `task agents:init REPO={repo_root}` first."
        )
    return tomllib.loads(config_path.read_text(encoding="utf-8"))


def build_tokens_from_config(repo_root: pathlib.Path, config: dict) -> Dict[str, str]:
    project = config.get("project", {})
    company = config.get("company", {})
    mcp = config.get("mcp", {})

    project_name = project.get("name", repo_root.name)
    project_slug = slugify(project.get("id", project_name))
    company_name = company.get("name", "Company")
    company_slug = slugify(company.get("id", company_name))
    project_language = project.get("language", "polyglot")
    default_profile = mcp.get("default_profile", "core")

    return {
        "STACK_ROOT": str(STACK_ROOT),
        "COMPANY_NAME": company_name,
        "COMPANY_SLUG": company_slug,
        "PROJECT_NAME": project_name,
        "PROJECT_SLUG": project_slug,
        "PROJECT_LANGUAGE": project_language,
        "DEFAULT_PROFILE": default_profile,
        "MEMORY_NAMESPACE": mcp.get("memory_namespace", project_slug),
        "QDRANT_COLLECTION": mcp.get("qdrant_collection", f"proj-{project_slug}"),
    }


def resolve_reference(repo_root: pathlib.Path, value: str) -> pathlib.Path:
    replaced = (
        value.replace("${STACK_ROOT}", str(STACK_ROOT)).replace("${REPO_ROOT}", str(repo_root))
    )
    candidate = pathlib.Path(replaced).expanduser()
    if not candidate.is_absolute():
        candidate = (repo_root / candidate).resolve()
    return candidate


def build_agents_markdown(repo_root: pathlib.Path, config: dict) -> str:
    project = config.get("project", {})
    company = config.get("company", {})
    mcp = config.get("mcp", {})
    context = config.get("context", {})
    guidelines = config.get("guidelines", {})
    prompts = config.get("prompts", {})
    process = config.get("process", {})

    project_name = project.get("name", "Project")
    company_name = company.get("name", "Company")
    project_language = project.get("language", "polyglot")
    default_profile = mcp.get("default_profile", "core")
    optional_profiles = ", ".join(mcp.get("optional_profiles", [])) or "core-surreal, core-archon, full"
    memory_namespace = mcp.get("memory_namespace", slugify(project_name))
    qdrant_collection = mcp.get("qdrant_collection", f"proj-{slugify(project_name)}")

    global_ref = guidelines.get("global", "${STACK_ROOT}/guidelines/global/engineering-always.md")
    company_ref = guidelines.get("company", ".ai/guidelines/company.md")
    project_ref = guidelines.get("project", ".ai/guidelines/project.md")
    context_ref = context.get("repo_map", ".ai/context/repo_context.md")
    platform_ref = context.get("platform_overview", ".ai/context/platform_overview.md")

    global_path = resolve_reference(repo_root, global_ref)
    company_path = resolve_reference(repo_root, company_ref)
    project_path = resolve_reference(repo_root, project_ref)
    context_path = resolve_reference(repo_root, context_ref)
    platform_path = resolve_reference(repo_root, platform_ref)

    bootstrap_prompt_path = resolve_reference(
        repo_root, prompts.get("bootstrap", ".ai/prompts/bootstrap_project_context.md")
    )
    initialize_prompt_path = resolve_reference(
        repo_root, prompts.get("initialize", ".ai/prompts/initialize_repository_knowledge.md")
    )
    update_prompt_path = resolve_reference(
        repo_root, prompts.get("update_memory", ".ai/prompts/update_project_memory.md")
    )
    init_process_ref = process.get("initialization", ".ai/process/repository_initialization.md")
    init_process_path = resolve_reference(repo_root, init_process_ref)

    bootstrap_prompt = render_guideline(bootstrap_prompt_path)
    initialize_prompt = render_guideline(initialize_prompt_path)
    update_prompt = render_guideline(update_prompt_path)
    init_process = render_guideline(init_process_path)

    return (
        f"""# AGENTS.md

## Scope
- Project: `{project_name}`
- Company context: `{company_name}`
- Primary language: `{project_language}`
- Default MCP profile: `{default_profile}`
- Optional MCP profiles: `{optional_profiles}`
- Memory namespace: `{memory_namespace}`
- Qdrant collection: `{qdrant_collection}`

## Instruction Precedence
Apply instructions in this order:
1. Global baseline guidelines
2. Company guidelines/semantics
3. Project/repository guidelines
4. Task-specific user instructions

## MCP Tool Routing
- `mcpx-lsp`: symbol navigation, definitions/references, safe refactors, diagnostics.
- `mcpx-qdrant`: fast semantic recall of decisions/snippets and cross-session context lookup.
- `mcpx-basic-memory`: long-term project memory and notes.
- `mcpx-chroma`: local vector fallback/experiments.
- `mcpx-archon-http` (when enabled): project/task/doc workflows and RAG on ingested sources.
- `mcpx-surrealdb-http` (when enabled): structured graph/document operations and local DB-backed experiments.

## Standard Workflow
1. If MCP stack orchestrator is available, confirm profile and health from stack root:
   - `cd {STACK_ROOT}`
   - `task infra:status`
   - `task quality:doctor PROFILE={default_profile}`
   If orchestrator tooling is unavailable in this environment, skip this step.
2. Read the repository context map first (path below), then run the bootstrap prompt.
3. For first-time setup or when context is stale, execute the deep initialization prompt and process.
4. Store stable decisions in memory (`mcpx-qdrant` and/or `mcpx-basic-memory`).
5. For company-sensitive tasks, apply company guideline overrides before coding.

## Repository Context Map
- Source: `{context_ref}`
- Resolved path: `{context_path}`
- Status: {"present" if context_path.exists() else "missing"}

## Repository & Platform Knowledge (Living Source of Truth)
- Source: `{platform_ref}`
- Resolved path: `{platform_path}`
- Status: {"present" if platform_path.exists() else "missing"}
- Maintenance policy:
  - Update this file whenever repository purpose, service boundaries, integrations, runtime behavior, or ops commands change.
  - Keep this file aligned with `.ai/context/repo_context.md` and write durable changes to project memory stores.

{render_guideline(platform_path)}

## Bootstrap Prompt
```text
{bootstrap_prompt}
```

## Memory Update Prompt
```text
{update_prompt}
```

## Repository Initialization Process
- Source: `{init_process_ref}`
- Resolved path: `{init_process_path}`
- Status: {"present" if init_process_path.exists() else "missing"}
```text
{init_process}
```

## Deep Initialization Prompt
```text
{initialize_prompt}
```

## Global Guidelines
Source: `{global_ref}`
{render_guideline(global_path)}

## Company Guidelines
Source: `{company_ref}`
{render_guideline(company_path)}

## Project Guidelines
Source: `{project_ref}`
{render_guideline(project_path)}
""".rstrip()
        + "\n"
    )


def init_repo(args: argparse.Namespace) -> int:
    repo_root = pathlib.Path(args.repo).expanduser().resolve()
    if not repo_root.exists() or not repo_root.is_dir():
        raise NotADirectoryError(f"invalid repo path: {repo_root}")

    company_slug = slugify(args.company)
    project_slug = slugify(args.project)

    tokens = {
        "STACK_ROOT": str(STACK_ROOT),
        "COMPANY_NAME": args.company,
        "COMPANY_SLUG": company_slug,
        "PROJECT_NAME": args.project,
        "PROJECT_SLUG": project_slug,
        "PROJECT_LANGUAGE": args.language,
        "DEFAULT_PROFILE": args.profile,
        "MEMORY_NAMESPACE": project_slug,
        "QDRANT_COLLECTION": f"proj-{project_slug}",
    }

    ai_dir = repo_root / ".ai"
    guidelines_dir = ai_dir / "guidelines"
    prompts_dir = ai_dir / "prompts"
    process_dir = ai_dir / "process"
    context_dir = ai_dir / "context"
    ai_dir.mkdir(parents=True, exist_ok=True)
    guidelines_dir.mkdir(parents=True, exist_ok=True)
    prompts_dir.mkdir(parents=True, exist_ok=True)
    process_dir.mkdir(parents=True, exist_ok=True)
    context_dir.mkdir(parents=True, exist_ok=True)

    created = []

    config_path = resolve_config_path(repo_root)
    config_content = fill_tokens(read_template("agents.toml.example"), tokens)
    if write_if_missing(config_path, config_content, force=args.force):
        created.append(config_path)

    company_content = fill_tokens(read_template("company.guidelines.md"), tokens)
    company_path = guidelines_dir / "company.md"
    if write_if_missing(company_path, company_content, force=args.force):
        created.append(company_path)

    project_content = fill_tokens(read_template("project.guidelines.md"), tokens)
    project_path = guidelines_dir / "project.md"
    if write_if_missing(project_path, project_content, force=args.force):
        created.append(project_path)

    bootstrap_prompt_content = fill_tokens(read_template("prompt.bootstrap.md"), tokens)
    bootstrap_prompt_path = prompts_dir / "bootstrap_project_context.md"
    if write_if_missing(bootstrap_prompt_path, bootstrap_prompt_content, force=args.force):
        created.append(bootstrap_prompt_path)

    initialize_prompt_content = fill_tokens(read_template("prompt.initialize.md"), tokens)
    initialize_prompt_path = prompts_dir / "initialize_repository_knowledge.md"
    if write_if_missing(initialize_prompt_path, initialize_prompt_content, force=args.force):
        created.append(initialize_prompt_path)

    update_prompt_content = fill_tokens(read_template("prompt.update.md"), tokens)
    update_prompt_path = prompts_dir / "update_project_memory.md"
    if write_if_missing(update_prompt_path, update_prompt_content, force=args.force):
        created.append(update_prompt_path)

    init_process_content = fill_tokens(read_template("process.repository_initialization.md"), tokens)
    init_process_path = process_dir / "repository_initialization.md"
    if write_if_missing(init_process_path, init_process_content, force=args.force):
        created.append(init_process_path)

    platform_overview_content = fill_tokens(read_template("context.platform_overview.md"), tokens)
    platform_overview_path = context_dir / "platform_overview.md"
    if write_if_missing(platform_overview_path, platform_overview_content, force=args.force):
        created.append(platform_overview_path)

    stack_env_path = repo_root / ".mcp-stack.env"
    stack_env_template = STACK_ROOT / "configs" / "mcp-stack.env.example"
    if stack_env_template.exists() and write_if_missing(
        stack_env_path, stack_env_template.read_text(encoding="utf-8"), force=False
    ):
        created.append(stack_env_path)

    config = load_config(repo_root)
    agents_md = build_agents_markdown(repo_root, config)
    agents_path = repo_root / "AGENTS.md"
    agents_path.write_text(agents_md, encoding="utf-8")
    created.append(agents_path)

    print(f"Initialized AI scaffolding for: {repo_root}")
    print("Updated files:")
    for path in created:
        print(f"- {path}")
    return 0


def render_repo(args: argparse.Namespace) -> int:
    repo_root = pathlib.Path(args.repo).expanduser().resolve()
    config = load_config(repo_root)
    rendered = build_agents_markdown(repo_root, config)
    if args.stdout:
        print(rendered, end="")
        return 0
    out_path = repo_root / "AGENTS.md"
    out_path.write_text(rendered, encoding="utf-8")
    print(f"Rendered: {out_path}")
    return 0


def print_prompt(args: argparse.Namespace) -> int:
    repo_root = pathlib.Path(args.repo).expanduser().resolve()
    config = load_config(repo_root)
    if args.kind == "bootstrap":
        template_name = "prompt.bootstrap.md"
    elif args.kind == "initialize":
        template_name = "prompt.initialize.md"
    else:
        template_name = "prompt.update.md"
    tokens = build_tokens_from_config(repo_root, config)
    print(fill_tokens(read_template(template_name), tokens), end="\n")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Scaffold and render layered AGENTS.md files.")
    sub = parser.add_subparsers(dest="command", required=True)

    init_cmd = sub.add_parser("init", help="Initialize repo-local AI scaffolding and AGENTS.md")
    init_cmd.add_argument("--repo", required=True, help="Repository root path")
    init_cmd.add_argument("--company", required=True, help="Company name/slug")
    init_cmd.add_argument("--project", required=True, help="Project/repository display name")
    init_cmd.add_argument(
        "--language",
        default="polyglot",
        choices=["typescript", "python", "polyglot", "other"],
        help="Primary language",
    )
    init_cmd.add_argument(
        "--profile",
        default="core",
        choices=["none", "core", "core-surreal", "core-archon", "full"],
        help="Default MCP profile for this repo",
    )
    init_cmd.add_argument("--force", action="store_true", help="Overwrite scaffold files if present")
    init_cmd.set_defaults(func=init_repo)

    render_cmd = sub.add_parser("render", help="Render AGENTS.md from .ai/agents.toml")
    render_cmd.add_argument("--repo", required=True, help="Repository root path")
    render_cmd.add_argument("--stdout", action="store_true", help="Print instead of writing AGENTS.md")
    render_cmd.set_defaults(func=render_repo)

    prompt_cmd = sub.add_parser("prompt", help="Print generated operational prompts")
    prompt_cmd.add_argument("--repo", required=True, help="Repository root path")
    prompt_cmd.add_argument("--kind", choices=["bootstrap", "initialize", "update"], default="bootstrap")
    prompt_cmd.set_defaults(func=print_prompt)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
