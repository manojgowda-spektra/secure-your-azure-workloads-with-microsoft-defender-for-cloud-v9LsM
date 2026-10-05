# Secure Your Azure Workloads with Microsoft Defender for Cloud

## Overview

This advanced Azure portal-only challenge lab places you in the role of Contoso's security owner. The `asclab` workload is intentionally vulnerable and has been assessed for 48 hours before the session. Use Microsoft Defender for Cloud to investigate the existing posture, remediate prioritized configuration risks, enable workload protections, inspect a fixed vulnerable container image and its AKS runtime, harden VM management access, automate high-severity recommendations, and export compliance evidence.

The lab uses one Azure subscription and Owner access. All learner work is performed in the Azure portal. The CloudLabs jump box is only an access aid. It sits in the same lab resource group as the workload, and you do not need it for any challenge.

## What is provisioned

- Virtual machines `asclab-win`, `asclab-win2`, and `asclab-linux`, including system-assigned identities on both Windows VMs.
- Storage account `asclabsa*` with an anonymous `asclab-public-container` containing synthetic sensitive blob records; the Windows VM identities have Storage Blob Data Contributor permission.
- Key Vault `asclab-kv*` with three secrets; the Windows VM identities have Key Vault get/list permission.
- SQL server `asclab-sql*` and database `asclab-db`.
- Basic registry `asclabcr*` and AKS cluster `asclab-aks`.
- Exact container image `contoso-vulnerable/aspnet-core:2.1`, imported into ACR from `mcr.microsoft.com/dotnet/core/aspnet:2.1` and used by AKS.
- Pre-session Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, cloud security graph, Microsoft Defender for Endpoint integration, and baseline recommendations.

Defender for Storage, Defender for Key Vault, Defender for SQL, and Defender for Containers are enabled during the challenges. The Logic App, recommendation-only workflow automation rule, custom standard, and JIT policies are created by the learner rather than provisioned in advance. No DevTestLab schedule is used.

## Challenge outcomes

| Challenge | Outcome |
|---|---|
| 1 — Onboard and baseline | Record posture observations and confirm the pre-existing Defender capabilities. |
| 2 — Strengthen posture | Remediate five prescribed storage, SQL, and Key Vault conditions and create `Contoso Secure Workload Baseline`. |
| 3 — Protect workloads | Enable three workload plans and triage the exact sample-alert type strings. |
| 4 — Secure containers | Relate the fixed vulnerable ACR image to its MCR source and AKS runtime. |
| 5 — Harden VM access | Configure JIT for ports 3389 and 22 with `PT3H` maximum duration and exercise a `PT15M` request. |
| 6 — Automate and prove | Create the Logic App with the exact supported trigger **When a Microsoft Defender for Cloud recommendation is created or triggered** and one **Compose** action, supported recommendation-only automation rule, healthy attack-path recommendation state, and MCSB CSV evidence. |

## Assessment boundary

Validation checks Azure and Defender resource state. It does not require a secure-score value or movement, and it does not require an attack path to disappear. The Microsoft cloud security benchmark (MCSB) is already applied by default; no add-standard step is required for it. Sample alerts use simulated resources and therefore do not identify the deployed `asclabsa*` storage account.

Continue with [Getting Started](./GettingStarted-V2.md), then complete the six challenge pages in order.

For support, contact: cloudlabs-support@spektrasystems.com

Live support: <https://cloudlabs.ai/labs-support>

Happy Learning!
