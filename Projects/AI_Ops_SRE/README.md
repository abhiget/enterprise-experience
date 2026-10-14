# Azure AIOps/SRE project

Build a hands-on Azure reliability platform that turns operational
telemetry into actionable, explainable incidents. The target system
combines Azure Monitor, Event Hubs, a Python consumer, FastAPI,
PostgreSQL, Azure OpenAI, and controlled remediation.

> **Status:** Infrastructure code is in place and the current full-stack
> Terraform plan has been reviewed. No AIOps lab resources have been
> applied, and the Python application, tests, and deployment pipeline
> have not been implemented yet. This is a development-lab target, not a
> production-ready service.

## Documentation

| Document | What it is for |
| --- | --- |
| [10-day hands-on plan](./10-day-implementation-plan.md) | Practical daily implementation, troubleshooting, and lab lifecycle |
| [Infrastructure overview](./infra/README.md) | Azure resource inventory, Terraform layout, deployment scope, and cost/safety notes |
| [Detailed project specification](./AIOps.md) | Target architecture, requirements, data model, controls, tests, and acceptance criteria |
| [Terraform operations guide](./infra/terraform/OPERATIONS.md) | Remote state setup and exact Terraform plan/apply/destroy procedures |

## Target workflow

```text
Azure workload
    |
    +--> Azure Monitor / Application Insights
              | supported diagnostic settings, alerts, and signal routes
              v
         Azure Event Hubs
              |
              v
      Python background worker
       validate -> normalize -> deduplicate/checkpoint
              |
       detect anomalies -> correlate signals
              |
              v
         PostgreSQL <------ FastAPI incident API
              |
       evidence packet and references
              |
              v
        Azure OpenAI
       summarize evidence and suggest checks
              |
       deterministic policy and approval gate
              |
              v
       allowlisted remediation
       execute -> verify -> audit
              |
              v
       Azure Managed Grafana
       incidents, SLOs, error budget, outcomes

Terraform -> repeatable Azure lab infrastructure
Entra ID and managed identities -> user and service authorization
Key Vault -> secrets only where managed identity is not sufficient
```

Azure Monitor signal types do not all use the same route. Verify the
supported export mechanism, categories, and permissions for each signal.
The AI component summarizes evidence and proposes checks; deterministic
code and explicit approval control any remediation.

## Build and operate

1. Start with the [10-day plan](./10-day-implementation-plan.md). Each day
   should leave a tested increment rather than a theory-only milestone.
2. Use Terraform to provision only the cumulative lab profile needed for
   that session. The remote state backend is separate and must survive
   lab teardown.
3. Verify Azure identity, network access, telemetry delivery, and
   permissions before debugging application code.
4. Implement and test the consumer, API, detection/correlation, AI
   analysis, and one tightly allowlisted remediation path.
5. Review cost and destroy disposable lab resources when finished. Keep
   code and redacted evidence, not long-running billable infrastructure.

See the [infrastructure overview](./infra/README.md) before provisioning
and the [Terraform operations guide](./infra/terraform/OPERATIONS.md) for
backend and command details.

## Current implementation layout

```text
AI_Ops_SRE/
├── README.md                         # Project overview and workflow
├── AIOps.md                          # Detailed target specification
├── 10-day-implementation-plan.md     # Hands-on daily build plan
└── infra/
    ├── README.md                     # Infrastructure overview
    └── terraform/
        ├── OPERATIONS.md             # State, plan, apply, destroy guide
        ├── .gitignore
        └── lab/                      # One Terraform root module and state
            ├── versions.tf
            ├── variables.tf
            ├── names.tf
            ├── main.tf               # Telemetry foundation
            ├── networking.tf
            ├── postgres.tf
            ├── identity_and_ai.tf
            ├── observability.tf
            ├── apps.tf
            ├── outputs.tf
            ├── backend.hcl.example
            ├── terraform.tfvars.example
            └── .terraform.lock.hcl
```

Terraform files in `lab/` are separated by responsibility for readability,
but remain in one root module. Their resource addresses and shared state
are not changed by this file organization.

The Python application, unit/integration tests, database migrations,
remediation workflows, and deployment pipeline remain planned work. The
Terraform App Service settings describe intended runtime entry points;
they do not mean application packages already exist or have been deployed.

## Infrastructure plan status

The latest full-stack plan was **33 to add, 0 to change, 0 to destroy**.
That plan is not an apply: no disposable AIOps resources were provisioned.
Before applying, review the subscription-wide Activity Log diagnostic
setting, Azure OpenAI model availability/quota, and the ongoing charges
for Event Hubs Standard, PostgreSQL, Azure OpenAI, Managed Grafana, and
App Service. Terraform does not provide a complete cost estimate.
