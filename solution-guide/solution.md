# Facilitator Solution Guide

## Scope and grading guardrails

Expected state for the six challenges in **Secure Your Azure Workloads with Microsoft Defender for Cloud**:

- Workload resource group: `asclab`; region: `eastus`. `lab-vm` contains only the CloudLabs access VM.
- The ARM deployment owns the workload, identities, permissions, fixed container image, and pre-session Defender configuration. Learners do not recreate or bootstrap these resources.
- Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, and Defender for Endpoint integration were enabled and assessed before the session.
- Grade resource/configuration state, recommendation state, alert presence, and evidence. Never require Secure Score movement, a Secure Score delta, or disappearance of an attack path.
- For Challenge 6, grade the attack-path recommendation's remediation state only.

Pinned values include VMs `asclab-win`, `asclab-win2`, and `asclab-linux`; ACR `asclabcr*`; AKS `asclab-aks`; image `contoso-vulnerable/aspnet-core:2.1`; custom standard `Contoso Secure Workload Baseline`; policy definition `2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`; JIT maximum `PT3H`, source `Any`, and learner request `PT15M`; Logic App `la-contoso-defender-recommendations`; and workflow rule `war-contoso-high-severity-recommendations`.

The Logic App must use the supported Microsoft Defender for Cloud recommendation trigger **When a Microsoft Defender for Cloud recommendation is created or triggered**. It must have exactly one `Compose` action containing the incoming recommendation payload. The MCSB CSV is learner/facilitator evidence only; it is not validator-observable and is not a strict validator condition.

Portal state is primary. The commands below are facilitator verification aids.

## Cost defaults and end-of-lab teardown

The ARM-owned footprint intentionally remains available for the lab: `Standard_B2als_v2` is retained for the CloudLabs jump box and all three workload VMs, and `Standard_B2as_v2` for the AKS agent pool; `Standard_LRS` is retained for managed OS disks and the storage account. No auto-shutdown schedule is deployed. The expected maximum runtime is 8 hours. **The author/facilitator, not the learner, owns cleanup immediately after the session and must not wait for browser CSV download state.** Preserve the AKS cluster and imported vulnerable image until all required evidence and validation are complete.

Use the correct subscription context and delete the workload resource group after the lab:

```azurecli
az group delete --name asclab --yes --no-wait
```

Resource-group deletion is the primary teardown for the ARM-owned workload. It removes `asclab-aks` and its node resources, the `asclab-win`, `asclab-win2`, and `asclab-linux` VMs, managed disks, SQL server/database, Basic ACR and imported image, storage account, Key Vault, NICs, public IP addresses, NSGs, and virtual network. Confirm the resource group is gone:

```azurecli
az group exists --name asclab
```

The facilitator must also remove the learner-created Logic App `la-contoso-defender-recommendations` and workflow automation rule `war-contoso-high-severity-recommendations` wherever they were created outside `asclab`. Review subscription-level Microsoft Defender for Cloud pricing and disable paid plans after teardown. Azure CLI uses `az security pricing create` with the pricing name and `--tier Free`; apply it to the plans that are present, typically:

```azurecli
for plan in CloudPosture VirtualMachines StorageAccounts KeyVaults SqlServers Containers; do
  az security pricing create --name "$plan" --tier Free
done
```

If the jump-box access aid is no longer needed, separately delete `lab-vm` after the session; do not remove it while learners still need access. Final facilitator verification must confirm no `asclab*` resources, public networking resources, AKS node resources, SQL, ACR, or paid Defender plans remain. This teardown is an operational cost-control action, not a learner exercise, and no validator grades it.

### Provisioning and readiness

Confirm the ARM deployment and CSE completed in `eastus` before the session. Check the workload rather than asking learners to recreate resources. Allow for eventual consistency between ARM completion, managed-identity role assignment, ACR import, AKS readiness, Defender ingestion, and recommendation refresh.

```powershell
Get-AzResourceGroup -Name asclab
Get-AzVM -ResourceGroupName asclab | Select-Object Name,Location,ResourceGroupName
Get-AzContainerRegistry -ResourceGroupName asclab | Where-Object Name -like 'asclabcr*' | Select-Object Name,Location,Sku
Get-AzAksCluster -ResourceGroupName asclab -Name asclab-aks | Select-Object Name,Location,ProvisioningState,PowerState
az acr repository show --name <ACR_NAME> --image contoso-vulnerable/aspnet-core:2.1 --query name -o tsv
az aks show --resource-group asclab --name asclab-aks --query "{provisioningState:provisioningState,identity:identity.type}" -o json
```

The jump box is an access aid only. The bootstrap may perform registry-side `az acr import` readiness work; no Docker build, registry credential, connector, or manual recreation is expected.

---

## Challenge 1 — Onboard and baseline

Validation: `validate-challenge-01`.

### Task 1: Confirm subscription and inventory

**Expected:** The assigned subscription is selected; `asclab` workload resources are distinguished from the access VM in `lab-vm`; Defender for Cloud overview and inventory are open.

**Full credit:** Subscription, both resource groups, and principal workload resources are identified without changing posture. **Partial:** correct subscription and overview, but resource-group separation or inventory is incomplete. **Pitfalls:** wrong subscription; looking only at `lab-vm`; confusing resource suffixes; creating resources before checking ARM deployment state.

### Task 2: Record baseline observations

**Expected:** Notes contain current Secure Score, control breakdown, unhealthy-resource count, recommendation counts by severity, timestamp/subscription context, and the 48-hour assessment context. These are observations, not targets.

**Full credit:** All observations and context are recorded without remediation merely to move Secure Score. **Partial:** one measurement or the 48-hour context is missing. **Pitfalls:** treating delayed recalculation as failure; counting `lab-vm`; expecting newly enabled plans to have immediate findings.

### Task 3: Confirm preconfigured Defender capabilities

**Expected:** Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, and Defender for Endpoint integration are enabled and not unnecessarily reconfigured.

**Full credit:** All four are confirmed. **Partial:** three are confirmed, or agentless scanning is confused with agent installation. **Pitfalls:** wrong subscription; checking only VM extensions; attempting cold enablement.

```powershell
Get-AzSecurityPricing | Select-Object Name,PricingTier
Get-AzSecuritySetting | Select-Object Name,Enabled
az security pricing list --query "[].{name:name,tier:pricingTier}" -o table
az security setting list -o table
```

The validator requires CSPM, Servers Plan 2, and agentless scanning. It does not evaluate notes or Secure Score.

---

## Challenge 2 — Strengthen posture

Validation: `validate-challenge-02`.

### Task 1: Remediate storage settings

**Expected:** The `asclabsa*` account has public network access disabled, minimum TLS `TLS1_2`, and HTTPS-only/secure transfer enabled. The anonymous container and synthetic records may remain as deployment evidence.

**Full credit:** All three properties are observable on the workload account. **Partial:** two properties are correct or another account was changed. **Pitfalls:** changing anonymous blob access instead of public network access; selecting `TLS1_0`/`TLS1_1`; waiting for Secure Score.

### Task 2: Close SQL and enable Key Vault soft delete

**Expected:** The authoritative graded SQL state is `publicNetworkAccess=Disabled` on the `asclab-sql*` server, and the `asclab-kv*` vault has soft delete enabled. If the `publicNetworkAccess` control is unavailable in the learner's portal/API surface, closing/removing the internet-open SQL firewall rule is the conditional fallback; it is not the authoritative graded state when the property is available.

**Full credit:** SQL `publicNetworkAccess` is `Disabled` and Key Vault soft delete is enabled. **Partial:** only one authoritative remediation is complete; or, only where the control is unavailable, the learner documents removal of the all-internet firewall rule and completes soft-delete remediation. **Pitfalls:** grading firewall-rule removal instead of `publicNetworkAccess`; changing only one test IP; checking the database rather than server; attempting to disable soft delete; soft-deleted Key Vault names blocking re-creation.

### Task 3: Create the custom standard

**Expected:** Exactly one `Contoso Secure Workload Baseline` custom standard exists with exactly one built-in policy: **Storage accounts should restrict network access using virtual network rules**, definition ID `2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`.

**Full credit:** Name, policy count, display name, and definition ID match and the saved standard is visible beside MCSB. **Partial:** correct standard/policy with extra policies, wrong name, or unsaved draft. **Pitfalls:** creating a policy assignment instead of a Defender custom standard; adding MCSB; selecting a similarly named initiative; creating duplicates after portal save delay.

### Task 4: Verify state

**Expected:** The five prescribed remediations and exact one-policy standard are visible. Recommendation freshness and Secure Score recalculation are not grading criteria.

```powershell
$sa = Get-AzStorageAccount -ResourceGroupName asclab | Where-Object Name -like 'asclabsa*' | Select-Object -First 1
$sa.EnableHttpsTrafficOnly; $sa.MinimumTlsVersion; $sa.PublicNetworkAccess
$sql = Get-AzSqlServer -ResourceGroupName asclab | Where-Object ServerName -like 'asclab-sql*' | Select-Object -First 1
Get-AzSqlServer -ResourceGroupName asclab -ServerName $sql.ServerName | Select-Object ServerName,PublicNetworkAccess
# Conditional fallback only when publicNetworkAccess is unavailable:
Get-AzSqlServerFirewallRule -ResourceGroupName asclab -ServerName $sql.ServerName
$kv = Get-AzKeyVault -ResourceGroupName asclab | Where-Object VaultName -like 'asclab-kv*' | Select-Object -First 1
$kv | Select-Object VaultName,EnableSoftDelete,PublicNetworkAccess
az policy definition show --name 2a1a9cdf-e04d-429a-8416-3bfb72a1b26f --query "{name:displayName,id:id}" -o json
```

The validator checks storage public access disabled, `TLS1_2`, HTTPS-only, authoritative SQL `publicNetworkAccess=Disabled`, and exactly the named one-policy standard. Firewall-rule closure is a conditional compatibility fallback only where that SQL control is unavailable.

---

## Challenge 3 — Protect workloads

Validation: `validate-challenge-03`.

### Task 1: Enable three Defender plans

**Expected:** Defender for Storage, Defender for Key Vault, and Defender for SQL are enabled at subscription scope; CSPM and Servers remain unchanged.

**Full credit:** All three subscription plan toggles are enabled. **Partial:** one or two are enabled or a plan is enabled at an unintended resource scope. **Pitfalls:** wrong subscription; confusing plan state with a recommendation; changing Containers here; expecting immediate findings.

### Task 2: Create and triage sample alerts

**Expected:** Security alerts > Sample alerts contains one subscription sample alert for each exact type: `Storage.Blob_OpenACL.Sensitive`, `KV_UnusualAccessSuspiciousIP`, and `SQL.DB_PotentialSqlInjection`. Each is opened/triaged with MITRE mapping, affected resource, and recommended remediation recorded.

**Full credit:** All three exact strings are present and triaged, with simulated resources distinguished from `asclabsa*`. **Partial:** strings exist but only one or two are triaged or the distinction is missing. **Pitfalls:** searching live alerts instead of Sample alerts; expecting simulated resources to name `asclabsa*`; using similar wording; filtering to a resource instead of subscription.

```powershell
az security pricing list --query "[?contains(name,'Storage') || contains(name,'KeyVault') || contains(name,'Sql')].{name:name,tier:pricingTier}" -o table
az security alert list --subscription (Get-AzContext).Subscription.Id -o json
```

The validator requires the three plans and all three exact strings.

---

## Challenge 4 — Secure containers

Validation: `validate-challenge-04`.

### Task 1: Enable Defender for Containers

**Expected:** Defender for Containers is enabled and container inventory/vulnerability findings are opened. No DevOps or GitHub organization is connected.

**Full credit:** Plan enabled and findings reviewed. **Partial:** plan enabled but an unnecessary connector is created; this earns no additional credit. **Pitfalls:** enabling only registry scanning; wrong subscription; trying to import/build a replacement image; waiting for a new scan when the fixed image was assessed.

### Task 2: Inspect the fixed ACR image

**Expected:** Findings identify `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core:2.1`, the highest-severity CVE shown in the tenant, and lineage to `mcr.microsoft.com/dotnet/core/aspnet:2.1`.

**Full credit:** Vulnerability details, highest displayed CVE, base-image lineage, and end-of-support/CVE exposure are explained without inventing an undisplayed CVE. **Partial:** repository/tag and findings are correct but lineage or detail inspection is absent. **Pitfalls:** looking at `latest`; confusing MCR source with ACR destination; using a newly built image; creating registry credentials.

### Task 3: Confirm AKS runtime linkage

**Expected:** `asclab-aks` runs the identical repository and tag `contoso-vulnerable/aspnet-core:2.1`.

**Full credit:** ACR finding and AKS deployment/pod image reference match exactly. **Partial:** ACR is correct but runtime linkage is not demonstrated or tag is omitted. **Pitfalls:** checking only repository; ignoring tag; changing the deployment before inspection.

```powershell
$acr = (Get-AzContainerRegistry -ResourceGroupName asclab | Where-Object Name -like 'asclabcr*' | Select-Object -First 1).Name
az acr repository show-tags --name $acr --repository contoso-vulnerable/aspnet-core -o table
az acr repository show-manifests --name $acr --repository contoso-vulnerable/aspnet-core -o table
az aks get-credentials --resource-group asclab --name asclab-aks --overwrite-existing
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"/"}{.metadata.name}{" "}{.spec.containers[*].image}{"\n"}{end}'
```

The validator checks Defender for Containers and findings for this repository/tag in the `asclabcr*` registry.

---

## Challenge 5 — Harden VM access

Validation: `validate-challenge-05`.

### Task 1: Configure JIT for both VMs

**Expected:** JIT covers `asclab-win` TCP 3389 and `asclab-linux` TCP 22. Both ports have maximum duration literal `PT3H` and source `Any`.

**Full credit:** Both VMs and ports have exact values. **Partial:** one VM/port is correct or a semantically similar non-pinned value is stored. **Pitfalls:** configuring `asclab-win2`; swapping ports; choosing “My IP”; using a human-readable duration; confusing JIT with a permanent NSG rule.

### Task 2: Configure and verify a bounded request

**Expected:** A learner request opens the correct port for exactly `PT15M`; the temporary rule is observable while active and removed/closed after expiry or release.

**Full credit:** Correct VM/port, exact `PT15M`, and open plus closed/expired behavior are verified. **Partial:** policy exists but only the request is shown. **Pitfalls:** requesting `PT3H`; inspecting the base NSG rather than temporary rule; expecting immediate closure.

### Task 3: Interpret agentless machine scanning

**Expected:** Pre-existing findings for software, vulnerabilities, and secrets on disk are reviewed in VM context. No cold enablement or agent installation is attempted.

**Full credit:** Findings are categorized with affected VM context. **Partial:** findings are opened but not categorized. **Pitfalls:** treating one absent finding as proof scanning is disabled; installing an agent; confusing agentless scanning with Endpoint integration.

```powershell
Get-AzJitNetworkAccessPolicy -ResourceGroupName asclab | Select-Object Name,VirtualMachines
az security jit-policy list -o json
```

The validator checks both VMs, ports 3389/22, maximum `PT3H`, and source `Any`; it does not grade temporary rules or notes.

---

## Challenge 6 — Automate and prove

Validation: `validate-challenge-06`.

### Task 1: Create the Logic App

**Expected:** `la-contoso-defender-recommendations` uses the exact supported Microsoft Defender for Cloud recommendation trigger **When a Microsoft Defender for Cloud recommendation is created or triggered** and has exactly one action, `Compose`, whose input contains the incoming recommendation payload.

**Full credit:** Name, supported trigger display name/type, one-action count, Compose action, and recommendation-payload mapping match. **Partial:** supported trigger exists but an extra action exists, or Compose lacks the payload. **Pitfalls:** recurrence or alert trigger; using an HTTP trigger; searching for an unsupported or nonexistent Defender-specific trigger; email/notification/approval actions; starter templates adding actions; wrong Logic App name or resource group.

### Task 2: Create the workflow automation rule

**Expected:** `war-contoso-high-severity-recommendations` is enabled, filters high severity, applies to recommendations only, and targets `la-contoso-defender-recommendations`.

**Full credit:** Name, enabled state, severity, recommendation-only restriction, and Logic App target are exact. **Partial:** correct target but disabled, or alerts are also selected. **Pitfalls:** selecting all events or Security alerts; confusing recommendation and alert severity; incorrect Logic App resource ID; saving before the connector trigger is available.

### Task 3: Trace and remediate the attack-path recommendation

**Expected:** Trace the pre-existing relationship from an internet-exposed VM through its over-permissioned system-assigned identity to the public storage account containing synthetic sensitive records. Remediate the recommendation that breaks the path; the attack-path recommendation is **Healthy**.

**Full credit:** Relationship, remediation, and healthy recommendation state are evidenced. **Partial:** identity or storage relationship is identified but remediation/state evidence is incomplete. **Pitfalls:** removing a VM or synthetic data; confusing `asclab-win` and `asclab-win2`; expecting graph disappearance; waiting for Secure Score movement.

After remediation, allow ARM/RBAC propagation, Defender assessment, and attack-path recomputation. Refresh and poll again; do not undo correct remediation or alter topology to force graph disappearance. The validator retries transient API failures but does not turn eventual-consistency delay into credit.

### Task 4: Export MCSB compliance evidence

**Expected:** The default-applied Microsoft cloud security benchmark (MCSB) is selected and a compliance report is downloaded as CSV.

**Full credit:** Facilitator-held evidence identifies MCSB and CSV; MCSB is not added as a custom standard. **Partial:** MCSB is selected and a report is generated but format is not evidenced. **Pitfalls:** exporting PDF/JSON; selecting `Contoso Secure Workload Baseline`; confusing dashboard display with downloaded evidence; tenant-specific export controls.

CSV is learner/facilitator evidence only. The external validator cannot inspect a learner workstation or download folder and does not grade CSV unless a separate Azure-side export record is exposed; no such record is a required Challenge 6 state.

```powershell
$sub = (Get-AzContext).Subscription.Id
az resource list --subscription $sub --query "[?contains(name,'la-contoso-defender-recommendations') || contains(name,'war-contoso-high-severity-recommendations')]" -o table
az rest --method get --url "https://management.azure.com/subscriptions/$sub/providers/Microsoft.Security/automations?api-version=2019-01-01-preview" -o json
az rest --method get --url "https://management.azure.com/subscriptions/$sub/providers/Microsoft.Logic/workflows/la-contoso-defender-recommendations?api-version=2019-05-01" -o json
```

Inspect the automation JSON for enabled state, recommendation-only filtering, high severity, and Logic App target. Inspect the workflow definition/portal designer for the supported connector trigger display name and exactly one Compose action. Use Attack paths only to confirm recommendation health. Do not substitute Secure Score, a local-file check, or graph disappearance.

## Cross-challenge troubleshooting

- **Wrong region/subscription:** workload resources are in `eastus` and `asclab`; switch context before changing anything.
- **ARM/readiness:** verify deployment operations and provisioning state before redeploying. Do not rebuild the fixed image or recreate missing workload resources.
- **RBAC propagation:** Owner permissions, managed-identity role assignments, policy updates, and Defender settings can lag. Refresh and query directly.
- **Defender freshness:** pre-session capabilities/findings were assessed for 48 hours; newly enabled plan findings can lag. Sample alerts are immediate Challenge 3 evidence.
- **Storage throttling/SKU behavior:** do not repeatedly recreate or resize storage; inspect the existing `asclabsa*` account and wait for control-plane operations.
- **Soft-deleted resources:** a soft-deleted Key Vault name can block re-creation. Recover or purge only under instructor direction; the required action is enabling soft delete on the deployed vault.
- **Identity and permissions:** verify the Windows VM system-assigned identity before interpreting Challenge 6; do not replace it with a user-assigned identity.
- **JIT timing:** `PT3H` is the policy maximum and `PT15M` is the learner request. Temporary rules appear and expire asynchronously.
- **Logic App/Defender connector:** use the exact supported trigger **When a Microsoft Defender for Cloud recommendation is created or triggered**. Do not use an HTTP, alert, or recurrence trigger, or an extra Response/notification action. If the trigger is unavailable, confirm the correct connector, subscription, region, and permissions; do not substitute a generic trigger.
- **Recommendation timing:** ARM remediation, Defender assessment, attack-path recomputation, and validator reads are asynchronous. Recheck after propagation; never infer success from one stale portal blade.
- **Portal/API mismatch:** use portal state for grading and CLI/REST as corroboration. A downloaded CSV is facilitator evidence, not validator-observable state.

## Final grading summary

| Challenge | Full-credit state | Validation |
|---|---|---|
| 1 | Baseline observations and four preconfigured capabilities confirmed; no score target | `validate-challenge-01` |
| 2 | Storage settings, SQL `publicNetworkAccess=Disabled`, Key Vault soft delete, and exact one-policy named custom standard; MCSB remains visible | `validate-challenge-02` |
| 3 | Three plans enabled and exact three sample-alert strings present and triaged | `validate-challenge-03` |
| 4 | Containers enabled; fixed ACR findings, CVE/base-image lineage, and identical AKS image verified | `validate-challenge-04` |
| 5 | JIT on both required VMs/ports with `PT3H`, `Any`, and `PT15M`; agentless findings interpreted | `validate-challenge-05` |
| 6 | Exact Logic App connector trigger and single Compose action, recommendation-only high-severity rule, and healthy attack-path recommendation; MCSB CSV retained as facilitator evidence only | `validate-challenge-06` |

No full- or partial-credit decision is based on Secure Score movement, Secure Score delta, attack-path disappearance, or a learner's local CSV download. The Challenge 6 validator observes the Azure-side Logic App, automation rule, and recommendation state. Validation references are limited to `validate-challenge-01` through `validate-challenge-06`.
