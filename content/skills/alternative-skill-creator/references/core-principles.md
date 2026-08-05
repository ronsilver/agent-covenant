# Core Principles

## Concise is Key

The context window is a public good. Skills share the context window with everything else Claude needs:
- System prompt
- Conversation history
- Other skills' metadata
- The actual user request

**Default assumption: Claude is already very smart.**

Only add context Claude doesn't already have. Challenge each piece of information:
- "Does Claude really need this explanation?"
- "Does this paragraph justify its token cost?"

**Prefer concise examples over verbose explanations.**

## Set Appropriate Degrees of Freedom

Match the level of specificity to the task's fragility and variability.

### High Freedom (Text-Based Instructions)

**When to use:**
- Multiple approaches are valid
- Decisions depend on context
- Heuristics guide the approach

**Example:**
```markdown
## Refactoring Strategy

Review the code and identify:
1. Duplicated logic that can be extracted
2. Complex functions that should be split
3. Unclear naming that should be improved
```

### Medium Freedom (Pseudocode or Scripts with Parameters)

**When to use:**
- A preferred pattern exists
- Some variation is acceptable
- Configuration affects behavior

**Example:**
```python
# rotate_image.py
def rotate_image(input_path: str, degrees: int, output_path: str):
    """Rotate image by specified degrees"""
    # Implementation allows parameter variation
```

### Low Freedom (Specific Scripts, Few Parameters)

**When to use:**
- Operations are fragile and error-prone
- Consistency is critical
- A specific sequence must be followed

**Example:**
```bash
#!/bin/bash
# deploy.sh - MUST be run in this exact order
set -e
docker build -t myapp:latest .
docker tag myapp:latest registry.example.com/myapp:latest
docker push registry.example.com/myapp:latest
kubectl apply -f k8s/deployment.yaml
kubectl rollout status deployment/myapp
```

## Mental Model: Path Exploration

Think of Claude as exploring a path:

- **Narrow bridge with cliffs** → Needs specific guardrails (low freedom)
- **Open field** → Allows many routes (high freedom)

## Token Budget Guidelines

| Content Type | Guideline |
|--------------|-----------|
| **Core workflow** | Essential, keep concise |
| **Examples** | 1-2 minimal examples, not exhaustive |
| **Explanations** | Only if non-obvious to Claude |
| **Error handling** | Only critical failure modes |
| **Background info** | Rarely needed, Claude knows general concepts |

## When to Elaborate vs. When to Be Concise

### Elaborate When
- Domain-specific terminology that Claude won't know
- Company-specific processes or schemas
- Critical constraints that must not be violated
- Non-standard tool usage

### Be Concise When
- General programming concepts
- Standard library usage
- Common patterns Claude already knows
- Self-explanatory workflows
