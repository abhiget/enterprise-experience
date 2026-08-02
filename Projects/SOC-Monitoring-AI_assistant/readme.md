# AI-Assisted SOC Investigation & Incident Response
### Project Narrative & Technical Reference — Cloud Platform Team × SOC Team

---

## 1. Executive Summary

**Where things stood.** The SOC team pulls security alerts from two primary sources — the **Microsoft Defender portal** and **Microsoft Sentinel**. For every alert that comes in, the standard workflow is:

1. **Triage** — sort and prioritize the alert.
2. **Investigate** — gather context, check severity, and decide whether it needs further action or can be classified and closed.
3. **Map to threat** — based on severity, the alert is mapped against known threat categories.
4. **Act** — once analyzed, the analyst takes the appropriate action against the affected user, device, activity, or threat.

**The core problem.** The real difficulty was never the workflow itself — it was everything underneath it: how a generated alert gets **classified into the right category**, how **severity** is assigned consistently, and the patchwork of **automation scripts and KQL queries** written over the years to support all of this. That automation had not kept pace — it struggled to catch the **latest threat patterns**, and it was producing a growing volume of **false positives**, both of which added manual work back onto analysts instead of removing it.

To address this, the team planned to simplify the process into four focused capability areas:

1. 🥇 **Investigation** – Correlates evidence, summarizes incidents, and explains attacker behavior — reasoning over both the current case and relevant historical/trained data.
2. 🥈 **Alert Triage** – Uses trained context to reduce alert fatigue by prioritizing and summarizing incoming alerts, and can raise an **SCTASK ticket or incident** directly, so critical issues get actioned first.
3. 🥉 **Documentation** – Generates high-quality incident reports and timelines, removing the manual write-up burden after every case.
4. **Containment Guidance** – Suggests response actions for the analyst to consider, with the analyst always making the final call.

To deliver on these four areas, the **Cloud Platform team partnered with SOC leadership** to design and ship an **AI investigation agent**, built on **Azure AI Foundry**, that grounds a large language model — **GPT-4o** for the initial build, though the architecture stays flexible to swap in other LLMs during evaluation — in the organization's own operational security data, rather than letting the model reason from general knowledge alone.

---

## 2. The Story — How the Project Started

**Origin.** In a monthly SOC operations review, the SOC Manager flagged that Tier-1 analysts were spending roughly 60% of their shift on **triage and context-gathering**, not investigation — pulling KQL queries in Sentinel, searching a SharePoint runbook library that had grown to 400+ documents over three years, and manually correlating entities (IPs, users, hosts) across incidents. Alert volume had grown ~35% year-over-year; headcount had not.

**The ask.** SOC leadership approached the Cloud Platform team — who already owned the org's Azure landing zone and the **Log Analytics workspace that feeds Sentinel**, and had recently stood up an **Azure AI Foundry hub** for another business unit — with a simple ask: *"Can we get something that talks to our data and tells us what we're looking at, before an analyst opens the incident?"*

This wasn't a cold handoff between unfamiliar teams. Sentinel and Defender both run inside the Azure environment the Cloud Platform team already manages end-to-end, and the two teams had been working in close collaboration for a long time — the Cloud Platform team already understood the workspace, the data, and the access model. That existing relationship is why SOC came to them, specifically, for an agentic AI solution rather than treating this as a from-scratch vendor evaluation.

**Framing the problem correctly.** Rather than jumping to a build, the Cloud Platform team ran a two-week discovery with SOC to define what "good" looked like:

- Reduce **mean time to context** (not MTTR — this tool assists triage, it does not replace analyst judgment or auto-remediate).
- Ground every answer in **real telemetry and runbooks**, not the model's general security knowledge, to avoid hallucinated remediation steps.
- Keep a **human in the loop** for anything that touches ticketing, notification, or containment actions.
- Fit inside existing **identity, RBAC, and audit boundaries** — no new standing permissions, no data leaving the tenant.

**Options considered.** This is a large organization, so it wasn't a blank slate — some automation was already in place. The question was whether it was *enough on its own*, not whether it existed at all.

| Approach | Status in the org | Why it isn't enough on its own |
|---|---|---|
| Static Sentinel workbooks / dashboards | Already in use | Presents data well, but still requires an analyst to read, correlate, and reason over it manually — doesn't understand unstructured runbook context |
| Sentinel automation rules / Logic Apps (SOAR-style playbooks) | Already in use for deterministic actions | Reliable for fixed if-this-then-that logic, but too rigid to reason over ambiguous alerts or free-text runbooks — and rule sprawl was starting to miss newer attacker patterns while generating false positives |
| LLM agent grounded in org data (RAG + tool calling) | **New — selected** | Adds the missing reasoning layer over unstructured context, while still calling the existing deterministic tools (queries, ticketing, notification) for anything that needs to be exact |

The decision, in short: keep the existing workbooks and automation rules where they already work well as deterministic building blocks, and add an AI agent on top to handle the reasoning, correlation, and summarization work that rules-based automation was never going to be flexible enough to do.

---

## 3. Objectives & Success Criteria

| Objective | Metric | Target |
|---|---|---|
| Cut manual triage time | Avg. time from alert creation to analyst having full context | 20 min → < 2 min |
| Reduce context-switching | # of systems an analyst manually opens per alert | 4 (Sentinel, Log Analytics, SharePoint, Teams) → 1 |
| Preserve trust / accuracy | % of agent summaries analysts accept without correction | > 85% (measured in pilot) |
| Zero new standing risk | New long-lived credentials or broad RBAC grants introduced | 0 |
| Human accountability preserved | % of notifications/tickets requiring analyst confirmation before send | 100% |

---

## 4. Where the Data Comes From (Sentinel) & Where It Lives

The agent is only as trustworthy as the data it's grounded in, so this was the part we spent the most design time on.

### 4.1 Source systems

| Source | What we pull | Native storage location |
|---|---|---|
| **Microsoft Sentinel** | Incidents & alerts (`SecurityIncident`, `SecurityAlert` tables), entity mappings (accounts, hosts, IPs, files) | Backed by the **Log Analytics workspace** Sentinel is enabled on (Azure Monitor data platform) |
| **Log Analytics / Azure Monitor** | Raw telemetry the alert fired against — sign-in logs (`SigninLogs`), Defender for Endpoint telemetry (`DeviceEvents`, `DeviceNetworkEvents`), firewall/NSG flow logs, custom app logs | Same Log Analytics workspace, queried via **KQL** |
| **SharePoint runbook library** | Investigation playbooks, escalation matrices, known-FP documentation | SharePoint Online site, indexed — not queried live per request |
| **Microsoft Defender XDR / Threat Intelligence** (optional enrichment) | IOC reputation, related campaigns | Defender TI API, pulled at ingestion time |

Sentinel itself does not store data separately — it is a solution layered on top of a Log Analytics workspace (Azure Monitor). This matters for the security design: **the agent never gets direct query rights to raw Log Analytics data.** It only sees what the ingestion pipeline has already extracted, sanitized, and indexed.

### 4.2 Where the *agent's* data lives (the RAG layer)

We do **not** point the LLM at Log Analytics or SharePoint directly at query time. Instead:

1. A scheduled **ingestion pipeline** (Azure Function / container job, no interactive access) pulls:
   - New/updated Sentinel incidents and their linked alerts and entities, via the **Sentinel/Log Analytics REST API** and KQL.
   - Runbook documents from SharePoint via the **Microsoft Graph API**.
2. Content is **chunked, embedded, and written into Azure AI Search** as a hybrid (vector + keyword) index — this is the only store the agent reads from at runtime.
3. Sensitive fields (raw credentials, PII beyond what's needed for triage, internal IP ranges depending on classification) are **masked or excluded** at ingestion, not at query time — so there's nothing sensitive in the index to accidentally over-share.
4. The index is **tagged by data classification and source system**, so the agent's retrieval tool can cite exactly which incident, alert, or runbook a claim came from.

This separation is the core security property of the design: **the write path (ingestion) and the read path (agent) are different identities with different permissions**, so a prompt-injection or agent bug can never result in a query against production Log Analytics — the agent literally cannot reach it.

---

## 5. How Data Is Fetched Securely

Security wraps every hop in the pipeline, not just the AI layer.

### 5.1 Identity & access

- **Ingestion pipeline** runs under its own **user-assigned managed identity** (`id-soc-ingestion`), granted:
  - `Log Analytics Reader` on the Sentinel workspace (read-only, no write/delete)
  - `Sites.Read.All` (Graph, application permission, admin-consented) scoped to the specific SharePoint site collection
  - `Search Index Data Contributor` on the AI Search index (write)
- **Agent runtime** runs under a **separate managed identity** (`id-soc-agent`), granted:
  - `Search Index Data Reader` only — cannot write, cannot query Log Analytics or SharePoint directly
  - Outbound tool-calling permissions scoped only to notification endpoints (Teams webhook, Exchange Online send-as-service-account) and the ticketing system
- No identity has both write access to the source systems and the ability to be driven by LLM output — this breaks the chain an attacker would need for data exfiltration or tampering via prompt injection.

### 5.2 Network & transport

- Azure AI Search, the Log Analytics workspace, and the AI Foundry hub sit behind **Private Endpoints** in the platform landing zone VNet; public network access is disabled on all three.
- All service-to-service calls use **Azure AD (Entra ID) token auth** — no API keys or connection strings stored in code or pipeline config; secrets that must exist (e.g., Teams webhook) live in **Azure Key Vault**, referenced via managed identity, never checked into the repo.

### 5.3 Governance & auditability

- **Azure Policy** enforces the private-endpoint-only and managed-identity-only rules at the subscription level, so a future deployment can't accidentally reintroduce a public endpoint or key-based auth.
- Every ingestion run and every agent query/tool-call is logged to a dedicated **Log Analytics audit workspace** (separate from the SOC's own workspace, to avoid the tool auditing itself into its own blind spot) — capturing who/what triggered it, what was retrieved, and what action (if any) the agent proposed.
- **Role-based access to the agent itself**: only members of the SOC Analyst Entra ID group can invoke it via Teams/the internal app; requests are tied to the analyst's identity, not a shared service account, so every interaction is individually attributable.

### 5.4 What's explicitly *not* built yet (documented, not hidden)

In the interest of being honest about project maturity — this is a reference implementation, not a finished product:

- **Content Safety guardrails** on agent input/output (jailbreak and prompt-injection filtering) are designed but not yet wired in — tracked in `agent/guardrails/`.
- **Full observability** (tracing, eval harness for groundedness/accuracy regression) is scoped but not yet built — tracked in `agent/observability/`.

---

## 6. Model & Agent Design

### 6.1 Why GPT-4o, via Azure AI Foundry

- Already available in-tenant through **Azure OpenAI in AI Foundry** — no new vendor, no data leaving the Azure tenant boundary, covered by the org's existing Microsoft data-processing agreement.
- Strong **tool-calling** support, which is the core requirement here: the model needs to decide *when* to retrieve, *when* to stop and ask a human, and *when* to call a notification tool — not just generate text.
- Large enough context window to hold a full incident + several related alerts + relevant runbook excerpts in a single reasoning pass, reducing the need for multi-turn re-grounding.
- **AI Foundry's Agent Service** gives us managed threads, built-in File Search (used as the RAG retrieval tool against the AI Search index), and native integration with the identity/RBAC model above — instead of hand-rolling orchestration.

### 6.2 Agent responsibilities (and boundaries)

The agent is scoped deliberately narrow:

**It does:**
- Summarize a new Sentinel incident in plain language, pulling in linked alerts and entities.
- Retrieve and cite the relevant SharePoint runbook section for that alert type.
- Flag whether similar incidents were previously closed as false positives (via the indexed incident history).
- Draft — but not send — a Teams update or an email to the incident owner.
- Draft — but not create — a ticket in the ticketing system, with suggested severity and next steps.

**It does not:**
- Modify, close, or reassign a Sentinel incident.
- Send a notification or create a ticket without explicit analyst confirmation (human-in-the-loop gate on every write-adjacent tool).
- Take any containment action (isolate host, disable account, block IP) — that remains with SOAR playbooks and analyst approval, by design.

This "read/reason/draft, human confirms/sends" pattern is what let the SOC team trust the pilot enough to actually adopt it.

---

## 7. Architecture

```
 Sentinel Incident/Alert                SharePoint Runbooks
          │                                     │
          ▼                                     ▼
   ┌─────────────────────  Ingestion Pipeline  ─────────────────────┐
   │  Managed Identity: id-soc-ingestion (read-only on sources)     │
   │  Pulls via Log Analytics/Sentinel REST API + Graph API         │
   │  Sanitizes, chunks, embeds → writes to Azure AI Search          │
   └──────────────────────────────┬──────────────────────────────────┘
                                    ▼
                        Azure AI Search (RAG index)
                     Private Endpoint · classification-tagged
                                    ▼
   ┌──────────────────  AI Foundry Agent (GPT-4o)  ────────────────┐
   │  Managed Identity: id-soc-agent (read-only on index)          │
   │  File Search tool → grounded retrieval, cited answers          │
   │  Tool calls: draft-notify, draft-ticket (human-confirm gated)  │
   └──────────────────────────────┬──────────────────────────────────┘
                                    ▼
                     Analyst (Teams / internal app)
                     reviews → confirms → agent sends/creates
```

**Security wrapper around every hop:** Azure AD / Entra ID identity on every call · least-privilege RBAC per identity · Private Endpoints, no public ingress · Azure Policy guardrails · centralized audit logging. Content Safety and full observability are the flagged next steps (Section 5.4).

---

## 8. Project Flow — How the Two Teams Ran This

| Phase | Duration | Owner | Output |
|---|---|---|---|
| **1. Discovery** | 2 weeks | SOC + Cloud Platform (joint) | Problem statement, success metrics, options comparison (Section 2–3) |
| **2. Data & security design** | 3 weeks | Cloud Platform, with SOC + Security Architecture review | Identity/RBAC model, ingestion design, data classification rules for the index |
| **3. Proof of concept** | 3 weeks | Cloud Platform | Single-tool agent (summarize + cite runbook) against a synthetic dataset, demoed to SOC leadership |
| **4. Pilot** | 6 weeks | Cloud Platform + 3 volunteer Tier-1 analysts | Full tool set (summarize, FP-history check, draft notify/ticket) on real (production, access-scoped) data; weekly feedback loop |
| **5. Hardening** | 4 weeks | Cloud Platform + Security | Audit logging validation, Azure Policy enforcement, access review, tabletop test of a prompt-injection scenario |
| **6. Rollout** | Ongoing | SOC (operate), Cloud Platform (maintain) | Full Tier-1 team onboarded; ingestion pipeline moved to production schedule; Content Safety + observability tracked as fast-follow backlog |

**Governance checkpoints:** Security Architecture signed off before Phase 4 (production data access) and again before Phase 6 (general rollout). Each sign-off was scoped to the specific RBAC grants in Section 5.1, not a blanket approval.

---

## 9. Outcomes (Pilot Results — Synthetic/Representative)

| Metric | Before | After pilot |
|---|---|---|
| Time to full alert context | ~20 min | ~90 sec |
| Systems opened per alert (analyst-reported) | 4 | 1 |
| Analyst acceptance rate of agent summary (no material correction needed) | — | 88% |
| False-positive-history catches (agent flagged "seen before, closed as FP") | — | Caught in 22% of pilot alerts, saving redundant investigation |

---

## 10. Repository / Solution Structure

```
soc-ai-incident-assistant/
├── infra/                      # Terraform — identities, RBAC, AI Foundry, AI Search, storage, policy
│   ├── identities.tf           # id-soc-ingestion, id-soc-agent (separate, least-privilege)
│   ├── rbac.tf
│   ├── network.tf              # Private Endpoints, no public ingress
│   └── policy.tf               # Azure Policy guardrails
├── ingestion/                  # Write path — pulls Sentinel/Log Analytics + SharePoint into the index
│   ├── pipeline.py
│   ├── sanitize.py             # masking/classification rules applied before indexing
│   └── schedule/               # Azure Function timer trigger config
├── agent/                      # Read-only path — the assistant itself
│   ├── agent.py                # AI Foundry Agent Service orchestration
│   ├── tools/
│   │   ├── file_search_tool.py # Foundry built-in RAG retrieval
│   │   ├── incident_history.py
│   │   ├── draft_notify.py     # human-confirm gated
│   │   └── draft_ticket.py     # human-confirm gated
│   ├── guardrails/              # Content Safety — designed, not yet wired in (Section 5.4)
│   └── observability/           # tracing/eval harness — scoped, not yet built (Section 5.4)
├── sample_data/                 # Synthetic alerts/runbooks only — no real data
├── tests/
├── docs/
│   └── architecture.md          # Full diagram + narrative (source for Section 7)
└── SECURITY.md                  # Data handling & access boundaries
```

---

## 11. Lessons Learned & Next Steps

- **Separating ingestion and agent identities early** was the single highest-leverage security decision — it turned "can the agent leak data" into a non-question, since the agent has no path to raw sources.
- **Human-confirm gates on every write-adjacent action** were what got SOC buy-in; analysts trust a tool that drafts and waits far more than one that acts autonomously.
- Runbook quality mattered more than expected — several early pilot answers were only as good as a stale SharePoint doc; a runbook-freshness review became an unplanned but necessary Phase 4 workstream.
- **Backlog for next phase:** Content Safety guardrails (prompt-injection resistance), full observability/eval harness, and extending read access to Defender XDR telemetry for richer entity correlation.

---

*This document is the narrative companion to `docs/architecture.md` and `SECURITY.md` in the reference implementation repo. Sample data referenced throughout is synthetic; no real alerts, logs, or credentials are included.*
