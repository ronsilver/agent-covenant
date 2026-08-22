// OpenCode plugin — logs reminder at session start.
// No OpenCode mechanism injects boot SKILL.md bodies: the model invokes all 7 via skill().
// This plugin logs an advisory reminder; enforcement lives in opencode-global.md <REINFORCE>.
export const BaselineSkills = async ({ client }) => {
  const reminder = `SESSION START — MANDATORY BOOT SKILLS

OpenCode does NOT auto-inject skill bodies. Check each body is verbatim in context.
If you do NOT see their content in context, invoke these 7 skills NOW:

  skill({name:"operating-protocol"})     → risk tiers, anti-hallucination
  skill({name:"governance"})             → compliance, binding
  skill({name:"engineering-standards"})   → code limits, pre-commit chain
  skill({name:"context-management"})      → JIT loading, staleness
  skill({name:"token-efficiency"})        → compression, model routing
  skill({name:"tool-usage"})              → dedicated > Bash
  skill({name:"skill-router"})            → full domain skill catalog

These are not optional. Proceed only after ALL 7 are loaded.`;

  await client.app.log({
    body: {
      service: "baseline-skills",
      level: "info",
      message: reminder
    }
  });
};
