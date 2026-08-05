# ACI Design Checklist & Evaluation

## Checklist — Before Shipping Any Tool

- [ ] Clear purpose — one unambiguous sentence
- [ ] Context-efficient — no redundant params, no unnecessary data returned
- [ ] No overlap with existing tools (merge if ambiguous)
- [ ] Response limits implemented (pagination + filtering + truncation with steering)
- [ ] Params unambiguous (`user_id` not `user`; enums over free strings)
- [ ] Errors actionable: `Error: <what>. Fix: <how>.` (one line)
- [ ] Evaluated on ≥5 real task examples
- [ ] Format chosen based on eval (JSON/XML/Markdown) — not habit

## Anthropic ACI Principles

1. **Simplicity** — fewer, focused tools > many granular ones. If human can't choose between 2 tools, agent won't either → merge or clarify.
2. **Transparency** — show planning steps in tool descriptions. Agents use descriptions for CoT.
3. **Documentation + Testing** — descriptions steer behavior. Test with real transcripts — agent CoT reveals what descriptions miss.

## Evaluation Metrics

Priority order:
1. **Accuracy** — does the tool return correct results?
2. **Total tool calls** — are agents using it efficiently (not calling 3× for 1 result)?
3. **Token consumption** — is the response appropriately sized?
4. **Error rate** — are errors actionable?
5. **Runtime** — is it fast enough for the use case?

Stop optimizing when: accuracy stable + call count plateaued + error rate <5%.

## Poka-Yoke Design

Make mistakes hard:
- Prefer absolute paths over relative
- Prefer enums over free strings
- Prefer explicit IDs over implicit lookups
- Prefer `start_line/end_line` over open-ended reads

## Workflow Patterns — Simplest First

```
prompt_chaining → routing → parallelization → orchestrator-workers → evaluator-optimizer → agents
```

Add next level ONLY when current level demonstrably fails. Never add complexity speculatively.
