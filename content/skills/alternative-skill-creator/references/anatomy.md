# Skill Anatomy

## Complete Structure

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter metadata (required)
│   │   ├── name: (required)
│   │   ├── description: (required)
│   │   └── compatibility: (optional, rarely needed)
│   └── Markdown instructions (required)
└── Bundled Resources (optional)
    ├── scripts/          - Executable code (Python/Bash/etc.)
    ├── references/       - Documentation (loaded as needed)
    └── assets/           - Output files (templates, icons, fonts)
```

## SKILL.md (Required)

Every SKILL.md consists of two parts:

### Frontmatter (YAML)

Required fields:
- **name**: Skill identifier — max 64 chars, lowercase letters/numbers/hyphens only, must not start/end with a hyphen, no consecutive hyphens (`--`), **must match the parent directory name**
- **description**: What the skill does + when to use it — max 1024 characters

Optional fields:
- **license**: License name or reference to a bundled license file
- **metadata**: Arbitrary key-value mapping for additional metadata
- **compatibility**: Environment requirements (rarely needed) — max 500 characters; include only if skill has specific environment needs (intended product, required system packages, network access, etc.)
- **allowed-tools**: YAML list of pre-approved tool patterns the skill may use *(experimental — support varies by agent implementation)*. Example: `["Bash(git *)", "Read", "LSP"]`
- **applyTo**: YAML list of glob patterns for file-based activation. Example: `["**/*.tf", "**/*.py"]`. Acts as a pre-filter — the skill body should still validate content heuristics.
- **setup**: YAML list of pre-session initialization commands as declarative hints. Example: `["terraform --version"]`. Not guaranteed execution; documents expected tooling.

**Critical**: Only `name` and `description` are read by Claude to determine when the skill triggers. Make the description clear and comprehensive.

**Example:**
```yaml
---
name: docx-editor
description: Comprehensive document creation, editing, and analysis with support for tracked changes, comments, formatting preservation, and text extraction. Use when Claude needs to work with professional documents (.docx files) for: (1) Creating new documents, (2) Modifying or editing content, (3) Working with tracked changes, (4) Adding comments, or any other document tasks
license: MIT
---
```

### Body (Markdown)

Instructions and guidance for using the skill. Only loaded AFTER the skill triggers.

**Content guidelines:**
- Keep under 500 lines
- Use imperative/infinitive form
- Include workflow steps
- Link to bundled resources
- Avoid verbose explanations

## Bundled Resources (Optional)

### scripts/ Directory

**Purpose**: Executable code for deterministic, repeatable tasks

**When to include:**
- Same code is being rewritten repeatedly
- Deterministic reliability is needed
- Complex operations that are error-prone when written from scratch

**Examples:**
```
scripts/
├── rotate_pdf.py          - Rotate PDF pages
├── extract_tables.py      - Extract tables from documents
└── batch_convert.sh       - Batch file conversion
```

**Benefits:**
- Token efficient (may be executed without loading into context)
- Deterministic output
- Tested and reliable

**Note:** Scripts may still need to be read by Claude for:
- Patching or bug fixes
- Environment-specific adjustments
- Understanding functionality

### references/ Directory

**Purpose**: Documentation loaded into context as needed

**When to include:**
- Database schemas
- API documentation
- Domain knowledge
- Company policies
- Detailed workflow guides

**Examples:**
```
references/
├── database-schema.md     - Table structures, relationships
├── api-docs.md            - API endpoints, request/response
├── finance-glossary.md    - Company-specific terminology
└── migration-guide.md     - Step-by-step migration process
```

**Benefits:**
- Keeps SKILL.md lean
- Loaded only when Claude determines it's needed
- Can contain extensive detail without bloating always-loaded context

**Best practices:**
- If files are large (>10k words), include grep search patterns in SKILL.md
- Avoid duplication between SKILL.md and references
- Use descriptive filenames
- Include table of contents for files >100 lines

### assets/ Directory

**Purpose**: Files used in output, not loaded into context

**When to include:**
- Templates that get copied or modified
- Images, icons, logos
- Boilerplate code
- Fonts or other resources

**Examples:**
```
assets/
├── logo.png                    - Company logo
├── slides.pptx                 - PowerPoint template
├── frontend-template/          - React boilerplate
│   ├── package.json
│   ├── src/
│   └── public/
└── font.ttf                    - Custom typography
```

**Benefits:**
- Separates output resources from documentation
- Enables Claude to use files without loading them into context
- Provides ready-to-use templates

## What NOT to Include

**NEVER create these files:**
- README.md
- INSTALLATION_GUIDE.md
- QUICK_REFERENCE.md
- CHANGELOG.md
- CONTRIBUTING.md
- docs/ directory with user-facing documentation

**Why:** The skill should only contain information needed for an AI agent to do the job. It should not contain:
- Auxiliary context about the creation process
- Setup and testing procedures
- User-facing documentation
- Development history

Creating additional documentation files adds clutter and confusion.

## Size Guidelines

| Component | Target Size |
|-----------|-------------|
| SKILL.md frontmatter | ~10-20 lines |
| SKILL.md body | <500 lines |
| Individual reference files | <200 lines (use TOC if >100) |
| Total skill size | No hard limit, but keep lean |

## Skill Discovery Convention

Clients scan for skills in these standard paths:

| Scope | Path | Purpose |
|-------|------|---------|
| Project (client-specific) | `<project>/.<your-client>/skills/` | Client's native location |
| Project (cross-client) | `<project>/.agents/skills/` | Cross-client interoperability |
| User (client-specific) | `~/.<your-client>/skills/` | Client's native location |
| User (cross-client) | `~/.agents/skills/` | Cross-client interoperability |

The `.agents/skills/` paths are the widely-adopted cross-client convention — skills placed there are visible to any compliant agent automatically. **Project-level skills override user-level skills** when names collide.
