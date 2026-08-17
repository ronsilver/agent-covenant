#!/usr/bin/env python3
"""Validate MCP server configs for portability and secret hygiene.

Checks (applied to canonical content/mcp/*.json and the deployed
~/.config/opencode/opencode.json when present):

1. No absolute binary paths in server commands, except the documented uv-tool
   venv exception (e.g. graphify's ~/.local/share/uv/tools/*/bin/python).
   Bare binaries (npx, uvx, go, python) are the portability contract.
2. No literal PATH injected into any server environment/env.
3. No real secret patterns in the file (ghp_, gho_, glsa_, secret_, sk-, xox).
4. No flattened single-element command arrays containing spaces (causes
   ENOENT: posix_spawn treats the whole string as one executable).
5. openspec server must run via `npx -y openspec-mcp` (the PyPI `uvx`
   distribution is broken).
6. No filesystem MCP server mounted at root '/' (whole-disk MCP write
   access for every agent; root must be a project directory).

Usage:
  python3 scripts/validate-mcp-config.py            # report only
  python3 scripts/validate-mcp-config.py --ci       # exit 1 on findings
  python3 scripts/validate-mcp-config.py --files <json> [<json> ...]
"""

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Documented exception: uv tool venvs (e.g. graphify) are absolute by design.
UV_TOOL_VENV_RE = re.compile(r"^/.*/\.local/share/uv/tools/[^/]+/bin/python")

# Token patterns (prefixes enough to catch real credentials, not placeholders).
SECRET_RE = re.compile(
    r"\b(ghp_|gho_|glsa_|secret_|sk-[A-Za-z0-9]{8,}|xox[baprs]-)[A-Za-z0-9_\-]+"
)

DEFAULT_FILES = [
    REPO_ROOT / "content/mcp/opencode-mcp.json",
    REPO_ROOT / "content/mcp/mcp.json",
    Path.home() / ".config/opencode/opencode.json",
]


def _iter_servers(cfg):
    """Yield (container_key, server_name, server_obj) for mcp / mcpServers."""
    for container in ("mcp", "mcpServers"):
        servers = cfg.get(container)
        if isinstance(servers, dict):
            for name, obj in servers.items():
                yield container, name, obj


def check_command(container, name, server, findings):
    cmd = server.get("command")
    if isinstance(cmd, list):
        if len(cmd) == 1 and " " in str(cmd[0]):
            findings.append(
                f"[{container}/{name}] flattened command array with spaces: {cmd!r} "
                f"(posix_spawn ENOENT). Split into [binary, arg, ...]."
            )
            return
        if not cmd:
            return
        first = str(cmd[0])
    else:
        first = str(cmd) if cmd else ""

    if not first:
        return

    if first.startswith("/") and not UV_TOOL_VENV_RE.match(first):
        findings.append(
            f"[{container}/{name}] absolute binary path {first!r} — use a bare "
            f"binary (npx/uvx/go) resolved via PATH for portability."
        )

    if name == "openspec":
        argv = (
            cmd
            if isinstance(cmd, list)
            else [str(cmd)] + [str(a) for a in server.get("args", [])]
        )
        if not (argv[:1] == ["npx"] and "-y" in argv):
            findings.append(
                f"[{container}/{name}] must run via ['npx', '-y', 'openspec-mcp'] "
                f"(PyPI uvx distribution is broken) — got {argv!r}"
            )


def check_env(container, name, server, findings):
    env = server.get("environment") if container == "mcp" else server.get("env")
    if isinstance(env, dict) and "PATH" in env:
        findings.append(
            f"[{container}/{name}] injects literal PATH into environment — remove; "
            f"servers inherit the agent runtime's PATH."
        )


def check_secrets(raw_text, findings):
    for m in SECRET_RE.finditer(raw_text):
        findings.append(f"secret-looking token pattern found: {m.group(0)[:12]}...")


def check_mount(container, name, server, findings):
    """Flag filesystem MCP servers mounted at filesystem root ('/').

    A '/' mount exposes whole-disk read/write to every agent that can call
    MCP tools (MCP tools are not gated by agent permission/tools blocks).
    Root must be narrowed to a project directory.
    """
    if name != "filesystem":
        return
    argv = []
    cmd = server.get("command")
    if isinstance(cmd, list):
        argv = list(cmd)
    args = server.get("args") or []
    argv += args if isinstance(args, list) else [str(args)]
    if "/" in argv:
        findings.append(
            f"[{container}/{name}] filesystem server mounted at '/' — grants "
            f"whole-disk MCP write access to every agent; narrow the root to "
            f"a project directory."
        )


def validate_file(path, findings):
    if not Path(path).exists():
        return
    try:
        raw = Path(path).read_text(encoding="utf-8")
        cfg = json.loads(raw)
    except (json.JSONDecodeError, OSError) as exc:
        findings.append(f"{path}: unreadable/invalid JSON ({exc})")
        return

    for container, name, server in _iter_servers(cfg):
        check_command(container, name, server, findings)
        check_env(container, name, server, findings)
        check_mount(container, name, server, findings)
    check_secrets(raw, findings)


def main():
    files = DEFAULT_FILES
    ci = "--ci" in sys.argv
    if "--files" in sys.argv:
        idx = sys.argv.index("--files")
        files = [Path(p) for p in sys.argv[idx + 1 :]]

    findings = []
    for f in files:
        validate_file(f, findings)

    if findings:
        print("MCP config validation FAILED:")
        for f in findings:
            print(f"  - {f}")
        if ci:
            sys.exit(1)
    else:
        print("MCP config validation passed (bare binaries, no PATH env, no secrets).")


if __name__ == "__main__":
    main()
