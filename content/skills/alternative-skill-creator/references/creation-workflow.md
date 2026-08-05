# Skill Creation Workflow

## Overview

Skill creation involves six steps, executed in order:

1. **Understand** - Get concrete examples
2. **Plan** - Identify reusable resources
3. **Initialize** - Generate skill template
4. **Edit** - Implement resources and instructions
5. **Package** - Validate and create .skill file
6. **Iterate** - Test and improve

## Step 1: Understanding the Skill with Concrete Examples

**Goal**: Clearly understand how the skill will be used in practice

**When to skip**: Only when usage patterns are already clearly understood

### Process

Ask the user for concrete examples of skill usage:

**Good questions:**
- "What functionality should this skill support?"
- "Can you give some examples of how this skill would be used?"
- "What would a user say that should trigger this skill?"
- "Are there edge cases or advanced scenarios to consider?"

**Example conversation for image-editor skill:**

> "What functionality should the image-editor skill support? Editing, rotating, anything else?"
>
> "Can you give examples of how this skill would be used?"
>
> "I can imagine users asking for things like 'Remove the red-eye from this image' or 'Rotate this image'. Are there other ways you imagine this skill being used?"

**Tips:**
- Avoid overwhelming users with too many questions at once
- Start with the most important questions
- Follow up as needed for clarity
- Generate example queries if user is unsure

**Completion criteria**: Clear sense of the functionality the skill should support

## Step 2: Planning Reusable Skill Contents

**Goal**: Identify what scripts, references, and assets would be helpful

### Analysis Process

For each concrete example, ask:

1. How would I execute this from scratch?
2. What would I need to look up or rewrite repeatedly?
3. What scripts, references, or assets would help?

### Examples

**Example 1: PDF Editor Skill**

User query: "Help me rotate this PDF"

Analysis:
1. Rotating a PDF requires specific library knowledge (PyPDF2)
2. Code is the same each time, just different parameters
3. **Solution**: Create `scripts/rotate_pdf.py`

**Example 2: Frontend Webapp Builder**

User queries:
- "Build me a todo app"
- "Build me a dashboard to track my steps"

Analysis:
1. Both require the same HTML/React boilerplate
2. Starting from scratch wastes time
3. **Solution**: Create `assets/hello-world/` template with boilerplate

**Example 3: BigQuery Analytics**

User query: "How many users logged in today?"

Analysis:
1. Requires knowing table schemas (users, events, etc.)
2. Schema discovery is time-consuming each time
3. **Solution**: Create `references/schema.md` with table documentation

### Resource Type Decision Tree

```
Is the content executable code?
├─ Yes → Put in scripts/
└─ No → Is it used in output?
    ├─ Yes → Put in assets/
    └─ No → Put in references/
```

**Output**: List of resources to create:
- scripts/ files: Executable code for deterministic tasks
- references/ files: Documentation and schemas
- assets/ files: Templates and output resources

## Step 3: Initializing the Skill

**Goal**: Create the skill directory structure

**When to skip**: Only if skill already exists and you're iterating

### Running init_skill.py

```bash
scripts/init_skill.py <skill-name> --path <output-directory>
```

**Example:**
```bash
scripts/init_skill.py pdf-editor --path ./content/skills/
```

### What the Script Creates

```
pdf-editor/
├── SKILL.md                    # Template with TODO placeholders
├── scripts/
│   └── example_script.py       # Example to customize or delete
├── references/
│   └── example_reference.md    # Example to customize or delete
└── assets/
    └── example_asset.txt       # Example to customize or delete
```

### After Initialization

- Review generated SKILL.md template
- Delete example files you don't need
- Prepare to add your planned resources

## Step 4: Editing the Skill

**Goal**: Implement all planned resources and write SKILL.md instructions

### 4.1: Implement Bundled Resources

**Start with resources first** (scripts, references, assets) before writing SKILL.md.

#### Creating Scripts

```python
# scripts/rotate_pdf.py
"""Rotate PDF pages by specified degrees."""
import PyPDF2
import sys

def rotate_pdf(input_path: str, degrees: int, output_path: str) -> None:
    """
    Rotate all pages in a PDF.

    Args:
        input_path: Path to input PDF
        degrees: Rotation angle (90, 180, 270)
        output_path: Path for output PDF
    """
    with open(input_path, 'rb') as pdf_file:
        pdf_reader = PyPDF2.PdfReader(pdf_file)
        pdf_writer = PyPDF2.PdfWriter()

        for page in pdf_reader.pages:
            page.rotate(degrees)
            pdf_writer.add_page(page)

        with open(output_path, 'wb') as output_file:
            pdf_writer.write(output_file)

if __name__ == '__main__':
    rotate_pdf(sys.argv[1], int(sys.argv[2]), sys.argv[3])
```

**Testing scripts:**
```bash
# Test with sample input
python scripts/rotate_pdf.py input.pdf 90 output.pdf

# Verify output
ls -lh output.pdf
```

**Important**: All scripts must be tested before packaging. If there are many similar scripts, test a representative sample.

#### Creating References

```markdown
# references/schema.md

# Database Schema

## Users Table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| email | VARCHAR(255) | User email (unique) |
| created_at | TIMESTAMP | Account creation time |

## Events Table

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | Foreign key to users.id |
| event_type | VARCHAR(50) | Event type (login, logout, etc.) |
| timestamp | TIMESTAMP | Event time |
```

#### Creating Assets

```
assets/frontend-template/
├── package.json
├── src/
│   ├── App.tsx
│   └── index.tsx
└── public/
    └── index.html
```

**Note**: This step may require user input. For example:
- Brand guidelines skill → User provides logos, templates
- Company policies skill → User provides policy documents

### 4.2: Write SKILL.md

**Writing guidelines**: Always use imperative/infinitive form.

#### Update Frontmatter

```yaml
---
name: pdf-editor
description: Comprehensive PDF manipulation including rotation, merging, splitting, and text extraction. Use when working with PDF files for document processing, form filling, or content extraction.
---
```

**Description best practices:**
- Include what the skill does
- Include when to use it (triggers)
- List key capabilities
- Be specific about use cases
- Max 1024 characters (official limit)

#### Write Body

Structure the body to guide skill usage:

**1. Overview**
```markdown
# PDF Editor

Comprehensive PDF manipulation with rotation, merging, splitting, and extraction.
```

**2. Core workflow**
```markdown
## Quick Operations

### Rotate PDF
```bash
scripts/rotate_pdf.py input.pdf 90 output.pdf
```

### Merge PDFs
```bash
scripts/merge_pdfs.py file1.pdf file2.pdf output.pdf
```
```

**3. Link to references**
```markdown
## Advanced Features

- **Form filling**: See [references/forms.md](references/forms.md)
- **Text extraction**: See [references/extraction.md](references/extraction.md)
```

**4. Constraints and best practices**
```markdown
## Best Practices

- Always validate PDFs before processing
- Use `--dry-run` flag for testing
- Check output file size for corruption
```

### 4.3: Learn Proven Design Patterns

Before finalizing SKILL.md, consult:

- **Output quality patterns**: [references/output-patterns.md](references/output-patterns.md)
- **Script design**: [references/using-scripts.md](references/using-scripts.md)
- **Evaluating skill quality**: [references/evaluating-skills.md](references/evaluating-skills.md)
- **Optimizing descriptions**: [references/optimizing-descriptions.md](references/optimizing-descriptions.md)

#### Pattern: Gotchas Section

The highest-value content in many skills is a list of environment-specific facts that defy reasonable assumptions — concrete corrections to mistakes the agent will make without being told:

```markdown
## Gotchas

- The `users` table uses soft deletes. Always include `WHERE deleted_at IS NULL`.
- User ID is `user_id` in the DB, `uid` in auth service, `accountId` in billing. All the same value.
- `/health` returns 200 even if the DB is down. Use `/ready` for full health.
```

Keep gotchas **in SKILL.md** — not in a reference file — so the agent reads them before encountering the situation.

#### Pattern: Checklist for Multi-Step Workflows

An explicit checklist helps the agent track progress and avoid skipping steps:

```markdown
## Processing Workflow

- [ ] Step 1: Analyze form (`scripts/analyze_form.py`)
- [ ] Step 2: Create field mapping (`fields.json`)
- [ ] Step 3: Validate mapping (`scripts/validate_fields.py`)
- [ ] Step 4: Fill form (`scripts/fill_form.py`)
- [ ] Step 5: Verify output (`scripts/verify_output.py`)
```

#### Pattern: Validation Loop

Instruct the agent to validate its own work before moving on:

```markdown
## Editing Workflow

1. Make your edits
2. Run validation: `python scripts/validate.py output/`
3. If validation fails: review error, fix issues, run again
4. Only proceed when validation passes
```

#### Pattern: Plan-Validate-Execute

For batch or destructive operations — have the agent create a plan, validate it, then execute:

```markdown
## PDF Form Filling

1. Extract fields: `python scripts/analyze_form.py input.pdf` → `form_fields.json`
2. Create `field_values.json` mapping each field name to its intended value
3. Validate: `python scripts/validate_fields.py form_fields.json field_values.json`
   (checks names exist, types compatible, required fields present)
4. If validation fails, revise `field_values.json` and re-validate
5. Fill: `python scripts/fill_form.py input.pdf field_values.json output.pdf`
```

The key is step 3: errors like "Field 'signature_date' not found" give the agent enough info to self-correct.

#### Principle: Start from Real Expertise

A common pitfall is asking an LLM to generate a skill without domain-specific context — relying on general training knowledge. The result is vague, generic procedures.

**Effective skills come from:**
- Completing a real task in conversation, then extracting the reusable pattern
- Feeding actual project artifacts: runbooks, API specs, code review comments, incident reports, version history
- Capturing corrections you made during the task ("use library X instead of Y", "check for edge case Z")

A skill synthesized from your team's actual runbooks will outperform one from generic best-practices articles — it captures *your* schemas, failure modes, and recovery procedures.

### 4.4: Clean Up

Delete any example files not needed:
```bash
rm scripts/example_script.py
rm references/example_reference.md
rm assets/example_asset.txt
```

## Step 5: Packaging the Skill

**Goal**: Validate and create distributable .skill file

### Official Validation (skills-ref)

The official `skills-ref` CLI validates your skill against the spec:

```bash
skills-ref validate ./my-skill
```

This checks frontmatter validity and naming conventions. Install from [github.com/agentskills/agentskills](https://github.com/agentskills/agentskills).

### Local Validation (quick_validate.py)

Alternatively, use the bundled script for a quick local check:

```bash
scripts/quick_validate.py <path/to/skill-folder>
```

### Running package_skill.py

```bash
scripts/package_skill.py <path/to/skill-folder>
```

**With output directory:**
```bash
scripts/package_skill.py <path/to/skill-folder> ./dist
```

### Validation Checks

The script automatically validates:

**Frontmatter validation:**
- PASS YAML format is correct
- PASS Required fields present (name, description)
- PASS `name` ≤64 chars, lowercase-with-hyphens, no consecutive hyphens, matches directory name
- PASS `description` ≤1024 characters

**Structure validation:**
- PASS SKILL.md exists
- PASS Skill naming conventions followed
- PASS Directory structure is correct

**Resource validation:**
- PASS Referenced files exist
- PASS No broken links in SKILL.md
- PASS File organization follows best practices

### Handling Validation Errors

If validation fails:

1. Read error messages carefully
2. Fix reported issues
3. Run packaging command again

**Common errors:**
```
Error: Missing required field 'description' in frontmatter
→ Fix: Add description to YAML frontmatter

Error: Referenced file not found: references/missing.md
→ Fix: Create the file or remove the reference

Error: Skill name must use lowercase with hyphens
→ Fix: Rename skill directory to follow convention
```

### Successful Packaging

On success, creates:
```
pdf-editor.skill
```

This .skill file is a zip archive containing all skill files, ready for distribution.

## Step 6: Iteration

**Goal**: Improve skill based on real usage

### Iteration Workflow

1. **Use the skill** on real tasks
2. **Notice struggles**
   - What took longer than expected?
   - What information was missing?
   - What was unclear?
3. **Identify improvements**
   - Add missing scripts
   - Clarify instructions in SKILL.md
   - Add references for complex topics
4. **Implement changes**
   - Update files
   - Test changes
5. **Re-package**
   - Run `package_skill.py` again
   - Share updated .skill file

### Common Iteration Patterns

**Pattern 1: Adding Missing Resources**

User reports: "I keep having to write the same validation code"

Solution:
```bash
# Add validation script
cat > scripts/validate_pdf.py << 'EOF'
def validate_pdf(filepath):
    # validation logic
    pass
EOF

# Update SKILL.md to reference it
echo "Use scripts/validate_pdf.py to validate PDFs" >> SKILL.md
```

**Pattern 2: Clarifying Instructions**

User feedback: "Not sure when to use merge vs concatenate"

Solution:
```markdown
# Add to SKILL.md

## Merge vs. Concatenate

| Operation | Use When | Script |
|-----------|----------|--------|
| Merge | Combining pages, preserve bookmarks | `merge_pdfs.py` |
| Concatenate | Simple append, no metadata | `concat_pdfs.py` |
```

**Pattern 3: Splitting Verbose Content**

SKILL.md grows to 600 lines

Solution:
```bash
# Extract advanced features to reference
mv sections_advanced.md references/advanced-features.md

# Update SKILL.md
echo "For advanced features, see [references/advanced-features.md]" >> SKILL.md
```

### Best Timing for Iteration

**Immediately after use** - Feedback is fresh and context is still loaded

**After multiple uses** - Patterns of struggle become clear

**When users request** - Direct feedback on pain points

## Complete Example Walkthrough

### Creating a "CSV Analyzer" Skill

**Step 1: Understanding**

User examples:
- "Analyze this sales data CSV and find trends"
- "Check this transaction log for anomalies"
- "Generate summary statistics for this dataset"

**Step 2: Planning**

Resources needed:
- `scripts/analyze_csv.py` - Statistical analysis
- `scripts/detect_anomalies.py` - Outlier detection
- `references/analysis-types.md` - Guide to analysis methods

**Step 3: Initialize**

```bash
scripts/init_skill.py csv-analyzer --path ./content/skills/
```

**Step 4: Edit**

Create scripts:
```python
# scripts/analyze_csv.py
import pandas as pd
import sys

df = pd.read_csv(sys.argv[1])
print(df.describe())
print(f"\nMissing values:\n{df.isnull().sum()}")
```

Create references:
```markdown
# references/analysis-types.md

## Descriptive Analysis
Basic statistics: mean, median, std dev

## Diagnostic Analysis
Identify outliers and anomalies

## Predictive Analysis
Trend analysis and forecasting
```

Update SKILL.md:
```markdown
---
name: csv-analyzer
description: Analyze CSV files with statistics, anomaly detection, and visualization. Use for data analysis, quality checks, or generating insights from tabular data.
---

# CSV Analyzer

## Quick Analysis
```bash
scripts/analyze_csv.py data.csv
```

## Analysis Types
See [references/analysis-types.md](references/analysis-types.md)
```

**Step 5: Package**

```bash
scripts/package_skill.py ./content/skills/csv-analyzer/
# Creates: csv-analyzer.skill
```

**Step 6: Iterate**

After first use, user says: "Would be nice to have visualization"

Add:
```python
# scripts/visualize_csv.py
import matplotlib.pyplot as plt
import pandas as pd
# visualization code
```

Update SKILL.md, re-package, done!
