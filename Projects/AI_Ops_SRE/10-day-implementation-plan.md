# Azure AIOps/SRE Platform — 10-Day Hands-on Build

This is an execution plan for building and troubleshooting a working Azure
lab, not a ten-day theory course. It assumes platform-engineering
experience and spends the time on the AIOps-specific work: telemetry
plumbing, event processing, FastAPI, AI-assisted incident triage,
controlled remediation, and operational proof.

See the [project overview](./README.md) for the end-to-end workflow,
[infrastructure overview](./infra/README.md) for the Terraform resource
scope, and [detailed specification](./AIOps.md) for security requirements
and project boundaries. Complete one working module each day; if a day's
exit check fails, troubleshoot that before adding another layer.

## What “done” means

By the end of Day 10, a repeatable development-lab incident drill should
work end to end:

1. Generate a controlled failure in a disposable Azure workload.
2. Observe its logs/telemetry in Log Analytics and on the selected
   Event Hubs route.
3. Ingest, normalize, deduplicate, and persist the event.
4. Create or update an incident and expose it through FastAPI.
5. Retrieve relevant evidence and generate an evidence-grounded AI
   triage summary with uncertainty and verification steps.
6. Optionally run one explicitly approved, low-risk action against the
   disposable workload and verify its outcome.
7. Review the incident and measured signals in a dashboard.
8. Rebuild/deploy from documented Terraform and application instructions,
   then clean up the lab safely.

The result is a tested dev lab, not a production-ready service. Report
anything unavailable (subscription permissions, Azure OpenAI quota,
regional service availability, or costs) as a blocker or known gap, not as
a completed integration.

## Lab operating rules

- Use a dedicated dev resource group, disposable workload, and synthetic
  or otherwise approved non-sensitive data.
- Design the Terraform code to describe the **complete target lab**, but
  make optional/costly components selectable so a daily session can deploy
  only the services it needs. A full end-to-end profile is used for the
  final game day, not necessarily every day.
- Keep only the Terraform remote-state backend (and, if desired, stable
  low-cost operator identities) outside the disposable lab lifecycle.
  Store state in the existing `az-104` resource group in `westindia`, in a
  separate protected storage account/container. Never include the backend
  in the lab's destroy operation.
- Use a single clearly named lab environment and the same Terraform state
  across its create/destroy cycles. Use checked-in example variable files
  for daily profiles; keep actual identifiers and secret values in
  ignored local files or approved secret management. Avoid using
  `terraform destroy` with a different profile from the one used to apply.
- Use the Azure Portal to create and inspect resources hands-on. At the
  same time, add the equivalent Terraform configuration and keep a
  resource inventory. Before Terraform manages a Portal-created resource,
  import/reconcile it into the intended state and review the plan. Never
  apply a plan with unexplained replacement or deletion.
- Use a protected Terraform backend and keep state, credentials, plans
  containing sensitive values, and secrets out of Git.
- Assign data-plane permissions to the runtime identities at the narrowest
  useful scope. Do not use account keys or broad subscription-level
  contributor roles as shortcuts.
- Check price and set a budget/cost alert before enabling billable
  PostgreSQL, Azure OpenAI, Managed Grafana, or always-on compute. Keep
  expensive services off until their day in the plan.
- Azure Monitor signals have different supported routes. A resource's
  diagnostic settings can send supported categories to Log Analytics and
  Event Hubs; this does not mean every Log Analytics workspace table can
  automatically be forwarded to Event Hubs. Verify the chosen resource,
  category, destination, and permissions in Azure.
- Capture redacted evidence each day: Terraform plan/apply output,
  resource IDs (not secrets), KQL results, event counts, API responses,
  test output, and screenshots where useful.

## Daily create-work-destroy workflow

The goal is to keep the infrastructure reproducible without paying to run
the entire stack between hands-on sessions. Recreate the **lab stack** as
needed; preserve the state backend and source code.

### One-time setup

1. Agree on the subscription, region, naming prefix, budget, and a
   dedicated lab resource group naming convention.
2. Create the Terraform state storage account and private container once
   using Azure CLI in the existing `az-104` resource group in `westindia`.
   Keep this backend outside the lab Terraform configuration/state so lab
   teardown cannot remove it. Document its access and recovery procedure.
3. Decide whether stable user-assigned identities are useful across lab
   sessions. If used, manage them in a separate foundation/state and
   scope their role assignments narrowly; otherwise create identities
   with the lab and accept that role propagation may delay testing.
4. Add the full lab's Azure resources and IAM to Terraform in modules.
   Put optional, billable services behind explicit, conservative variables
   or profile files (for example: telemetry core, database, model, hosted
   services, dashboard, remediation). Do not default expensive features
   to enabled.
   Profiles should be cumulative: for example, the Day 5 profile contains
   the resources needed to reproduce Days 1-5 together, not only the
   resources introduced on Day 5. This lets each fresh deployment exercise
   the working stack built so far.
5. Add example variable/profile files with no secrets. Configure state
   locking, encryption, restricted access, and recovery. Do not commit
   `.tfstate`, state backups, credentials, or sensitive plan files.
6. Verify the Terraform destroy plan only targets the disposable lab
   resources. Consider `prevent_destroy` for resources that must never be
   removed, but do not rely on it instead of separating the backend.

### At the start of each hands-on session

1. Check Azure subscription/tenant context, budget, existing resources,
   prior session status, and Terraform state.
2. Choose that day's cumulative profile and inspect `terraform plan`.
   Resolve drift and any unplanned replacement/deletion before apply.
3. Apply only after reviewing the plan. Wait for role assignments to
   propagate and run small identity/connectivity smoke tests before
   debugging application code.
4. Work on the day's implementation and record test evidence, costs, and
   any issue that changes the plan.

### At the end of each session

1. Save code, redacted evidence, KQL/API queries, and the exact profile
   used. Do not save secrets, raw sensitive events, or state.
2. Stop test traffic and disable any trigger or schedule that can continue
   generating events or actions.
3. Run and review `terraform plan -destroy` for the **lab state and the
   same configuration/profile used for deployment**. Confirm the target
   subscription/resource group and list of resources. Never destroy the
   state backend or unrelated resources.
4. Run `terraform destroy` only after that review. Confirm the lab
   resource group and remaining billable resources are gone or stopped.
5. Check Azure Cost Management later as well: billing data can lag, and
   retained Log Analytics data, soft-deleted resources, or other
   provider-specific retention may continue to incur charges after the
   main resources are deleted.

Example PowerShell session (replace the profile name with the day's
reviewed variable file; these commands are a workflow template, not proof
that a deployment has been run):

```powershell
Set-Location infra\terraform\lab
terraform init
terraform fmt -check
terraform validate
terraform plan -var-file="profiles\day-01.tfvars"
terraform apply -var-file="profiles\day-01.tfvars"
# Run that day's checks and save redacted evidence.
terraform plan -destroy -var-file="profiles\day-01.tfvars"
# Review the destroy plan before executing:
terraform destroy -var-file="profiles\day-01.tfvars"
```

Keep the variables that determine resource identity and configuration
consistent between plan, apply, and destroy. If the deployed profile
changes during a session, review a normal plan to understand the
transition; do not blindly apply a destroy profile that no longer matches
the resources in state.

**Cost note:** Destroying resources reduces ongoing compute/service costs
but does not guarantee a zero bill. Ingestion already consumed, retained
data, bandwidth, soft-delete/recovery windows, and charges accrued before
teardown may remain billable. Budgets and alerts inform; they are not
instant spending caps.

## How we will work through the plan

Treat the 10-day document as a living execution checklist. At the start of
a session, work only on the current day's module and confirm its Azure
profile, permissions, and cost. During the session, implement the
Portal/IaC changes and the application slice together. At the end, record
what actually passed, the troubleshooting performed, and any blocker;
then update the next day's scope if a real Azure constraint or test result
changes the approach. Do not silently mark a blocked integration complete
or carry forward assumptions as facts.

## Daily build sequence

| Day | Build module | Working result |
| --- | --- | --- |
| 1 | Azure lab foundation and IAM | Core resources exist, identities/roles are tested, Terraform state and inventory are ready |
| 2 | Telemetry plumbing | The same controlled source signal is queryable in Log Analytics and observed in Event Hubs where supported |
| 3 | Signal generator and alert drill | Repeatable normal/error/latency scenarios produce searchable telemetry and an alert |
| 4 | Event consumer and persistence | Python worker consumes real events, safely writes them, and recovers from duplicate delivery |
| 5 | FastAPI incident service | Working health, incident, event, and triage endpoints over persisted data |
| 6 | AI-assisted triage | Incident evidence becomes a validated Azure OpenAI summary with cited evidence and uncertainty |
| 7 | Correlation and incident workflow | Repeated related signals update one incident; unrelated signals stay separate |
| 8 | Approved remediation | One fixed, approved dev action is audited and independently verified, or remains explicitly disabled |
| 9 | Reliability view and operational hardening | SLO/incident dashboard, failure drills, logs, alerts, and access review |
| 10 | Full incident game day and reproducible handoff | Fresh run, measured evidence, Terraform/app instructions, and cleanup procedure |

## Day 1 — Create the Azure lab and prove IAM

**Today’s outcome:** The base telemetry environment is deployed in Azure,
the runtime identities are defined, and each required access path has a
recorded verification. Begin with the Portal, not application code.

### In Azure Portal

1. Select the intended subscription and region; create a dedicated
   resource group with owner/project/environment/expiry tags.
2. Create the Log Analytics workspace.
3. Create an Event Hubs namespace and a dedicated event hub for the lab.
   Create a dedicated consumer group for the worker; do not use `$Default`
   for the application.
4. Create a storage account/container for Event Hubs checkpoints if the
   selected consumer implementation requires it.
5. Select or deploy the smallest disposable workload that can emit
   structured telemetry (for example, a small web/API workload). Enable
   Application Insights only if it is part of the chosen test signal.
6. Create or identify separate managed identities for the consumer and
   API. If hosting is not selected yet, create user-assigned identities
   that can later be attached to the corresponding services.
7. Record the resource IDs, region, SKU/capacity, diagnostic categories,
   identity principal IDs, network settings, and monthly cost estimate in
   the project inventory. Do not record secrets.

### IAM to configure and test

- Consumer identity: Event Hubs data-plane receive permission on the
  required namespace/event hub, plus the minimum checkpoint-storage
  permission if Blob checkpointing is used.
- Test emitter: Event Hubs send permission only if it publishes test
  events directly. Do not give the consumer send permission by default.
- API identity: Log Analytics query/read access only if the API queries
  the workspace, and Azure OpenAI invocation permission only when that
  integration is added.
- Deployment/operator identity: only the control-plane permissions needed
  to configure diagnostic settings, role assignments, and the resources
  in scope. Keep operator permissions distinct from runtime permissions.
- Configure and verify the required authorization for Azure Monitor to
  write to the selected Event Hubs destination. Follow the selected
  destination's supported authorization model; do not compensate for a
  failed diagnostic route by granting broad runtime permissions.

### Terraform alongside Portal work

- Create `infra/terraform/` with provider/version constraints, variables,
  outputs, naming/tags, and the resource definitions as each resource is
  created.
- Build the complete target stack as modules, with explicit daily profiles
  or feature switches so optional paid services can remain absent until
  needed.
- Create a Terraform resource inventory linking each Terraform address to
  its Azure resource ID and state status.
- Use the documented Terraform import workflow for resources already
  created in the Portal. Run `terraform plan` after each import and resolve
  differences before applying anything.
- Configure a protected remote backend in the existing `az-104` resource
  group, outside the disposable lab state. The backend storage is created
  once using Azure CLI; do not store state or backend credentials in the
  repository.
- At session end, review and destroy only the lab resources. Preserve the
  Terraform backend and verify that the next session can safely recreate
  the selected profile.

### Verify before stopping

- Portal shows all expected resources in the intended subscription,
  resource group, and region.
- The consumer identity can receive from the test event hub; the emitter
  can send only if direct test publishing is part of the lab. Verify with
  a minimal SDK/CLI smoke test or an approved test client.
- A test query can read the workspace (for example, a simple
  `AzureActivity | take 5`, if that table is populated and authorized).
- Terraform `fmt`, `validate`, and `plan` work; no unexplained create,
  replace, or destroy actions remain.

### Troubleshoot

- **Authorization fails:** identify whether it is Azure Resource Manager
  control-plane access or Event Hubs/Storage data-plane access; inspect
  the exact principal ID and scope, then allow for role assignment
  propagation.
- **Diagnostic destination is rejected:** verify resource/category support,
  namespace/hub selection, destination authorization, and region/service
  constraints. Record the actual error rather than broadening roles.
- **Terraform wants to replace a resource:** stop before apply; compare
  imported configuration with Portal properties and provider defaults.

**Exit gate:** Core Azure resources, tested identities, inventory, remote
state approach, daily profile, and a no-surprise create/destroy plan are
in place. Prove the lab can be removed without affecting the backend.

## Day 2 — Connect Azure Monitor, Log Analytics, and Event Hubs

**Today’s outcome:** Prove the exact telemetry route for one selected
resource and signal type. Do not treat the workspace as a universal
Event Hubs forwarder.

### Hands-on work

1. Pick one real source: the disposable web workload, an Azure platform
   resource, or a test Azure Monitor alert.
2. In the source resource's **Diagnostic settings**, enable the needed
   supported categories and route them to Log Analytics and Event Hubs
   where that source supports both destinations.
3. If the chosen data originates in a Log Analytics workspace table rather
   than a resource diagnostic category, verify a supported workspace
   export/data-collection path or use a scheduled-query alert/action route.
   Write down which path is actually used and any table/category limits.
4. Add the diagnostic settings and required role/configuration resources
   to Terraform. If they were created through Portal, import/reconcile
   them.
5. Send one harmless test request/action that creates a distinctive,
   searchable event. Avoid using production or personal data.
6. Query Log Analytics using the actual table/schema, filtering by a
   narrow time range, resource ID, and unique test marker.
7. Read from the Event Hub using the dedicated consumer group and record
   the received envelope, properties, partition, offset/sequence number,
   and timestamp. Redact payload fields before saving evidence.
8. Compare source, workspace, and Event Hubs counts/timestamps. Allow for
   documented ingestion latency; do not assume the destinations are
   synchronous.

### Verify and troubleshoot

- KQL returns the test marker in the expected table and time range.
- The Event Hubs consumer sees a corresponding event if the selected route
  supports that category.
- If Log Analytics receives data but Event Hubs does not, check the
  category-to-destination route and Event Hubs authorization—not the
  Python worker yet.
- If neither receives data, verify the source is emitting, category is
  enabled, diagnostic setting is attached to the right resource, and
  ingestion has had time to complete.
- If an alert route is used, inspect alert evaluation state, action group
  delivery status, payload schema, and retries.

**Exit gate:** A real signal is evidenced in Log Analytics and the
appropriate Event Hubs route, or a precise service limitation/blocker and
the verified alternative path are documented.

## Day 3 — Generate and rehearse controlled incidents

**Today’s outcome:** Create repeatable telemetry patterns that will be
used to test detection, triage, and later remediation.

### Hands-on work

1. Add a small test workload or script with named scenarios:
   `normal`, `http_5xx_burst`, `latency_spike`, and `recovery`. Make the
   test duration/rate bounded and safe for the dev environment.
2. Emit structured logs with UTC timestamp, service/environment, request
   or operation ID, outcome/status, duration, and a stable test-run ID.
   Do not place secrets or personal data in the log.
3. Run each scenario and verify its records in Log Analytics with KQL.
   Save the queries and expected event volume.
4. Create one Azure Monitor alert for a practical symptom (for example,
   failed-request count or latency above a test threshold) and connect its
   action group to the selected notification/ingestion path.
5. Trigger the alert deliberately, verify its fired/resolved lifecycle,
   and inspect the real payload. Repeat once to learn duplicate/repeat
   behavior.
6. Add the workload, diagnostic settings, alert rule, action group, and
   related permissions to Terraform incrementally.

### Troubleshoot

- **No logs:** confirm instrumentation/diagnostic category and the
  destination table; distinguish application logs from platform/resource
  logs.
- **Alert never fires:** inspect metric/log query, aggregation window,
  evaluation frequency, dimensions, threshold, and alert state.
- **Alert fires repeatedly:** inspect auto-mitigation, stateful behavior,
  dimensions, suppression/action rules, and notification delivery.
- **Unexpected schema:** capture a redacted real payload and update the
  event contract from evidence instead of guessing.

**Exit gate:** Every scenario has reproducible steps, a KQL query, and
known expected signal/alert behavior.

## Day 4 — Build the real Event Hubs consumer

**Today’s outcome:** The independent Python worker consumes the Day 2/3
Azure event and persists it once, even when Event Hubs redelivers it.

### Hands-on work

1. Create the Python package, configuration, structured logging, typed
   event envelope, and consumer entry point. Keep it separate from the
   FastAPI process.
2. Authenticate using `DefaultAzureCredential` locally and managed
   identity when hosted. Do not use connection strings in committed
   configuration.
3. Consume from the dedicated consumer group. Normalize the source
   payload to a versioned internal schema and UTC timestamps; retain
   safe source/resource IDs and event metadata.
4. Add PostgreSQL and migrations for the minimal event, anomaly, incident,
   and evidence-reference records. For local development, a local
   PostgreSQL instance may be used; add the Azure database when the
   approved hosting/networking/cost choices are ready.
5. Use a unique source event ID/fingerprint and database uniqueness
   constraint for idempotency. Commit the event before checkpointing.
6. Implement bounded retries, graceful shutdown, safe malformed-event
   handling, and checkpoint/consumer health logging.
7. Run the real generated signal through the worker. Restart the worker
   and replay/redeliver a test event; confirm one logical record exists.

### Troubleshoot

- **No events in worker:** compare consumer group, starting position,
  partition ownership, checkpoint location, Event Hubs lag, and identity.
- **Duplicate rows:** fix stable identity/fingerprint and database
  uniqueness; do not depend only on in-memory dedupe.
- **Event loss after crash:** verify commit-before-checkpoint ordering and
  test the crash window explicitly.
- **Poison event blocks a partition:** quarantine safe metadata and define
  whether/how the event is skipped; never log unrestricted raw payloads.

**Exit gate:** A real Event Hubs event becomes one persisted normalized
event, with a restart/redelivery test and useful lag/error diagnostics.

## Day 5 — Build FastAPI for live operations

**Today’s outcome:** An operator can inspect health and follow the event
into a persisted incident using a working API.

### Implement

- `GET /health`: process liveness only.
- `GET /ready`: dependency readiness for the API (database, required
  configuration); do not report the worker healthy from the API process.
- `GET /incidents` and `GET /incidents/{incident_id}` with pagination,
  filters, and evidence/event references.
- `GET /events` for restricted operational debugging, with redaction and
  bounded response sizes.
- `POST /test-scenarios/{scenario}` only in dev mode, to invoke the
  bounded signal generator; ensure it cannot be enabled in production.
- OpenAPI docs and a consistent error schema; validate configuration at
  startup and fail clearly on missing required settings.

### Hands-on validation

1. Start the API and consumer as separate processes.
2. Run `pytest` for route, validation, authorization, and database failure
   paths.
3. Trigger a test scenario and use the API to retrieve its persisted
   event/incident.
4. Check API logs and health responses while stopping/restarting the
   database and worker; confirm liveness and readiness differ correctly.
5. Add API and database configuration/deployment resources to Terraform
   only after selecting a hosting/network path; avoid exposing a database
   publicly for convenience.

**Exit gate:** The API serves real persisted records, and its readiness
and error behavior reflect actual dependency state.

## Day 6 — Add AI-assisted root-cause triage

**Today’s outcome:** The API produces a useful triage packet from actual
incident evidence without allowing the model to invent facts or execute
actions.

### Hands-on work

1. Provision/configure an Azure OpenAI resource and model deployment only
   after verifying regional availability, quota, access approval, and
   expected cost. Add the API managed identity's least-privilege inference
   role and verify it.
2. Build an evidence collector that fetches a bounded time window of
   relevant Log Analytics records and joins it with normalized events,
   incident links, and (if available) recent deployment/change metadata.
3. Query Log Analytics with parameterized time/resource filters and
   explicit row/byte limits. Redact secrets and exclude unnecessary raw
   fields before sending context to the model.
4. Implement `POST /incidents/{incident_id}/triage`. The request gathers
   evidence, calls Azure OpenAI with a bounded timeout, validates a
   structured response, and stores model/deployment/prompt version,
   evidence references, latency, and result status.
5. Require the model response to separate observed facts from hypotheses,
   state missing evidence/uncertainty, list impact and verification
   checks, and identify no action or a fixed allowlisted action ID.
6. Display the result via `GET /incidents/{incident_id}` or a dedicated
   triage endpoint.

### Test and troubleshoot

- Test a known failure with enough evidence, an incident with insufficient
  evidence, malformed model output, timeout, throttling, and model
  unavailability.
- Put prompt-injection-like instructions in a synthetic log message;
  confirm it is treated as data and cannot alter policy or invoke tools.
- If the model claims a cause without matching evidence references, fail
  validation or label the statement as an unverified hypothesis.
- If no Azure OpenAI quota/access is available, complete the provider
  interface and tests, record the blocker, and do not label a stub response
  as a live Azure OpenAI result.

**Exit gate:** One real incident has a schema-valid, evidence-linked AI
triage response; uncertainty and dependency failures are handled honestly.

## Day 7 — Correlate signals into incidents

**Today’s outcome:** A burst of repeated/related alerts becomes one
understandable incident with a defensible timeline.

### Hands-on work

1. Implement deterministic correlation on stable resource/service,
   bounded event-time window, and configured environment/dependency hints.
2. Persist the correlation reason and event-to-incident links.
3. Deduplicate notifications using stable source IDs/fingerprints.
4. Define open, acknowledged, resolved, and reopened lifecycle behavior;
   handle late-arriving events explicitly.
5. Add a timeline endpoint/view showing initial event, correlated evidence,
   anomaly rule/reason, alert transitions, AI triage, and human decisions.
6. Re-run Day 3 scenarios: repeated 5xx, latency spike, unrelated service
   spike, late event, and recovery.

### Troubleshoot

- **Over-correlation:** inspect resource IDs, time window, environment,
  service mapping, and dependency hints.
- **Under-correlation:** inspect missing dimensions, resource ID
  normalization, clock skew, and notification dedupe key.
- **Incident never resolves/reopens incorrectly:** inspect quiet period,
  recovery signal semantics, and late-event policy.

**Exit gate:** The documented scenario set yields expected incident groups
and lifecycle transitions; each group has a human-readable reason.

## Day 8 — Add one guarded remediation path

**Today’s outcome:** Either one reversible dev-only action is safely
executed and verified, or the action remains disabled with the exact
missing controls documented.

### Hands-on work

1. Choose a low-impact action on the disposable workload, such as
   restarting a test process or scaling a dev-only component within a
   fixed bound. Do not target production or allow arbitrary parameters.
2. Define a versioned action ID and fixed workflow (Logic App, Automation
   Runbook, or other approved mechanism). The model may recommend an ID;
   deterministic application policy decides eligibility.
3. Add authorization, preconditions, human approval, idempotency key,
   cooldown, timeout, bounded retries, and audit records.
4. Invoke only the fixed workflow. Never pass model-generated commands,
   scripts, URLs, or resource IDs into an execution shell.
5. Verify outcome independently through workload health/telemetry; record
   success only when the check passes.
6. Test unauthorized request, no approval, duplicate request, action
   timeout, workflow failure, and failed health verification.

**Exit gate:** The approved dev action is auditable and independently
verified, or it remains disabled and is reported as an explicit gap.

## Day 9 — Deploy the services and build the operations view

**Today’s outcome:** API and worker are separately deployed with their
own health, identity, and scaling behavior; an operator can see what the
system is doing.

### Hands-on work

1. Choose the API and long-running worker hosting target based on the
   actual workload, restart semantics, identity support, networking, and
   cost. Do not assume a web API host reliably runs an independent
   background consumer.
2. Deploy API and worker separately. Attach the correct managed
   identities, configure secrets only through approved secret management,
   and keep database/Event Hubs access private or restricted as practical.
3. Add structured logs and operational counters for consumer state,
   event lag, processed/duplicate/invalid counts, DB failures, triage
   latency/errors, and remediation outcomes. Never log tokens or full
   sensitive payloads.
4. Define one SLI/SLO from a documented numerator, denominator, time
   window, and missing-data policy.
5. Build the first dashboard using the chosen supported data source
   (Azure Managed Grafana if approved/budgeted): incidents by status,
   ingestion lag/errors, anomaly counts, triage latency, and remediation
   outcomes. Label synthetic lab data.
6. Verify dashboard queries against KQL/SQL/API results and verify
   Entra ID access boundaries.

### Troubleshoot

- **Worker stops after deployment:** inspect hosting process model,
  health/restart policy, scale-to-zero settings, startup command, and
  identity attachment.
- **Managed identity works locally but not hosted:** inspect the actual
  attached identity/client ID, role scope, role propagation, and
  credential selection.
- **Dashboard differs from API/KQL:** inspect time zones, aggregation
  windows, duplicate handling, filters, and missing-data policy.

**Exit gate:** Independently deployed API and worker stay healthy through
a restart; dashboard values match their source queries.

## Day 10 — Run the SRE game day and prepare the handoff

**Today’s outcome:** Complete a full failure-to-triage drill, test recovery,
and leave another engineer able to deploy and clean up the project.

### Game-day sequence

1. Start from the documented deployment state and check Terraform plan.
2. Confirm health/readiness for API, worker, Event Hubs, database, and
   telemetry source.
3. Run normal traffic, then the controlled error/latency scenario.
4. Follow one test-run ID across source logs, Log Analytics, Event Hubs,
   consumer logs, database rows, API incident, AI evidence references,
   and dashboard.
5. If enabled, request approval for the safe remediation and verify
   workload recovery independently.
6. Inject at least two failures: stop the worker, interrupt database
   access, or make the model unavailable. Verify detection, bounded retry,
   no duplicate incident/action, and recovery after restoring service.
7. Record measured detection/processing/triage times with test window,
   query, and limitations. Do not claim MTTR reduction from a single
   synthetic drill.
8. Follow teardown instructions; verify billable resources are stopped or
   removed as intended.

### Handoff checklist

- Terraform code and variables cover all project resources; include the
  one-time Azure CLI backend setup and imports for resources first created
  in the Portal.
- Document prerequisites, IAM roles/scopes, Terraform init/plan/apply,
  application startup/deployment, signal generation, KQL queries, API
  examples, dashboard access, troubleshooting, and cleanup.
- Keep secret values, Terraform state, and sensitive plan output out of
  the repository.
- State which integrations were actually deployed and tested, which were
  unit-tested only, and which remain blocked.
- Capture a redacted architecture diagram and screenshots/log excerpts as
  evidence; never use real customer/production data.

**Exit gate:** Another engineer can follow the guide to reproduce the
dev-lab flow without undocumented Portal clicks, and every project claim
is backed by observed evidence or labeled as a gap. The guide includes
the one-time backend setup, daily profile apply/destroy, and post-destroy
cost checks.

## Final incident drill acceptance

- [ ] Controlled workload scenarios produce searchable telemetry.
- [ ] The selected real telemetry route to Log Analytics and Event Hubs is
      verified and documented.
- [ ] Runtime identities have only the documented permissions needed.
- [ ] Worker restart/redelivery does not create duplicate logical events.
- [ ] FastAPI exposes health/readiness and persisted incidents correctly.
- [ ] Correlation is deterministic and has a stored reason.
- [ ] AI triage is evidence-grounded, schema-validated, uncertainty-aware,
      and cannot execute actions.
- [ ] Remediation is gated, allowlisted, audited, and independently
      verified—or explicitly disabled.
- [ ] Dashboard values agree with their source queries.
- [ ] Terraform, deployment, troubleshooting, and teardown instructions
      are complete and safe to follow.
