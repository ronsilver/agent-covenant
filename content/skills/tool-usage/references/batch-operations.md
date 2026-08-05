# Batch Operations Best Practices

Best practices for reading N files, editing 1 file in N places, and editing N
files. Goal: minimize tool calls while preserving context quality and diff
visibility.

## 1. Massive Reading Strategies

### Decision Matrix

| Scenario | Tool | Why | Context preserved |
|----------|------|-----|-------------------|
| Understand project structure | `directory_tree` first | Get layout before reading any file | Full structure |
| Find files matching pattern | `Glob` | No content read, just paths | Paths only |
| Search content across N files | `Grep` (with `include` filter) | Fast, no full file reads | Match + line |
| Search + surrounding context | `Grep` with `-A/-B/-C` flags | Gets match + N lines without full read | Match + N lines |
| Read N small files (<500 lines each) | `read_multiple_files` | Single call, all content in context | Full content |
| Read 1 large file (relevant section) | `Read(offset, limit)` | Targeted, avoids loading entire file | Section only |
| Read N large files (different sections) | Parallel `Read(offset, limit)` calls | Each call reads only needed section | Sections only |
| Deep understanding of entry point + deps | Read entry -> Grep imports -> Read deps JIT | Progressive disclosure | Full (targeted) |

### Strategy: Structure-First Progressive Disclosure

```
1. directory_tree -> understand layout (1 call)
2. Glob -> find relevant files by pattern (1 call)
3. Grep with context -> find specific content across files (1 call)
4. read_multiple_files -> read only the files that matched (1 call)
5. Read(offset, limit) -> deep-dive into specific sections (parallel calls)
```

### Anti-patterns

```bash
# BAD -- 20 sequential Read calls for 20 files (slow, expensive)
Read(file1); Read(file2); ... Read(file20)

# GOOD -- single read_multiple_files call
read_multiple_files(paths=[file1, file2, ..., file20])

# BAD -- grep -r without context, then assume understanding
grep -r "function" src/

# GOOD -- grep with context, then targeted reads
Grep(pattern="function", include="*.go", context=3)
# Then read_multiple_files on files that matched

# BAD -- reading entire 5000-line file for 1 section
Read(filePath="large.go")  # 5000 lines loaded

# GOOD -- read only the needed section
Read(filePath="large.go", offset=100, limit=50)

# BAD -- reading all files upfront "just in case"
Read(file1); Read(file2); Read(file3); Read(file4); Read(file5)

# GOOD -- read entry point, follow deps JIT
Read(entry.go) -> Grep(imports) -> Read(dep1.go) -> Read(dep2.go)
```

## 2. Batch Editing of a Single File

### Rule: Read ONCE, Edit ALL in ONE call

The `edit_file` tool accepts an `edits[]` array -- multiple independent edits to
the same file in a single call. This is 5-10x more efficient than N sequential
Edit calls.

### Pattern

```
1. Read file (ONCE)
2. Identify ALL edits needed
3. Single edit_file call with edits[] array containing all changes
4. Verify (optional re-read or grep)
```

### When to use replaceAll

- Same string appears N times and ALL must change -> `replaceAll: true`
- Different strings in different locations -> separate `edits[]` entries

### Examples

```bash
# BAD -- 3 sequential Edit calls for 3 changes in 1 file
Edit(file, oldText="port: 8080", newText="port: 9090")
Edit(file, oldText="host: localhost", newText="host: 0.0.0.0")
Edit(file, oldText="debug: true", newText="debug: false")

# GOOD -- 1 Edit call with 3 edits in edits[] array
Edit(file, edits=[
  {oldText: "port: 8080", newText: "port: 9090"},
  {oldText: "host: localhost", newText: "host: 0.0.0.0"},
  {oldText: "debug: true", newText: "debug: false"}
])

# BAD -- re-reading between edits (wasted context)
Read(file) -> Edit(file, change1) -> Read(file) -> Edit(file, change2)

# GOOD -- read once, edit all
Read(file) -> Edit(file, edits=[change1, change2])
```

### Anti-patterns

- N sequential `edit_file` calls to the same file (1 change per call)
- Re-reading the file between edits (stale context risk, wasted tokens)
- Using `sed -i` when `edit_file` exists (no diff visibility, T2 risk)
- Using `replaceAll` when edits are different (use `edits[]` array instead)

## 3. Multi-File Editing

### Safe Pattern (recommended)

```
1. Glob -> identify all target files (1 call)
2. read_multiple_files -> read all in 1 call (or parallel Read for large files)
3. Parallel edit_file calls (1 per file, all in same message)
4. Single git add for all modified files
```

### Bash Loop Pattern (limited use)

ONLY for: identical simple text replacement across N files (same old -> same new).
NEVER for: structured data (YAML/JSON/CSV) -- use yq/jq + Write.
Trade-off: faster but no per-file diff visibility, harder to rollback.

```bash
# BAD -- sequential edits for independent files
Edit(file1, change)
Edit(file2, change)
Edit(file3, change)

# GOOD -- parallel edits for independent files (same message)
Edit(file1, change)  # |
Edit(file2, change)  # |-- all in same message
Edit(file3, change)  # |

# BAD -- find | xargs sed -i on structured data (destructive, no diff)
find . -name "*.yaml" -exec sed -i 's/example.io/example.com/g' {} +

# GOOD -- yq + Write for structured data
for f in $(find . -name "*.yaml"); do
  yq -i '.domain = "example.com"' "$f"
done
```

### Anti-patterns

- `find | xargs sed -i` on structured data (breaks quoting, no diff, T2+)
- Sequential `edit_file` calls when files are independent (should be parallel)
- Editing without reading first (violates read-before-edit rule)
- Single git commit mixing unrelated changes across files
- Bash loop for complex transforms (use parallel Edit calls for diff visibility)

## Cross-references

- File operations (Read/Edit/Write) -> [tool-selection.md](tool-selection.md)
- Parallel execution rules -> [parallel-execution.md](parallel-execution.md)
- Orchestration patterns -> [orchestration.md](orchestration.md)
