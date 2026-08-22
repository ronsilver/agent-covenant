#!/usr/bin/env python3
"""Process-group launch, bounded draining, and timeout termination for the
opencode benchmark harness. Stdlib only.

Timeout safety: children launch with start_new_session=True; on timeout the
process group receives TERM, waits within the bound, then KILL if needed.
Stdout and stderr are drained by separate threads into files, never into
memory, so a child that writes continuously cannot cause unbounded growth.
"""

import os
import signal
import subprocess
import threading
import time
from pathlib import Path

from events import read_events_file, session_id_of, write_events_file

DEFAULT_GRACE_S = 2.0
DRAIN_CHUNK = 65536


def _drain(stream, path):
    with open(path, "w", encoding="utf-8", errors="replace") as handle:
        while True:
            chunk = stream.read(DRAIN_CHUNK)
            if chunk == "":
                break
            handle.write(chunk)
    try:
        stream.close()
    except OSError:
        pass


def _terminate_group(proc, grace_s):
    try:
        os.killpg(os.getpgid(proc.pid), signal.SIGTERM)
    except (ProcessLookupError, PermissionError, OSError):
        pass
    try:
        proc.wait(timeout=grace_s)
        return
    except subprocess.TimeoutExpired:
        pass
    try:
        os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
    except (ProcessLookupError, PermissionError, OSError):
        pass


def run_command_with_timeout(cmd, env, timeout_s, out_dir, attempt_id):
    """Run cmd with bounded timeout and process-group termination.

    Returns a dict with exit_code, timed_out, wall_ms, stdout_path,
    stderr_path, events_path, and events. Never raises on timeout; never
    blocks past bounded joins. When the stream contains no parseable events,
    events_path and events are None (recorded as a missing-usage failure,
    never as a zero-usage success)."""
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    stdout_path = out / f"{attempt_id}.stdout"
    stderr_path = out / f"{attempt_id}.stderr"
    events_path = out / f"{attempt_id}.jsonl"
    start = time.monotonic()
    proc = subprocess.Popen(
        cmd,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        start_new_session=True,
        text=True,
        errors="replace",
    )
    drain_out = threading.Thread(
        target=_drain, args=(proc.stdout, stdout_path), daemon=True
    )
    drain_err = threading.Thread(
        target=_drain, args=(proc.stderr, stderr_path), daemon=True
    )
    drain_out.start()
    drain_err.start()
    timed_out = False
    returncode = None
    try:
        returncode = proc.wait(timeout=timeout_s)
    except subprocess.TimeoutExpired:
        timed_out = True
        _terminate_group(proc, DEFAULT_GRACE_S)
        try:
            returncode = proc.wait(timeout=DEFAULT_GRACE_S + 1.0)
        except subprocess.TimeoutExpired:
            returncode = -1
    wall_ms = int((time.monotonic() - start) * 1000.0)
    drain_out.join(timeout=DEFAULT_GRACE_S + 1.0)
    drain_err.join(timeout=DEFAULT_GRACE_S + 1.0)
    events = None
    events_path_str = None
    session_id = None
    parsed = read_events_file(stdout_path)
    if parsed:
        write_events_file(events_path, parsed)
        events = parsed
        events_path_str = str(events_path)
        session_id = session_id_of(parsed)
    return {
        "exit_code": returncode if returncode is not None else -1,
        "timed_out": timed_out,
        "wall_ms": wall_ms,
        "stdout_path": str(stdout_path),
        "stderr_path": str(stderr_path),
        "events_path": events_path_str,
        "events": events,
        "session_id": session_id,
    }
