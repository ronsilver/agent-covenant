---
name: alternative-skill-creator
description: "Create, edit, and improve skills that extend AI agent capabilities with domain knowledge, workflows, and tool integrations. Use when creating a new SKILL.md, editing or refactoring an existing skill, updating skill content or references, adding reference files, redesigning skill structure, applying progressive disclosure, defining activation triggers, or evaluating skill quality. Trigger: skill creation, SKILL.md editing, skill quality. Do NOT trigger for: general writing or documentation tasks not related to AI agent skills."
license: MIT
metadata:
  author: Community
  version: "2.0"
  category: meta
  status: stable
---

# Alternative Skill Creator

**Guide for creating effective skills that extend host agent capabilities.**

**See [references/overview.md](references/overview.md)**

## What Skills Provide

Skills extend agent capabilities with domain knowledge, workflows, tool integrations, and bundled resources (scripts, references, assets).

## Quality Standard — 7 Pillars

Every skill must meet the **7-pillar standard** to be considered world-class.
Score is measured by `scripts/validate-skill-quality.py` (0-100).
Passing: ≥70. Target: ≥80.

| #   | Pillar                  | Weight | What it means                                       |
| --- | ----------------------- | ------ | --------------------------------------------------- |
| 1   | **Self-Sufficiency**     | 20pt   | Usable without chasing references/ for 80% of cases |
| 2   | **Decision Tree** | 15pt   | Decision table or branching workflow with ≥3 routes |
| 3   | **Anti-patterns**       | 15pt   | ≥3 FAIL:/PASS: pairs with concrete code             |
| 4   | **Verification**        | 15pt   | Workflow ends with verification checklist           |
| 5   | **Depth**         | 10pt   | Known bugs, platform quirks, edge cases             |
| 6   | **Precise Triggers**   | 15pt   | description has ≥3 triggers + ≥1 anti-trigger       |
| 7   | **Living References**   | 10pt   | ≥2 external URLs + last_verified dates              |

→ Full standard + canonical template: [`../../_TEMPLATE/SKILL.md`](../../_TEMPLATE/SKILL.md)
→ Template: [`references/skill-template.md`](references/skill-template.md)

## Core Principles

| Principle              | Guideline                                                                                  |
| ---------------------- | ------------------------------------------------------------------------------------------ |
| **Concise is Key**     | Context window is shared. Only add what the host agent doesn't know.                               |
| **Degrees of Freedom** | Match specificity to task fragility: High (text), Medium (pseudocode), Low (exact scripts) |
| **World-Class First**  | Follow 7-pillar standard. Run validate-skill-quality.py before marking done.               |

## Skill Structure

- `SKILL.md` (required) — canonical section template: Overview, Quick Reference, Workflow, Guidelines, Anti-patterns, Troubleshooting, Verification, References
- `scripts/` (executable code, invoked as black boxes)
- `references/` (edge case docs loaded on demand — keep minimal)
- `assets/` (templates, resources)

→ [references/anatomy.md](references/anatomy.md)

## Progressive Disclosure

Three levels:

1. Metadata (always)
2. SKILL.md (<500 lines, <5000 tokens)
3. Resources (as needed)

**Key rule**: SKILL.md <500 lines

## Creation Workflow

1. **Understand patterns** — from real tasks, not generic LLM output
2. **Plan resources** — SKILL.md + scripts/ + references/ + assets/
3. **Initialize** — `init_skill.py <name> --path <dir> --category <cat>`
4. **Implement SKILL.md** — use [`references/skill-template.md`](references/skill-template.md) as guide
   - Include all 7 canonical sections: Overview, Quick Reference, Workflow, Guidelines/DO-DON'T, Anti-patterns, Troubleshooting, Verification, References
   - Add ≥3 FAIL:/PASS: anti-pattern pairs with code
   - Add decision table with ≥3 rows
   - Add verification checklist at end of each workflow
5. **Implement resources** — scripts/ + references/
6. **Validate** — `quick_validate.py <skill_dir> --strict`
7. **Shell safety** — `python3 scripts/validate-shell-safety.py --ci`
   - Ensures no exclamation marks in prose outside fenced code blocks (prevents Zsh history expansion)
   - See [`references/skill-template.md`](references/skill-template.md) Shell Safety section for rules
8. **Evaluate** — `python3 scripts/evaluate_skill.py <skill-dir>`
   - Runs `evals/evals.json` against target + judge models via Ollama
   - For Ollama Cloud: `python3 scripts/evaluate_skill.py <dir> --ollama-cloud` (set `$OPENAI_API_KEY`)
   - For batch ecosystem evaluation: `python3 scripts/evaluate_ecosystem.py --ollama-cloud`
   - Computes baseline (with_skill vs without_skill) and delta metrics
   - Target: `delta.pass_rate >= +0.1` AND overall pass_rate >= 0.7
   - Review `workspace/iteration-1/benchmark.json` — iterate SKILL.md if needed
   - Commit `benchmark.json` as quality artifact alongside the skill
9. **Score quality** — `python3 scripts/validate-skill-quality.py --report`
   - Target: ≥70 (passing). World-class: ≥80
   - Iterate pillars below threshold
10. **Register** — add to `manifest.yaml` → `make validate` → `make sync`
11. **Package** — `package_skill.py`

**Schema v2 required fields:**
`name`(≤64 chars, kebab-case, matches dir) | `description`(≥50 chars, ≤1024, contains "Use when" AND ≥3 trigger keywords AND ≥1 anti-trigger) | `license`(MIT or Proprietary) | `metadata.author`(generic) | `metadata.version`(semver) | `metadata.category`(enum)

→ See [canonical template](../../_TEMPLATE/SKILL.md) for schema v2 metadata requirements
→ [references/creation-workflow.md](references/creation-workflow.md)

## Overview

Creates and maintains high-quality skills (SKILL.md files) that extend AI agent capabilities with domain knowledge, workflows, and tool integrations. Covers the 7-pillar quality standard, progressive disclosure, schema v2 metadata, and the full creation lifecycle from pattern discovery to manifest registration.

## Quick Reference

| Scenario                             | Action                                                                       |
| ------------------------------------ | ---------------------------------------------------------------------------- |
| Creating a new skill                 | Use `init_skill.py <name> --path <dir> --category <cat>`                     |
| Evaluating skill quality             | `validate-skill-quality.py --report`                                         | Step 9                                                                       |
| Evaluating skill automatically       | `evaluate_skill.py <dir>` or `evaluate_skill.py <dir> --ollama-cloud`        | Step 8                                                                       |
| Evaluating all skills at once        | `evaluate_ecosystem.py --skip-evals` (structural) or `--ollama-cloud` (full) | See [references/ecosystem-evaluation.md](references/ecosystem-evaluation.md) |
| Improving a low-scoring skill        | Check 7-pillar breakdown; iterate weakest pillar first                       |
| Registering a skill in the ecosystem | Add to `manifest.yaml` → `make validate` → `make sync`                       |
| Packaging a skill for distribution   | Run `package_skill.py`                                                       |

## References

| Resource              | URL                            | Last verified |
| --------------------- | ------------------------------ | ------------- |
| YAML Frontmatter Spec | https://yaml.org/spec/1.2.2/   | 2026-05-25    |
| Semantic Versioning   | https://semver.org/            | 2026-05-25    |
| Markdown Guide        | https://www.markdownguide.org/ | 2026-05-25    |

- [references/agent-design-guide.md](references/agent-design-guide.md)
- [references/bundled-resources.md](references/bundled-resources.md)
- [references/core-principles.md](references/core-principles.md)
- [references/eval-schema.md](references/eval-schema.md)
- [references/evaluating-skills.md](references/evaluating-skills.md)
- [references/optimizing-descriptions.md](references/optimizing-descriptions.md)
- [references/output-patterns.md](references/output-patterns.md)
- [references/progressive-disclosure.md](references/progressive-disclosure.md)
- [references/using-scripts.md](references/using-scripts.md)
- [references/what-skills-provide.md](references/what-skills-provide.md)

## Verification Checklist

- [ ] 7-pillar quality score ≥70 (run `validate-skill-quality.py --report`)
- [ ] Metadata matches schema v2: name, description, license, author, version, category
- [ ] Description contains "Use when" + ≥3 trigger keywords + ≥1 anti-trigger
- [ ] SKILL.md < 500 lines and < 5000 tokens
- [ ] ≥3 FAIL:/PASS: anti-pattern pairs with code examples
- [ ] Decision table with ≥3 rows present
- [ ] Registered in `manifest.yaml` → `make validate` passes

## Troubleshooting

| [WARN] Known issue                                                 | Likely cause                                                             | Fix                                                                                                                              |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------- |
| `validate-skill-quality.py` score < 70                             | Missing pillars: decision tree, anti-patterns, or verification checklist | Check pillar breakdown; iterate weakest pillar first; add missing sections                                                       |
| Skill not syncing to agents                                        | Not registered in `manifest.yaml`; `make validate` failing               | Add entry to `manifest.yaml`; run `make validate` then `make sync`                                                               |
| Skill consumes too many tokens (>5000)                             | Too much content in SKILL.md; references not offloaded                   | Move edge cases to `references/` directory; keep SKILL.md focused on core guidance                                               |
| Description not triggering agent correctly                         | Description lacks "Use when" phrase or trigger keywords                  | Add "Use when" + ≥3 trigger keywords (e.g., "creating", "editing", "updating", "refactoring")                                    |
| Skill validation passes locally but fails in CI (known limitation) | Python version mismatch or missing dev dependencies in CI environment    | Pin validate-skill-quality.py deps in requirements.txt; run same Python version locally as CI                                    |
| Ollama Cloud authentication fails                                  | `OPENAI_API_KEY` env var not set or wrong endpoint URL                   | `export OPENAI_API_KEY=$OLLAMA_API_KEY`; verify URL: `https://ollama.com/v1`; use `--ollama-cloud` flag for automatic URL config |
