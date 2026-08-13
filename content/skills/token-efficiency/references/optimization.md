# KV-Cache, Observation Masking & Partitioning

Technical optimization techniques that extend effective context capacity.
Complement [compression.md](compression.md) — apply these BEFORE compaction.

## KV-Cache Optimization (apply FIRST — zero quality risk)

**MANDATORY ordering** to maximize cache hit rate:

```
1. System prompt         ← immutable, NEVER interpolate timestamps/IDs
2. Tool definitions      ← stable across turns
3. Reused templates      ← few-shot examples, static reference docs
4. Conversation history  ← grows per turn
5. Current query         ← ALWAYS last (dynamic content)
```

## Model-Specific Cache Minimums (CORRECTED -- not generation-based, per-model)

Cache checkpoint minimum tokens vary BY MODEL, not by generation number:
| Model | Min tokens/checkpoint | Max checkpoints | TTL options |
|-------|----------------------|-----------------|-------------|
| Claude 3.7 Sonnet | 1,024 | 4 | 5 min |
| Claude 3.5 Sonnet v2 | 1,024 | 4 | 5 min |
| Claude Opus 4 | 1,024 | 4 | 5 min |
| Claude Sonnet 4.6 | 1,024 | 4 | 5 min |
| Claude Opus 4.5 | 4,096 | 4 | 5 min, 1 hr |
| Claude Opus 4.6 | 4,096 | 4 | 5 min |
| Claude Haiku 4.5 | 4,096 | 4 | 5 min, 1 hr |
| Claude Sonnet 4.5 | 4,096 | 4 | 5 min, 1 hr |

Source: https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-caching.html (accessed 2026-06-30, V-graded)

CRITICAL: sub-minimum prompt prefix = 0% cache hit silently. Inference succeeds but no caching occurs. ALWAYS verify the target model's minimum before placing cache checkpoints.

## TTL Ordering Rule

Cache entries with longer TTL MUST appear before shorter TTLs. A 1-hour cache entry must appear before any 5-minute cache entries. Reversed order = cache invalidation.
Use 1-hour TTL when: follow-up prompts may exceed 5 minutes (long-running agents, chat with slow user response). Use 5-minute TTL when: prompts repeat more frequently than every 5 minutes (refreshed at no extra charge).

Target: **70%+ hit rate** → 50%+ cost reduction, 40%+ latency reduction.

Rules:
- NEVER embed `Date.now()`, request IDs, or dynamic values in system prompt — invalidates cache prefix
- Static docs must come BEFORE conversation history in the context order
- Cache breakpoints: max 4 per request, placed at end of tools / system / ref_docs

## Prompt-Cache Keep-Warm (long-idle sessions)

On sessions with long idle gaps, ping the ~1h prompt-cache checkpoint just BEFORE expiry with a minimal 0.1x-prefix request (cache read only, no generation) to avoid up to 2x input re-write on resume. Use at most 2 pings per pause. Auto-tripwire: if pings stop paying (cache hit ratio does not recover), STOP pinging and accept the re-write.

Source: ooples/token-optimizer (master catalog #114 token-optimizer).

## Observation Masking (largest capacity gains — apply SECOND)

Tool outputs routinely reach 80%+ of total trajectory tokens. Mask aggressively.

**NEVER mask:**
- Current task critical content
- Most recent turn
- Active reasoning chain
- Errors during active debugging (last 3 turns)

**Mask after 3+ turns** (replace with compact reference):
```
[Obs:{ref_id} elided. Key: {one-line summary}. Retrieve: {hash|ID|offset|path}]
```

## Reversibility Contract (MANDATORY -- zero data loss)

Every observation mask MUST include a retrieval handle: hash, ID, offset, or file path.
Without a retrieval handle, masked content is LOST -- the agent cannot recover it.

**Irreversible masking** (no handle, content permanently dropped) is permitted ONLY for:
- Proven-disposable content (duplicate outputs, already-summarized, boilerplate headers)
- Content explicitly confirmed as non-recoverable-needed by the task

Source: https://headroom-docs.vercel.app/docs/ccr (CCR -- zero data-loss compression, accessed 2026-06-30)

Quality check: after masking, verify the retrieval handle resolves to the original content. If it does not, NEVER mask.

**Mask immediately:**
- Duplicate outputs (same tool, same params)
- Boilerplate headers / pagination metadata
- Already-summarized outputs

## PreToolUse vs PostToolUse Output Reduction

PostToolUse compactors (34 Bash compactors) run AFTER output returns: they can only ADD context (their value is persistence across compaction, never current-turn shrink). Real current-turn reduction requires a PreToolUse rewrite — edit the command BEFORE it runs so the captured output is already small.

Manifest minimization: fewer exposed tools = fewer manifest tokens (15 tools ~1.5KT vs 68 ~6KT; thin inputSchema -44%). Trim the tool surface before tuning output hooks.

## Pre-Entry Filtering (G11) -- intercept BEFORE context entry

Distinct from observation masking (post-entry). Pre-entry filtering intercepts tool output BEFORE it enters LLM context -> filters/indexes -> returns summary + search interface.

Source: rtk-ai/rtk (CLI proxy, 60-90% per command, 4 strategies: filter/group/truncate/dedupe, accessed 2026-06-30, V-graded) + mksglu/context-mode (sandbox + FTS5/BM25, strict-compression formula pct=(1-With/Without)*100, ~98% claimed, [unverified]).

Mechanism:
```
tool output -> pre-entry filter -> [filter: remove noise] -> [group: aggregate similar] -> [truncate: keep relevant] -> [dedupe: collapse repeats] -> filtered summary enters LLM context
```

Graceful degradation: on filter failure, passthrough RAW output (save full unfiltered output on failure so LLM can read it without re-executing).

### QUALITY CLAUSE (G11 -- MANDATORY)

Keep errors UNMASKED. Only filter large successful responses. Error messages, stack traces, and failure output MUST pass through unfiltered. Filtering an error = hiding root cause = quality failure.

NEVER filter:
- Error output (non-zero exit codes, stderr, exception traces)
- Security-sensitive output (secrets, credentials, PII)
- Output the user explicitly requested in full

Filter ONLY:
- Large successful command output (ls, tree, test runs, build logs)
- Duplicate/repeated content
- Boilerplate headers and pagination metadata

Target: **60-80% reduction, <2% quality impact**.

## Ghost Token Detection (G13)

Ghost tokens = tokens loaded into context but NEVER referenced by the task. Sources: redundant context, outdated memory, leaked system prompts, unreferenced CLAUDE.md sections.

Source: nadimtuhin/claude-token-optimizer (ghost-scanner hook, accessed 2026-06-30, V-graded) + ooples/token-optimizer-mcp (compression skip-guard: if compressed >= original, skip and cache original, V-graded) + alexgreensh/token-optimizer (per-session token decomposition: cache_write, cache_read, fresh_input, output; 3-tier savings: Measured/Estimated/Opportunity, [unverified]).

Detection:
1. Scan context for sections loaded but not referenced in current task
2. Flag as "ghost" candidates
3. Skip-guard: if compressed size >= original size, skip compression (no savings = do not compress, cache original)

### QUALITY CLAUSE (G13 -- MANDATORY)

Archive flagged sections, NEVER delete. Same principle as cto prune (archives, never deletes). Review before archiving -- a section unreferenced in one task may be critical in the next. Archiving preserves recoverability; deleting destroys it.

NEVER archive:
- System prompt sections (core identity, safety rules)
- Currently active task context
- Error context from last 3 turns

## JIT Context Injection (G14) -- keyword-matched context loading

Inject context files ONLY when the user's prompt keywords match the file topic. Zero token cost for non-matching files.

Source: nadimtuhin/claude-token-optimizer (JIT injection hook, 88% reduction 11K -> 1.3K [unverified self-reported], accessed 2026-06-30, V-graded).

Mechanism:
```
user prompt -> extract keywords -> match against file stems in docs/learnings/ -> inject matching files (sorted by match score) -> LLM sees relevant context + zero cost for irrelevant files
```

Env vars (confirmed from source):
```
CTO_LEARNINGS_DIR    = docs/learnings    (default)
CTO_MAX_INJECT_FILES = 3                 (default: max 3 files per prompt)
CTO_MAX_INJECT_WORDS = 1500              (default: ~2000 tokens max injected)
```

### QUALITY CLAUSE (G14 -- MANDATORY)

Cap injections: <=3 files, <=1500 words per injection. Keyword matching is NAIVE (substring/stem matching) -> false positives possible (e.g. "db" matches "database" AND "debounce"). Consider embeddings for precision in production. Human review of injection set recommended for high-stakes tasks.

NEVER inject:
- Files exceeding word cap (truncate or skip)
- Files with zero keyword matches
- System/internal files (only user-facing learning docs)

Quality check: after injection, verify the injected content is relevant to the task. If injected content misleads the agent (wrong context), the keyword match was a false positive -- NEVER use naive matching for precision-critical tasks.

## Partitioning (last resort — coordination overhead is real)

Use sub-agents with isolated contexts ONLY when:
- Estimated context > 60% of limit AND
- Task decomposes into ≥3 independent subtasks (break-even threshold)

```
savings = (tokens_avoided × cost_per_token)
overhead = coordinator_turns × avg_turn_cost
enable_partitioning = savings > overhead
```

Reserve 5-10% of total budget as buffer for coordinator messages.
NEVER partition for <3 subtasks — overhead exceeds savings.

## Decision Order

```
1. KV-cache ordering    → apply always (free wins)
2. Observation masking  → apply when tool outputs > 50% of context
3. Compaction           → apply at 70-80% utilization (see compression.md)
4. Partitioning         → apply only when ≥3 independent subtasks + near limit
```

| Dominant component  | First action                    | Second action              |
|---------------------|---------------------------------|----------------------------|
| Tool outputs (>50%) | Masking                         | Compaction of remaining    |
| Retrieved docs      | Summarization                   | Partitioning if independent|
| Message history     | Compaction                      | Partitioning for subtasks  |
| Multiple sources    | KV-cache → masking + compaction |                            |
| Active debugging    | Mask resolved only              | Preserve recent errors     |
