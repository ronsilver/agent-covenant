#!/usr/bin/env bats
# =============================================================================
# Regression tests for the benchmark harness (tests/benchmark/).
# Exactly 12 base no-spend cases + 1 T11 quality case = 13/13.
# No base case spends money, uses network access, mutates the repository, or
# launches `opencode`. A fake `opencode` fails the test if it is ever launched.
# Run: bats tests/test_benchmark.bats
# =============================================================================

setup() {
    REPO_ROOT="$BATS_TEST_DIRNAME/.."
    BENCH="$REPO_ROOT/tests/benchmark/benchmark.py"
    PY_DIR="$REPO_ROOT/tests/benchmark"
    MARKER="$BATS_TEST_TMPDIR/opencode-launched"
    FAKE_BIN="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$FAKE_BIN"
    cat >"$FAKE_BIN/opencode" <<'EOF'
#!/usr/bin/env bash
touch "$BENCH_LAUNCH_MARKER"
echo "opencode must never be launched by a no-spend test" >&2
exit 99
EOF
    chmod +x "$FAKE_BIN/opencode"
    export BENCH_LAUNCH_MARKER="$MARKER"
    export PATH="$FAKE_BIN:$PATH"
    rm -rf "$REPO_ROOT/tests/benchmark/out"
}

@test "benchmark --help exits 0" {
    run python3 "$BENCH" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"usage:"* ]]
    [ ! -e "$MARKER" ]
}

@test "invalid mode rejects" {
    run python3 "$BENCH" --mode bogus --dry-run
    [ "$status" -eq 2 ]
    [ ! -e "$MARKER" ]
}

@test "runs above max-runs rejects" {
    run python3 "$BENCH" --runs 11 --max-runs 10 --dry-run
    [ "$status" -eq 2 ]
    [ ! -e "$MARKER" ]
}

@test "invalid finite/cost cap rejects before spawn" {
    run python3 "$BENCH" --max-cost-usd -5 --dry-run
    [ "$status" -eq 2 ]
    run python3 "$BENCH" --jitter nan --dry-run
    [ "$status" -eq 2 ]

    # Isolation preflight gates on synthetic HOME/TMPDIR fixtures. The real
    # auth file is never read; the fake opencode proves zero launch.
    FAKE_HOME="$BATS_TEST_TMPDIR/fakehome"
    FAKE_TMP="$BATS_TEST_TMPDIR/tmp"
    mkdir -p "$FAKE_HOME/.local/share/opencode" "$FAKE_TMP"

    # missing auth.json -> isolation preflight exits 2
    run env HOME="$FAKE_HOME" TMPDIR="$FAKE_TMP" python3 "$BENCH" --mode baseline --prompts p1 --runs 1
    [ "$status" -eq 2 ]

    # invalid auth.json (not JSON) -> isolation preflight exits 2
    printf 'not json' >"$FAKE_HOME/.local/share/opencode/auth.json"
    run env HOME="$FAKE_HOME" TMPDIR="$FAKE_TMP" python3 "$BENCH" --mode baseline --prompts p1 --runs 1
    [ "$status" -eq 2 ]

    # valid auth but unremovable stale leftover -> residual fails the gate
    printf '{"ok": true}' >"$FAKE_HOME/.local/share/opencode/auth.json"
    : >"$FAKE_TMP/bench-baseline-home-stale"
    run env HOME="$FAKE_HOME" TMPDIR="$FAKE_TMP" python3 "$BENCH" --mode baseline --prompts p1 --runs 1
    [ "$status" -eq 2 ]
    [ ! -e "$MARKER" ]
}

@test "dry-run emits context and baseline commands and writes nothing" {
    run python3 "$BENCH" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"[context]"* ]]
    [[ "$output" == *"[baseline]"* ]]
    [ "$(grep -c "opencode run" <<<"$output" || true)" -eq 10 ]
    [ "$(grep -c -- "--format json" <<<"$output" || true)" -eq 10 ]
    [ "$(grep -c -- "--prompt-file" <<<"$output" || true)" -eq 0 ]
    [ "$(grep -c -- " --out " <<<"$output" || true)" -eq 0 ]
    [ "$(grep -c -- "--pure" <<<"$output" || true)" -eq 0 ]
    [ "$(grep -c "^HOME\[context\]=" <<<"$output" || true)" -eq 1 ]
    [ "$(grep -c "^HOME\[baseline\]=" <<<"$output" || true)" -eq 1 ]
    HOME_CTX="$(grep "^HOME\[context\]=" <<<"$output" | cut -d= -f2-)"
    HOME_BASE="$(grep "^HOME\[baseline\]=" <<<"$output" | cut -d= -f2-)"
    [ -n "$HOME_CTX" ] && [ -n "$HOME_BASE" ]
    [ "$HOME_CTX" != "$HOME_BASE" ]
    [ ! -e "$REPO_ROOT/tests/benchmark/out" ]
    [ ! -e "$MARKER" ]

    # --pure is defense-in-depth only: appended to all 10 commands when set
    run python3 "$BENCH" --dry-run --pure
    [ "$status" -eq 0 ]
    [ "$(grep -c -- "--pure" <<<"$output" || true)" -eq 10 ]
    [ ! -e "$MARKER" ]
}

@test "probe dry-run emits exactly two mode commands" {
    run python3 "$BENCH" --probe-only --dry-run
    [ "$status" -eq 0 ]
    [ "$(grep -c "^\[context\]" <<<"$output" || true)" -eq 1 ]
    [ "$(grep -c "^\[baseline\]" <<<"$output" || true)" -eq 1 ]
    [ "$(grep -c "opencode run" <<<"$output" || true)" -eq 2 ]
    [ "$(grep -c "^HOME\[context\]=" <<<"$output" || true)" -eq 1 ]
    [ "$(grep -c "^HOME\[baseline\]=" <<<"$output" || true)" -eq 1 ]
    [ ! -e "$MARKER" ]
}

@test "token normalization and derived formulas" {
    run python3 -c '
import sys
sys.path.insert(0, sys.argv[1])
from metrics import normalize_token_usage, compute_derived, SchemaError
assert normalize_token_usage(100, 10, 5) == 85.0
assert normalize_token_usage(0, 0, 0) == 0.0
try:
    normalize_token_usage(5, 10, 0)
    raise SystemExit("expected SchemaError")
except SchemaError:
    pass
try:
    normalize_token_usage(1, 1, float("nan"))
    raise SystemExit("expected SchemaError")
except SchemaError:
    pass
d = compute_derived({"billable_input": 100.0, "cost_usd": 0.5, "quality_score": 1.0,
                     "wall_ms": 1000.0, "tokens_total": 200.0, "success_rate": 1.0})
assert set(d) == {"quality_per_billable_input", "quality_per_cost", "tokens_per_second",
                  "cost_per_success", "tokens_per_success"}, d
' "$PY_DIR"
    [ "$status" -eq 0 ]
    [ ! -e "$MARKER" ]
}

@test "attempt schema accepts nullable timestamps and rejects missing fields" {
    run python3 -c '
import sys
sys.path.insert(0, sys.argv[1])
from schema import validate_attempt, SCHEMA_KEYS
base = dict.fromkeys(SCHEMA_KEYS, None)
base.update({
    "record_type": "attempt", "batch_id": "b", "logical_run_id": "l",
    "attempt_id": "a", "attempt_index": 0, "retry_of_attempt_id": None,
    "retry_reason": None, "mode": "context", "prompt_id": "p1",
    "prompt_file": "tests/benchmark/prompts/p1-manifest.md",
    "snapshot_path": "tests/benchmark/out/snapshot/prompts/p1-manifest.md",
    "snapshot_sha256": "0" * 64, "source_prompt_sha256": "0" * 64,
    "snapshot_read_only": True, "started_at": None, "finished_at": None,
    "timeout_s": 600.0, "timed_out": False, "wall_ms": 0, "first_token_ms": -1,
    "exit_code": 0, "session_id": None, "input_raw": 0, "cache_read": 0,
    "cache_write": 0, "reasoning": 0, "output": 0, "billable_input": 0,
    "tokens_total": 0, "cost_usd": 0.0, "cost_estimate_usd": 0.0,
    "reserved_cost_usd": 0.0, "released_cost_usd": 0.0,
    "cost_state": "not_reserved", "quality_score": 0.0,
    "instruction_adherence": 0.0, "success_rate": 0.0, "model_refusal": False,
    "stdout_path": "tests/benchmark/out/raw/a.stdout",
    "stderr_path": "tests/benchmark/out/raw/a.stderr",
    "raw_events_path": "tests/benchmark/out/raw/a.jsonl",
    "token_source": "export", "error_count": 0,
})
assert validate_attempt(base) == [], validate_attempt(base)
del base["prompt_id"]
assert validate_attempt(base), "missing field must be rejected"
' "$PY_DIR"
    [ "$status" -eq 0 ]
    [ ! -e "$MARKER" ]
}

@test "manifest parser accepts 63 entries and fails closed on malformed fixtures" {
    run python3 -c '
import sys
sys.path.insert(0, sys.argv[1])
from manifest import parse_manifest_skills
names = parse_manifest_skills(sys.argv[2])
assert len(names) == 63, len(names)
assert len(set(names)) == 63
' "$PY_DIR" "$REPO_ROOT/manifest.example.yaml"
    [ "$status" -eq 0 ]

    MALFORMED="$BATS_TEST_TMPDIR/malformed.yaml"
    cat >"$MALFORMED" <<'EOF'
skills:
  source_dir: "skills"
  directories:
    - accessibility-expert
    - accessibility-expert
    - {bad: yaml}
EOF
    run python3 -c '
import sys
sys.path.insert(0, sys.argv[1])
from manifest import parse_manifest_skills, ManifestError
try:
    parse_manifest_skills(sys.argv[2])
except ManifestError:
    sys.exit(2)
sys.exit(0)
' "$PY_DIR" "$MALFORMED"
    [ "$status" -eq 2 ]
    [ ! -e "$MARKER" ]
}

@test "timeout terminates continuous-stderr child process group" {
    run python3 -c '
import sys, time
sys.path.insert(0, sys.argv[1])
from process import run_command_with_timeout
import tempfile, os
out = tempfile.mkdtemp()
child = [sys.executable, "-c",
         "import sys, time\nwhile True:\n    sys.stderr.write(\"x\" * 1024)\n    sys.stderr.flush()"]
start = time.monotonic()
result = run_command_with_timeout(child, dict(os.environ), 1.0, out, "attempt-1")
elapsed = time.monotonic() - start
assert result["timed_out"] is True, result
assert elapsed < 15.0, elapsed
assert result["wall_ms"] > 0
assert result["exit_code"] != 0
assert os.path.getsize(result["stderr_path"]) > 0
' "$PY_DIR"
    [ "$status" -eq 0 ]
    [ ! -e "$MARKER" ]
}

@test "summary writer emits batch_meta then cell_summary with fixed rows" {
    run python3 -c '
import sys, json, tempfile, os
sys.path.insert(0, sys.argv[1])
from report import write_summary_jsonl
from metrics import RAW_METRICS, DERIVED_METRICS
bm = {
    "record_type": "batch_meta", "batch_id": "b1", "seed": 1,
    "cell_order": ["p1:context:1"], "selected_prompt_ids": ["p1"],
    "prompt_snapshot_sha256": "0" * 64,
    "inventories": {"context": {"counts": {"rules": 1, "skills": 63,
        "subagents": 17, "mcp_write_capable": 0}, "valid": True},
        "baseline": {"counts": {"rules": 0, "skills": 0, "subagents": 0,
        "mcp_write_capable": 0}, "valid": True}},
    "opencode_version": "x", "cumulative_cost_usd": 0.0,
}
def cell(mode):
    return {"record_type": "cell_summary", "batch_id": "b1", "mode": mode,
        "prompt_id": "p1", "logical_run_count": 1, "attempt_count": 1,
        "metrics": {m: {"median": 1.0, "iqr": 0.0} for m in RAW_METRICS},
        "derived": {m: {"median": 1.0, "iqr": 0.0} for m in DERIVED_METRICS}}
d = tempfile.mkdtemp()
p = os.path.join(d, "summary.jsonl")
write_summary_jsonl(p, [cell("context"), cell("baseline")], bm)
lines = open(p).read().splitlines()
first = json.loads(lines[0])
assert first["record_type"] == "batch_meta", first
assert len(lines) == 3
for raw in lines[1:]:
    row = json.loads(raw)
    assert row["record_type"] == "cell_summary", row
    assert set(row["metrics"]) == set(RAW_METRICS), row
    assert set(row["derived"]) == set(DERIVED_METRICS), row
bad = cell("context")
bad["metrics"]["bogus"] = {"median": 1.0, "iqr": 0.0}
try:
    write_summary_jsonl(os.path.join(d, "bad.jsonl"), [bad], bm)
    raise SystemExit("expected writer error")
except ValueError:
    pass
' "$PY_DIR"
    [ "$status" -eq 0 ]
    [ ! -e "$MARKER" ]
}

@test "snapshot is read-only, hash-stable, and output path is ignored" {
    run python3 -c '
import sys, tempfile, os
sys.path.insert(0, sys.argv[1])
from preflight import create_snapshot
d1, d2 = tempfile.mkdtemp(), tempfile.mkdtemp()
s1 = create_snapshot(["p1", "p5"], d1)
s2 = create_snapshot(["p1", "p5"], d2)
assert s1["read_only"] is True
assert s1["sha256"] == s2["sha256"], "snapshot hash must be stable"
p = os.path.join(d1, "snapshot", "prompts", "p1-manifest.md")
assert (os.stat(p).st_mode & 0o444) == 0o444, "snapshot must be read-only"
assert len(s1["files"]) == 2
' "$PY_DIR"
    [ "$status" -eq 0 ]
    run git -C "$REPO_ROOT" check-ignore tests/benchmark/out/
    [ "$status" -eq 0 ]
    [ ! -e "$MARKER" ]
}

@test "quality verdicts honor precedence and per-prompt thresholds" {
    run python3 -c '
import sys, os, tempfile
sys.path.insert(0, sys.argv[1])
from quality import compute_verdicts, VERDICT_KEYS, score_quality
from metrics import RAW_METRICS, DERIVED_METRICS, MODES, PROMPT_IDS
from schema import SCHEMA_KEYS, validate_attempt

def cell(mode, pid="p1", quality=1.0, adherence=1.0, success=1.0):
    c = {"record_type": "cell_summary", "batch_id": "b", "mode": mode,
         "prompt_id": pid, "logical_run_count": 1, "attempt_count": 1,
         "metrics": {m: {"median": 1.0, "iqr": 0.0} for m in RAW_METRICS},
         "derived": {m: {"median": 1.0, "iqr": 0.0} for m in DERIVED_METRICS}}
    c["metrics"]["quality_score"] = {"median": quality, "iqr": 0.0}
    c["metrics"]["instruction_adherence"] = {"median": adherence, "iqr": 0.0}
    c["metrics"]["success_rate"] = {"median": success, "iqr": 0.0}
    return c

def complete(quality=1.0, adherence=1.0, success=1.0):
    return [cell(m, p, quality=quality, adherence=adherence, success=success)
            for p in PROMPT_IDS for m in MODES]

def mk_attempt(mode="context", stdout=None, stderr=None):
    d = dict.fromkeys(SCHEMA_KEYS, None)
    d.update({
        "record_type": "attempt", "batch_id": "b", "logical_run_id": "l",
        "attempt_id": "a", "attempt_index": 0, "retry_of_attempt_id": None,
        "retry_reason": None, "mode": mode, "prompt_id": "p1",
        "prompt_file": "tests/benchmark/prompts/p1-manifest.md",
        "snapshot_path": "tests/benchmark/out/snapshot/prompts/p1-manifest.md",
        "snapshot_sha256": "0" * 64, "source_prompt_sha256": "0" * 64,
        "snapshot_read_only": True, "started_at": None, "finished_at": None,
        "timeout_s": 600.0, "timed_out": False, "wall_ms": 0, "first_token_ms": -1,
        "exit_code": 0, "session_id": None, "input_raw": 0, "cache_read": 0,
        "cache_write": 0, "reasoning": 0, "output": 0, "billable_input": 0,
        "tokens_total": 0, "cost_usd": 0.0, "cost_estimate_usd": 0.0,
        "reserved_cost_usd": 0.0, "released_cost_usd": 0.0,
        "cost_state": "not_reserved", "quality_score": 0.0,
        "instruction_adherence": 0.0, "success_rate": 0.0, "model_refusal": False,
        "stdout_path": stdout or "tests/benchmark/out/raw/a.stdout",
        "stderr_path": stderr or "tests/benchmark/out/raw/a.stderr",
        "raw_events_path": "tests/benchmark/out/raw/a.jsonl",
        "token_source": "export", "error_count": 0,
    })
    assert validate_attempt(d) == [], validate_attempt(d)
    return d

snapshot = {"path": "tests/benchmark/out/snapshot/prompts", "read_only": True,
            "files": ["a"], "sha256": "0" * 64}
inv_ok = {
    "context": {"valid": True, "counts": {"rules": 1, "skills": 63,
        "subagents": 17, "mcp_write_capable": 0}},
    "baseline": {"valid": True, "counts": {"rules": 0, "skills": 0,
        "subagents": 0, "mcp_write_capable": 0}},
}
inv_safety = {"context": {"valid": True, "safety_ok": False}, "baseline": {"valid": True}}

# safety violation yields FAIL for all four keys
v = compute_verdicts([cell("context"), cell("baseline")], inv_safety, snapshot, [])
assert v == {k: "FAIL" for k in VERDICT_KEYS}, v

# incomplete evidence yields INCONCLUSIVE for all four keys
v = compute_verdicts([cell("context")], inv_ok, snapshot, [])
assert v == {k: "INCONCLUSIVE" for k in VERDICT_KEYS}, v
assert set(v) == set(VERDICT_KEYS)

# eligibility requires a passed isolation smoke: None or FAIL is INCONCLUSIVE
v = compute_verdicts(complete(), inv_ok, snapshot, [mk_attempt()])
assert v == {k: "INCONCLUSIVE" for k in VERDICT_KEYS}, v
v = compute_verdicts(complete(), inv_ok, snapshot, [mk_attempt()], smoke_verdict="FAIL")
assert v == {k: "INCONCLUSIVE" for k in VERDICT_KEYS}, v

# smoke PASS + complete evidence reaches comparisons: equal medians -> FAIL
# for token/cost/efficiency, PASS for effectiveness
v = compute_verdicts(complete(), inv_ok, snapshot, [mk_attempt()], smoke_verdict="PASS")
assert v == {"token_optimization": "FAIL", "cost_reduction": "FAIL",
             "efficiency": "FAIL", "effectiveness": "PASS"}, v

# safety precedence holds even with a passed smoke
v = compute_verdicts(complete(), inv_safety, snapshot, [mk_attempt()], smoke_verdict="PASS")
assert v == {k: "FAIL" for k in VERDICT_KEYS}, v

# absolute threshold table: success_rate < 1.0 anywhere fails effectiveness
v = compute_verdicts(complete(success=0.9), inv_ok, snapshot,
                     [mk_attempt()], smoke_verdict="PASS")
assert v["effectiveness"] == "FAIL", v

# absolute threshold table: quality_score < 0.75 anywhere fails effectiveness
v = compute_verdicts(complete(quality=0.5), inv_ok, snapshot,
                     [mk_attempt()], smoke_verdict="PASS")
assert v["effectiveness"] == "FAIL", v

# any loaded-evidence marker in baseline stdout/stderr no longer fails effectiveness;
# only kernel literals cause failure
marker_dir = tempfile.mkdtemp()
marker_file = os.path.join(marker_dir, "baseline.stdout")
open(marker_file, "w").write("<GOVERN> loaded")  # kernel literal
v = compute_verdicts(complete(), inv_ok, snapshot,
                      [mk_attempt(mode="baseline", stdout=marker_file)],
                      smoke_verdict="PASS")
assert v["effectiveness"] == "FAIL", v

# skill name should NOT cause failure (advisory only)
marker_file2 = os.path.join(marker_dir, "baseline.stdout")
open(marker_file2, "w").write("golang-expert loaded")
v = compute_verdicts(complete(), inv_ok, snapshot,
                      [mk_attempt(mode="baseline", stdout=marker_file2)],
                      smoke_verdict="PASS")
assert v["effectiveness"] == "PASS", v

# p1 category grouping: sum of 63 counts passes, anything else fails
assert score_quality("p1", "{\"a\": 63}") == 1.0
assert score_quality("p1", "{\"a\": 62}") == 0.0
assert score_quality("p1", "not json") == 0.0
' "$PY_DIR"
    [ "$status" -eq 0 ]
    [ ! -e "$MARKER" ]
}
