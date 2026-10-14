# AIOps/SRE infrastructure overview

This document describes the Azure infrastructure currently represented by
Terraform for the AIOps lab. For exact backend setup and command-by-command
operations, see the [Terraform operations guide](./terraform/OPERATIONS.md).

## Environment boundaries

| Environment component | Location / ownership | Lifecycle |
| --- | --- | --- |
| Terraform remote state | Storage account `staiopsstate104673`, container `tfstate`, in the existing `az-104` resource group in West India | Persistent; do not include in lab destroy |
| AIOps lab | Existing `RG-SRE-AIOPS` resource group in East US | Disposable; Terraform manages resources inside it |

Terraform reads the lab resource group; it does not create or delete the
resource group itself. The lab state uses Azure Blob remote state with
Microsoft Entra authentication. State may contain sensitive infrastructure
attributes, so access to the backend must remain restricted.

## Terraform root

All `.tf` files under [`terraform/lab`](./terraform/lab/) form one root
module and share one state. The files are grouped by purpose for easier
navigation; they are not separate Terraform modules.

| File | Responsibility |
| --- | --- |
| `versions.tf` | Terraform/provider constraints, AzureRM provider, backend |
| `variables.tf`, `names.tf` | Configuration, feature switches, shared names |
| `main.tf` | Log Analytics, Event Hubs, checkpoint storage, worker identity/RBAC, optional subscription Activity Log export |
| `networking.tf` | Optional VNet, delegated subnets, PostgreSQL private DNS |
| `postgres.tf` | Optional private Entra-authenticated PostgreSQL server and database |
| `identity_and_ai.tf` | Optional API identity, Key Vault, Azure OpenAI deployment, and access roles |
| `observability.tf` | Optional Application Insights and Managed Grafana |
| `apps.tf` | Optional shared App Service plan and separate API/worker Web Apps |
| `outputs.tf` | Useful resource names, IDs, and endpoints |
| `terraform.tfvars.example`, `backend.hcl.example` | Safe starting templates; local real values are excluded from Git |

`enable_extended_stack` defaults to `false` in the checked-in example.
It gates the VNet, PostgreSQL, Key Vault, Azure OpenAI, Application
Insights, Managed Grafana, and App Services. The core telemetry foundation
is separately configurable. The backend example and local ignored files
are described in the [operations guide](./terraform/OPERATIONS.md).

## Planned resource inventory

### Telemetry foundation

- Log Analytics workspace with configurable retention and daily ingestion
  quota.
- Event Hubs Standard namespace, telemetry hub, and dedicated worker
  consumer group.
- Private Blob container and storage account for worker checkpoints.
- User-assigned worker identity with Event Hubs receive and checkpoint
  Blob data access.
- Optional subscription-scoped Activity Log diagnostic setting to route
  selected categories to Log Analytics and Event Hubs.

**Scope warning:** the Activity Log diagnostic setting targets the whole
subscription, not only `RG-SRE-AIOPS`. It is controlled by
`enable_subscription_activity_log_export`; inspect the plan and disable
it unless subscription-wide export is intended and approved.

### Optional extended stack

- VNet and delegated subnets for App Service integration and private
  PostgreSQL.
- Private DNS and Entra-only PostgreSQL Flexible Server/database.
- Key Vault with RBAC authorization.
- Azure OpenAI account and configurable incident-triage model deployment.
- Application Insights and Azure Managed Grafana.
- API managed identity and scoped access to Log Analytics, Key Vault, and
  Azure OpenAI.
- Separate API and worker Web Apps on one shared B1 Linux App Service
  plan. They are separate applications but share compute capacity and
  scale together.

The infrastructure is not yet a deployed application. App code,
Entra-authenticated API enforcement, PostgreSQL principals/table grants
for app identities, Grafana's supported connection path to private
PostgreSQL, alert receivers, and remediation workflows remain to be built
and verified.

## Current plan and cost

The latest full-stack Terraform plan reported **33 to add, 0 to change,
0 to destroy**. It was plan-only; no AIOps lab resources were applied.
The result does not guarantee Azure OpenAI model quota, regional
availability, or final pricing.

Event Hubs Standard, PostgreSQL compute/storage/backups, Azure OpenAI,
Managed Grafana Standard, and the B1 App Service plan can incur charges
while provisioned. Terraform plan is not a bill estimate. Review current
pricing, budgets, region capacity, and destroy/retention behavior before
enabling the extended stack.

## Provisioning workflow

1. Confirm the active Azure subscription, region, permissions, and budget.
2. Review the Terraform plan for scope, role assignments, public exposure,
   replacement/deletion, and cost.
3. Apply only the resources needed for the current cumulative day/profile.
4. Verify identity and network connectivity, then prove the telemetry
   route before adding application layers.
5. At session end, review the destroy plan for the lab state and remove
   disposable resources. Keep the remote state account/container.

Use the [10-day hands-on plan](../10-day-implementation-plan.md) for
day-by-day implementation and the
[Terraform operations guide](./terraform/OPERATIONS.md) for exact
commands and backend procedures.
