# Skill Eval Harness

## Scope

Methodology for proving a skill makes a measurable difference. This repo
ships `evals/evals.json` per skill and `scripts/validate-skill-quality.py`
for the 7-pillar SKILL.md score. This file documents the runtime eval
methodology (skill behavior), separate from the static quality score.

## with_skill vs without_skill (agent-skills-eval)

Every eval runs the SAME prompt twice:
1. with_skill: SKILL.md loaded into context
2. without_skill: baseline, skill stripped

A judge model grades both outputs against the same assertions. If the skill
does not produce measurable lift, it is not earning its context budget.

```
same prompt -> [with_skill] -> target model -> output
           \-> [without_skill] -> target model -> output
                                                    \-> judge -> pass/fail
```

## Artifact Layout (iteration-N)

```
agent-skills-workspace/
  iteration-1/
    meta.json          # run metadata
    benchmark.json     # rolled-up pass/fail per skill
    eval-basic/
      with_skill/      # output, timing, judge grading
      without_skill/   # same, skill stripped
    report/
      index.html       # visual report
```

## Repo Eval Schema (evals/evals.json)

This repo's evals.json uses:
- `stratum`: simple | medium | complex (difficulty tier)
- `test_cases[]`: id, stratum, input, expected_behaviors, flags_to_avoid

NOTE: `scripts/validate-skill-quality.py` scores SKILL.md against the 7-pillar
standard (Autosuficiencia, Arbol de decisiones, etc.) - it does NOT consume
evals.json. The two are complementary:
- 7-pillar score = static SKILL.md quality (>=70 to pass CI)
- evals.json = runtime behavior cases (run via agent-skills-eval or equivalent)

## Adding Eval Cases

New cases MUST:
- Declare a stratum (simple|medium|complex)
- List expected_behaviors (observable, not vibes)
- List flags_to_avoid (failure modes)
- Be paired conceptually with a without_skill baseline (the harness runs both)

Reference: https://github.com/darkrishabh/agent-skills-eval (last_verified: 2026-06)
- with_skill vs without_skill, judge model, iteration-N layout, agentskills.io spec.

## Boundary

- Evaluation rubric design, LLM-as-judge, pairwise comparison: -> `evaluation-expert` skill
- This file documents the harness USAGE and schema, not rubric design.
- SkillOpt (microsoft/SkillOpt, master catalog #154): skill self-optimization loop — trajectory -> edit -> validation gate -> best_skill.md (~300-2000 tokens); evaluation twin of agent-skills-eval (#36), recorded reference only.
