# Azure AIOps Cloud Reliability Platform

> **Project status: Planned / in active development.** This repository
> is intended to become a hands-on, end-to-end Azure AIOps project. Do
> not describe any capability as implemented or claim performance
> improvements until the code is deployed, tested, and measured.

## 1. Project goal

Build a cloud reliability platform that turns Azure operational
telemetry into actionable incidents. The platform will:

1. Ingest selected Azure monitoring signals.
2. Normalize and deduplicate telemetry.
3. Detect unusual behaviour using explainable statistical rules.
4. Correlate related alerts and anomalies into incident records.
5. Use Azure OpenAI to create evidence-grounded root-cause summaries
   and remediation suggestions.
6. Execute only explicitly allowlisted remediation workflows, with
   approval and verification controls.
7. Present incidents, SLOs, error budgets, MTTR, anomalies, and
   remediation outcomes in Azure Managed Grafana.

The project demonstrates Azure platform engineering, Python backend
development, event-driven architecture, observability, security,
Infrastructure as Code (IaC), and responsible AIOps automation.

## Hands-on learning path

Use the [10-day implementation plan](./10-day-implementation-plan.md) to
build this as a hands-on Azure lab: deploy and secure the telemetry
foundation, prove the Log Analytics/Event Hubs route, generate controlled
failures, then implement and exercise the FastAPI, AI triage, and safe
remediation paths. The ten days target a tested development lab, not
production readiness.

## 2. Planned architecture

```text
Azure workloads
   ├── Azure Monitor metrics and alerts
   ├── Log Analytics logs
   └── Application Insights telemetry
                |
                | Supported diagnostic settings, alert actions,
                | and signal-specific export paths
                v
          Azure Event Hubs
                |
                v
       Python background consumer
                |
                ├── Validate and normalize events
                ├── Deduplicate and checkpoint
                ├── Statistical anomaly detection
                └── Incident correlation
                         |
             ┌───────────┴───────────┐
             v                       v
       PostgreSQL              Blob Storage
       incident state           optional raw payload archive
             |
             +----> Azure OpenAI: grounded incident analysis
             |
             +----> Policy/safety gate
                         |
                         v
              Logic Apps / Automation Runbooks
                         |
                         v
                 Verify and audit outcome

FastAPI REST API <----> PostgreSQL
Azure Managed Grafana ----> PostgreSQL curated operational data
Microsoft Entra ID ----> API and Grafana authentication
Managed identities + Key Vault ----> service-to-service access/secrets
Terraform ----> repeatable Azure infrastructure deployment
```

### Architecture principles

- **Use real Azure telemetry from the start.** Avoid a mock-data-only
  implementation path. Unit tests may use fixtures, but the deployed
  integration must use actual Azure resources.
- Azure Monitor signals do not all reach Event Hubs through one
  universal mechanism. Configure and test each signal type separately:
  diagnostic settings for supported logs/resource logs, alert action
  groups for alert notifications, and a supported metrics export/query
  path where required.
- Keep the FastAPI web API separate from the long-running Event Hubs
  consumer process. They may share a repository and common modules,
  but their lifecycle, scaling, and health checks should be
  independently manageable.
- Use deterministic rules for detection, correlation, and action
  eligibility. Use the language model to summarize evidence and
  suggest an approved action, not to make unrestricted infrastructure
  changes.
- Treat Event Hubs processing as at-least-once: duplicates and retries
  are possible. Use idempotent persistence and remediation.
- PostgreSQL stores structured operational state; Blob Storage is
  optional for large raw payloads and replay/audit.
- Prefer managed identities and Microsoft Entra ID. Never commit
  credentials, tokens, connection strings, or API keys.
- Use the Azure Portal for hands-on learning when useful, while adding
  Terraform configuration alongside each resource. Track Portal-created
  resources and reconcile them into Terraform state before Terraform
  manages them; avoid unmanaged drift and never apply an unexpected
  replacement or deletion.
- Treat the deployed lab as ephemeral. Keep the Terraform backend and its
  state outside the lab's lifecycle; use Terraform profiles to create only
  the resources needed for a session, then review and destroy the lab
  resources when finished. Preserve code and redacted evidence, not live
  billable infrastructure. Check for retained-data or soft-delete charges
  after teardown.
- Make each milestone testable and deployable before moving on.

## 3. Technology stack

---


| Area                    Planned technology      Purpose  Cloud                   Microsoft Azure         Runtime and managed                |
| ------------------------------------------------------------------------------------------------------------------------------------------- |
|                                                   services  Telemetry               Azure Monitor, Log      Metrics, logs,                  |
|                           Analytics, Application  application telemetry,                                                                    |
|                           Insights                and alerts  Streaming               Azure Event Hubs        Near-real-time event          |
|                                                   transport  Backend/API             Python, FastAPI,        Authenticated REST APIs        |
|                           Pydantic                and application logic  Background processing   Python Event Hubs       Reliable event     |
|                           consumer                processing  Detection               Python statistical      Explainable anomaly           |
|                           rules                   candidates  Correlation             Python rules and        Group related signals         |
|                           PostgreSQL state        into incidents  AI analysis             Azure OpenAI            Evidence-based incident   |
|                                                   summary and suggested                                                                     |
|                                                   checks  Database                Azure Database for      Incidents, anomalies,             |
|                           PostgreSQL              SLOs, links, and                                                                          |
|                                                   remediation audit  Raw payload archive     Azure Blob Storage      Replay/audit of        |
|                           (optional)              selected raw events  Remediation             Azure Logic Apps and/or Approved operational |
|                           Azure Automation        workflows                                                                                 |
|                           Runbooks  Dashboards              Azure Managed Grafana   Reliability and                                         |
|                                                   operations                                                                                |
|                                                   visualizations  Identity                Microsoft Entra ID,     Authentication and        |
|                           managed identities      service-to-service                                                                        |
|                                                   authorization  Secrets                 Azure Key Vault         Storage of secrets that    |
|                                                   cannot be eliminated  IaC                     Terraform               Repeatable resource |
|                                                   provisioning  Tests                   pytest; API/integration Unit, contract,             |
|                           tests                   integration, and                                                                          |
|                                                   failure-path testing                                                                      |

Developer workflow      VS Code + GPT Codex     Assisted
                          extension               implementation, review,
                                                  and iterative
                                                  development
-------------------------------------------------------------

**Hosting decision to validate:** Azure App Service is the planned
target for the FastAPI API. The Event Hubs consumer should run as a
separately managed worker process/service. Before choosing its final
hosting target, validate long-running process support, restarts,
scaling, and graceful shutdown. Do not assume that hosting the API
automatically provides a reliable background consumer.

## 4. Core functional requirements

### 4.1 Telemetry ingestion

- Consume selected events from a dedicated Event Hubs consumer group.
- Validate event schemas and normalize timestamps to UTC.
- Preserve source event IDs, resource IDs, signal names, dimensions,
  and event time.
- Handle retries, duplicates, checkpointing, malformed events, poison
  events, and consumer lag.
- Avoid logging sensitive raw payloads.
- Record enough metadata to trace an incident back to its source
  evidence.

### 4.2 Anomaly detection

Start with explainable rolling-baseline rules. Candidate approaches
include mean plus standard-deviation thresholds and percentile-based
thresholds.

Requirements: - Minimum sample count and protection against
zero/near-zero variance. - Configurable baseline window, threshold,
severity, cooldown, and hysteresis. - Support for different baselines by
metric/resource/service where appropriate. - Persist the observed value,
baseline, threshold, detection method, and timestamp. - Avoid a single
universal threshold for all workloads. - Test both expected detections
and false-positive scenarios.

An anomaly is a candidate signal, not automatically a confirmed
incident.

### 4.3 Incident correlation

- Group related events using a configurable time window, resource ID,
  service/environment tags, dependency hints, and deployment/change
  metadata where available.
- Deduplicate repeated notifications using stable IDs or fingerprints.
- Update an existing incident when more evidence arrives.
- Persist a human-readable correlation reason.
- Define incident quiet periods, resolution rules, and handling for
  late-arriving events.
- Test over-grouping and under-grouping with known scenarios.

### 4.4 Azure OpenAI analysis

For each eligible incident, provide a compact context packet containing
selected metric changes, relevant log excerpts, correlated alerts,
recent deployment/change details, and evidence references.

Expected structured response: - Summary of what happened. - Evidence
supporting the summary. - Plausible causes, clearly marked as hypotheses
when not proven. - Impact and affected resources. - Recommended
verification steps. - An optional action ID selected from an explicit
allowlist. - Uncertainty or missing evidence.

Controls: - Validate output against a schema. - Treat telemetry and log
text as untrusted input; defend against prompt injection. - Redact
secrets and unnecessary personal/customer data. - Do not send
unrestricted raw logs to the model. - Record model deployment and prompt
versions, evidence references, latency, and outcome where available. -
If evidence is insufficient, the model must say so.

### 4.5 Remediation

Start with **one low-risk, reversible action**. Add more only after
testing.

Every action must: - Map to a fixed, version-controlled action ID and
workflow. - Pass precondition and authorization checks. - Use
least-privilege identity. - Enforce idempotency, timeout, retry limit,
and cooldown. - Require human approval for disruptive or high-impact
changes. - Verify health independently after execution. - Record
initiator, approval, parameters, start/end times, outcome, and
rollback/escalation status.

Never execute arbitrary model-generated commands, scripts, URLs, or
resource operations.

### 4.6 API and dashboards

Initial read-oriented API endpoints: - `GET /health` -
`GET /incidents` - `GET /incidents/{incident_id}` - `GET /anomalies` -
`GET /slos` - `GET /remediations`

Add authenticated action-triggering endpoints only when the policy gate
and audit path are implemented. Protect APIs with Microsoft Entra ID
token validation.

Grafana dashboard groups: - **Reliability:** availability, latency
percentiles, SLO attainment, error budget. - **Incidents:** active
incidents by severity, incident timelines, incident volume, MTTD,
MTTR. - **AIOps quality:** anomaly counts, correlation rate, duplicate
alerts reduced, AI summary latency and reviewer feedback. -
**Remediation:** eligible incidents, attempts, success/failure,
rollbacks, approval wait time, and repeated-action blocks.

Define each metric and calculation before displaying it. Do not invent
or hardcode performance results.

## 5. Data model (initial proposal)

---

  Table                               Purpose

---

  `incidents`                         Incident lifecycle, severity,
                                      status, service, timestamps,
                                      summary

  `events`                            Normalized signals, source IDs,
                                      resource IDs, event time,
                                      fingerprints, payload references

  `anomalies`                         Observed value, baseline,
                                      threshold, method, detection time

  `incident_events`                   Links between incidents and
                                      supporting events, including
                                      correlation reason

  `remediation_runs`                  Action ID, incident ID, status,
                                      initiator, timing, outcome, audit
                                      details

  `slos`                              Service-level objectives,
                                      indicators, targets, windows

`slo_rollups`                       Good/total counts and error-budget
                                      calculations for dashboard windows
------------------------------------------------------------------------

Use migrations, foreign keys, indexes for common filters/time ranges,
parameterized SQL, connection pooling, and UTC timestamps. Define
retention and deletion rules. Store large raw payloads in Blob Storage
only when there is a justified need.

## 6. Security and reliability requirements

- Entra ID authentication for APIs and Grafana SSO.
- Managed identity for Azure service access wherever supported.
- Key Vault for unavoidable secrets; no secrets in source code or
  committed `.env` files.
- Least privilege for Log Analytics reads, Event Hubs listen, Blob
  writes, database access, Azure OpenAI calls, and remediation
  triggers.
- Network access limited to required paths; TLS in transit.
- Input validation, structured logs, correlation IDs, and redaction.
- Retry/backoff and graceful shutdown.
- Event idempotency and safe handling of out-of-order/late events.
- Model timeouts, rate-limit handling, and bounded context size.
- Human approval for risky actions.
- Audit logs and independent post-remediation verification.
- Azure budgets/alerts and cleanup instructions for development
  resources.
- No customer or production data in the initial lab unless explicitly
  approved and appropriately protected.

## 7. Repository structure

Use this as the initial target. Keep the implementation simple and add
modules only when they have a real purpose.

```text
azure-aiops-reliability/
├── README.md
├── pyproject.toml
├── .gitignore
├── .env.example
├── app/
│   ├── main.py                 # FastAPI app entry point
│   ├── api/
│   │   ├── routes_health.py
│   │   ├── routes_incidents.py
│   │   ├── routes_anomalies.py
│   │   └── dependencies.py     # auth and dependency wiring
│   ├── core/
│   │   ├── config.py
│   │   ├── logging.py
│   │   └── security.py
│   ├── ingestion/
│   │   ├── consumer.py
│   │   ├── schemas.py
│   │   └── normalize.py
│   ├── detection/
│   │   ├── baseline.py
│   │   └── rules.py
│   ├── correlation/
│   │   └── engine.py
│   ├── ai/
│   │   ├── client.py
│   │   ├── prompts.py
│   │   └── schemas.py
│   ├── remediation/
│   │   ├── policy.py
│   │   └── dispatcher.py
│   ├── db/
│   │   ├── models.py
│   │   ├── repository.py
│   │   └── migrations/
│   └── schemas/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── infra/
│   └── terraform/
│       ├── .gitignore
│       ├── OPERATIONS.md
│       ├── lab/
│       │   ├── versions.tf
│       │   ├── variables.tf
│       │   ├── names.tf
│       │   ├── main.tf
│       │   ├── networking.tf
│       │   ├── postgres.tf
│       │   ├── identity_and_ai.tf
│       │   ├── observability.tf
│       │   ├── apps.tf
│       │   ├── outputs.tf
│       │   ├── backend.hcl.example
│       │   ├── terraform.tfvars.example
│       │   ├── .terraform.lock.hcl
│       │   └── profiles/    # planned cumulative, cost-aware configurations
├── scripts/
└── docs/
    ├── architecture.md
    ├── decisions.md
    └── runbooks.md
```

The structure is a guide, not a requirement to create every file
immediately. Begin with the smallest working vertical slice.

## 8. Milestones and acceptance criteria

### Milestone 1 --- Foundation

Create a protected Terraform backend separately from the disposable lab.
Use Terraform profiles/modules to provision the dev resource group and
only the resources needed for the current hands-on session. Add the
Log Analytics/Event Hubs route, workload, optional database, Azure OpenAI,
Key Vault, identities, and networking as their implementation milestones
require them.

**Done when:** resources and permissions are documented; connectivity
tests pass; the lab can be destroyed without affecting Terraform state;
and costs, retained-data considerations, and cleanup steps are understood.

### Milestone 2 --- Ingestion

Implement a real Event Hubs consumer, event normalization,
checkpointing, duplicate handling, retry policy, and poison-event
handling.

**Done when:** a real Azure test signal is consumed and safely
persisted; duplicate and restart tests pass.

### Milestone 3 --- Detection

Implement one transparent baseline/rule and explainable anomaly records.

**Done when:** a controlled spike is detected, normal traffic does not
trigger continuous noise, and the reason is stored.

### Milestone 4 --- Correlation

Implement time/resource/service-aware grouping and incident lifecycle
management.

**Done when:** related test signals produce one incident, unrelated
signals remain separate, and duplicates update existing records.

### Milestone 5 --- AI analysis

Integrate Azure OpenAI and schema-validated incident summaries.

**Done when:** output is grounded in supplied evidence, uncertainty is
represented, and no unrestricted action can be invoked.

### Milestone 6 --- Safe remediation

Connect one low-risk allowlisted workflow with preconditions and
verification.

**Done when:** unauthorized and ineligible actions are blocked; the
permitted test action is audited and its result verified.

### Milestone 7 --- Grafana

Connect the curated PostgreSQL data source and build core
reliability/incident panels.

**Done when:** panels match independently checked query results and
Entra ID access controls work.

### Milestone 8 --- Security and resilience

Test identity, least privilege, retries, model/database outages,
consumer lag, timeouts, and cost controls.

**Done when:** failure-path tests pass and operational
alerts/documentation exist.

### Milestone 9 --- Deployment and evidence

Deploy backend and worker using the chosen hosting pattern; manage Azure
resources through Terraform; document repeatable setup and cleanup. Azure
Portal may be used for hands-on resource creation during development, but
each resource must be reconciled into Terraform configuration and state.

**Done when:** a clean dev deployment can be repeated and the repository
contains Terraform code for the project resources, daily create/destroy
profiles, clear deployment and cleanup instructions, tests, architecture
decisions, screenshots, and measured results. The Terraform code and
instructions must support provisioning the environment without
undocumented Portal clicks, as well as explain how to import resources
created during the learning process. The remote state backend must remain
separate from lab teardown.

## 9. Test plan

At minimum, test: - Valid event and malformed event. - Duplicate event
and duplicate alert notification. - Out-of-order and late-arriving
event. - Consumer restart and checkpoint recovery. - Event Hubs
throttling or temporary outage. - Database timeout/unavailability. -
Azure OpenAI timeout, invalid output, and rate limit. - Insufficient
evidence for root-cause analysis. - Prompt-injection-like text inside a
log event. - Unapproved remediation request. - Remediation
timeout/failure and failed health verification. - Repeated action
blocked by idempotency/cooldown. - Unauthorized API request. - SLO
calculation against a hand-verified sample.

## 10. Measurements to collect

Do not claim improvement until a baseline and repeatable test exist.

---

  Metric                              Measurement approach

---

  Alert-to-incident reduction         Compare raw alert count and
                                      resulting incident count for the
                                      same test window; also assess
                                      correlation quality

  Detection delay                     Detection timestamp minus source
                                      event timestamp

  MTTD                                Defined incident-start timestamp to
                                      detection/open time

  MTTR                                Incident opened/detected time to a
                                      clearly defined restoration or
                                      resolution time

  Correlation quality                 Label known test cases and evaluate
                                      correct grouping versus
                                      over/under-grouping

  AI summary quality                  Review grounding, factual accuracy,
                                      uncertainty, and usefulness with a
                                      rubric

  Remediation success                 Verified successful actions divided
                                      by completed eligible attempts

  SLO/error budget                    Calculate from a documented SLI and
                                      target over a defined window

Cost                                Track ingestion, compute, database,
                                      storage, and Azure OpenAI usage
---------------------------------------------------------------------

Record test setup, workload, time window, query, raw outputs, and
limitations. Do not fabricate metrics.

## 11. Resume positioning

### Planned resume bullet --- target only, not yet a factual accomplishment

> **AIOps & Cloud Reliability Platform (Azure):** Building an
> event-driven AIOps platform using Azure Monitor, Event Hubs,
> Python/FastAPI, statistical anomaly detection, incident correlation,
> Azure OpenAI--assisted root-cause analysis, and policy-controlled
> runbook remediation; visualizing SLOs, error budgets, incident trends,
> and MTTR in Azure Managed Grafana.

Use "Building" while work is in progress. Once complete, revise to
"Built/Implemented" only for components actually delivered. Add
quantitative claims only after collecting defensible measurements from
repeatable tests.

### Evidence to gather before finalizing the resume bullet

- Architecture diagram and deployment instructions.
- Terraform configuration and a successful repeatable deployment.
- Tests showing ingestion, deduplication, anomaly detection, and
  correlation.
- Sample evidence-grounded AI summary with sensitive data removed.
- Audit records for a safe remediation test.
- Grafana screenshots and definitions of SLO/MTTR metrics.
- Measured baseline versus test results and cost assumptions.
- Clear statement of what was tested in a dev lab versus production.

## 12. Instructions for GPT Codex in VS Code

Treat this document as the detailed project specification and source of
truth for target requirements. Use the top-level `README.md` for the
project overview and `infra/README.md` for the current infrastructure
inventory.
Implement incrementally and keep the code deployable.

1. First inspect the repository and summarize the current state. Do not
   overwrite existing work without explaining the change.
2. Propose the next smallest vertical slice and list files to
   create/change before implementing a broad refactor.
3. Prefer simple, typed, testable Python modules, Pydantic schemas,
   clear interfaces, structured logging, and dependency injection.
4. Add unit tests with each feature. Add integration tests for Azure
   services using explicit configuration and safe test resources.
5. Use current, supported Azure SDKs and official authentication
   patterns. If a package/API version is uncertain, flag it and verify
   against current official documentation rather than guessing.
6. Never hardcode secrets, subscription IDs, tenant IDs, resource IDs,
   credentials, or production values. Use environment configuration,
   managed identity, and Key Vault as appropriate.
7. Do not invent Azure resource properties, diagnostic-setting
   capabilities, or deployment success. Validate service-specific
   telemetry routes and permissions.
8. Never let an LLM execute arbitrary commands or directly control
   Azure. Only dispatch fixed allowlisted action IDs after
   deterministic policy checks.
9. Do not silently add expensive resources or enable public network
   access. Explain cost, region, identity, networking, and teardown
   implications before deployment changes.
10. Keep Terraform changes separate and reviewable. Run formatting,
    validation, and `terraform plan` before deployment. If a resource was
    created manually in Azure Portal, write matching Terraform
    configuration and import/reconcile it into the correct state before
    managing it with Terraform; do not apply a plan that would replace or
    destroy it unexpectedly.
11. Update README/docs with every meaningful architecture or operational
    change.
12. At the end of each task, report: files changed, design choices,
    tests run and results, Azure resources/permissions needed, commands
    to run, known gaps, and the next milestone.
13. Do not claim a test, deployment, measurement, or remediation
    succeeded unless it actually ran and the result was observed.

### Suggested first prompt for Codex

```text
Read the top-level README.md and AIOps.md fully. Treat AIOps.md as the
detailed project specification.

Do not build the entire system in one pass. First inspect the repository and report:
1. What exists and what is missing.
2. A proposed minimal Python project scaffold.
3. The configuration and identity approach.
4. The first vertical slice and its tests.
5. Any Azure design assumptions that need validation.

Then wait for my approval before making broad changes. Keep the implementation real-Azure-ready, secure by default, testable, and aligned with the milestone plan. Do not fabricate Azure settings or claim deployments/tests that have not been run.
```

## 13. Open decisions to resolve during implementation

- Azure region, subscription, budget, and naming convention.
- Existing versus new Event Hubs namespace and its
  throughput/retention settings.
- Exact telemetry types and the supported path for each type.
- PostgreSQL version, network access, and authentication method.
- Azure OpenAI model deployment, quota, region availability, and
  data-handling requirements.
- Separate hosting choice for the long-running consumer worker.
- First workload and controlled failure scenario.
- First remediation action and approval requirement.
- Retention, privacy, and audit requirements.
- SLI/SLO definitions and authoritative source for good/total events.

---

**Definition of success:** A repeatable dev deployment that consumes
real Azure telemetry, creates explainable anomalies and correlated
incidents, produces evidence-grounded AI summaries, safely executes one
approved remediation, and displays independently verified operational
metrics---backed by tests and documented measurements.
