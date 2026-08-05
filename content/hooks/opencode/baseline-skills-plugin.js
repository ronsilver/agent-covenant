// OpenCode plugin — logs reminder at session start.
// Primary enforcement: instructions[] in opencode-mcp.json injects boot SKILL.md content.
// This plugin is a fallback for sessions where opencode-mcp.json is not synced.
export const BaselineSkills = async ({ client }) => {
  const reminder = `SESSION START — MANDATORY BOOT SKILLS

Boot skills are auto-loaded via instructions[] in opencode-mcp.json.
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
