# Facilitator Solution Guide

## Scope and grading guardrails

Expected state for the six challenges in **Secure Your Azure Workloads with Microsoft Defender for Cloud**:

- Lab resource group: the single CloudLabs-created group `ODL-DFC-<DeploymentID>`; region: whichever region CloudLabs deployed the group into. The jump box sits in it and contains only the CloudLabs access VM.
- The ARM deployment owns the workload, identities, permissions, fixed container image, and pre-session Defender configuration. Learners do not recreate or bootstrap these resources.
- Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, and Defender for Endpoint integration were enabled and assessed before the session.
- Grade resource/configuration state, recommendation state, alert presence, and evidence. Never require Secure Score movement or a Secure Score delta.
- For Challenge 6 Task 3, grade the storage account's `allowBlobPublicAccess` setting only. Do not grade attack path analysis; see the marker's note on that task.

Pinned values include VMs `asclab-win`, `asclab-win2`, and `asclab-linux`; ACR `asclabcr*`; AKS `asclab-aks`; image `contoso-vulnerable/aspnet-core:2.1`; custom standard `Contoso Secure Workload Baseline`; policy definition `2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`; JIT maximum `PT3H`, source `Any`, and a learner request of 1 hour (the portal slider offers 1-3 hours only); Logic App `la-contoso-defender-recommendations`; and workflow rule `war-contoso-high-severity-recommendations`.

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

The facilitator must also remove the learner-created Logic App `la-contoso-defender-recommendations` and workflow automation rule `war-contoso-high-severity-recommendations` wherever they were created outside the lab resource group. Review subscription-level Microsoft Defender for Cloud pricing and disable paid plans after teardown. Azure CLI uses `az security pricing create` with the pricing name and `--tier Free`; apply it to the plans that are present, typically:

```azurecli
for plan in CloudPosture VirtualMachines StorageAccounts KeyVaults SqlServers Containers; do
  az security pricing create --name "$plan" --tier Free
done
```

If the jump-box access aid is no longer needed, delete the whole lab resource group after the session, which removes the workload and the jump box together; do not remove it while learners still need access. Final facilitator verification must confirm no `asclab*` resources, public networking resources, AKS node resources, SQL, ACR, or paid Defender plans remain. This teardown is an operational cost-control action, not a learner exercise, and no validator grades it.

### Provisioning and readiness

Confirm the ARM deployment and CSE completed before the session. Check the workload rather than asking learners to recreate resources. Allow for eventual consistency between ARM completion, managed-identity role assignment, ACR import, AKS readiness, Defender ingestion, and recommendation refresh.

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

**Expected:** The assigned subscription is selected; `asclab-*` `asclab-*` workload resources are distinguished from the jump box; Defender for Cloud overview and inventory are open.

**Full credit:** Subscription, both resource groups, and principal workload resources are identified without changing posture. **Partial:** correct subscription and overview, but resource-group separation or inventory is incomplete. **Pitfalls:** wrong subscription; looking only at the jump box; confusing resource suffixes; creating resources before checking ARM deployment state.

### Task 2: Record baseline observations

**Expected:** Notes contain current Secure Score, control breakdown, unhealthy-resource count, recommendation counts by severity, timestamp/subscription context, and the 48-hour assessment context. These are observations, not targets.

**Full credit:** All observations and context are recorded without remediation merely to move Secure Score. **Partial:** one measurement or the 48-hour context is missing. **Pitfalls:** treating delayed recalculation as failure; counting the jump box; expecting newly enabled plans to have immediate findings.

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

### Task 2: Close public network access on SQL and the Key Vault

**Expected:** `publicNetworkAccess=Disabled` on the `asclab-sql*` server **and** no firewall rule starting at `0.0.0.0` (the lab ships `AllowAll`), plus `publicNetworkAccess=Disabled` on the `asclab-kv*` vault. Both SQL states are graded; the portal hides the firewall section once public access is disabled, so the rule must be removed first. If the `publicNetworkAccess` control is unavailable in the learner's portal/API surface, closing/removing the internet-open SQL firewall rule is the conditional fallback; it is not the authoritative graded state when the property is available.

**Full credit:** SQL `publicNetworkAccess` is `Disabled` with no `0.0.0.0` firewall rule, and Key Vault `publicNetworkAccess` is `Disabled`. **Partial:** only one of the three remediations is complete. **Pitfalls:** disabling SQL public access *before* deleting the `AllowAll` rule, after which the portal hides the firewall section and the rule can no longer be removed; missing the **Proceed** confirmation on the storage pane, which silently reverts the choice; checking the database rather than the server; expecting soft delete to be a learner action, when Azure enables it on every new vault and no longer permits disabling it.

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
$kv | Select-Object VaultName,PublicNetworkAccess
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

**Expected:** Security alerts > Sample alerts contains `SIMULATED_Storage.Blob_OpenACL`, `SIMULATED_SQL.DB_PotentialSqlInjection`, and at least one `SIMULATED_KV_*` alert (selecting the Key Vaults plan creates five). Defender prefixes every sample alert type with `SIMULATED_`. Each is opened/triaged with affected resource and recommended remediation recorded; MITRE intent is `Collection` for the Storage alert and `Unknown` for the other two, so do not require a tactic for those.

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

### Task 2: Inspect the registry image findings

**Expected:** The learner finds the per-package findings named **`Update <package>`** against repository `contoso-vulnerable/aspnet-core` in the `asclabcr*` registry, reached from **Recommendations** using the list's **Search by title / resource** box.

**Full credit:** The learner distinguishes the **Container image** rows (registry) from the **Container** rows (cluster), records the provenance `mcr.microsoft.com/dotnet/core/aspnet:2.1`, and records the finding count and risk levels. **Partial:** findings located but the two resource types are not distinguished. **Pitfalls:** searching the portal's global search bar instead of the list's own box; hunting for a roll-up recommendation; confusing MCR source with ACR destination; creating registry credentials.

> **Marker's note.** There is no recommendation called "Azure registry container images should have vulnerabilities resolved" or "Azure running container images should have vulnerabilities resolved" — verified absent from this subscription on 9 Oct 2026. Defender publishes one `Update <package>` recommendation per affected package instead. A learner who reports being unable to find the named recommendation has read an older guide, not made a mistake.
>
> The registry findings carry **no tag**. `mcr.microsoft.com/dotnet/core/aspnet:2.1` is a multi-architecture image, so the import produced a tagged manifest list plus untagged per-platform manifests; Defender scans the untagged manifests and addresses them by digest. A finding named **Update windows_10** is expected and comes from the Windows images in that manifest list. Do not expect, or award credit for, a tag on a registry-side finding.

### Task 3: Record the CVE evidence

**Expected:** CVE identifier, CVSS score, affected package and fix version, taken from **Take action > Associated CVEs** on a **Container image** finding.

**Full credit:** The learner reaches the Associated CVEs tab, records the four values, and explains why the recommendation's **Risk level** and the CVE's **CVSS** differ. **Partial:** finding opened but CVE evidence not retrieved from the Associated CVEs tab. **Pitfalls:** expecting CVE data on the finding's first pane; searching the portal for an "introducing base image", which Defender does not report for this workload.

> **Marker's note.** Accept whatever CVE list the learner sees; the feed changes. In testing on 9 Oct 2026, `Update microsoft.aspnetcore.server.kestrel.core` listed CVE-2025-55315, CVSS 9.9, fix version 2.3.6, source MDVM, while the recommendation's own risk level read Medium.

### Task 4: Confirm AKS runtime linkage

**Expected:** The learner shows that the packages reported against the **Container image** (registry) are also reported against the **Container** running in `asclab-aks`, and takes the tag `2.1` and its digest from the ACR **Repositories** blade.

**Full credit:** Package overlap between the two resource types is demonstrated, and registry, repository, tag, digest and cluster are recorded. **Partial:** registry side correct but the runtime comparison is not made. **Pitfalls:** expecting the recommendation pane to print the cluster, registry, tag or digest — it shows only the short resource name `aspnet-core`; expecting the registry and runtime findings to share a digest.

> **Marker's note.** The registry and runtime scans target **different digests of the same repository**: the runtime finding is on the digest the tag `2.1` points to, the registry findings are on the untagged per-platform manifests. Do not require matching digests. The linkage to credit is the shared package set — 12 of 14 packages in testing. Runtime findings depend on the Defender sensor and appear later than the registry ones; `validate-challenge-04` deliberately does not gate on them.

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

**Expected:** A learner request opens the correct port for 1 hour; a temporary allow rule appears at priority `100` above Defender's own deny at `1000` and the lab's original `AllowRdp`/`AllowSsh` rule, and is removed after expiry or release.

**Full credit:** Correct VM/port, a bounded request, and open plus closed/expired behaviour are verified. **Partial:** policy exists but only the request is shown. **Pitfalls:** choosing **My IP** on an IPv6 connection, which JIT rejects outright - use **IP Range** `0.0.0.0/0`; looking for an "Any" source button, which the request pane does not have; expecting to select minutes, when the slider is in whole hours.

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

### Task 3: Trace and close the exposure of the sensitive data

**Expected:** The learner uses Defender CSPM risk analysis — the **Risk factors** filter, a recommendation's **Risk level**, **Tactics & techniques** and the **Take action > Graph** tab — to trace how the workload exposes the storage account holding the synthetic records, then disables **Allow Blob anonymous access** on the `asclabsa*` storage account.

**Full credit:** The exposure chain is recorded (internet-reachable `asclab-win`, its system-assigned identity holding **Storage Blob Data Contributor**, the `asclabsa*` account, the container holding `customer-records.json`, and anonymous blob access) **and** anonymous blob access is Disabled. **Partial:** the chain is traced but the setting is not changed. **Pitfalls:** assuming Challenge 2 already closed this — Challenge 2 disables the account's *network* access, which is a different setting; removing a VM or the synthetic data; confusing `asclab-win` and `asclab-win2`; waiting for Secure Score movement.

> **Marker's note — this task was redesigned on 10 Oct 2026 and the reason matters.**
>
> It previously required a **healthy attack-path recommendation**, and it was never passable. Attack path analysis is produced by the cloud security graph roughly 48 hours after **Defender CSPM is enabled**, not 48 hours after the lab deploys. On the test deployment CSPM was enabled 2026-10-08 12:41 UTC, so the window opened 2026-10-10 12:41 UTC — and the environment expired about nine hours before that. Attack paths read 0 at every check, in Resource Graph and in the portal blade ("No attack paths found").
>
> Because the learner enables CSPM *during* the lab, that clock starts when they start, and the lab is 7h35m. No learner working in order can ever reach an attack path. Defender has also narrowed attack paths to "only the most urgent, externally sourced threats", so the intended internet-exposed-VM-to-public-storage path may never be produced at all. It has not been observed on any of the three deployments tested.
>
> The replacement grades `allowBlobPublicAccess` on the storage account, which takes effect immediately and does not depend on Defender assessment timing. The investigation half still uses the cloud security graph — risk factors, MITRE mapping and the Graph tab were all populated and working throughout testing — so the tracing skill is preserved. **Do not re-introduce an attack-path requirement without first proving one appears in this lab.**
>
> Accept a learner who reports no anonymous-access recommendation listed in Defender; the guide tells them to continue, and the graded state is the storage setting, not Defender's view of it.

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

Inspect the automation JSON for enabled state, recommendation-only filtering, high severity, and Logic App target. Inspect the workflow definition/portal designer for the supported connector trigger display name and exactly one Compose action. Read `allowBlobPublicAccess` on the `asclabsa*` account for Task 3. Do not substitute Secure Score or a local-file check, and do not reinstate an attack-path requirement.

## Cross-challenge troubleshooting

- **Wrong region/subscription:** workload resources are all in the lab resource group, in whichever region it was deployed to; switch context before changing anything.
- **ARM/readiness:** verify deployment operations and provisioning state before redeploying. Do not rebuild the fixed image or recreate missing workload resources.
- **RBAC propagation:** Owner permissions, managed-identity role assignments, policy updates, and Defender settings can lag. Refresh and query directly.
- **Defender freshness:** pre-session capabilities/findings were assessed for 48 hours; newly enabled plan findings can lag. Sample alerts are immediate Challenge 3 evidence.
- **Storage throttling/SKU behavior:** do not repeatedly recreate or resize storage; inspect the existing `asclabsa*` account and wait for control-plane operations.
- **Soft-deleted resources:** a soft-deleted Key Vault name can block re-creation. Recover or purge only under instructor direction; the required action is enabling soft delete on the deployed vault.
- **Identity and permissions:** verify the Windows VM system-assigned identity before interpreting Challenge 6; do not replace it with a user-assigned identity.
- **JIT timing:** `PT3H` is the policy maximum, which the validator checks; the learner request is a separate 1-3 hour window chosen on a slider. Temporary rules appear and expire asynchronously.
- **Logic App/Defender connector:** use the exact supported trigger **When a Microsoft Defender for Cloud recommendation is created or triggered**. Do not use an HTTP, alert, or recurrence trigger, or an extra Response/notification action. If the trigger is unavailable, confirm the correct connector, subscription, region, and permissions; do not substitute a generic trigger.
- **Recommendation timing:** ARM remediation, Defender assessment, and validator reads are asynchronous. Recheck after propagation; never infer success from one stale portal blade. Note that Challenge 6 Task 3 is deliberately graded on a resource setting rather than a Defender assessment, so it is not subject to this delay.
- **Portal/API mismatch:** use portal state for grading and CLI/REST as corroboration. A downloaded CSV is facilitator evidence, not validator-observable state.

## Final grading summary

| Challenge | Full-credit state | Validation |
|---|---|---|
| 1 | Baseline observations and four preconfigured capabilities confirmed; no score target | `validate-challenge-01` |
| 2 | Storage settings, SQL `publicNetworkAccess=Disabled` with no `0.0.0.0` firewall rule, Key Vault `publicNetworkAccess=Disabled`, and exact one-policy named custom standard; MCSB remains visible | `validate-challenge-02` |
| 3 | Three plans enabled and exact three sample-alert strings present and triaged | `validate-challenge-03` |
| 4 | Containers enabled; fixed ACR findings, CVE/base-image lineage, and identical AKS image verified | `validate-challenge-04` |
| 5 | JIT on both required VMs/ports with `PT3H` and `Any`, plus a bounded 1-hour request; agentless findings interpreted | `validate-challenge-05` |
| 6 | Exact Logic App connector trigger and single Compose action, recommendation-only high-severity rule, and anonymous blob access disabled on `asclabsa*`; MCSB CSV retained as facilitator evidence only | `validate-challenge-06` |

No full- or partial-credit decision is based on Secure Score movement, Secure Score delta, attack path analysis, or a learner's local CSV download. The Challenge 6 validator observes the Azure-side Logic App, automation rule, and storage account setting. Validation references are limited to `validate-challenge-01` through `validate-challenge-06`.
