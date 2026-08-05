# Contributing

## Quick Start

```bash
# Install dependencies
brew install yq shellcheck shfmt bats-core
pip3 install pyyaml  # optional: for migration scripts

# Validate the project
make check

# Strict schema v2 validation (all skills)
for d in content/skills/*/; do
  python3 scripts/validate-skill-quality.py "$d" --strict
done
```

## Adding a New Agent

1. Add a section in `manifest.yaml` under `agents:`:

```yaml
agents:
  my-agent:
    enabled: true
    description: "My Agent Description"
    detect:
      paths:
        - "${HOME}/.my-agent"
      commands:
        - "my-agent --version"
    targets:
      rules:
        path: "${HOME}/.my-agent/rules"
        format: individual       # or: merged
        strip_frontmatter: false
```

2. Test with dry-run: `./scripts/sync.sh --agent my-agent --dry-run`
3. Sync: `./scripts/sync.sh --agent my-agent`

## Adding a New Rule

1. Create `content/rules/<category>/<name>.md` with frontmatter:

```markdown
---
trigger: always
---

# Rule Title

Content...
```

2. Add the path to `manifest.yaml` under `rules.files`:

```yaml
rules:
  files:
    - category/name.md
```

3. Validate: `./scripts/validate.sh`

## Adding a Workflow

1. Create `content/workflows/<category>/<name>.md`:

```markdown
---
name: workflow-name
description: What this workflow does
---

# Workflow: Name

Steps...
```

2. Add to `manifest.yaml` under `workflows.files`.

## Adding a Prompt

1. Create `content/prompts/<name>.prompt.md`:

```markdown
---
name: Prompt Name
description: What this prompt does
trigger: manual
tags:
  - category
---

# Prompt Name

Instructions...
```

2. Add to `manifest.yaml` under `prompts.files`.

## Adding a Skill (Schema v2)

1. Use the init script to scaffold:

```bash
# Manual: create content/skills/my-skill/SKILL.md from content/skills/_TEMPLATE/SKILL.md
```

2. Edit `content/skills/my-skill/SKILL.md` — required schema v2 frontmatter:

```yaml
---
name: my-skill
description: "What this skill does. Use when ... (min 50 chars, max 1024 chars)"
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: backend  # enum: ai-agents|backend|cloud|core|data|frontend|infrastructure|meta|process|quality|security
  status: stable     # stable|beta|deprecated
# Optional:
# skills: [dep-skill-1, dep-skill-2]
# aliases: [alt-name]
# allowed-tools: [Bash(git *), Read]
---
```

3. Add to `manifest.yaml` under `skills.directories`:

```yaml
skills:
  directories:
    - my-skill
```

4. Optionally add `references/`, `scripts/`, or `assets/` subdirectories.
5. Validate strict: `python3 scripts/validate-skill-quality.py content/skills/my-skill --strict`
6. Full validate: `./scripts/validate.sh`
7. Sync: `./scripts/sync.sh`

**License rule:** MIT for all skills. See `docs/SKILL_QUALITY_STANDARD.md`.

## Adding a New Agent Kernel

1. Create `content/rules/agents/<agent>-global.md` following the microkernel pattern (see `windsurf-global.md`).
2. Add the agent to `manifest.yaml` under `agents:` with `source_files: [agents/<agent>-global.md]`.
3. Run `./scripts/sync.sh --agent <agent> --dry-run` to verify.
4. Supported agents: windsurf, copilot, claude-code, gemini, antigravity, opencode, cursor (disabled until installed).

## Quarterly Review (S15)

Run every quarter to detect stale skills and quality gaps:

```bash
python3 scripts/quarterly_review.py --stale-days 90 --output docs/review-$(date +%Y-%m).md
```

Outputs a Markdown report with: staleness, schema issues, category distribution, quality opportunities.

## Grafana Dashboard (S14)

Import `docs/grafana/skill-usage-dashboard.json` into Grafana to track skill invocation metrics.
Requires Prometheus (metrics) and Loki (logs) datasources.

## Validation

Before submitting changes, run:

```bash
make check    # lint → fmt-check → validate → test

# Strict schema v2 check on all skills:
for d in content/skills/*/; do
  python3 scripts/validate-skill-quality.py "$d" --strict
done
```

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(rules): add rust best practices
fix(sync): handle empty glob paths
docs(readme): update agent table
```

## Code Style

- Shell scripts: 4-space indent, `set -euo pipefail`
- Format with `shfmt -i 4 -ci`
- Lint with `shellcheck`
