# Agent-Computer Interface (ACI) Design

## Core Principles (Anthropic)
1. Give model enough tokens to 'think' before committing to output format
2. Keep format close to what model has seen naturally on internet
3. Avoid formatting overhead (line counting in diffs, JSON string escaping)

## Tool Design Checklist
- [ ] Is it obvious how to use this tool from description + parameters?
- [ ] Are parameter names descriptive? (like writing docstrings for junior devs)
- [ ] Does tool handle edge cases explicitly in description?
- [ ] Have you tested with many example inputs in workbench?
- [ ] Have you applied poka-yoke (mistake-proofing) to arguments?

## Anti-patterns
- Diff output: model must count lines before writing -> failure prone. Use whole-file rewrite or search/replace.
- JSON code output: extra escaping of newlines/quotes -> use markdown code blocks.
- Ambiguous param names: `user` vs `user_id` -> be specific.
- Missing required failure modes: tool descriptions must cover error cases.

## Namespacing
{domain}_{resource}_{action}
- payments_transactions_search
- knowledge_base_query
- guardrail_validate_content
