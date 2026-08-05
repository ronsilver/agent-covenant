# SKILL.md Template Reference

**Canonical template location:** `../../_TEMPLATE/SKILL.md`

This file exists to provide a local reference to the shared skill template, following the pattern where each skill's `references/` directory contains pointers to external resources.

## Usage

When creating a new skill, use the canonical template:

```bash
cp ../../_TEMPLATE/SKILL.md content/skills/<new-skill>/SKILL.md
```

Then edit the new SKILL.md with your skill's specific content.

## Template Structure

The template includes all 7 canonical sections required by the 7-pillar quality standard:

1. **Overview** — Domain, problem, scope
2. **Quick Reference** — Decision table with ≥3 rows
3. **Workflow** — Primary + alternative paths with preconditions and verification
4. **Guidelines** — DO/DO NOT tables with Incorrect/Correct anti-pattern pairs
5. **Anti-patterns** — ≥3 concrete code examples with explanations
6. **Troubleshooting** — Symptom/cause/fix table
7. **Verification Checklist** — Binary criteria for "done"
8. **References** — External URLs with last_verified dates
9. **Shell Safety** — Zsh history expansion prevention rules

## Quality Gates

Before marking a skill as done:

- [ ] `validate-skill-quality.py --report` ≥70 (target ≥80)
- [ ] Schema v2 frontmatter valid
- [ ] Description contains "Use when" + ≥3 triggers + ≥1 anti-trigger
- [ ] SKILL.md < 500 lines, < 5000 tokens
- [ ] ≥3 Incorrect/Correct anti-pattern pairs with code
- [ ] Decision table ≥3 rows
- [ ] Registered in `manifest.yaml` → `make validate` passes

## Related

- [Quality Standard](../../../docs/SKILL_QUALITY_STANDARD.md)
- [Schema v2 ADR](../../../docs/adr/0006-skill-metadata-schema.md)
- [Creation Workflow](../skill-creator/references/creation-workflow.md)
