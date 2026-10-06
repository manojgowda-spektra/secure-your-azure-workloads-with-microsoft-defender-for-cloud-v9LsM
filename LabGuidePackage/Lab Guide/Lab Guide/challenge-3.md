# Challenge 3: Protect workloads and triage sample alerts

### Estimated Duration: 1.5 Hours

## Scenario

Contoso has a deliberately vulnerable workload in the **asclab (<inject key="DeploymentID" enableCopy="false"/>)** resource group. Baseline capabilities are already available, but workload-specific protection for Storage, Key Vault, and SQL is not enabled. You will enable those three Microsoft Defender plans, create supported Microsoft Defender for Cloud sample alerts for the subscription, and investigate the resulting alerts as a security analyst.

## Overview

You will use Microsoft Defender for Cloud as the single investigation surface. First, you will enable and verify the three workload protection plans. Next, you will create sample alerts for those plans from **Security alerts**. Finally, you will open each exact alert type, record its MITRE mapping, simulated affected resource, and recommended remediation.

Sample alerts are a controlled demonstration feature. They are not evidence that the corresponding `asclab-*` resource generated a real attack: Microsoft documents that sample alerts use simulated resources. Newly enabled plans may need additional time before real workload findings appear; the sample-alert workflow normally makes its alerts visible within a few minutes after creation.

## Objectives

- Task 1: Enable and verify Microsoft Defender for Storage, Microsoft Defender for Key Vault, and Microsoft Defender for SQL.
- Task 2: Create subscription sample alerts for the three enabled plans.
- Task 3: Triage the exact alert types and distinguish simulated alerts from workload findings.

## Task 1: Enable and verify the workload protection plans

In this task, you will configure the three workload-specific Defender plans at subscription scope and verify their final state.

1. Sign in to the Azure portal at <https://portal.azure.com> with:
   - **User name:** <inject key="AzureAdUserEmail"></inject>
   - **Password:** <inject key="AzureAdUserPassword"></inject>

2. Open **Microsoft Defender for Cloud**, select **Environment settings**, and select the subscription identified by <inject key="SubscriptionID"></inject>.

3. On the Defender plans page, review the current state before changing anything. The lab has already enabled and assessed Defender CSPM and Defender for Servers Plan 2; do not change those settings. Agentless machine scanning and Microsoft Defender for Endpoint integration are also pre-existing capabilities for this lab.

4. Enable the following plans if they are Off:
   - **Storage** (Microsoft Defender for Storage)
   - **Key Vault** (Microsoft Defender for Key Vault)
   - **SQL** (Microsoft Defender for SQL)

   Select **Save** after making the changes. If the portal presents a plan-specific settings pane, retain the default settings unless the portal requires a confirmation to enable the plan.

5. Reopen or refresh **Environment settings** for the same subscription and verify that Storage, Key Vault, and SQL each show **On**. Do not use secure score as the completion test; this challenge is graded on plan state and the required alert records.

> [!Important]
> Microsoft Learn documents the subscription path as **Microsoft Defender for Cloud > Environment settings > subscription > Defender plans**, followed by **Save**. The plan names and available controls can change slightly as the portal experience evolves, but subscription-level enablement and the saved On state are the required outcomes.

## Task 2: Create sample alerts for the enabled plans

In this task, you will use Defender for Cloud's sample-alert feature rather than generating activity against the vulnerable workload.

1. In Microsoft Defender for Cloud, open **Security alerts**. Review the toolbar for **Sample alerts**. If the portal is showing a preview alerts experience, use the sample-alert control in that experience.

2. Select **Sample alerts**, choose the subscription identified by <inject key="SubscriptionID"></inject>, and select the relevant plans **Storage**, **Key Vault**, and **SQL**. Submit the operation with **Create sample alerts**.

3. Confirm that the portal reports that sample alerts are being created. Wait a few minutes, then refresh **Security alerts** and filter to the selected subscription if necessary.

4. Do not create a real attack, upload test malware, access Key Vault through Tor, or alter the `asclab-*` storage, Key Vault, or SQL resources to force an alert. Those activities are outside this challenge. The sample-alert control is the intended test path.

> [!Note]
> Microsoft Learn describes sample alerts as a way to evaluate Defender plan capabilities and validate alert integrations. After **Create sample alerts**, the alerts generally appear after a few minutes. Timing can vary; a brief delay or refresh is expected.

## Task 3: Triage the three exact sample-alert types

In this task, you will open each sample alert and capture the investigation details required for completion. Use the alert type or alert-name field—not a similar recommendation name—to identify the records.

1. Locate and open the Storage sample alert with the exact type string **`Storage.Blob_OpenACL.Sensitive`**. Record:
   - The MITRE ATT&CK tactic or technique shown in the alert.
   - The affected resource shown by the alert. Treat it as a simulated resource; it is not required to be the deployed `asclabsa*` storage account.
   - The investigation or remediation guidance shown in the alert.

2. Locate and open the Key Vault sample alert with the exact type string **`KV_UnusualAccessSuspiciousIP`**. Record the MITRE mapping, affected simulated resource, and recommended remediation or investigation actions.

3. Locate and open the SQL sample alert with the exact type string **`SQL.DB_PotentialSqlInjection`**. Record the MITRE mapping, affected simulated resource, and recommended remediation or investigation actions.

4. For each alert, read the detail pane fully. Defender for Cloud security alerts provide suspicious-activity details, affected resource, severity or prioritization information, MITRE context when available, and recommended actions. The purpose of this triage is to interpret those fields—not to remediate the simulated resource.

5. Compare the alert resource names with the deployed workload. State in your notes that these are sample alerts for simulated resources, so their affected-resource names do not prove that `asclabsa*`, `asclab-kv*`, or `asclab-sql*` generated the activity. Also state that real findings from newly enabled plans can take hours to become available, while sample alerts are designed to appear within minutes.

> [!Tip]
> If one record is not visible immediately, verify the subscription and plan filters, clear any severity or status filters, refresh the page, and allow additional time. Do not substitute a similarly worded alert: the validator looks for the exact strings `Storage.Blob_OpenACL.Sensitive`, `KV_UnusualAccessSuspiciousIP`, and `SQL.DB_PotentialSqlInjection`.

<validation step="validate-challenge-03"/>

## Summary

You enabled and verified Microsoft Defender for Storage, Microsoft Defender for Key Vault, and Microsoft Defender for SQL at subscription scope, then used **Security alerts > Sample alerts** to create and investigate one sample alert for each plan. Your triage identifies the exact alert strings, their MITRE and remediation details, and the key distinction that the affected resources are simulated. The challenge is complete when all three plans are On and all three exact alert types are present for the subscription.
