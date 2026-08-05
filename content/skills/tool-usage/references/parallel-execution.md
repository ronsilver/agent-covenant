# Parallel Execution Rules

## Can Execute in Parallel
- Independent file reads (different files)
- Independent searches (different patterns/paths)
- Read + grep + glob (no data dependency)
- Multiple API calls to different services
- Fetching multiple URLs

## Must Execute Sequentially
- Read before Edit/Write (must know current content)
- Write before Bash (for git operations)
- Edit before validate (verify changes)
- Test after code changes
- Build after dependencies install

## Batch Execution
- N similar operations -> single Bash with loop
- Multiple edits to same file -> single Edit with replaceAll or multiple independent edits
- Multiple writes -> parallel Write calls (different files)

## Anti-Patterns
- Reading a file just written without re-read (stale context)
- Editing same file in parallel (race condition)
- Assuming tool output without explicit check
- Chaining too many sequential calls (batch them)
