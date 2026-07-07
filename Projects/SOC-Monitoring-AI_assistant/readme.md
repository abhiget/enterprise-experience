# AI-Assisted SOC Investigation & Incident Response

An AI agent that investigates security alerts by grounding GPT-4o in real operational data — Sentinel alerts, Log Analytics telemetry, and SharePoint runbooks — instead of relying on the model's general knowledge alone.

> Sanitized reference implementation. Sample data is synthetic — no real alerts, logs, or credentials included. See [SECURITY.md](SECURITY.md) for data handling and access boundaries.

## The problem

SOC alert triage was manual: analysts pulled telemetry, searched runbooks, and cross-referenced context by hand for every Sentinel alert — slow, inconsistent, and scattered across four disconnected systems.

## The approach

The SOC team asked the cloud platform team for something interactive to reduce manual triage. After evaluating static dashboards and rules-based SOAR playbooks — both too rigid to reason over unstructured context — we built an **Azure AI Foundry agent** grounded in the org's own security data, keeping a human in the loop for judgment calls.

## Architecture

**Pipeline:** Sentinel alert → Azure AI Search (RAG index) → AI Foundry agent (GPT-4o) → agent tools → Teams + Email

**Security wrapper:** identity/access (Azure AD, managed identity, RBAC) and governance (Azure Policy, audit logging) surround every step. Content Safety guardrails and observability are documented as recommended next steps, not yet built — see `agent/guardrails/` and `agent/observability/`.

Full diagrams and narrative: [`docs/architecture.md`](docs/architecture.md)

## What this demonstrates

| Capability | Where |
|---|---|
| AI Foundry Agent + GPT-4o orchestration | `agent/agent.py` |
| Grounding via Foundry's built-in File Search tool (not MCP) | `agent/tools/file_search_tool.py` |
| Log/document ingestion into AI Search | `ingestion/pipeline.py` |
| Least-privilege identity separation | `infra/identities.tf`, `infra/rbac.tf` |
| Incident enrichment + notification | `agent/tools/` |

## Tech stack
`Python` · `Azure AI Foundry` · `Azure AI Search` · `Azure Blob Storage` · `Terraform` · `Azure AD / RBAC`

## How to run
```bash
cd agent
pip install -r requirements.txt
python agent.py --query "Summarize the latest Sentinel alert"
```
> Requires an Azure AI Foundry endpoint and API key in `.env` (see `.env.example`).

## Structure
```
soc-ai-incident-assistant/
├── infra/          # Terraform — identities, RBAC, AI Foundry, AI Search, storage
├── ingestion/       # Write path: pulls logs/runbooks into the search index
├── agent/          # Read-only path: the actual assistant
├── sample_data/    # Synthetic alerts/runbooks only
├── tests/
└── docs/
```

## License
MIT — see [LICENSE](LICENSE)
