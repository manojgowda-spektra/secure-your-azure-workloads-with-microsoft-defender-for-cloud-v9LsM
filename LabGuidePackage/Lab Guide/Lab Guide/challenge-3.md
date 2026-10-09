# Challenge 3: Protect workloads and triage sample alerts

### Estimated Duration: 1.5 Hours

## Scenario

Contoso has a deliberately vulnerable workload in the **asclab (<inject key="DeploymentID" enableCopy="false"/>)** resource group. Baseline capabilities are already available, but workload-specific protection for Storage, Key Vault, and SQL is not enabled. You will enable those three Microsoft Defender plans, create supported Microsoft Defender for Cloud sample alerts for the subscription, and investigate the resulting alerts as a security analyst.

## Overview

You will use Microsoft Defender for Cloud as the single investigation surface. First, you will enable and verify the three workload protection plans. Next, you will create sample alerts for those plans from **Security alerts**. Finally, you will open each exact alert type, record its MITRE mapping, simulated affected resource, and recommended remediation.

Sample alerts are a controlled demonstration feature. They are not evidence that the corresponding `asclab-*` resource generated a real attack: Microsoft documents that sample alerts use simulated resources. Newly enabled plans may need additional time before real workload findings appear; the sample-alert workflow normally makes its alerts visible within a few minutes after creation.

## Objectives

- Task 1: Enable and verify Microsoft Defender for Storage, Microsoft Defender for Key Vault, and Microsoft Defender for Azure SQL Databases.
- Task 2: Create subscription sample alerts for the three enabled plans.
- Task 3: Triage the exact alert types and distinguish simulated alerts from workload findings.

## Task 1: Enable and verify the workload protection plans

In this task, you will configure the three workload-specific Defender plans at subscription scope and verify their final state.

1. Sign in to the Azure portal at <https://portal.azure.com> with:
   - **User name:** <inject key="AzureAdUserEmail"></inject>
   - **Password:** <inject key="AzureAdUserPassword"></inject>

2. Open **Microsoft Defender for Cloud**, select **Environment settings**, and select the subscription identified by <inject key="SubscriptionID"></inject>.

3. On the Defender plans page, review the current state before changing anything. The lab has already enabled and assessed Defender CSPM and Defender for Servers Plan 2; do not change those settings. Agentless machine scanning and Microsoft Defender for Endpoint integration are also pre-existing capabilities for this lab.

4. Under **Cloud Workload Protection (CWPP)**, switch the **Storage** row and the **Key Vault** row to **On**.

5. Azure SQL is not a row of its own. On the **Databases** row, select **Select types >** — the row shows `Selected: 0/4` — then set **Azure SQL Databases** to **On** in the **Resource types selection** pane and select **Continue**. Leave *SQL servers on machines*, *Open-source relational databases* and *Azure Cosmos DB* Off; this subscription has no instances of them. The **Databases** row switches to **On** by itself once a type is selected.

6. Select **Save**. The portal confirms with a notification reading *"'Storage, Key Vault, Azure SQL Databases' plan in subscription ... were saved successfully!"*

7. Reopen or refresh **Environment settings** for the same subscription and verify that **Storage**, **Key Vault** and **Databases** each show **On**, and that the Databases row now reads `Selected: 1/4`. Do not use secure score as the completion test; this challenge is graded on plan state and the required alert records.

> [!Important]
> Microsoft Learn documents the subscription path as **Microsoft Defender for Cloud > Environment settings > subscription > Defender plans**, followed by **Save**. The plan names and available controls can change slightly as the portal experience evolves, but subscription-level enablement and the saved On state are the required outcomes.

## Task 2: Create sample alerts for the enabled plans

In this task, you will use Defender for Cloud's sample-alert feature rather than generating activity against the vulnerable workload.

1. In Microsoft Defender for Cloud, open **Security alerts**. Review the toolbar for **Sample alerts**. If the portal is showing a preview alerts experience, use the sample-alert control in that experience.

2. Select **Sample alerts**, choose the subscription identified by <inject key="SubscriptionID"></inject>, and in **Defender for Cloud plans** select **Storage Accounts**, **Key Vaults** and **Azure SQL Databases**. The picker starts with all twelve plans selected; use **Select all** to clear it, then tick those three. Submit the operation with **Create sample alerts**.

3. The pane stays open after you select **Create sample alerts**, and the confirmation arrives in the portal's notification bell rather than on the pane itself — it can lag the click by a minute or two. It reads *"Successfully created sample alerts for subscription … Selected bundles: Key Vaults, Azure SQL Databases, Storage Accounts"*. Do not click **Create sample alerts** repeatedly while you wait. Close the pane, give it a few minutes, then refresh **Security alerts**. You should see roughly 35 alerts, each named with a `[SAMPLE ALERT]` prefix and affecting simulated resources such as `Sample-Storage` and `Sample-DB`, all in a `Sample-RG` resource group.

4. Do not create a real attack, upload test malware, access Key Vault through Tor, or alter the `asclab-*` storage, Key Vault, or SQL resources to force an alert. Those activities are outside this challenge. The sample-alert control is the intended test path.

> [!Note]
> Microsoft Learn describes sample alerts as a way to evaluate Defender plan capabilities and validate alert integrations. After **Create sample alerts**, the alerts generally appear after a few minutes. Timing can vary; a brief delay or refresh is expected.

## Task 3: Triage the three exact sample-alert types

In this task, you will open each sample alert and capture the investigation details required for completion. Use the alert type or alert-name field—not a similar recommendation name—to identify the records.

Defender prefixes the type of every sample alert with **`SIMULATED_`**. That prefix is part of the real string and is expected; it is what marks the record as simulated rather than a finding against your workload.

1. Locate and open the Storage sample alert with the type string **`SIMULATED_Storage.Blob_OpenACL`**, displayed as *"[SAMPLE ALERT] Storage account with potentially sensitive data has been detected with a publicly exposed container"*. Record:
   - The MITRE ATT&CK tactic shown in the alert — this one maps to **Collection**.
   - The affected resource shown by the alert. Treat it as a simulated resource; it is not required to be the deployed `asclabsa*` storage account.
   - The investigation or remediation guidance shown in the alert.

2. Locate and open the Key Vault sample alert with the type string **`SIMULATED_KV_TORAccess`**, displayed as *"[SAMPLE ALERT] Access from a TOR exit node to a Key Vault"*. Record the affected simulated resource and the recommended remediation or investigation actions. Its MITRE intent reads **Unknown** — note that as the observed value rather than looking for a tactic that is not there.

3. Locate and open the SQL sample alert with the type string **`SIMULATED_SQL.DB_PotentialSqlInjection`**, displayed as *"[SAMPLE ALERT] Potential SQL Injection"*. Record the affected simulated resource and the recommended remediation, which links to Microsoft guidance on SQL injection. Its MITRE intent also reads **Unknown**.

   Selecting the Key Vaults plan creates five Key Vault sample alerts — `KV_AccountVolumeAnomaly`, `KV_ListGetAnomaly`, `KV_OperationVolumeAnomaly`, `KV_PutGetAnomaly` and `KV_TORAccess`, each with the `SIMULATED_` prefix. Any one of them satisfies the validator, so if the TOR alert is slow to appear, triage one of the others and say which you used.

4. For each alert, read the detail pane fully. Defender for Cloud security alerts provide suspicious-activity details, affected resource, severity or prioritization information, MITRE context when available, and recommended actions. The purpose of this triage is to interpret those fields—not to remediate the simulated resource.

5. Compare the alert resource names with the deployed workload. State in your notes that these are sample alerts for simulated resources, so their affected-resource names do not prove that `asclabsa*`, `asclab-kv*`, or `asclab-sql*` generated the activity. Also state that real findings from newly enabled plans can take hours to become available, while sample alerts are designed to appear within minutes.

> [!Tip]
> If one record is not visible immediately, verify the subscription and plan filters, clear any severity or status filters, refresh the page, and allow additional time. The validator looks for `Storage.Blob_OpenACL`, `SQL.DB_PotentialSqlInjection` and any `KV_*` alert, with or without the `SIMULATED_` prefix. Do not substitute a Storage or SQL alert with a different suffix — `Storage.Blob_OpenContainersScanning.SuccessfulDiscovery`, for instance, is a different alert and will not satisfy the check.

<validation step="validate-challenge-03"/>

## Summary

You enabled and verified Microsoft Defender for Storage, Microsoft Defender for Key Vault, and Microsoft Defender for Azure SQL Databases at subscription scope, then used **Security alerts > Sample alerts** to create and investigate one sample alert for each plan. Your triage identifies the alert type strings, their MITRE and remediation details, and the key distinction that the affected resources are simulated — which the `SIMULATED_` prefix and the `[SAMPLE ALERT]` display name both signal. The challenge is complete when all three plans are On and the three alert types are present for the subscription.
