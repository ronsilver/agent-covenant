# Master Catalog Mapping

Source of truth: `/Users/silver/Documents/Silver-Cloud/Silver Vault/Personal/Knowledge/links-maestro-2026-06-25.md` (277 lines, 42 KB, personal Obsidian vault).

## Purpose

The master catalog is the external index of tools, workflows, and domains the operator curates. This repository mirrors a curated subset as skills. This document records the mapping so the catalog drives future coverage decisions instead of ad-hoc additions.

## Ingestion Rule

1. A domain from the master catalog becomes a skill when it meets ALL of: (a) it matches a repo content category from the AGENTS.md whitelist, (b) it does not collide with an existing skill boundary, and (c) it is not blocked by a standing validator (for example `validate-no-fintech.sh`).
2. Each ingested skill records its master-catalog item numbers in the SKILL.md References section.
3. Skills whose domain is intentionally not onboarded are recorded here as out-of-scope with the blocker.
4. Adding a skill without a catalog mapping entry is a governance miss: update this file in the same change.

## Classification Summary

Priority onboarded (2026-08-09):

| Master items | Domain | Skill |
|---|---|---|
| #39-44, #145, #117 | Offensive security and penetration testing | `penetration-testing-expert` |
| #45, #138, #146 | AI web-browsing agents | `web-browsing-agent-expert` |
| #46, #47 | OpenSpec / spec-kit | `spec-driven-development` |

Out of scope (recorded, not created):

| Master items | Domain | Blocker |
|---|---|---|
| #61, #62, #91 | Financial tooling | `validate-no-fintech.sh` bans fintech terms in content/ |
| #180-190 | Education and learning | Not prioritized; no category fit |
| #21, #92 | Obsidian, n8n | Not prioritized; outside current agent stack |

## Existing Coverage Map

The 71 active skills in `manifest.yaml` under `skills.directories` cover: security (security-expert, penetration-testing-expert), AI agents (agent-expert, agent-architecture-expert, web-browsing-agent-expert, mcp-expert), infrastructure, data, frontend, backend, quality, process, and core.

## Updateable-Resource Cruce

The cruce de proyectos vs recurso actualizable: every master-catalog entry maps to a repo URL and, when the repository holds the guidance, to the exact update-target resource (skill or reference file). Updating guidance from these sources is only allowed through the re-read-source-before-update protocol below.

<!-- CRUCE TABLE START -->
| Master # | Repo | Repo URL | Category | Disposition | Update target | How to update |
|---|---|---|---|---|---|---|
| 1 | zakirullin/files.md | https://github.com/zakirullin/files.md | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 2 | auroracapital/ai-gmail-assistant | https://github.com/auroracapital/ai-gmail-assistant | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 3 | ai-for-developers/awesome-ai-coding-tools | https://github.com/ai-for-developers/awesome-ai-coding-tools | curated list | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 4 | DanMcInerney/architect-loop | https://github.com/DanMcInerney/architect-loop | agent tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 5 | tensorzero/tensorzero | https://github.com/tensorzero/tensorzero | LLM gateway | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 6 | starship/starship | https://github.com/starship/starship | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 7 | ClementTsang/bottom | https://github.com/ClementTsang/bottom | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 8 | alibaba/open-code-review | https://github.com/alibaba/open-code-review | review tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 9 | microsoft/pg_durable | https://github.com/microsoft/pg_durable | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 10 | kristapsdz/openrsync | https://github.com/kristapsdz/openrsync | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 11 | chopratejas/headroom | https://github.com/chopratejas/headroom | token optimization | UPD | content/skills/token-efficiency/references/compression-algorithms.md | Re-read the repo README and https://headroom-docs.vercel.app/docs/how-compression-works before editing; verify the compressor taxonomy and savings figures; update the reference; bump the skill version and add a CHANGELOG bullet if guidance changed |
| 12 | xiongcccc/pgcheck | https://github.com/xiongcccc/pgcheck | database tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 13 | ory/talos | https://github.com/ory/talos | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 14 | ntrospect0/glint | https://github.com/ntrospect0/glint | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 15 | sickn33/antigravity-awesome-skills | https://github.com/sickn33/antigravity-awesome-skills | curated skill list | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 16 | alirezarezvani/claude-skills | https://github.com/alirezarezvani/claude-skills | curated skill list | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 17 | addyosmani/agent-skills | https://github.com/addyosmani/agent-skills | planning | STR | content/skills/planning-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 18 | mattpocock/skills | https://github.com/mattpocock/skills | agent skills | STR | content/skills/planning-expert/SKILL.md, content/skills/documentation-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 19 | ComposioHQ/awesome-codex-skills | https://github.com/ComposioHQ/awesome-codex-skills | curated skill list | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 20 | obra/superpowers | https://github.com/obra/superpowers | planning | STR | content/skills/planning-expert/SKILL.md, content/skills/reviewer-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 21 | kepano/obsidian-skills | https://github.com/kepano/obsidian-skills | obsidian | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 22 | google/skills (cloud) | https://github.com/google/skills/tree/main/skills/cloud | vendor bundle | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 23 | zxkane/aws-skills | https://github.com/zxkane/aws-skills | AWS skills | STR | content/skills/aws-cloud-expert/SKILL.md, content/skills/finops-cost-optimization/SKILL.md, content/skills/agent-architecture-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 24 | thedotmack/claude-mem | https://github.com/thedotmack/claude-mem | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 25 | RyjoxTechnologies/Octopoda-OS | https://github.com/RyjoxTechnologies/Octopoda-OS | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 26 | activeloopai/hivemind | https://github.com/activeloopai/hivemind | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 28 | muratcankoylan/agent-skills-for-context-engineering | https://github.com/muratcankoylan/agent-skills-for-context-engineering | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 29 | colbymchenry/codegraph | https://github.com/colbymchenry/codegraph | context/token | UPD | content/skills/token-efficiency/references/retrieval-economics.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 30 | drona23/claude-token-efficient | https://github.com/drona23/claude-token-efficient | token optimization | UPD | content/skills/token-efficiency/references/baselines.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 31 | nidhinjs/prompt-master | https://github.com/nidhinjs/prompt-master | token optimization | STR | content/skills/prompt-expert/SKILL.md, content/skills/llm-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 32 | hardikpandya/stop-slop | https://github.com/hardikpandya/stop-slop | token optimization | UPD | content/skills/token-efficiency/references/ai-slop-patterns.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 33 | blader/humanizer | https://github.com/blader/humanizer | token optimization | UPD | content/skills/token-efficiency/references/ai-slop-patterns.md, content/skills/llm-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 34 | ruvnet/ruflo | https://github.com/ruvnet/ruflo | agent framework | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 35 | rsham004/claude-flow | https://github.com/rsham004/claude-flow | agent framework | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 36 | darkrishabh/agent-skills-eval | https://github.com/darkrishabh/agent-skills-eval | evaluation | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 37 | karpathy/llm-council | https://github.com/karpathy/llm-council | evaluation | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 38 | massgen/massgen | https://github.com/massgen/massgen | evaluation | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 39 | 0xSteph/pentest-ai-agents | https://github.com/0xSteph/pentest-ai-agents | security | ADD | content/skills/penetration-testing-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 40 | elementalsouls/Claude-BugHunter | https://github.com/elementalsouls/Claude-BugHunter | security | ADD | content/skills/penetration-testing-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 41 | SudoHopeX/KaliGPT | https://github.com/SudoHopeX/KaliGPT | security | ADD | content/skills/penetration-testing-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 42 | mukul975/Anthropic-Cybersecurity-Skills | https://github.com/mukul975/Anthropic-Cybersecurity-Skills | security | ADD | content/skills/penetration-testing-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 43 | h4ckf0r0day/obscura | https://github.com/h4ckf0r0day/obscura | security | ADD | content/skills/penetration-testing-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 44 | asgeirtj/system_prompts_leaks | https://github.com/asgeirtj/system_prompts_leaks | security | ADD | content/skills/penetration-testing-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 45 | JasonHonKL/Openbrowser | https://github.com/JasonHonKL/Openbrowser | web browsing | ADD | content/skills/web-browsing-agent-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 46 | Fission-AI/OpenSpec | https://github.com/Fission-AI/OpenSpec | coding workflows | ADD | content/skills/spec-driven-development/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 47 | github/spec-kit | https://github.com/github/spec-kit | coding workflows | ADD | content/skills/spec-driven-development/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 48 | garrytan/gstack | https://github.com/garrytan/gstack | coding workflows | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 49 | affaan-m/ECC | https://github.com/affaan-m/ECC | coding workflows | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 50 | SkeneTechnologies/skene | https://github.com/SkeneTechnologies/skene | evaluation | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 51 | openai/codex-plugin-cc | https://github.com/openai/codex-plugin-cc | vendor bundle | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 52 | virattt/dexter | https://github.com/virattt/dexter | financial | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 53 | scitix/siclaw | https://github.com/scitix/siclaw | coding workflows | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 54 | pixlcore/xyops | https://github.com/pixlcore/xyops | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 55 | zxkane aws-agentic-ai | https://github.com/zxkane/aws-skills/tree/main/plugins/aws-agentic-ai/skills/aws-agentic-ai | vendor bundle | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 56 | zxkane aws-mcp-setup | https://github.com/zxkane/aws-skills/tree/main/plugins/aws-common/skills/aws-mcp-setup | vendor bundle | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 57 | zxkane aws-cost-ops | https://github.com/zxkane/aws-skills/tree/main/plugins/aws-cost-ops/skills/aws-cost-operations | cost ops | STR | content/skills/finops-cost-optimization/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 58 | punkpeye/awesome-mcp-servers | https://github.com/punkpeye/awesome-mcp-servers | MCP | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 59 | VoltAgent/awesome-claude-code-subagents | https://github.com/VoltAgent/awesome-claude-code-subagents | curated list | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 60 | hesreallyhim/awesome-claude-code | https://github.com/hesreallyhim/awesome-claude-code | curated list | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 61 | anthropics/financial-services | https://github.com/anthropics/financial-services | financial | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 62 | Open-Dev-Society/OpenStock | https://github.com/Open-Dev-Society/OpenStock | financial | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 63 | santifer/career-ops | https://github.com/santifer/career-ops | financial | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 64 | FlorianBruniaux/claude-code-ultimate-guide | https://github.com/FlorianBruniaux/claude-code-ultimate-guide | guides | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 65 | google/skills-cloud | https://github.com/google/skills-cloud | vendor bundle | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 66 | hashicorp/agent-skills | https://github.com/hashicorp/agent-skills | IaC | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 67 | msitarzewski/brew-browser | https://github.com/msitarzewski/brew-browser | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 68 | DietrichGebert/ponytail | https://github.com/DietrichGebert/ponytail | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 69 | NangoHQ/nango | https://github.com/NangoHQ/nango | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 70 | rmyndharis/OpenWA | https://github.com/rmyndharis/OpenWA | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 71 | zzet/gortex | https://github.com/zzet/gortex | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 72 | heiswayi/archmap | https://github.com/heiswayi/archmap | diagram tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 73 | tw93/pake | https://github.com/tw93/pake | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 74 | oh-my-mermaid/oh-my-mermaid | https://github.com/oh-my-mermaid/oh-my-mermaid | diagram tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 75 | dstotijn/hetty | https://github.com/dstotijn/hetty | security | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 76 | graykode/abtop | https://github.com/graykode/abtop | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 77 | iii-hq/iii | https://github.com/iii-hq/iii | agent framework | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 78 | restic/restic | https://github.com/restic/restic | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 79 | Thysrael/Horizon | https://github.com/Thysrael/Horizon | agent framework | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 80 | bjarneo/cliamp | https://github.com/bjarneo/cliamp | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 81 | itsfatduck/optimizerDuck | https://github.com/itsfatduck/optimizerDuck | token optimization | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 82 | nsoybean/solostack | https://github.com/nsoybean/solostack | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 83 | shadcn/improve | https://github.com/shadcn/improve | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 84 | JuliusBrussee/caveman | https://github.com/JuliusBrussee/caveman | token optimization | UPD | content/skills/token-efficiency/references/baselines.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 85 | microsoft/markitdown | https://github.com/microsoft/markitdown | python tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 86 | yamadashy/repomix | https://github.com/yamadashy/repomix | context/token | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 87 | cinicu/opencode-dotfiles | https://github.com/cinicu/opencode-dotfiles | opencode | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 88 | open-gsd/gsd-core | https://github.com/open-gsd/gsd-core | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 89 | harry0703/MoneyPrinterTurbo | https://github.com/harry0703/MoneyPrinterTurbo/tree/main | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 90 | pewdiepie-archdaemon/odysseus | https://github.com/pewdiepie-archdaemon/odysseus | agent framework | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 91 | TraderAlice/OpenAlice | https://github.com/TraderAlice/OpenAlice | financial | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 92 | n8n-io/skills | https://github.com/n8n-io/skills | n8n | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 93 | giancarloerra/SocratiCode | https://github.com/giancarloerra/SocratiCode | review | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 94 | severity1/claude-code-prompt-improver | https://github.com/severity1/claude-code-prompt-improver | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 95 | 0x0funky/Agentinel | https://github.com/0x0funky/Agentinel | evaluation | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 96 | Agents365-ai/drawio-skill | https://github.com/Agents365-ai/drawio-skill | diagram tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 97 | nvidia/skillspector | https://github.com/nvidia/skillspector | security | STR | content/skills/security-expert/SKILL.md, content/skills/engineering-standards/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 98 | anthropics/claude-code-security-review | https://github.com/anthropics/claude-code-security-review | security | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 99 | oraios/serena | https://github.com/oraios/serena | context/agent | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 100 | SuperClaude-Org/SuperClaude_Framework | https://github.com/SuperClaude-Org/SuperClaude_Framework | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 101 | Piebald-AI/claude-code-system-prompts | https://github.com/Piebald-AI/claude-code-system-prompts | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 102 | petar-nauka/fact-check-skill | https://github.com/petar-nauka/fact-check-skill | research | STR | content/skills/research-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 103 | revfactory/harness | https://github.com/revfactory/harness | evaluation | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 104 | imbad0202/academic-research-skills | https://github.com/imbad0202/academic-research-skills | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 105 | anthropics/knowledge-work-plugins | https://github.com/anthropics/knowledge-work-plugins | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 106 | leonxlnx/taste-skill | https://github.com/leonxlnx/taste-skill | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 107 | Egonex-AI/Understand-Anything | https://github.com/Egonex-AI/Understand-Anything | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 108 | ai-infra-curriculum/ai-infra-engineer-learning | https://github.com/ai-infra-curriculum/ai-infra-engineer-learning | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 109 | nsoybean/ai-meeting-memory-flutter | https://github.com/nsoybean/ai-meeting-memory-flutter | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 110 | upstash/context7 | https://github.com/upstash/context7 | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 111 | zilliztech/claude-context | https://github.com/zilliztech/claude-context | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 112 | mksglu/context-mode | https://github.com/mksglu/context-mode | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 113 | Mibayy/token-savior | https://github.com/Mibayy/token-savior | token optimization | UPD | content/skills/token-efficiency/references/baselines.md, content/skills/token-efficiency/references/optimization.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 114 | alexgreensh/token-optimizer | https://github.com/alexgreensh/token-optimizer | token optimization | UPD | content/skills/llm-expert/SKILL.md, content/skills/token-efficiency/references/optimization.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 115 | ryoppippi/ccusage | https://github.com/ryoppippi/ccusage | token optimization | UPD | content/skills/token-efficiency/references/observability-loop.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 116 | scanaislop/aislop | https://github.com/scanaislop/aislop | token optimization | UPD | content/skills/token-efficiency/references/ai-slop-patterns.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 117 | tirth8205/code-review-graph | https://github.com/tirth8205/code-review-graph | security | ADD | content/skills/penetration-testing-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 118 | ubikron/Awesome-AI-OSINT | https://github.com/ubikron/Awesome-AI-OSINT | curated list | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 119 | trimstray/the-book-of-secret-knowledge | https://github.com/trimstray/the-book-of-secret-knowledge | curated list | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 120 | mergisi/awesome-openclaw-agents | https://github.com/mergisi/awesome-openclaw-agents | curated list | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 121 | awesome-opencode/awesome-opencode | https://github.com/awesome-opencode/awesome-opencode | curated list | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 122 | thealgorithms | https://github.com/thealgorithms | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 123 | thedaviddias/front-end-checklist | https://github.com/thedaviddias/front-end-checklist | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 124 | sindresorhus/awesome | https://github.com/sindresorhus/awesome | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 125 | LeCoupa/awesome-cheatsheets | https://github.com/LeCoupa/awesome-cheatsheets | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 126 | ebookfoundation/free-programming-books | https://github.com/ebookfoundation/free-programming-books | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 127 | donnemartin/system-design-primer | https://github.com/donnemartin/system-design-primer | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 128 | trekhleb/javascript-algorithms | https://github.com/trekhleb/javascript-algorithms | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 129 | Sairyss/backend-best-practices | https://github.com/Sairyss/backend-best-practices | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 130 | codecrafters-io/build-your-own-x | https://github.com/codecrafters-io/build-your-own-x | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 131 | walkinglabs/learn-harness-engineering | https://github.com/walkinglabs/learn-harness-engineering | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 132 | practical-tutorials/project-based-learning | https://github.com/practical-tutorials/project-based-learning | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 133 | nilbuild/developer-roadmap | https://github.com/nilbuild/developer-roadmap | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 134 | yangshun/tech-interview-handbook | https://github.com/yangshun/tech-interview-handbook | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 135 | yifanfeng97/Hyper-Extract | https://github.com/yifanfeng97/Hyper-Extract | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 136 | bjarneo/ku | https://github.com/bjarneo/ku/tree/main | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 137 | eyaltoledano/claude-task-master | https://github.com/eyaltoledano/claude-task-master | agent framework | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 138 | browser-use/browser-use | https://github.com/browser-use/browser-use | web browsing | ADD | content/skills/web-browsing-agent-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 139 | cloudflare/agentic-inbox | https://github.com/cloudflare/agentic-inbox | agent framework | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 140 | langchain-ai/langgraph | https://github.com/langchain-ai/langgraph | agent architecture | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 141 | n8n-io/n8n | https://github.com/n8n-io/n8n | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 142 | crewAIInc/crewAI | https://github.com/crewAIInc/crewAI | agent architecture | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 143 | NousResearch/hermes-agent | https://github.com/NousResearch/hermes-agent | agent framework | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 144 | OpenHands/OpenHands | https://github.com/OpenHands/OpenHands | agent framework | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 145 | elder-plinius/T3MP3ST | https://github.com/elder-plinius/T3MP3ST | security | ADD | content/skills/penetration-testing-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 146 | Panniantong/agent-reach | https://github.com/Panniantong/agent-reach | web browsing | ADD | content/skills/web-browsing-agent-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 147 | mvanhorn/last30days-skill | https://github.com/mvanhorn/last30days-skill | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 148 | ai-driven-dev/framework | https://github.com/ai-driven-dev/framework/tree/next | planning | STR | content/skills/planning-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 149 | ishanvyas22/awesome-open-source-systems | https://github.com/ishanvyas22/awesome-open-source-systems | curated list | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 150 | decolua/9router | https://github.com/decolua/9router | LLM gateway | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 151 | alibaba/zvec | https://github.com/alibaba/zvec | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 152 | Sahir619/fable-method | https://github.com/Sahir619/fable-method | agent skills | STR | content/skills/agent-expert/SKILL.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 153 | diegosouzapw/OmniRoute | https://github.com/diegosouzapw/OmniRoute | LLM gateway | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 154 | microsoft/SkillOpt | https://github.com/microsoft/SkillOpt | agent skills | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 155 | ayghri/i-have-adhd | https://github.com/ayghri/i-have-adhd | token optimization | UPD | content/skills/token-efficiency/references/action-first-output.md | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 156 | hashicorp terraform-ansible blog | https://www.hashicorp.com/es/blog/whats-new-with-terraform-ansible | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 157 | arps18 claude-code-mastery | https://arps18.github.io/posts/claude-code-mastery/ | guides | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 158 | deepswe blog | https://deepswe.datacurve.ai/blog | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 159 | aiengineeringfromscratch.com | https://aiengineeringfromscratch.com/ | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 160 | AWS DevOps Agent MCP blog | https://aws.amazon.com/blogs/devops/diagnose-eks-node-issues-faster-with-aws-devops-agent-and-custom-mcp/ | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 161 | thenewstack.io tickets-to-ai | https://thenewstack.io/delegate-tickets-to-ai/ | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 162 | perceptiontheory context-sculpting | https://perceptiontheory.bearblog.dev/context-sculpting/ | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 163 | Radeon power blog | https://www.tarreo.com/pc/logran-que-la-radeon-rx-9070-xt-consuma-mucho-menos-energia-sin-perder-apenas-rendimiento-con-pequenos-ajustes-manuales/ | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 164 | Microsoft spec-driven blog | https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 165 | HashiCorp agent-skills blog | https://www.hashicorp.com/es/blog/introducing-hashicorp-agent-skills | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 166 | civillearning token blog | https://civillearning.medium.com/10-github-repos-that-cut-claude-code-token-usage-by-up-to-90-a692abb11b00 | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 167 | HashiCorp Terraform DR blog | https://www.hashicorp.com/es/blog/disaster-recovery-strategies-with-terraform | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 168 | HashiCorp Terraform security blog | https://www.hashicorp.com/es/blog/terraform-security-5-foundational-practices | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 169 | GitHub Copilot refactor tutorial | https://docs.github.com/en/copilot/tutorials/refactor-code | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 170 | Google Open Knowledge Format blog | https://cloud.google.com/blog/products/data-analytics/how-the-open-knowledge-format-can-improve-data-sharing | blog | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 171 | animeztoretienda.com | https://animeztoretienda.com/collections/s-h-figuarts?filter.v.availability=1&page=2&sort_by=best-selling&utm_source=ig&utm_medium=social&utm_content=link_in_bio&fbclid=PAb21jcARsaNpleHRuA2FlbQIxMQBzcnRjBmFwcF9pZA81NjcwNjczNDMzNTI0MjcAAae5S8bhFfw6VpHBUXmpStEP6-JxDFwmoVuFQtjanSvIx8JPD4-JnC6YMmdY0A_aem_sDtBF0A9fFOZwkAsN6R9jg | shop | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 172 | petwild.cl | https://www.petwild.cl/ | shop | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 173 | maoristore.com bomber 1 | https://maoristore.com/products/bomber-jacket-calaveras-mariposas-ms5d2989 | shop | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 174 | maoristore.com bomber 2 | https://maoristore.com/products/bomber-jacket-urban-shred-mscxm1s3 | shop | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 175 | ataraxy-labs sem | https://ataraxy-labs.github.io/sem/ | research tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 176 | universalmemoryprotocol.io | https://universalmemoryprotocol.io/ | context tooling | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 177 | odyssey.ml agora-1 | https://odyssey.ml/introducing-agora-1 | agent framework | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 178 | atlasphere.io | https://atlasphere.io/ | misc tooling | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 179 | microsoft Sentinel | https://www.microsoft.com/es-cl/security/business/siem-and-xdr/microsoft-sentinel-platform | security | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 180 | k8sgames.com | https://k8sgames.com | education | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 181 | devops.games | https://devops.games | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 182 | overthewire.org | https://overthewire.org | education | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 183 | ohmygit.org | https://ohmygit.org | education | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 184 | tynker.com | https://tynker.com | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 185 | codingame.com | https://codingame.com | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 186 | skillbuilder.aws | https://skillbuilder.aws/ | education | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 187 | learn.microsoft.com | https://learn.microsoft.com/en-us/ | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 188 | docker-curriculum.com | https://docker-curriculum.com/ | education | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 189 | kubernetes.io | https://kubernetes.io/ | education | COV | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
| 190 | edx.org devops | https://www.edx.org/learn/devops | education | OOS | — | Re-read the source repo URL first (never update from memory); record access date; update the target resource; bump skill version + CHANGELOG bullet if guidance changed; OOS rows: revisit at quarterly review |
<!-- CRUCE TABLE END -->

## Update Procedure

- Onboarding a new skill: add a row to Classification Summary and reference the items in the new SKILL.md.
- Retiring a skill: move the row to out of scope with the reason.
- Revisit out-of-scope rows during the quarterly review (`python3 scripts/quarterly_review.py`).

## Closed 1-190 Disposition Table

Every master-catalog entry (1-190) has exactly one disposition: ADD / STR / UPD / COV / OOS. Full disposition table lives in T15o of `docs/plans/update-skills-and-rules.md` and is mirrored here verbatim; the plan is the source of truth. Dispositions: ADD = onboarded skill, STR = strengthened skill, UPD = refreshed skill, COV = covered by an existing skill (recorded reference only, no content change), OOS = out of scope (recorded-only, rationale in T15o-6).

<!-- DISPOSITION TABLE START -->
| 1 | zakirullin/files.md | misc tooling | OOS | local-first .md notes app; recorded-only |
| 2 | auroracapital/ai-gmail-assistant | misc tooling | OOS | Gmail AI automation; recorded-only |
| 3 | ai-for-developers/awesome-ai-coding-tools | curated list | OOS | AI coding-tools list; discovery not adopted; recorded-only |
| 4 | DanMcInerney/architect-loop | agent tooling | COV | plan-execution verification -> agent-expert (typed-evidence watchdog) |
| 5 | tensorzero/tensorzero | LLM gateway | OOS | deferred by operator 2026-08-12; recorded-only — no skill created |
| 6 | starship/starship | misc tooling | OOS | shell prompt; recorded-only |
| 7 | ClementTsang/bottom | misc tooling | OOS | system monitor; recorded-only |
| 8 | alibaba/open-code-review | review tooling | COV | review tooling -> reviewer-expert |
| 9 | microsoft/pg_durable | misc tooling | OOS | Postgres durable SQL functions; recorded-only |
| 10 | kristapsdz/openrsync | misc tooling | OOS | rsync implementation; recorded-only |
| 11 | chopratejas/headroom | token optimization | UPD | refreshed by T14b (token-efficiency) |
| 12 | xiongcccc/pgcheck | database tooling | COV | Postgres health-check CLI -> postgres-database-expert (recorded reference, T15o-3) |
| 13 | ory/talos | misc tooling | OOS | short-lived API keys; recorded-only |
| 14 | ntrospect0/glint | misc tooling | OOS | terminal dashboard; recorded-only |
| 15 | sickn33/antigravity-awesome-skills | curated skill list | COV | discovery reference -> skills-catalog.md |
| 16 | alirezarezvani/claude-skills | curated skill list | COV | discovery reference -> skills-catalog.md |
| 17 | addyosmani/agent-skills | planning | STR | strengthened by T15c (planning-expert) |
| 18 | mattpocock/skills | agent skills | STR | grill-me / CONTEXT.md strengthened into planning-expert + documentation-expert (T15o-1) |
| 19 | ComposioHQ/awesome-codex-skills | curated skill list | COV | discovery reference -> skills-catalog.md |
| 20 | obra/superpowers | planning | STR | strengthened by T15c/T15d/T15h |
| 21 | kepano/obsidian-skills | obsidian | OOS | Obsidian skills; out of scope (D6), recorded-only |
| 22 | google/skills (cloud) | vendor bundle | OOS | Google Cloud skills; vendor bundle, recorded-only |
| 23 | zxkane/aws-skills | AWS skills | STR | cost-ops/AgentCore/IaC stance strengthened into aws-cloud-expert, finops-cost-optimization, agent-architecture-expert (T15i/T15j/T15l IaC stance) |
| 24 | thedotmack/claude-mem | context tooling | COV | agent memory -> context-management |
| 25 | RyjoxTechnologies/Octopoda-OS | context tooling | COV | agent memory OS -> context-management |
| 26 | activeloopai/hivemind | context tooling | COV | shared memory -> context-management |
| 28 | muratcankoylan/agent-skills-for-context-engineering | context tooling | COV | context engineering skills -> context-management |
| 29 | colbymchenry/codegraph | context/token | UPD | refreshed by T14c (token-efficiency retrieval-economics) |
| 30 | drona23/claude-token-efficient | token optimization | UPD | refreshed by T14e (token-efficiency baselines) |
| 31 | nidhinjs/prompt-master | token optimization | STR | completed by T15o-4 (prompt-expert); token audit stays in llm-expert (T14i) |
| 32 | hardikpandya/stop-slop | token optimization | UPD | refreshed by T14d (token-efficiency ai-slop-patterns) |
| 33 | blader/humanizer | token optimization | UPD | refreshed by T14d (token-efficiency) + llm-expert |
| 34 | ruvnet/ruflo | agent framework | COV | agentic engineering platform -> agent-architecture-expert (recorded) |
| 35 | rsham004/claude-flow | agent framework | COV | agent orchestration -> agent-architecture-expert (recorded) |
| 36 | darkrishabh/agent-skills-eval | evaluation | COV | skill evaluation framework -> evaluation-expert |
| 37 | karpathy/llm-council | evaluation | COV | multi-LLM evaluation -> evaluation-expert |
| 38 | massgen/massgen | evaluation | COV | multi-agent consensus framework -> agent-expert/agent-architecture-expert (recorded, T15o-5c) |
| 39 | 0xSteph/pentest-ai-agents | security | ADD | onboarded by T1 (penetration-testing-expert) |
| 40 | elementalsouls/Claude-BugHunter | security | ADD | onboarded by T1 (penetration-testing-expert) |
| 41 | SudoHopeX/KaliGPT | security | ADD | onboarded by T1 (penetration-testing-expert) |
| 42 | mukul975/Anthropic-Cybersecurity-Skills | security | ADD | onboarded by T1 (penetration-testing-expert) |
| 43 | h4ckf0r0day/obscura | security | ADD | onboarded by T1 (penetration-testing-expert) |
| 44 | asgeirtj/system_prompts_leaks | security | ADD | onboarded by T1 (penetration-testing-expert) |
| 45 | JasonHonKL/Openbrowser | web browsing | ADD | onboarded by T2 (web-browsing-agent-expert) |
| 46 | Fission-AI/OpenSpec | coding workflows | ADD | onboarded by T15a (spec-driven-development) |
| 47 | github/spec-kit | coding workflows | ADD | onboarded by T15a (spec-driven-development) |
| 48 | garrytan/gstack | coding workflows | OOS | software factory suite; vendor bundle, recorded-only |
| 49 | affaan-m/ECC | coding workflows | COV | constitution / exit-code tooling -> agent-expert/engineering-standards (recorded, T15o-5a) |
| 50 | SkeneTechnologies/skene | evaluation | COV | AI compliance monitoring -> evaluation-expert (recorded, T15o-6) |
| 51 | openai/codex-plugin-cc | vendor bundle | OOS | official Codex plugin; vendor bundle, recorded-only |
| 52 | virattt/dexter | financial | OOS | financial research agent; D3 financial rationale, recorded-only |
| 53 | scitix/siclaw | coding workflows | OOS | DevOps/SRE agent workflow; vendor suite, recorded-only |
| 54 | pixlcore/xyops | misc tooling | OOS | job scheduling and monitoring; recorded-only |
| 55 | zxkane aws-agentic-ai | vendor bundle | OOS | Bedrock AgentCore skill; vendor bundle, recorded-only |
| 56 | zxkane aws-mcp-setup | vendor bundle | OOS | AWS docs MCP setup; vendor bundle, recorded-only |
| 57 | zxkane aws-cost-ops | cost ops | STR | strengthened by T15j (finops-cost-optimization) |
| 58 | punkpeye/awesome-mcp-servers | MCP | COV | MCP servers catalog -> mcp-expert |
| 59 | VoltAgent/awesome-claude-code-subagents | curated list | COV | discovery reference -> subagents-catalog.md (T15o-5d) |
| 60 | hesreallyhim/awesome-claude-code | curated list | COV | discovery reference -> skills/subagents-catalog.md (T15o-5d) |
| 61 | anthropics/financial-services | financial | OOS | financial skills; D3 out of scope |
| 62 | Open-Dev-Society/OpenStock | financial | OOS | stock-market app; D3 out of scope |
| 63 | santifer/career-ops | financial | OOS | job-search tooling; D3 financial rationale, recorded-only |
| 64 | FlorianBruniaux/claude-code-ultimate-guide | guides | COV | Claude Code guide -> customize-opencode/agent-expert |
| 65 | google/skills-cloud | vendor bundle | OOS | Google Cloud skills; vendor bundle, recorded-only |
| 66 | hashicorp/agent-skills | IaC | COV | Terraform provider skills -> terraform-expert |
| 67 | msitarzewski/brew-browser | misc tooling | OOS | Homebrew TUI browser; recorded-only |
| 68 | DietrichGebert/ponytail | misc tooling | OOS | terminal UI library; recorded-only |
| 69 | NangoHQ/nango | misc tooling | OOS | API integration platform; recorded-only |
| 70 | rmyndharis/OpenWA | misc tooling | OOS | WhatsApp automation; recorded-only |
| 71 | zzet/gortex | misc tooling | OOS | Go microservice framework; recorded-only |
| 72 | heiswayi/archmap | diagram tooling | COV | architecture diagrams -> diagram-expert |
| 73 | tw93/pake | misc tooling | OOS | web-to-desktop converter; recorded-only |
| 74 | oh-my-mermaid/oh-my-mermaid | diagram tooling | COV | Mermaid editor -> diagram-expert |
| 75 | dstotijn/hetty | security | COV | HTTP security toolkit -> security-expert (recorded, T15o-6) |
| 76 | graykode/abtop | misc tooling | OOS | system monitor; recorded-only |
| 77 | iii-hq/iii | agent framework | COV | code research framework -> agent-architecture-expert (recorded) |
| 78 | restic/restic | misc tooling | OOS | backup tool; recorded-only |
| 79 | Thysrael/Horizon | agent framework | COV | agent dev framework -> agent-architecture-expert (recorded) |
| 80 | bjarneo/cliamp | misc tooling | OOS | LLM CLI amplifier; recorded-only |
| 81 | itsfatduck/optimizerDuck | token optimization | COV | prompt optimizer -> llm-expert (recorded) |
| 82 | nsoybean/solostack | misc tooling | OOS | indie stack; recorded-only |
| 83 | shadcn/improve | misc tooling | OOS | UI component improvement; recorded-only |
| 84 | JuliusBrussee/caveman | token optimization | UPD | refreshed by T14e (token-efficiency baselines) |
| 85 | microsoft/markitdown | python tooling | COV | doc-to-markdown -> python-expert |
| 86 | yamadashy/repomix | context/token | COV | repo packager -> context-management/token-efficiency |
| 87 | cinicu/opencode-dotfiles | opencode | COV | OpenCode config -> customize-opencode |
| 88 | open-gsd/gsd-core | misc tooling | OOS | software dev framework; recorded-only |
| 89 | harry0703/MoneyPrinterTurbo | misc tooling | OOS | short-video generator; recorded-only |
| 90 | pewdiepie-archdaemon/odysseus | agent framework | COV | AI agent automation -> agent-architecture-expert (recorded) |
| 91 | TraderAlice/OpenAlice | financial | OOS | trading bot; D3 out of scope |
| 92 | n8n-io/skills | n8n | OOS | n8n workflow skills; out of scope (D6), recorded-only |
| 93 | giancarloerra/SocratiCode | review | COV | Socratic review skill -> reviewer-expert |
| 94 | severity1/claude-code-prompt-improver | misc tooling | OOS | prompt-improver skill; recorded-only (T15m) |
| 95 | 0x0funky/Agentinel | evaluation | COV | agent monitoring/analysis -> evaluation-expert (recorded, T15o-6) |
| 96 | Agents365-ai/drawio-skill | diagram tooling | COV | drawio-skill #96 -> diagram-expert (drawio .drawio XML deferred as optional reference, T15o-5b) |
| 97 | nvidia/skillspector | security | STR | strengthened by T15e/T15f (security-expert, engineering-standards) |
| 98 | anthropics/claude-code-security-review | security | COV | security review skill -> security-expert (recorded) |
| 99 | oraios/serena | context/agent | COV | semantic coding agent -> context-management/agent-architecture-expert |
| 100 | SuperClaude-Org/SuperClaude_Framework | misc tooling | OOS | skills framework; recorded-only (T15m) |
| 101 | Piebald-AI/claude-code-system-prompts | misc tooling | OOS | system prompts; recorded-only (T15m) |
| 102 | petar-nauka/fact-check-skill | research | STR | strengthened by T15k (research-expert) |
| 103 | revfactory/harness | evaluation | COV | agent testing harness -> evaluation-expert (recorded, T15o-6) |
| 104 | imbad0202/academic-research-skills | misc tooling | OOS | academic research skills; recorded-only (T15m) |
| 105 | anthropics/knowledge-work-plugins | misc tooling | OOS | knowledge-work plugins; recorded-only (T15m) |
| 106 | leonxlnx/taste-skill | misc tooling | OOS | preference skill; recorded-only (T15m) |
| 107 | Egonex-AI/Understand-Anything | misc tooling | OOS | comprehension skill; recorded-only (T15m) |
| 108 | ai-infra-curriculum/ai-infra-engineer-learning | misc tooling | OOS | infra-engineer curriculum; recorded-only (T15m) |
| 109 | nsoybean/ai-meeting-memory-flutter | context tooling | COV | meeting memory -> context-management |
| 110 | upstash/context7 | context tooling | COV | context system -> context-management |
| 111 | zilliztech/claude-context | context tooling | COV | Claude context -> context-management |
| 112 | mksglu/context-mode | context tooling | COV | context mode -> context-management |
| 113 | Mibayy/token-savior | token optimization | UPD | refreshed by T14e (token-efficiency baselines/optimization) |
| 114 | alexgreensh/token-optimizer | token optimization | UPD | refreshed by T14g (llm-expert optimization) |
| 115 | ryoppippi/ccusage | token optimization | UPD | refreshed by T14f (token-efficiency observability-loop) |
| 116 | scanaislop/aislop | token optimization | UPD | refreshed by T14d (token-efficiency ai-slop-patterns) |
| 117 | tirth8205/code-review-graph | security | ADD | onboarded by T1 (penetration-testing-expert) |
| 118 | ubikron/Awesome-AI-OSINT | curated list | OOS | OSINT list; recorded-only |
| 119 | trimstray/the-book-of-secret-knowledge | curated list | OOS | tool/resource collection; recorded-only |
| 120 | mergisi/awesome-openclaw-agents | curated list | OOS | OpenClaw agents list; recorded-only |
| 121 | awesome-opencode/awesome-opencode | curated list | OOS | OpenCode resources list; recorded-only |
| 122 | thealgorithms | education | OOS | algorithm collection; D6 education, recorded-only |
| 123 | thedaviddias/front-end-checklist | education | OOS | front-end checklist; D6, recorded-only |
| 124 | sindresorhus/awesome | education | OOS | curated list of lists; D6, recorded-only |
| 125 | LeCoupa/awesome-cheatsheets | education | OOS | cheatsheets; D6, recorded-only |
| 126 | ebookfoundation/free-programming-books | education | OOS | free programming books; D6, recorded-only |
| 127 | donnemartin/system-design-primer | education | OOS | system design primer; D6, recorded-only |
| 128 | trekhleb/javascript-algorithms | education | OOS | JS algorithms; D6, recorded-only |
| 129 | Sairyss/backend-best-practices | education | OOS | backend best practices; D6, recorded-only |
| 130 | codecrafters-io/build-your-own-x | education | OOS | build tutorials; D6, recorded-only |
| 131 | walkinglabs/learn-harness-engineering | education | OOS | Harness engineering guide; D6, recorded-only |
| 132 | practical-tutorials/project-based-learning | education | OOS | project tutorials; D6, recorded-only |
| 133 | nilbuild/developer-roadmap | education | OOS | developer roadmaps; D6, recorded-only |
| 134 | yangshun/tech-interview-handbook | education | OOS | interview handbook; D6, recorded-only |
| 135 | yifanfeng97/Hyper-Extract | misc tooling | OOS | data extraction tool; recorded-only |
| 136 | bjarneo/ku | misc tooling | OOS | CLI utility; recorded-only |
| 137 | eyaltoledano/claude-task-master | agent framework | COV | task framework -> agent-architecture-expert (recorded) |
| 138 | browser-use/browser-use | web browsing | ADD | onboarded by T2 (web-browsing-agent-expert) |
| 139 | cloudflare/agentic-inbox | agent framework | OOS | Cloudflare product; vendor, recorded-only |
| 140 | langchain-ai/langgraph | agent architecture | COV | agent graph framework -> agent-architecture-expert |
| 141 | n8n-io/n8n | misc tooling | OOS | workflow platform; recorded-only |
| 142 | crewAIInc/crewAI | agent architecture | COV | multi-agent framework -> agent-architecture-expert |
| 143 | NousResearch/hermes-agent | agent framework | COV | Hermes agent -> agent-architecture-expert (recorded) |
| 144 | OpenHands/OpenHands | agent framework | COV | autonomous coding agent -> agent-architecture-expert (recorded) |
| 145 | elder-plinius/T3MP3ST | security | ADD | onboarded by T1 (penetration-testing-expert) |
| 146 | Panniantong/agent-reach | web browsing | ADD | onboarded by T2 (web-browsing-agent-expert) |
| 147 | mvanhorn/last30days-skill | misc tooling | OOS | research skill; recorded-only (T15m) |
| 148 | ai-driven-dev/framework | planning | STR | strengthened by T15c (planning-expert, three amigos) |
| 149 | ishanvyas22/awesome-open-source-systems | curated list | OOS | open-source systems list; recorded-only |
| 150 | decolua/9router | LLM gateway | OOS | deferred by operator 2026-08-12; recorded-only — no skill created |
| 151 | alibaba/zvec | context tooling | COV | vector DB -> context-management |
| 152 | Sahir619/fable-method | agent skills | STR | strengthened by T15h (agent-expert, think/act/prove) |
| 153 | diegosouzapw/OmniRoute | LLM gateway | OOS | deferred by operator 2026-08-12; recorded-only — no skill created |
| 154 | microsoft/SkillOpt | agent skills | COV | recorded reference only (T15o-2): skill self-optimization, evaluation twin of #36 |
| 155 | ayghri/i-have-adhd | token optimization | UPD | refreshed by T14h (token-efficiency action-first-output) |
| 156 | hashicorp terraform-ansible blog | blog | OOS | Terraform/Ansible blog; recorded-only |
| 157 | arps18 claude-code-mastery | guides | COV | Claude Code guide -> customize-opencode/agent-expert |
| 158 | deepswe blog | blog | OOS | Datacurve blog; recorded-only |
| 159 | aiengineeringfromscratch.com | education | OOS | AI engineering curriculum; D6, recorded-only |
| 160 | AWS DevOps Agent MCP blog | blog | OOS | EKS diagnosis blog; D6, recorded-only |
| 161 | thenewstack.io tickets-to-ai | blog | OOS | SDLC/agent blog; D6, recorded-only |
| 162 | perceptiontheory context-sculpting | context tooling | COV | context-sculpting explicitly REJECTED as blocker; recorded in context-failure-modes.md |
| 163 | Radeon power blog | blog | OOS | hardware blog; D6, recorded-only |
| 164 | Microsoft spec-driven blog | blog | OOS | spec-driven blog; D6, recorded-only |
| 165 | HashiCorp agent-skills blog | blog | OOS | vendor blog; D6, recorded-only |
| 166 | civillearning token blog | blog | OOS | token-usage blog; D6, recorded-only |
| 167 | HashiCorp Terraform DR blog | blog | OOS | DR strategies blog; D6, recorded-only |
| 168 | HashiCorp Terraform security blog | blog | OOS | security practices blog; D6, recorded-only |
| 169 | GitHub Copilot refactor tutorial | blog | OOS | refactor tutorial; D6, recorded-only |
| 170 | Google Open Knowledge Format blog | blog | OOS | OKF announcement blog; recorded-only |
| 171 | animeztoretienda.com | shop | OOS | e-commerce shop; recorded-only |
| 172 | petwild.cl | shop | OOS | pet store; recorded-only |
| 173 | maoristore.com bomber 1 | shop | OOS | e-commerce shop; recorded-only |
| 174 | maoristore.com bomber 2 | shop | OOS | e-commerce shop; recorded-only |
| 175 | ataraxy-labs sem | research tooling | COV | semantic understanding on Git -> research-expert |
| 176 | universalmemoryprotocol.io | context tooling | COV | memory protocol -> context-management |
| 177 | odyssey.ml agora-1 | agent framework | OOS | multi-agent world model; product, recorded-only |
| 178 | atlasphere.io | misc tooling | OOS | cloud infra map; product, recorded-only |
| 179 | microsoft Sentinel | security | COV | SIEM/XDR platform -> security-expert (recorded, T15o-6) |
| 180 | k8sgames.com | education | COV | Kubernetes learning games -> kubernetes-expert |
| 181 | devops.games | education | OOS | DevOps games; D6, recorded-only |
| 182 | overthewire.org | education | COV | security wargames -> security-expert |
| 183 | ohmygit.org | education | COV | Git learning game -> git-expert |
| 184 | tynker.com | education | OOS | kids coding platform; D6, recorded-only |
| 185 | codingame.com | education | OOS | coding challenges; D6, recorded-only |
| 186 | skillbuilder.aws | education | COV | AWS training -> aws-cloud-expert |
| 187 | learn.microsoft.com | education | OOS | Microsoft Learn; D6, recorded-only |
| 188 | docker-curriculum.com | education | COV | Docker tutorial -> docker-expert |
| 189 | kubernetes.io | education | COV | Kubernetes docs -> kubernetes-expert |
| 190 | edx.org devops | education | OOS | DevOps courses; D6, recorded-only |
<!-- DISPOSITION TABLE END -->
