# Terraform lab operations

The disposable lab uses the existing `RG-SRE-AIOPS` resource group in
`eastus`. Terraform does not create or delete that resource group.

The Terraform remote-state storage account `staiopsstate104673` and
private `tfstate` container have been created with Azure CLI in the
existing `az-104` resource group in `westindia`. They are intentionally
outside the lab Terraform state and are not managed or destroyed by the
lab configuration.

## One-time remote-state setup

### Prerequisites

- Azure CLI and Terraform 1.6 or later.
- Permission to read the selected subscription/resource group, create a
  storage account/container in `az-104`, and assign the `Storage Blob Data
  Contributor` role to your user on the new storage account.
- Confirm the `az-104` resource group and subscription are approved for
  this purpose. This storage account will hold Terraform state for the
  AIOps lab; state can include sensitive infrastructure attributes.

Sign in and verify subscription and resource group before creating
anything:

```powershell
$subscriptionId = "<your-approved-subscription-guid>"
az login
az account set --subscription $subscriptionId
az account show --query "{subscription:id, name:name, tenant:tenantId}" --output table
az group show --name "az-104" --query "{name:name, location:location}" --output table
```

Stop if the selected subscription is not the subscription that contains
the expected existing `az-104` resource group in `westindia`.

The state storage account created for this lab is
`staiopsstate104673`. If reproducing this setup in another subscription,
choose a globally unique lowercase storage account name (3-24 characters,
letters and numbers only), check its availability, and substitute it in
the commands and backend configuration:

```powershell
$stateStorageName = "staiopsstate104673"
az storage account check-name --name $stateStorageName --query "{available:nameAvailable, reason:reason}" --output table
```

The account and container already exist in this environment; do not run
the create commands again. For a new environment, if `available` is false,
choose another candidate and check again. Create the account in `az-104`
and grant the signed-in user data-plane access.
The identity creating the role assignment needs appropriate RBAC
administrative permission at the storage account scope or above.

```powershell
# Run only when setting up a different state account.
az storage account create `
  --name $stateStorageName `
  --resource-group "az-104" `
  --location "westindia" `
  --sku "Standard_LRS" `
  --kind "StorageV2" `
  --min-tls-version "TLS1_2" `
  --https-only true `
  --allow-blob-public-access false `
  --allow-shared-key-access false `
  --output none

# Run only when setting up a different state account.
$accountId = "/subscriptions/$subscriptionId/resourceGroups/az-104/providers/Microsoft.Storage/storageAccounts/$stateStorageName"
$userObjectId = az ad signed-in-user show --query id --output tsv

az role assignment create `
  --assignee-object-id $userObjectId `
  --assignee-principal-type User `
  --role "Storage Blob Data Contributor" `
  --scope $accountId `
  --output none
```

After role assignment propagation, create the private state container using
Microsoft Entra authentication (not an account key):

```powershell
# Run only when setting up a different state account.
az storage container create `
  --name "tfstate" `
  --account-name $stateStorageName `
  --auth-mode login `
  --public-access off `
  --output none
```

Verify account settings and container:

```powershell
az storage account show `
  --name $stateStorageName `
  --resource-group "az-104" `
  --query "{name:name, location:primaryLocation, httpsOnly:enableHttpsTrafficOnly, sharedKeyEnabled:allowSharedKeyAccess, publicBlobAccess:allowBlobPublicAccess}" `
  --output table

az storage container show `
  --name "tfstate" `
  --account-name $stateStorageName `
  --auth-mode login `
  --query "{name:name, publicAccess:properties.publicAccess}" `
  --output table
```

Do not delete the account or container during daily lab teardown. Protect
access to this resource group and account; Terraform state is sensitive.
The storage account is in West India and the lab is in East US, so state
requests are cross-region. This is acceptable for a small learning lab,
but has some latency and should be reconsidered for a production backend.

## Configure and initialize the lab backend

From this directory:

```powershell
Set-Location ..\lab
Copy-Item backend.hcl.example backend.hcl
Copy-Item terraform.tfvars.example terraform.tfvars
```

The example backend file already names the state account created for this
project. Edit `terraform.tfvars` only if the subscription or stable
resource-name suffix changes. These local files are excluded by
`.gitignore`; do not commit them.

Initialize the lab state backend with the Azure CLI identity:

```powershell
terraform init -reconfigure -backend-config="backend.hcl"
terraform fmt -check
terraform validate
terraform plan
```

If a local Terraform state already exists and contains resources, do not
use `-reconfigure`; migrate that state to the remote backend with
`terraform init -migrate-state -backend-config="backend.hcl"` and confirm
the migration prompt. No Azure resources should be applied before the
first remote-backend initialization.

## Review and deploy the initial telemetry foundation

The initial Terraform configuration creates, in one reviewed apply:

- A Log Analytics workspace with 30-day retention and a configurable
  daily ingestion quota.
- An Event Hubs Standard namespace, telemetry hub, dedicated worker
  consumer group, and authorization rule for Azure Monitor diagnostic
  export. Azure Monitor's Event Hubs streaming path requires Manage,
  Send, and Listen permissions on this rule; this permission set is for
  the diagnostic export path, not the Python worker identity.
- A checkpoint storage account and private Blob container.
- A user-assigned worker identity with Event Hubs receive access scoped to
  the telemetry hub and Blob checkpoint access scoped to the checkpoint
  storage account.
- An optional subscription-scoped Activity Log diagnostic setting that
  exports the selected categories to Log Analytics and Event Hubs.

The Activity Log diagnostic setting applies to the subscription, not only
to `RG-SRE-AIOPS`. Review the Terraform plan and confirm that scope and
categories are acceptable. Set
`enable_subscription_activity_log_export = false` in `terraform.tfvars`
if you want to omit it. It exports Azure Activity Logs; it does not
forward arbitrary Log Analytics tables.

```powershell
terraform plan
# Apply only after reviewing every create/update/replace/delete and cost.
terraform apply
terraform output
```

Later project days add resource-specific diagnostics, the test workload,
consumer, database, API, AI, dashboard, and remediation when needed.

## Full AIOps stack plan

The optional resources are split by concern across `networking.tf`,
`postgres.tf`, `identity_and_ai.tf`, `observability.tf`, and `apps.tf`.
They are controlled by `enable_extended_stack`. The checked-in example
defaults to `false`;
the ignored local `terraform.tfvars` can enable it for a **plan-only**
review:

```hcl
enable_extended_stack         = true
postgres_admin_principal_name = "<signed-in Entra user UPN>"
```

The extended plan adds a private VNet path for App Service and PostgreSQL,
an Entra-only PostgreSQL Flexible Server/database, Key Vault, an Azure
OpenAI account/model deployment, Application Insights, a Standard Managed
Grafana instance, and separate API/worker Web Apps with managed identities
and scoped role assignments. The API and worker share one B1 App Service
plan to limit lab cost; they run as separate apps/processes but share
compute capacity and scale together.

The most recent full plan completed successfully with **33 to add, 0 to
change, and 0 to destroy**. This is a plan result only; no lab resources
were applied. Plans do not reserve or prove Azure OpenAI model quota,
regional capacity, or final pricing. Verify model/version/SKU availability
and current costs in the subscription before applying.

The full stack is not yet a one-click operational application:

- App Service instances are provisioned before the application code
  exists. Deploy and test the API/worker packages separately; configure
  Entra authentication before exposing a useful API.
- PostgreSQL uses private networking and Entra authentication. Terraform
  assigns the current user as server Entra administrator, but application
  managed identities still need database principals and least-privilege
  SQL grants created/validated inside PostgreSQL. Azure RBAC assignments
  alone do not grant SQL table access.
- Managed Grafana is provisioned with an identity and Log Analytics read
  access. Connecting it to the private PostgreSQL database needs a
  separately verified supported network path and database identity; do
  not assume the current resource plan creates that data-source
  connectivity.
- Alert notification receivers and remediation workflows are intentionally
  not created until the alert destination and one fixed safe action are
  selected.
- The subscription Activity Log diagnostic setting is broader than
  `RG-SRE-AIOPS`. Disable it in local `terraform.tfvars` unless its
  subscription-wide scope and exported categories have been approved.
- Azure Monitor's Event Hubs streaming authorization rule requires Manage,
  Send, and Listen permissions. Keep it dedicated to the diagnostic export
  path; the worker uses managed identity for receive access.

When reviewing a full-stack plan, expect billable Event Hubs Standard,
PostgreSQL compute/storage/backups, Azure OpenAI usage/model deployment,
Managed Grafana Standard, and the B1 App Service plan. These are
provisioned only when `enable_extended_stack = true`; review each cost,
network exposure, role assignment, and destroy consequence before apply.
Azure OpenAI accounts are purged on Terraform destroy to allow the lab to
reuse its name; Key Vault is soft-deleted and recovered on the next create.
PostgreSQL backup retention can outlast server teardown.

## Daily hands-on lifecycle

Keep `name_suffix`, backend config, and lab tfvars stable between apply
and destroy. The lab Terraform does not manage either resource group or
the remote-state storage account/container.

At session start:

```powershell
Set-Location Projects\AI_Ops_SRE\infra\terraform\lab
terraform init -backend-config="backend.hcl"
terraform plan
```

At session end, save code and redacted evidence, then inspect the destroy
plan. Confirm the target subscription and that it contains only disposable
lab resources:

```powershell
terraform plan -destroy
# Review the plan before executing:
terraform destroy
```

Destroying the lab does not reverse ingestion charges or necessarily
remove retained/soft-deleted data immediately. Check Azure Cost Management
after teardown. Never delete the state backend as part of the lab workflow.

## Terraform safety notes

- Never commit state, `.terraform`, local tfvars, backend config, secrets,
  or plan files.
- Do not change the suffix between apply and destroy.
- Stop and investigate any plan that unexpectedly replaces or deletes a
  resource.
- Azure Monitor diagnostic export to Event Hubs requires a namespace
  authorization rule with Manage, Send, and Listen permissions. Review
  this broader permission when assessing the diagnostic export design.
- If resources are created manually in the Portal, import them into the
  correct lab state before Terraform manages them.
- The backend account disables shared-key access and public blob access,
  and uses TLS/HTTPS. Network access may be limited to improve security,
  but ensure the Terraform runner remains able to reach the storage
  endpoint.
