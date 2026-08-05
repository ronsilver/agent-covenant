# AWS Bedrock Agents Architecture

## Components
- **Agent**: FM + instructions + action groups + knowledge bases
- **Action Groups**: API schemas (OpenAPI) + Lambda functions for execution
- **Knowledge Bases**: S3 data source -> chunking -> embeddings -> vector store
- **Guardrails**: content filters, sensitive info filters, topic denial, word filters

## Agent Lifecycle
1. Create agent (name + FM + instructions + IAM role)
2. Add action groups and/or knowledge bases
3. Prepare agent (Bedrock builds prompts + orchestration logic)
4. Test with TSTALIASID, inspect traces
5. Create version, create alias (dev/staging/prod)
6. Deploy to application via InvokeAgent API

## Prompt Templates (Advanced)
- Pre-processing: classify intent, validate input
- Orchestration: plan steps, select actions, handle KB queries
- Knowledge base response generation: augment with retrieved context
- Post-processing: format output, apply guardrails

## AgentCore Services
- Gateway: managed MCP endpoint for agents
- Runtime: code execution sandbox (Python/Node.js)
- Memory: conversation state persistence
- Identity: OAuth/OIDC for agent auth
- Observability: traces, metrics, logs
- Registry: agent catalog
- Evaluations: quality assessment pipeline

## Key Limits
- Max action groups: 20
- Max KB per agent: 5
- Lambda timeout: 30s for action groups
- Prompt template max length: 10K chars
