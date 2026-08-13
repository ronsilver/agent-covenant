# Agent Attack Patterns (Condensed)

Condensed from the skillspector 68-pattern / 17-category agent-attack catalog (master catalog #97). Lists the named pattern families an agent-skill reviewer must check. Each pattern family carries a risk score (0-100) and an install verdict.

## Verdict Scale

| Verdict | Meaning |
|---|---|
| SAFE | No exploitation path found; install with normal review |
| CAUTION | Exploitable under conditions; install only with the stated mitigations |
| DO_NOT_INSTALL | Exploitable in the default configuration; reject or sandbox |

## Pattern Catalog

| ID | Family | Risk | Verdict | Detection |
|----|--------|-----:|---------|-----------|
| P1 | Direct prompt injection | 85 | CAUTION | Embedded instructions addressed to the model |
| P2 | Indirect prompt injection | 90 | CAUTION | Skill fetches untrusted external data into context |
| P3 | Role-play override | 75 | CAUTION | "you are now" restarts and persona swaps |
| P4 | Hidden instructions | 80 | CAUTION | Instructions in comments, invisible text, or params |
| P5 | Context smuggling | 70 | CAUTION | Instructions smuggled via delimiters or encoding |
| P6 | Goal hijacking | 85 | CAUTION | Re-declares the task toward a new malicious goal |
| P7 | Many-shot injection | 60 | CAUTION | Large crafted few-shot sets steer behavior |
| P8 | Jailbreak patterns | 90 | DO_NOT_INSTALL | Refusal-evasion and policy-bypass scaffolds |
| AR1 | Anti-refusal reframing | 70 | CAUTION | Rewraps a refused request into a permitted frame |
| AR2 | Anti-refusal escalation | 75 | CAUTION | Pressures by ranking or demanding justification |
| AR3 | Anti-refusal role-play | 65 | CAUTION | Uses fictional or academic framing to bypass refusal |
| E1 | Direct exfiltration | 95 | DO_NOT_INSTALL | Sends secrets or data to an external endpoint |
| E2 | Exfiltration via tool | 90 | DO_NOT_INSTALL | Uses file, network, or MCP tools to ship data out |
| E3 | Covert-channel exfiltration | 85 | DO_NOT_INSTALL | Encodes data in timing, logs, or metadata |
| E4 | Delayed exfiltration | 80 | DO_NOT_INSTALL | Stashes data for later network pickup |
| SC1 | Urgency con | 50 | CAUTION | Manufactures time pressure to skip review |
| SC2 | Authority con | 60 | CAUTION | Fakes seniority or vendor authority |
| SC3 | Scarcity con | 45 | CAUTION | Fakes limited availability to force action |
| SC4 | Social-proof con | 40 | CAUTION | Cites fake endorsements or community consensus |
| SC5 | Familiarity con | 50 | CAUTION | Exploits known names and trusted phrases |
| SC6 | Reciprocity con | 40 | CAUTION | Offers small help to extract a large action |
| EA1 | Unauthorized tool use | 85 | CAUTION | Invokes tools outside the declared scope |
| EA2 | Over-broad permissions | 80 | CAUTION | Asks for or relies on excess permissions |
| EA3 | Auto-approve chains | 90 | DO_NOT_INSTALL | Sequences approvals into an irreversible action |
| EA4 | Resource abuse | 70 | CAUTION | Burns tokens, calls, or compute without bound |
| MP1 | Poisoned tool definition | 90 | DO_NOT_INSTALL | Tool descriptions embed malicious instructions |
| MP2 | Tool response tampering | 85 | DO_NOT_INSTALL | Modifies tool output before the model sees it |
| MP3 | Schema confusion | 60 | CAUTION | Ambiguous schemas accept forged arguments |
| TM1 | Missing trust boundary | 55 | CAUTION | No boundary between trusted and untrusted input |
| TM2 | Unvalidated data flows | 60 | CAUTION | Untrusted data reaches sinks without checks |
| TM3 | Missing abuse cases | 45 | CAUTION | Threat model omits abuse scenarios |
| RA1 | Retrieval poisoning | 80 | CAUTION | Corrupts the corpus that grounds retrieval |
| RA2 | Document injection | 85 | CAUTION | Injects instructions into retrieved documents |
| TR1 | Keyword-squatting trigger | 70 | CAUTION | Skill auto-triggers on common keywords |
| TR2 | Over-broad trigger | 75 | CAUTION | trigger: always with a broad description |
| TR3 | Always-on activation | 85 | CAUTION | Runs on every turn without explicit request |
| TT1 | Taint to exec | 95 | DO_NOT_INSTALL | Untrusted input reaches exec/eval/shell |
| TT2 | Taint to SQL | 85 | DO_NOT_INSTALL | Untrusted input reaches query construction |
| TT3 | Taint to path | 75 | CAUTION | Untrusted input reaches file paths |
| TT4 | Taint to prompt | 80 | CAUTION | Untrusted input reaches the instruction block |
| TT5 | Taint to tool argument | 90 | DO_NOT_INSTALL | Untrusted input reaches a tool parameter |
| LP1 | Over-scoped credentials | 70 | CAUTION | Credentials exceed the skill's task |
| LP2 | Open file access | 65 | CAUTION | Reads or writes outside the workspace |
| LP3 | Unbounded network | 80 | CAUTION | No egress allowlist in skill scripts |
| LP4 | Missing deny-list | 60 | CAUTION | No fail-closed default for unknown actions |
| TP1 | Unsigned skill package | 75 | CAUTION | No checksum or signature on the package |
| TP2 | Unicode and homoglyph abuse | 85 | DO_NOT_INSTALL | Lookalike names or zero-width text hide instructions |
| TP3 | Hidden instructions in params | 80 | CAUTION | Parameter descriptions carry instructions |
| TP4 | Dependency confusion | 85 | DO_NOT_INSTALL | Skill pulls a lookalike or typosquatted dependency |

## MCP Vetting (5 steps)

1. Provenance: verify the server owner, repo, license, and release tags
2. Code review: read the server source; check tool definitions and handlers
3. Permissions: confirm the server runs with least-privilege credentials
4. Docker sandbox: run the server in an isolated container before host use
5. Monitoring: log tool calls and review for unexpected behavior after install

Cross-references: MITRE ATLAS mapping and MCP tool-poisoning checklist live in references/owasp-agent-attacks.md; ingestion-time supply-chain checks live in engineering-standards/references/supply-chain.md.
