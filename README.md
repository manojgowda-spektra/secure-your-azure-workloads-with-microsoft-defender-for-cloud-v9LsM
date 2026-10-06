# Secure Your Azure Workloads with Microsoft Defender for Cloud

## Summary

This advanced, Azure portal-only challenge lab gives learners Owner access to one subscription containing a deliberately vulnerable `asclab-*` workload in the single CloudLabs-created resource group. The ARM-owned workload includes three VMs, system-assigned identities and their storage/Key Vault permissions, synthetic sensitive blob records, three Key Vault secrets, SQL, and an ACR-imported fixed vulnerable image running on AKS. The workload is assessed for 48 hours before delivery so Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, the cloud security graph, and baseline recommendations are available for investigation.

Learners use Microsoft Defender for Cloud as the single control plane in an investigate-first, then remediate flow. They record a baseline without requiring secure-score movement, remediate storage, SQL, and Key Vault findings, create a custom security standard, enable workload protection plans, triage exact sample alerts, inspect the fixed vulnerable container image and its AKS runtime, configure JIT, automate high-severity recommendations, trace an attack path, and export compliance evidence. Defender workload plans, the custom standard, JIT policies, Logic App, and workflow automation rule are learner-created; no DevTestLab schedule is used.

## Lab Details

• Cloud: Azure
• Region: `eastus`
• Duration: 480 minutes
• Delivery: Azure portal only
• Audience: Advanced Azure learners
• Access: Owner access to one subscription
• Lab resource group: `ODL-DFC-<DeploymentID>` (CloudLabs-created, one group)
• Jump box: `labvm-<DeploymentID>`, in the same lab resource group as the workload
• Challenges: 6
• Validations: `validate-challenge-01`, `validate-challenge-02`, `validate-challenge-03`, `validate-challenge-04`, `validate-challenge-05`, `validate-challenge-06`
• Inline questions: None

## Challenges

1. **Onboard and baseline** — Confirm the subscription connection, inventory the `asclab-*` workload resources separately from the jump box, record baseline observations, and confirm preconfigured Defender capabilities.
2. **Strengthen posture** — Remediate storage, SQL, and Key Vault findings and create exactly one custom standard named `Contoso Secure Workload Baseline` containing the built-in policy definition `Storage accounts should restrict network access using virtual network rules` (`2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`).
3. **Protect workloads** — Enable Defender for Storage, Key Vault, and SQL and triage the exact sample alert types `Storage.Blob_OpenACL.Sensitive`, `KV_UnusualAccessSuspiciousIP`, and `SQL.DB_PotentialSqlInjection`.
4. **Secure containers** — Enable Defender for Containers and inspect findings for `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core:2.1`, including its highest-severity CVE, introducing base image, and identical AKS runtime.
5. **Harden VM access** — Configure JIT for `asclab-win` port 3389 and `asclab-linux` port 22 with maximum request duration `PT3H`, allowed source `Any`, and a learner request of `PT15M`; interpret pre-existing agentless results.
6. **Automate and prove** — Create Logic App `la-contoso-defender-recommendations` with the Microsoft Defender for Cloud recommendation trigger `When a Microsoft Defender for Cloud recommendation is created or triggered` and one `Compose` action, create enabled recommendation-only workflow rule `war-contoso-high-severity-recommendations`, remediate the attack-path recommendation, and download an MCSB CSV report.

## Environment and Fixed Image

The ARM deployment provisions the jump box and vulnerable workload, including:

• VMs `asclab-win`, `asclab-win2`, and `asclab-linux`
• System-assigned identities on both Windows VMs, with Storage Blob Data Contributor and Key Vault get/list permissions that support the Challenge 6 attack path
• Internet-exposed RDP on `asclab-win` and SSH on `asclab-linux` through an NSG
• Storage account `asclabsa*` with an anonymous container `asclab-public-container` containing synthetic sensitive records
• Key Vault `asclab-kv*` with three secrets
• SQL server `asclab-sql*` and database `asclab-db`
• Basic ACR `asclabcr*`
• AKS cluster `asclab-aks` with one Free-tier node
• Pre-session Defender configuration and baseline recommendations

The fixed vulnerable image is imported into ACR with `az acr import`, without Docker, a build agent, registry credentials, or Docker Hub credentials:

```azurecli
az acr import --name <ACR_NAME> --source mcr.microsoft.com/dotnet/core/aspnet:2.1 --image contoso-vulnerable/aspnet-core:2.1
```

Source: `mcr.microsoft.com/dotnet/core/aspnet:2.1`  
Destination: `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core:2.1`

The ARM deployment and bootstrap configure AKS to run exactly `contoso-vulnerable/aspnet-core:2.1`.

## Deployment and Bootstrap

The package contains one ARM deployment stage using the canonical CloudLabs Azure Lab VM shape, `GET-` and `GEN-` parameter placeholders, and a Custom Script Extension. The CSE downloads and executes:

`https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/CloudLabsCommon.ps1`

The deployment creates the Azure workload, identities and role assignments, fixed image deployment, and pre-session Defender configuration. It does not create the Logic App, workflow automation rule, custom standard, JIT policy, or learner secrets in ARM outputs. The retained cost defaults are `Standard_B2als_v2` for the lab VM and the three workload VMs, `Standard_B2as_v2` for the AKS agent pool, and `Standard_LRS` for managed OS disks and the storage account. No auto-shutdown schedule is deployed.

## End-of-Lab Cleanup — Author/Facilitator Operation

**The author or facilitator must perform teardown after each lab run and no later than the expected maximum runtime of 8 hours. Do not wait for, or rely on, a learner's browser CSV download state.** Preserve the ARM-owned AKS/image footprint during the lab; clean it up only after evidence collection and validation are complete.

From an authenticated Azure CLI session in the correct subscription, the primary cleanup is:

```azurecli
az group delete --name asclab --yes --no-wait
```

This removes the workload resource group and its AKS cluster (including its node resources), VMs, managed disks, SQL server/database, ACR and imported image, storage/Key Vault resources, NICs, public IP addresses, NSGs, and virtual network. Confirm completion before considering the workload closed:

```azurecli
az group exists --name asclab
```

A `false` result is expected after deletion. The facilitator must also remove any learner-created Logic App and workflow automation rule that were deployed outside the lab resource group, and review subscription-level Defender pricing. Disable every paid pricing tier that is currently Standard by enumerating the subscription pricing resources:

```azurecli
for plan in $(az security pricing list --query "[?pricingTier=='Standard'].name" -o tsv); do
  az security pricing create --name "$plan" --tier Free
done
```

If the jump-box access aid is no longer needed, the facilitator deletes the whole lab resource group, which removes the workload and the jump box together; do not delete it before the session ends. Verify that no `asclab*` resources, public IPs, NICs, NSGs, AKS node resources, SQL, ACR, or paid Defender pricing remains. The cleanup is author/facilitator-operated, is independent of browser downloads, and is not a learner exercise or a validation condition.

## Defender State and Grading Boundaries

Preconfigured and soaked for 48 hours: Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, and Microsoft Defender for Endpoint integration. Learners enable Defender for Storage, Defender for Key Vault, Defender for SQL, and Defender for Containers.

> **Operator prerequisite — the Defender plans are not enabled by the ARM template.**
>
> `Microsoft.Security/pricings` is a **subscription-scoped** resource type and this template
> deploys at resource-group scope, so ARM rejects it:
> *"The scopeId '/subscriptions/.../resourcegroups/...' is not supported. Supported scopes are
> subscription id or resource id."* An resource-group-scoped template cannot create it, and it
> cannot grant itself a subscription-scoped role assignment to do it from a script either.
>
> Before the environment is pre-deployed, someone with Security Admin or Owner on the lab
> subscription must run:
>
> ```bash
> az security pricing create -n CloudPosture --tier standard
> az security pricing create -n VirtualMachines --tier standard --subplan P2 >   --extensions name=AgentlessVmScanning isEnabled=True
> ```
>
> This must happen **before** the 48-hour soak starts, not after. Challenge 1 asks the learner to
> confirm these are already on, and Challenges 5 and 6 depend on agentless scanning results and the
> cloud security graph, which only populate once the plans are enabled and a full scan cycle has
> run.

The workflow automation rule is a supported Defender for Cloud recommendation trigger: it is enabled, scoped to high-severity recommendations only, and targets the named Logic App. The six PowerShell validators check strict observable resource and Defender states, including the named standard, plans, sample alerts, fixed image, JIT values, automation objects, and healthy attack-path recommendation. Validators do not assert a secure-score value or delta, do not assert disappearance of an attack path, and do not inspect a browser CSV download. No RBAC artifact or Azure Policy artifact is included; the Challenge 2 standard uses the named built-in policy definition through Defender for Cloud's custom-standard experience rather than ARM deployment.

## Package Contents

• ARM deployment template and parameters
• Azure Custom Script Extension/bootstrap script
• Lab guide and master document
• Six PowerShell validations
• Solution guide
• Specification sheet and README

No inline assessment questions are included. The package does not include DevTestLab schedules, live DevOps connectors, starter Logic Apps, starter standards, starter JIT policies, or secrets in ARM outputs.