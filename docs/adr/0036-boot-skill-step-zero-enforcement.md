# ADR-0036: Boot-Skill Step-Zero Enforcement

**Date:** 2026-08-21
**Status:** Accepted

> Approval record: Accepted by repository owner via explicit session directive
> (2026-08-21) after full multi-agent audit (dual-track R1, delta-clean R2,
> TEMPLATE_SYNCED byte verification). Implementation delegated to ultracode.

## Context

A confirmed incident: an agent loaded 3 of the 7 mandatory boot skills and justified
skipping the rest using defective repository text. Findings:

1. `content/skills/skill-router/SKILL.md` L40-44 ("Boot Skills (NEVER invoke via
   `skill()`)", "Auto-loaded at session start") and L99 instruct models literally,
   suppressing mandatory session-start invocations.
2. Six sources falsely assume harnesses inject `trigger: always` skill bodies:
   boot-manifest.yaml L2, content/rules/README.md L54-55,
   docs/reference/skills-catalog.md L5, baseline-skills-plugin.js L2/L7, AGENTS.md L18.
   Reality is per-agent: Claude Code injects via @import in its kernel; OpenCode and
   all other agents require the model to invoke every boot skill itself.
3. Boot-count drift: 7 (kernels, AGENTS.md) vs 6 Core (governance SKILL.md L63/138/181/254)
   vs 5-item pre-flight lists (opencode kernel GOVERN, tool-usage compliance gate,
   AGENTS.md invariant 5) vs 4 (opencode baseline-skills.sh, validate-kernel-skill-coherence.sh).
4. Zero runtime verification: OpenCode hooks are disabled (manifest.yaml L452-458);
   the Claude Code SessionStart hook is print-only, exits 0 always, and asserts blanket
   auto-load instead of asking the model to verify.
5. User directive (2026-08-21): core-skill loading must be TRANSITIVE across every load
   path — skills invoking skills, agents spawning subagents, global rules referencing
   skills or subagents, hooks triggering skills or subagents. `skill-router` remains the
   discovery router: it tells the agent or LLM WHICH additional domain skill to load
   next, easing context discovery; it does not inject anything.

Refuted causes (unchanged): token-efficiency and context-management do not instruct
skipping loads.

## Decision

Make Step Zero (invoke all 7 boot skills before any other tool call) explicit,
unconditional, machine-checked, and transitive:

1. skill-router (Core): rewrite the boot-skills section. `trigger: always` marks catalog
   membership, NOT automatic injection; Step Zero mandates invoking ALL 7 via skill();
   read-only tasks, small budgets, and trivial work never waive it; skip an individual
   invocation only when that skill's full body is already verbatim in context
   (Claude Code @import). skill-router stays the discovery router for on-demand domain
   skills. Version 3.0 -> 3.1.
2. Kernels opencode-global.md and claude-code-global.md: append an anti-waiver clause to
   <SKILLS>; correct opencode GOVERN pre-flight to "verify all 7 boot skills loaded";
   compensating trims keep claude-code within the 6000-byte budget.
3. Docs truth table: boot-manifest.yaml, docs/reference/skills-catalog.md,
   content/rules/README.md, baseline-skills-plugin.js, AGENTS.md heading state per-agent
   injection instead of blanket claims.
4. governance (Core): unify subagent binding count to "all 7 boot skills" across SKILL.md,
   references, evals, and content/README.md L133; scope the context-overflow exception to subagents only, never
   primary-agent session-start loading. Version 2.3 -> 2.4.
5. tool-usage (Core): extend the compliance-gate checklist from 5 to all 7 boot skills.
   Version 2.1 -> 2.2.
6. Hooks and validators: opencode baseline-skills.sh lists 4 -> 7; Claude Code hook
   reworded verify-first without a leading auto-load assertion;
   validate-kernel-skill-coherence.sh baseline list extended to 7.
7. CI gates: new bats file bans resurrected prohibition wording, blanket auto-injection
   sentences, and stale boot-count literals anywhere under content/ or AGENTS.md.
8. Transitive Binding (governance Core): new `### Transitive Binding` subsection under
   `## Mandatory Binding` declaring that every load path inherits the precondition —
   skills invoking skills, agents spawning subagents, global rules referencing skills or
   subagents, and hooks triggering skills or subagents MUST ensure the target context
   holds all 7 boot skills before dependent work begins, and orchestrators MUST carry
   this binding into every task dispatch prompt.

This modifies three Core skills, so per governance protocol it requires ADR -> human
approval -> version bumps -> CHANGELOG. Manifest registration needs no change (no new
skills; all edited files already registered).

## Alternatives Considered

1. Trust prompt-only enforcement (status quo): rejected — demonstrated failure.
2. Re-enable OpenCode hooks as primary enforcement: rejected — OpenCode has no native
   shell-hook lifecycle; plugin remains advisory fallback.
3. Shorten kernels by deleting sections to fit the full clause verbatim: rejected —
   semantic loss; compact clause preserves every element within budget.
4. Enforce transitivity per-file in every skill/subagent/hook: rejected — duplicates one
   rule across dozens of files; a single canonical clause in governance plus CI gates
   achieves the same guarantee without drift.

## Consequences

- Models receive consistent, non-contradictory instructions: Step Zero is unconditional
  except for the verbatim-body exception.
- Every delegation path (skill chain, subagent spawn, hook trigger) inherits the
  boot-skill precondition by declared contract, closing nested-context gaps.
- CI fails if defective wording or stale counts are reintroduced under content/.
- Kernel budgets remain within limits: opencode 5864 B, claude-code 5985 B (limit 6000).
- Manual eval (two fresh OpenCode read-only sessions) validates end-to-end behavior.

## Evidence

- Defective text: skill-router/SKILL.md L40-44, L99; boot-manifest.yaml L2;
  content/rules/README.md L47-L56; docs/reference/skills-catalog.md L5;
  baseline-skills-plugin.js L2, L7; AGENTS.md L18, L188, L192;
  opencode-global.md L50; claude-code-global.md L68, L111; governance SKILL.md
  L63/138/181/254/271 + references + evals; tool-usage SKILL.md L51-55;
  content/hooks/opencode/baseline-skills.sh L12-17; scripts/validate-kernel-skill-coherence.sh L65;
  content/README.md L133.
- Byte simulations executed against temp copies of both kernels on 2026-08-21.
