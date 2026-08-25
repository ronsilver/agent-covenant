# Benchmark Harness for `opencode run`

Deterministic, stdlib-only Python 3 harness for measuring the `context`
configuration (1 global rule, 71 skills, 17 subagents, 0 write-capable MCP
servers) against `baseline` (0/0/0/0). `paired` is a CLI selection meaning
"run both canonical modes"; it is not a third execution mode. No artifact uses
an obsolete singular benchmark path or stale mode terminology.

Baseline isolation: the baseline process runs with a per-batch temp HOME
(`bench-baseline-home-*`, chmod `0700`) containing only a byte-for-byte copy of
the real `auth.json` (chmod `0600`). The context process keeps the real user
HOME. The repo-root `AGENTS.md` is a project rule that loads in both modes and
is therefore excluded from the baseline `0/0/0/0` counts.

## Fixture tree

```text
tests/benchmark/
├── README.md            # this file
├── benchmark.py         # CLI runner, preflight gates, snapshot, execution
├── manifest.py          # exact skills.directories parser (fail closed)
├── metrics.py           # raw/derived metric lists, formulas, cost reservation
├── preflight.py         # inventories, immutable snapshot, repo fingerprint
├── process.py           # process-group launch, draining, timeout termination
├── quality.py           # per-prompt quality scores and batch verdicts
├── records.py           # authoritative attempt-record factory
├── report.py            # render_header, write_summary_jsonl, smoke verdicts
├── schema.py            # attempt-schema validation (nullable timestamps)
├── mcp-fixtures/        # sanitized read-only MCP fixtures (0 write-capable)
└── prompts/             # five immutable UTF-8 prompt files (one line + LF)
```

The Bats suite lives at `tests/test_benchmark.bats` and contains exactly
**13 tests** (12 base no-spend cases + 1 T11 quality case).

## Preflight inventories

Each canonical mode produces an observable inventory with loaded artifact
paths, counts, hashes, fixture-tree hash, environment-allowlist hash, command
hash, and repository fingerprint:

| Mode | rules | skills | subagents | write-capable MCP |
|---|---|---|---|---|
| context | 1 (`content/rules/agents/opencode-global.md`) | 71 | 17 | 0 |
| baseline | 0 | 0 | 0 | 0 |

Any inventory error or missing loaded evidence exits `2`/`INCONCLUSIVE`
before any `Popen`. The harness configures its own sanitized, read-only MCP
fixtures with zero write-capable servers; it never reads the repository's live
MCP config. The environment is an explicit allowlist (`HOME`, `LANG`, `PATH`,
`TMPDIR`; only `HOME` differs per mode); secret values are never serialized.

## Isolation smoke (`--smoke`)

The isolation gate runs before any live batch. It forces `paired`/`p1`/`runs=1`
and rejects `--dry-run`, `--probe-only`, any explicit `--mode` other than
`paired`, any `--prompts`, and any `--runs` (exit `2`). Flow: check the macOS
app-support opencode dir (absent or empty), validate the real `auth.json`
(exists, readable, valid JSON — bytes never logged; only `auth copy: ok|failed`
is printed), build the per-batch temp HOME with the byte-for-byte auth copy and
verify the post-copy tree is exactly `{auth.json}`, sweep stale
`bench-baseline-home-*` leftovers (a residual fails the gate), then run context
and baseline once each.

Exit codes: `0` PASS, `1` FAIL (marker found or invalid baseline), `2`
INCONCLUSIVE (isolation preflight failed closed). A smoke verdict JSON is
always written to `tests/benchmark/out/smoke-<batch_id>.json` and printed to
stdout. The verdict object has exactly 10 keys: `record_type` ("smoke"),
`batch_id`, `marker_absent`, `markers_found`, `input_raw_context`,
`input_raw_baseline`, `input_raw_ratio` (context/baseline; `"N/A"` when
baseline `input_raw` is 0; reported, not gating), `baseline_exit_code`,
`baseline_usage_event_valid` (baseline attempt `error_count == 0`),
`verdict`.

The loaded-evidence marker catalog is deterministic: 71 skill names
(`content/skills/*/` excluding `_TEMPLATE`), 17 subagent names (`name:`
frontmatter, excluding `README.md`), the `*-global.md` kernel rule filenames,
the 12 MCP server names from `content/mcp/opencode-mcp.json`, plus the literal
kernel markers `<GOVERN>` and `## Core Skills Compliance`. **Only the two kernel
literals are decisive for the smoke gate**: their absence yields PASS, presence
yields FAIL. The full catalog is advisory and counted in `markers_found` but
never gates the smoke verdict. Counts are validated and any drift fails closed.

## Snapshot contract

Before any `Popen`, selected prompts are copied to
`tests/benchmark/out/snapshot/prompts/`, set read-only (mode `0444`), and hashed
canonically over sorted tuples `(relative path, mode, byte length, bytes)`.
Every run reads only this snapshot. Source drift is fingerprinted separately
and can never alter a run.

## Timeout and process safety

Children launch with `start_new_session=True`, separate stdout/stderr drainer
threads, and bounded joins. On timeout the process group receives TERM, waits
within the bound, then KILL if needed. Records `timeout_s`, `timed_out`,
`wall_ms`, exit status, and all paths. A child writing continuously to stderr
is terminated without deadlock or unbounded memory growth.

## Cost reservation

A present cap is validated as finite and non-negative before any spawn. Empty,
negative, NaN, infinity, or malformed values fail closed. Before every probe,
attempt, and retry:

```text
observed_cost + reserved_cost + estimate <= cap
```

Every attempt retains estimate, reservation, release, actual cost, and cost
state. Actual cost is never discarded; probe cost is included in
reconciliation.

## Canonical attempt schema

The single attempt schema lives in `schema.py` (`SCHEMA_KEYS`); `records.py`
builds records and `metrics.py` re-exports `validate_attempt`. Nullable
timestamp rules are strict: before launch both timestamps may be null; a
launched attempt requires both ISO-8601 UTC values with
`finished_at >= started_at`. `first_token_ms` uses `-1` as the "no first token
observed" sentinel.

## Exact report APIs

```python
render_header(batch_meta, inventories, snapshot, verdicts)
write_summary_jsonl(path, summaries, batch_meta)
write_smoke_verdict(path, verdict)
validate_smoke_verdict(path)
```

`write_summary_jsonl` writes one fixed `batch_meta` object as line one and
fixed `cell_summary` objects thereafter. Markdown compare tables use the 12 raw
metric rows in exact raw-list order followed by the 5 derived rows in exact
derived-list order; row names are the metric names only. Report files are
`tests/benchmark/out/report-<batch_id>.md`, `runs-<batch_id>.jsonl`,
`summary-<batch_id>.jsonl`, and `smoke-<batch_id>.json`.

## Metrics

Raw (12): `billable_input`, `cache_read`, `cache_write`, `reasoning`, `output`,
`tokens_total`, `cost_usd`, `wall_ms`, `first_token_ms`, `quality_score`,
`instruction_adherence`, `success_rate`.

Derived (5): `quality_per_billable_input`, `quality_per_cost`,
`tokens_per_second`, `cost_per_success`, `tokens_per_success`.

Normalization: `billable_input = input_raw - cache_read - cache_write`.
Missing, negative, or non-finite values are rejected.

## Verdicts

`compute_verdicts(cells, inventories, snapshot, attempts, *, smoke_verdict=None)`
returns exactly `token_optimization`, `cost_reduction`, `efficiency`,
`effectiveness`, each `PASS`, `FAIL`, or `INCONCLUSIVE`. Precedence: safety or
cost-cap violation yields `FAIL`; incomplete evidence yields `INCONCLUSIVE`;
eligible comparisons yield `PASS`/`FAIL`. Eligibility requires a passed
isolation smoke (`smoke_verdict == "PASS"`; `None` or any other value is
`INCONCLUSIVE`), both canonical modes, all five prompts, equal run counts,
complete attempt accounting, valid inventories, matching fingerprints, valid
immutable snapshot, finite normalized values, valid cost reconciliation, and
no safety violation. `effectiveness` additionally fails on any loaded-evidence
marker in a baseline attempt's stdout/stderr (missing output files are
skipped, never fatal). The deterministic threshold table is fixed:
`quality_score >= 0.75`, `instruction_adherence >= 0.75`, and
`success_rate == 1.0` per prompt; p1 additionally requires a non-empty category
grouping whose counts sum to the validated 71 skills.

## Limitations of structural quality proxies

`quality_score`, `instruction_adherence`, and `success_rate` are deterministic
substring/structure checks. They do **not** measure semantic correctness,
factuality, or user value. Derived utility metrics never replace a primary
dimension and never change a verdict.

## Make targets

| Target | Behavior |
|---|---|
| `make benchmark-dry` | Print context and baseline commands; write nothing |
| `make benchmark-probe` | Probe dry-run; emit exactly two mode commands |
| `make benchmark` | Live benchmark: `MODE=context\|baseline\|paired RUNS=5 MAX_RUNS=10` |

## Separate live benchmark command

The isolation smoke (spends ~$0.15) runs before any live batch; then the
isolated live run (spends money, needs approval) is invoked directly after all
no-spend checks pass:

```bash
python3 tests/benchmark/benchmark.py --smoke --model opencode-go/deepseek-v4-flash
python3 tests/benchmark/benchmark.py --mode paired --runs 5 --max-runs 10
```

It retains every attempt and reconciles observed, reserved, estimated, and
actual cost.

## Verification

```bash
bats tests/test_benchmark.bats          # exactly 13/13
python3 tests/benchmark/benchmark.py --help   # exit 0
```
