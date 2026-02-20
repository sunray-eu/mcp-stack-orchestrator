#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import pathlib
import shlex
import subprocess
import sys
import time
from typing import Any, Dict, List

HOME = pathlib.Path.home()
SCRIPT_PATH = pathlib.Path(__file__).resolve()
STACK_ROOT = SCRIPT_PATH.parent.parent
MANIFEST_PATH = STACK_ROOT / "configs" / "mcp_stack_manifest.json"
LOG_ROOT = STACK_ROOT / "logs"
BACKUP_ROOT = STACK_ROOT / "backups"


def run(cmd: List[str], env: Dict[str, str] | None = None, check: bool = True) -> subprocess.CompletedProcess:
    cp = subprocess.run(cmd, env=env, text=True, capture_output=True)
    if check and cp.returncode != 0:
        raise RuntimeError(
            f"command failed ({cp.returncode}): {' '.join(shlex.quote(c) for c in cmd)}\n"
            f"stdout:\n{cp.stdout}\n"
            f"stderr:\n{cp.stderr}"
        )
    return cp


def now_stamp() -> str:
    return time.strftime("%Y%m%d-%H%M%S")


def resolve_tokens(value: Any) -> Any:
    if isinstance(value, str):
        return (
            value
            .replace("${STACK_ROOT}", str(STACK_ROOT))
            .replace("${HOME}", str(HOME))
        )
    if isinstance(value, list):
        return [resolve_tokens(v) for v in value]
    if isinstance(value, dict):
        return {k: resolve_tokens(v) for k, v in value.items()}
    return value


def load_manifest() -> dict:
    raw = json.loads(MANIFEST_PATH.read_text())
    return resolve_tokens(raw)


def backup_files(stamp: str) -> pathlib.Path:
    backup_dir = BACKUP_ROOT / f"stack-apply-{stamp}"
    backup_dir.mkdir(parents=True, exist_ok=True)

    targets = {
        "codex.config.toml": HOME / ".codex" / "config.toml",
        "codex-eval.config.toml": HOME / ".codex-mcp-eval" / "config.toml",
        "claude.json": HOME / ".claude.json",
        "opencode.jsonc": HOME / ".config" / "opencode" / "opencode.jsonc",
    }
    for dst, src in targets.items():
        if src.exists():
            (backup_dir / dst).write_text(src.read_text())

    (STACK_ROOT / ".latest-stack-apply-backup").write_text(str(backup_dir) + "\n")
    return backup_dir


def codex_remove_managed(home_dir: pathlib.Path, managed: List[str]) -> None:
    env = os.environ.copy()
    env["CODEX_HOME"] = str(home_dir)
    for name in managed:
        run(["codex", "mcp", "remove", name], env=env, check=False)


def codex_add_profile(home_dir: pathlib.Path, profile_servers: List[str], servers: dict) -> None:
    env = os.environ.copy()
    env["CODEX_HOME"] = str(home_dir)
    for name in profile_servers:
        spec = servers[name]["codex"]
        kind = spec["kind"]
        if kind == "http":
            run(["codex", "mcp", "add", name, "--url", spec["url"]], env=env)
            continue
        cmd = ["codex", "mcp", "add", name]
        for k, v in spec.get("env", {}).items():
            cmd.extend(["--env", f"{k}={v}"])
        cmd.extend(["--", spec["command"], *spec.get("args", [])])
        run(cmd, env=env)


def codex_set_timeouts(home_dir: pathlib.Path, profile_servers: List[str], servers: dict) -> None:
    cfg = home_dir / "config.toml"
    if not cfg.exists():
        return
    text = cfg.read_text()
    for name in profile_servers:
        spec = servers[name]["codex"]
        timeout = spec.get("startup_timeout_sec")
        if timeout is None:
            continue
        marker = f"[mcp_servers.{name}]"
        idx = text.find(marker)
        if idx < 0:
            continue
        next_idx = text.find("[mcp_servers.", idx + len(marker))
        section = text[idx: next_idx if next_idx >= 0 else len(text)]
        if "startup_timeout_sec" in section:
            continue
        section = section.rstrip() + f"\nstartup_timeout_sec = {int(timeout)}\n\n"
        text = text[:idx] + section + (text[next_idx:] if next_idx >= 0 else "")
    cfg.write_text(text)


def claude_remove_managed(managed: List[str]) -> None:
    for name in managed:
        run(["claude", "mcp", "remove", "--scope", "user", name], check=False)


def claude_add_profile(profile_servers: List[str], servers: dict) -> None:
    for name in profile_servers:
        spec = servers[name]["claude"]
        transport = spec["transport"]
        if transport in {"http", "sse"}:
            run(["claude", "mcp", "add", "--scope", "user", "--transport", transport, name, spec["url"]])
            continue
        cmd = ["claude", "mcp", "add", "--scope", "user", "--transport", "stdio", name]
        for k, v in spec.get("env", {}).items():
            cmd.extend(["-e", f"{k}={v}"])
        command = spec["command"]
        cmd.extend(["--", *command])
        run(cmd)


def load_opencode_jsonc(path: pathlib.Path) -> dict:
    node_script = r'''
const fs = require('fs');
const vm = require('vm');
const p = process.argv[1];
const txt = fs.readFileSync(p, 'utf8');
let obj;
try {
  obj = vm.runInNewContext('(' + txt + ')', {}, { timeout: 1000 });
} catch (e) {
  obj = JSON.parse(txt);
}
process.stdout.write(JSON.stringify(obj));
'''
    cp = subprocess.run(["node", "-e", node_script, str(path)], text=True, capture_output=True)
    if cp.returncode != 0:
        raise RuntimeError(f"failed to parse opencode config: {cp.stderr}")
    return json.loads(cp.stdout)


def write_opencode(path: pathlib.Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def opencode_apply(profile_servers: List[str], servers: dict, managed: List[str]) -> None:
    path = HOME / ".config" / "opencode" / "opencode.jsonc"
    obj = load_opencode_jsonc(path) if path.exists() else {}
    if not isinstance(obj, dict):
        obj = {}
    mcp = obj.get("mcp")
    if not isinstance(mcp, dict):
        mcp = {}
    for name in managed:
        mcp.pop(name, None)
    for name in profile_servers:
        mcp[name] = servers[name]["opencode"]
    obj["mcp"] = mcp
    write_opencode(path, obj)


def log_snapshots(stamp: str, codex_targets: List[pathlib.Path]) -> None:
    LOG_ROOT.mkdir(parents=True, exist_ok=True)
    for target in codex_targets:
        env = os.environ.copy()
        env["CODEX_HOME"] = str(target)
        cp = run(["codex", "mcp", "list"], env=env, check=False)
        (LOG_ROOT / f"codex_mcp_list_{target.name}_{stamp}.txt").write_text(cp.stdout + cp.stderr)

    cp_claude = run(["claude", "mcp", "list"], check=False)
    (LOG_ROOT / f"claude_mcp_list_{stamp}.txt").write_text(cp_claude.stdout + cp_claude.stderr)

    cp_opencode = run(["opencode", "mcp", "list"], check=False)
    (LOG_ROOT / f"opencode_mcp_list_{stamp}.txt").write_text(cp_opencode.stdout + cp_opencode.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description="Apply MCP profile across Codex/Claude/OpenCode")
    parser.add_argument("profile", help="Profile name from manifest")
    parser.add_argument("--agents", default="codex,claude,opencode", help="comma-separated subset")
    parser.add_argument("--codex-target", default="both", choices=["user", "eval", "both"], help="Codex config target")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    manifest = load_manifest()
    profiles = manifest["profiles"]
    servers = manifest["servers"]
    managed = manifest["managed_servers"]

    if args.profile not in profiles:
        print(f"Unknown profile: {args.profile}", file=sys.stderr)
        print("Available:", ", ".join(sorted(profiles.keys())), file=sys.stderr)
        return 2

    selected = [a.strip() for a in args.agents.split(",") if a.strip()]
    for s in selected:
        if s not in {"codex", "claude", "opencode"}:
            print(f"Unknown agent: {s}", file=sys.stderr)
            return 2

    profile_servers = profiles[args.profile]

    print(f"Applying profile: {args.profile}")
    print(f"Servers: {', '.join(profile_servers) if profile_servers else '(none)'}")
    print(f"Agents: {', '.join(selected)}")
    print(f"Stack root: {STACK_ROOT}")

    stamp = now_stamp()
    backup_dir = backup_files(stamp)
    print(f"Backup: {backup_dir}")

    if args.dry_run:
        return 0

    codex_homes: List[pathlib.Path] = []
    if args.codex_target in {"user", "both"}:
        codex_homes.append(HOME / ".codex")
    if args.codex_target in {"eval", "both"}:
        codex_homes.append(HOME / ".codex-mcp-eval")

    if "codex" in selected:
        for home in codex_homes:
            home.mkdir(parents=True, exist_ok=True)
            cfg = home / "config.toml"
            if not cfg.exists():
                cfg.write_text("")
            codex_remove_managed(home, managed)
            codex_add_profile(home, profile_servers, servers)
            codex_set_timeouts(home, profile_servers, servers)

    if "claude" in selected:
        claude_remove_managed(managed)
        claude_add_profile(profile_servers, servers)

    if "opencode" in selected:
        opencode_apply(profile_servers, servers, managed)

    log_snapshots(stamp, codex_homes)
    print("Done")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
