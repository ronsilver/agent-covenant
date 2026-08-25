#!/usr/bin/env python3
"""Preflight inventories, immutable snapshot, and repo fingerprint for the
opencode benchmark harness. Stdlib only.

- ``context`` inventory: 1 global rule, 71 skills, 17 subagents, 0
  write-capable MCP servers (the harness configures its own sanitized MCP
  fixtures; it never reads the repository's live MCP config).
- ``baseline`` inventory: 0 global rules, 0 skills, 0 subagents, 0
  write-capable MCP servers.
"""

import hashlib
import json
import os
import shutil
import tempfile
from pathlib import Path

from manifest import parse_manifest_skills

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
CONTENT = REPO_ROOT / "content"
RULES_DIR = CONTENT / "rules" / "agents"
SUBAGENTS_DIR = CONTENT / "subagents"
SKILLS_DIR = CONTENT / "skills"
MCP_FIXTURE_DIR = Path(__file__).resolve().parent / "mcp-fixtures"
PROMPTS_DIR = Path(__file__).resolve().parent / "prompts"

CONTEXT_COUNTS = {"rules": 1, "skills": 71, "subagents": 17, "mcp_write_capable": 0}
BASELINE_COUNTS = {"rules": 0, "skills": 0, "subagents": 0, "mcp_write_capable": 0}
CONTEXT_GLOBAL_RULE = "opencode-global.md"
ENV_ALLOWLIST_KEYS = ("HOME", "LANG", "PATH", "TMPDIR")

# Baseline isolation: the baseline process runs with a per-batch temp HOME
# that contains only a byte-for-byte copy of the real auth.json. The temp
# HOME is created under the system temp dir with a fixed prefix so stale
# leftovers can be swept and any residual fails the gate.
BASELINE_HOME_PREFIX = "bench-baseline-home-"
AUTH_REL_PATH = Path(".local/share/opencode/auth.json")
APP_SUPPORT_OPENDCODE_DIR = Path("/Library/Application Support/opencode")

# Loaded-evidence marker catalog (baseline must contain no marker). Literal
# kernel markers plus the deterministic catalog sources; counts are validated
# and any drift fails closed.
KERNEL_MARKER_LITERALS = ("<GOVERN>", "## Core Skills Compliance")


class IsolationError(RuntimeError):
    """Raised when the baseline isolation preflight fails closed."""


def sha256_bytes(data):
    return hashlib.sha256(data).hexdigest()


def file_sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return digest.hexdigest()


def env_allowlist_hash(env):
    """Hash of the explicit environment allowlist (names and values)."""
    digest = hashlib.sha256()
    for key in sorted(env):
        digest.update(key.encode("utf-8"))
        digest.update(b"\x00")
        digest.update(str(env[key]).encode("utf-8"))
        digest.update(b"\x00")
    return digest.hexdigest()


def build_env_allowlist():
    """Explicit environment allowlist for the benchmarked process."""
    return {key: os.environ[key] for key in ENV_ALLOWLIST_KEYS if key in os.environ}


def build_env(mode, batch_home=None):
    """Explicit environment for one canonical mode; only HOME differs.

    context runs with the real user HOME; baseline runs with the per-batch
    temp HOME (``batch_home``). When no batch home exists (dry-run/probe
    display), the deterministic placeholder string is used."""
    if mode == "context":
        home = os.path.expanduser("~")
    elif batch_home is not None:
        home = str(batch_home)
    else:
        home = os.path.join(tempfile.gettempdir(), f"{BASELINE_HOME_PREFIX}<dry-run>")
    return {
        "HOME": home,
        "LANG": os.environ.get("LANG", ""),
        "PATH": os.environ.get("PATH", ""),
        "TMPDIR": os.environ.get("TMPDIR", ""),
    }


def _subagent_names():
    paths = sorted(SUBAGENTS_DIR.glob("*.md"))
    paths = [p for p in paths if p.name != "README.md"]
    if len(paths) != CONTEXT_COUNTS["subagents"]:
        raise RuntimeError(f"expected 17 subagents, found {len(paths)}")
    names = []
    for path in paths:
        text = path.read_text(encoding="utf-8")
        if not text.startswith("---"):
            raise RuntimeError(f"subagent missing frontmatter: {path.name}")
        for line in text.splitlines()[1:]:
            if line == "---":
                break
            if line.startswith("name:"):
                names.append(line.split(":", 1)[1].strip().strip('"'))
                break
        else:
            raise RuntimeError(f"subagent missing name: field: {path.name}")
    return names


def _mcp_server_names():
    path = CONTENT / "mcp" / "opencode-mcp.json"
    try:
        with open(path, "r", encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, ValueError) as exc:
        raise RuntimeError(f"mcp config unreadable: {path.name}") from exc
    servers = data.get("mcp", {})
    if not isinstance(servers, dict) or not servers:
        raise RuntimeError(f"mcp config has no servers: {path.name}")
    return sorted(servers)


def marker_catalog():
    """Deterministic loaded-evidence marker catalog for the baseline smoke.

    Returns the four catalog sections plus a flat sorted ``markers`` list of
    case-sensitive substrings the baseline stdout/stderr must not contain.
    Counts are validated and any drift fails closed."""
    skill_names = sorted(
        path.name
        for path in SKILLS_DIR.iterdir()
        if path.is_dir() and (path / "SKILL.md").is_file() and path.name != "_TEMPLATE"
    )
    if len(skill_names) != CONTEXT_COUNTS["skills"]:
        raise RuntimeError(f"expected 71 skills, found {len(skill_names)}")
    subagent_names = sorted(_subagent_names())
    global_rules = sorted(path.name for path in RULES_DIR.glob("*-global.md"))
    if not global_rules:
        raise RuntimeError("no *-global.md kernel rule files found")
    mcp_names = _mcp_server_names()
    sections = {
        "skills": skill_names,
        "subagents": subagent_names,
        "global_rules": global_rules,
        "mcp": mcp_names,
    }
    markers = sorted(
        set(skill_names + subagent_names + global_rules + mcp_names)
        | set(KERNEL_MARKER_LITERALS)
    )
    return {**sections, "markers": markers}


def _real_home():
    return Path(os.path.expanduser("~"))


def check_app_support_opencode():
    """Fail closed when the macOS app-support opencode dir exists non-empty."""
    path = APP_SUPPORT_OPENDCODE_DIR
    if not path.exists():
        return
    if not path.is_dir():
        raise IsolationError(f"{path} exists and is not a directory")
    if any(path.iterdir()):
        raise IsolationError(f"{path} is not empty")


def validate_real_auth():
    """The real auth.json must exist, be readable, and be valid JSON. The
    bytes are never logged; the runner prints only ``auth copy: ok|failed``."""
    auth = _real_home() / AUTH_REL_PATH
    if not auth.is_file():
        raise IsolationError("auth.json missing in the real user HOME")
    try:
        with open(auth, "r", encoding="utf-8", errors="strict") as handle:
            json.load(handle)
    except (OSError, ValueError) as exc:
        raise IsolationError("auth.json is not readable or not valid JSON") from exc
    return auth


def _sweep_stale_baseline_homes():
    root = Path(tempfile.gettempdir())
    for entry in sorted(root.glob(f"{BASELINE_HOME_PREFIX}*")):
        if entry.is_dir():
            try:
                shutil.rmtree(entry)
            except OSError as exc:
                raise IsolationError(
                    f"stale baseline-home could not be removed: {entry.name}"
                ) from exc
        else:
            raise IsolationError(
                f"stale baseline-home leftover is not a directory: {entry.name}"
            )
    residual = list(root.glob(f"{BASELINE_HOME_PREFIX}*"))
    if residual:
        raise IsolationError(
            f"stale baseline-home leftover remains: {residual[0].name}"
        )


def _verify_home_tree(home):
    expected = {AUTH_REL_PATH}
    found = set()
    for path in home.rglob("*"):
        if path.is_file():
            found.add(path.relative_to(home))
    if found != expected:
        raise IsolationError(f"temp HOME tree mismatch: {sorted(found)}")


def build_baseline_home():
    """Create the per-batch temp HOME with the byte-for-byte auth copy.

    Stale leftovers under the system temp dir are swept first and any
    residual fails the gate. The temp HOME is chmod 0700; the auth copy is
    chmod 0600; the post-copy tree must be exactly ``{auth.json}``."""
    _sweep_stale_baseline_homes()
    auth = validate_real_auth()
    home = Path(tempfile.mkdtemp(prefix=BASELINE_HOME_PREFIX))
    try:
        os.chmod(home, 0o700)
        auth_dst = home / AUTH_REL_PATH
        auth_dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(auth, auth_dst)
        os.chmod(auth_dst, 0o600)
        _verify_home_tree(home)
    except Exception:
        shutil.rmtree(home, ignore_errors=True)
        raise
    print("auth copy: ok")
    return home


def cleanup_baseline_home(batch_home):
    """Idempotent removal of the per-batch temp HOME."""
    if batch_home is None:
        return
    shutil.rmtree(batch_home, ignore_errors=True)


def command_hash(cmd):
    return sha256_bytes("\n".join(cmd).encode("utf-8"))


def fixture_tree_hash():
    """Hash of the prompt fixture tree (relative path + bytes)."""
    digest = hashlib.sha256()
    for path in sorted(PROMPTS_DIR.glob("*.md")):
        digest.update(path.name.encode("utf-8"))
        digest.update(b"\x00")
        digest.update(file_sha256(path).encode("utf-8"))
        digest.update(b"\x00")
    return digest.hexdigest()


def _load_rules(mode):
    if mode == "baseline":
        return []
    path = RULES_DIR / CONTEXT_GLOBAL_RULE
    if not path.is_file():
        raise RuntimeError(f"missing global rule: {path}")
    return [str(path.relative_to(REPO_ROOT))]


def _load_skills(mode):
    if mode == "baseline":
        return []
    return parse_manifest_skills(REPO_ROOT / "manifest.yaml")


def _load_subagents(mode):
    if mode == "baseline":
        return []
    paths = sorted(SUBAGENTS_DIR.glob("*.md"))
    paths = [p for p in paths if p.name != "README.md"]
    if len(paths) != 17:
        raise RuntimeError(f"expected 17 subagents, found {len(paths)}")
    return [str(p.relative_to(REPO_ROOT)) for p in paths]


def _mcp_fixture(mode):
    """The harness configures zero write-capable MCP servers for both modes.

    Sanitized read-only fixtures are installed by the runner before launch;
    the inventory records the fixture hash and a write-capable count of 0."""
    digest = hashlib.sha256()
    if MCP_FIXTURE_DIR.is_dir():
        for path in sorted(MCP_FIXTURE_DIR.rglob("*")):
            if path.is_file():
                digest.update(str(path.relative_to(MCP_FIXTURE_DIR)).encode())
                digest.update(file_sha256(path).encode())
    return {
        "write_capable": 0,
        "fixture_dir": str(MCP_FIXTURE_DIR.relative_to(REPO_ROOT)),
        "fixture_hash": digest.hexdigest(),
    }


def build_inventory(mode, batch_home=None):
    """Build one observable preflight inventory for the given canonical mode.

    The environment-allowlist hash is computed per mode over the explicit
    allowlist (only HOME differs: real user HOME for context, the per-batch
    temp HOME for baseline)."""
    rules = _load_rules(mode)
    skills = _load_skills(mode)
    subagents = _load_subagents(mode)
    mcp = _mcp_fixture(mode)
    counts = CONTEXT_COUNTS if mode == "context" else BASELINE_COUNTS
    expected = CONTEXT_COUNTS if mode == "context" else BASELINE_COUNTS
    valid = (
        len(rules) == expected["rules"]
        and len(skills) == expected["skills"]
        and len(subagents) == expected["subagents"]
        and mcp["write_capable"] == expected["mcp_write_capable"]
    )
    return {
        "mode": mode,
        "valid": valid,
        "counts": counts,
        "loaded_evidence": {
            "rules": rules,
            "skills": skills[:5],
            "skill_count": len(skills),
            "subagents": subagents,
        },
        "hashes": {
            "fixture_tree": fixture_tree_hash(),
            "mcp_fixture": mcp["fixture_hash"],
            "env_allowlist": env_allowlist_hash(build_env(mode, batch_home)),
        },
        "mcp": mcp,
    }


def _iter_fingerprint_files():
    """Tracked and required untracked files, sorted by relative path."""
    paths = []
    import subprocess

    proc = subprocess.run(
        ["git", "-C", str(REPO_ROOT), "ls-files"],
        capture_output=True,
        text=True,
        check=True,
    )
    for line in proc.stdout.splitlines():
        if line.strip():
            paths.append(REPO_ROOT / line)
    for name in ("manifest.yaml",):
        path = REPO_ROOT / name
        if path.is_file():
            paths.append(path)
    return sorted(set(paths), key=lambda p: str(p.relative_to(REPO_ROOT)))


def repo_fingerprint():
    """Fingerprint tracked + required untracked files. Symlinks are recorded
    as links and never followed; file mode changes fail the fingerprint."""
    digest = hashlib.sha256()
    for path in _iter_fingerprint_files():
        rel = str(path.relative_to(REPO_ROOT))
        digest.update(rel.encode("utf-8"))
        digest.update(b"\x00")
        if path.is_symlink():
            digest.update(b"link\x00" + os.readlink(path).encode("utf-8"))
            continue
        digest.update(f"mode:{oct(path.stat().st_mode & 0o777)}\x00".encode())
        digest.update(file_sha256(path).encode("utf-8"))
        digest.update(b"\x00")
    return digest.hexdigest()


def snapshot_hash(prompt_files):
    """Canonical hash over sorted tuples (relative path, mode, length, bytes)."""
    digest = hashlib.sha256()
    entries = []
    for path in prompt_files:
        data = path.read_bytes()
        entries.append((path.name, oct(path.stat().st_mode & 0o777), len(data), data))
    for name, mode, length, data in sorted(entries, key=lambda e: e[0]):
        digest.update(name.encode("utf-8"))
        digest.update(b"\x00" + mode.encode("utf-8"))
        digest.update(b"\x00" + str(length).encode("utf-8"))
        digest.update(b"\x00" + data)
        digest.update(b"\x00")
    return digest.hexdigest()


def _display_path(path):
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def create_snapshot(prompt_ids, out_dir):
    """Copy selected prompts to out/snapshot/prompts/, read-only, return dict."""
    snapshot_root = Path(out_dir) / "snapshot" / "prompts"
    snapshot_root.mkdir(parents=True, exist_ok=True)
    copied = []
    for prompt_id in prompt_ids:
        src = PROMPTS_DIR / f"{prompt_id}-{_prompt_name(prompt_id)}.md"
        dst = snapshot_root / src.name
        if dst.exists():
            dst.unlink()
        data = src.read_bytes()
        with open(dst, "wb") as handle:
            handle.write(data)
        os.chmod(dst, 0o444)
        copied.append(dst)
    return {
        "path": _display_path(snapshot_root),
        "read_only": True,
        "files": [_display_path(p) for p in copied],
        "sha256": snapshot_hash(copied),
    }


def _prompt_name(prompt_id):
    return {
        "p1": "manifest",
        "p2": "create-skill",
        "p3": "review-script",
        "p4": "subagent-flow",
        "p5": "validate-content",
    }[prompt_id]
