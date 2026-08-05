# Bundled Resources Guide

## scripts/ - Executable Code

### When to Use

Include scripts when:
- PASS: The same code is being rewritten repeatedly
- PASS: Deterministic reliability is needed
- PASS: Operations are complex and error-prone
- PASS: Environment-specific setup is required

NEVER include scripts when:
- FAIL: Claude can easily write the code each time
- FAIL: Code needs frequent customization
- FAIL: It's a simple one-liner

### Examples

**Good script candidates:**
```python
# scripts/rotate_pdf.py
# Complex PDF manipulation with specific library usage
import PyPDF2
import sys

def rotate_pdf(input_path, degrees, output_path):
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

**Bad script candidate (too simple):**
```bash
# scripts/hello.sh
echo "Hello World"  # Claude can write this inline
```

### Testing Scripts

All scripts must be tested:
```bash
# Test script with sample input
python scripts/rotate_pdf.py input.pdf 90 output.pdf

# Verify output
ls -lh output.pdf
```

If there are many similar scripts, test a representative sample.

### Script Documentation

Include docstrings and usage examples:
```python
def process_data(input_file: str, config: dict) -> dict:
    """
    Process data file according to configuration.
    
    Args:
        input_file: Path to input CSV
        config: Processing configuration dict
        
    Returns:
        dict with processed results
        
    Example:
        >>> process_data('data.csv', {'normalize': True})
        {'rows': 100, 'status': 'success'}
    """
```

## references/ - Documentation

### When to Use

Include references when:
- PASS: Database schemas that don't change often
- PASS: API documentation Claude needs to reference
- PASS: Company-specific terminology or processes
- PASS: Detailed workflow guides
- PASS: Domain knowledge not in Claude's training data

NEVER include references when:
- FAIL: Information is already in Claude's training (general programming concepts)
- FAIL: Content is better suited for SKILL.md (core workflow)
- FAIL: Documentation duplicates SKILL.md

### Organization Patterns

#### Pattern 1: By Domain

```
references/
├── finance.md     - Revenue, billing metrics
├── sales.md       - Opportunities, pipeline
├── product.md     - API usage, features
└── marketing.md   - Campaigns, attribution
```

When user asks about sales metrics, Claude only reads `sales.md`.

#### Pattern 2: By Feature

```
references/
├── basic-usage.md      - Getting started
├── advanced-features.md - Complex patterns
├── api-reference.md    - Complete API
└── troubleshooting.md  - Common issues
```

#### Pattern 3: By Framework

```
references/
├── aws.md     - AWS deployment
├── gcp.md     - GCP deployment
└── azure.md   - Azure deployment
```

### Reference File Structure

For files >100 lines, include a table of contents:

```markdown
# Database Schema Reference

## Table of Contents
- [Users Table](#users-table)
- [Orders Table](#orders-table)
- [Products Table](#products-table)
- [Relationships](#relationships)

## Users Table
...
```

### Linking from SKILL.md

**Good linking (descriptive):**
```markdown
For database schema details, see [references/schema.md](references/schema.md)

When working with tracked changes, consult [references/redlining.md](references/redlining.md)
```

**Bad linking (non-descriptive):**
```markdown
See [here](references/schema.md)
More info [in this file](references/redlining.md)
```

## assets/ - Output Files

### When to Use

Include assets when:
- PASS: Templates that get copied and modified
- PASS: Images/icons used in generated output
- PASS: Boilerplate code structures
- PASS: Fonts or design resources

NEVER include assets when:
- FAIL: Files are for documentation (use references/)
- FAIL: Files are executable code (use scripts/)
- FAIL: Assets are easily found online

### Examples

#### Template Directory

```
assets/frontend-template/
├── package.json
├── tsconfig.json
├── src/
│   ├── App.tsx
│   ├── index.tsx
│   └── components/
│       └── README.md
└── public/
    └── index.html
```

Usage in SKILL.md:
```markdown
## Creating a New App

Copy the template:
```bash
cp -r assets/frontend-template/ ./my-new-app/
cd my-new-app
npm install
```

#### Brand Assets

```
assets/
├── logo.png          - Company logo
├── logo-dark.png     - Dark mode variant
├── favicon.ico       - Website icon
└── style-guide.pdf   - Design guidelines
```

#### Document Templates

```
assets/
├── proposal-template.docx
├── invoice-template.xlsx
└── slides-template.pptx
```

Usage:
```markdown
## Creating a Proposal

Start with the template:
- Copy `assets/proposal-template.docx`
- Update sections 1-5 with project details
- Replace placeholder text in brackets
```

## Avoiding Duplication

**Rule**: Information should live in ONE place.

**SKILL.md vs. references:**
- SKILL.md: Core workflow, essential steps, links to references
- references/: Detailed information, schemas, comprehensive guides

**Bad (duplicated):**
```markdown
# SKILL.md
## Database Schema
users table has: id, email, name...

# references/schema.md
## Users Table
id, email, name...
```

**Good (single source):**
```markdown
# SKILL.md
## Database Schema
See [references/schema.md](references/schema.md) for complete schema.

# references/schema.md
## Users Table
Full detailed schema here...
```

## Size Management

**Large files (>10k words):**

Include search patterns in SKILL.md:
```markdown
## API Reference

Complete API docs in [references/api.md](references/api.md)

Search for:
- "POST /api/users" - User creation
- "GET /api/orders" - Order retrieval
- "DELETE /api/products" - Product deletion
```

This helps Claude know what's available without loading the entire file.
