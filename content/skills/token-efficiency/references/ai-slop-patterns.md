# AI Slop Patterns -- 33-Pattern Catalog

Source: blader/humanizer v2.8.0+ (33 patterns). Enriched with stop-slop 5-dimension rubric and aislop 6-engine deterministic scoring.

## Safety Carve-Out (MANDATORY -- inherits caveman Auto-Clarity override)

Patterns #22, #28, #30 are NON-SAFETY ONLY. In security/legal/irreversible contexts, Auto-Clarity override drops compression to Level 1 (full clarity). NEVER strip risk caveats, hedging, or uncertainty signals when:
- Security warnings (CVE, injection, credential exposure)
- Irreversible action confirmations (delete, destroy, drop)
- Legal/compliance statements
- Error messages shown to end users

## Scoring Rubrics (enrichment)

### stop-slop 5-dimension scoring (source: stop-slop)
Score each dimension 1-10. Total < 35/50 -> revise.
| Dimension | What it measures |
|-----------|-----------------|
| Directness | No preamble, no circular logic |
| Rhythm | Varied sentence length, not monotonous |
| Trust | No false certainty, no overclaiming |
| Authenticity | No performative empathy, no "great question" |
| Density | High signal-per-token, no padding |

### aislop 6-engine deterministic scoring (source: aislop)
6 engines score 0-100 each: format, lint, quality, AI-slop, security, architecture.
CI gate: failBelow: 70. Inline suppression: `// aislop-ignore-next-line`.

## 33 Patterns (5 categories)

### Category 1: Content (6 patterns)

1. Replace "I think we should probably consider" with "Update the config." Drop hedging verbs.
Before: "I think we should probably consider updating the config."
After: "Update the config."

2. Replace "It's worth noting that" with nothing. Delete throat-clearing.
Before: "It's worth noting that the API returns JSON."
After: "API returns JSON."

3. Replace "In order to" with "To". Drop redundant prepositions.
Before: "In order to validate the input..."
After: "To validate input..."

4. Replace "There are several ways to approach this" with the chosen way. Delete menu-mode.
Before: "There are several ways to approach this. One option is..."
After: "Approach: ..."

5. Replace "As mentioned earlier" with nothing. Trust conversation history.
Before: "As I mentioned earlier, the bug is in auth middleware."
After: "Bug in auth middleware."

6. Replace "It's important to understand that" with nothing. Delete importance signals.
Before: "It's important to understand that the cache invalidates on write."
After: "Cache invalidates on write."

### Category 2: Language (6 patterns)

7. Replace "utilize" with "use". Drop corporate-speak.
Before: "We utilize Redis for caching."
After: "We use Redis for caching."

8. Replace "leverage" with "use". Drop business jargon.
Before: "We leverage the existing infrastructure."
After: "We use existing infra."

9. Replace "facilitate" with "enable" or the actual verb. Delete filler verbs.
Before: "This facilitates communication between services."
After: "This enables service communication."

10. Replace "in the context of" with "for" or "in". Delete context padding.
Before: "In the context of our system..."
After: "For processing..."

11. Replace "with regards to" with "about" or delete. Drop transition filler.
Before: "With regards to the database issue..."
After: "DB issue..."

12. Replace "a number of" with the actual number or "several". Delete vague quantifiers.
Before: "A number of services were affected."
After: "5 services affected." (or "Several services affected.")

### Category 3: Style (13 patterns)

13. Replace "delve into" with "examine". Delete academic filler.
Before: "Let's delve into the architecture."
After: "Examine the architecture."

14. Replace "explore" with "test" or "examine". Delete exploration language.
Before: "Let's explore the options."
After: "Examine options."

15. Replace "navigate" with "use" or "access". Delete journey metaphors.
Before: "Navigate to the settings page."
After: "Open settings."

16. Replace "journey" with "process" or delete. Delete narrative framing.
Before: "Our journey to microservices..."
After: "Microservices migration..."

17. Replace "landscape" with "ecosystem" or delete. Delete panoramic filler.
Before: "The API landscape has changed."
After: "APIs changed."

18. Replace "realm" with "area" or delete. Delete domain padding.
Before: "In the realm of distributed systems..."
After: "In distributed systems..."

19. Replace "robust" with "reliable" or delete. Delete quality adjectives.
Before: "A robust error handling system."
After: "Reliable error handling."

20. Replace "comprehensive" with "full" or delete. Delete scope adjectives.
Before: "A comprehensive guide to testing."
After: "Full testing guide."

21. Replace "seamless" with "direct" or delete. Delete integration adjectives.
Before: "Seamless integration with the external gateway."
After: "Direct gateway integration."

22. [NON-SAFETY ONLY] Replace "it should be noted that" with nothing. Delete note signals. MUST NOT apply in security/legal contexts.
Before: "It should be noted that the token expires in 24h."
After: "Token expires in 24h."

23. Replace "furthermore" with "also" or delete. Drop transition words.
Before: "Furthermore, the cache improves latency."
After: "Cache also improves latency."

24. Replace "moreover" with "and" or delete. Drop additive transitions.
Before: "Moreover, the system scales horizontally."
After: "System scales horizontally."

25. Replace "additionally" with "also" or delete. Drop additive filler.
Before: "Additionally, we added monitoring."
After: "Also added monitoring."

26. Replace "consequently" with "so" or delete. Drop causal filler.
Before: "Consequently, the latency dropped."
After: "Latency dropped."

27. Replace "subsequently" with "then" or delete. Drop temporal filler.
Before: "Subsequently, the service restarted."
After: "Service restarted."

28. [NON-SAFETY ONLY] Replace "it is worth mentioning that" with nothing. Delete mention signals. MUST NOT apply in security/legal contexts.
Before: "It is worth mentioning that the API has rate limits."
After: "API has rate limits."

### Category 4: Communication (3 patterns)

29. Replace "I hope this helps" with nothing. Delete closings.
Before: "I hope this helps! Let me know if you have questions."
After: (delete entirely)

30. [NON-SAFETY ONLY] Replace "feel free to" with "you can" or delete. Delete permission granting. MUST NOT apply in security/legal contexts.
Before: "Feel free to adjust the timeout."
After: "Adjust timeout as needed."

31. Replace "let me know if you need anything else" with nothing. Delete service closings.
Before: "Let me know if you need anything else."
After: (delete entirely)

### Category 5: Filler / Hedging (2 patterns -- #22, #28 above are also hedging-class)

32. Replace "basically" with nothing. Delete filler adverbs.
Before: "Basically, the cache stores tokens."
After: "Cache stores tokens."

33. Replace "essentially" with nothing. Delete filler adverbs.
Before: "Essentially, it is a queue with retries."
After: "Queue with retries."
