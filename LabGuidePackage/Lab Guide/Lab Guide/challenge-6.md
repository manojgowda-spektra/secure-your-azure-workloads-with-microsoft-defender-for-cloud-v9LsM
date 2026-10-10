# Challenge 6: Automate Remediation and Prove Compliance

### Estimated Duration: 1.25 Hours

## Scenario

You are completing the investigation of the deliberately vulnerable **asclab (<inject key="DeploymentID" enableCopy="false"/>)** workload. In this challenge, you will create a minimal Logic App with the supported Microsoft Defender for Cloud recommendation trigger, connect it to a recommendation-only workflow automation rule, trace how the workload exposes its sensitive data and close that exposure, and export Microsoft cloud security benchmark (MCSB) compliance evidence. The required state is the configuration and remediation result; no Secure Score change is required.

## Overview

Work in the Azure portal. Create and verify the Logic App, create the named high-severity recommendation rule, trace the internet-exposed VM through its over-permissioned identity to the storage account holding the sensitive records, close the anonymous access that exposes it, and download the MCSB report as CSV.

> [!Important]
> Sign in to <https://portal.azure.com> with **Email:** <inject key="AzureAdUserEmail"></inject> and **Password:** <inject key="AzureAdUserPassword"></inject>. Confirm that the selected directory and subscription are the lab subscription before making changes.

## Objectives

- Task 1: Create and verify the recommendation-receiving Logic App.
- Task 2: Create a recommendation-only workflow automation rule.
- Task 3: Trace and close the exposure of the sensitive data.
- Task 4: Export MCSB compliance evidence as CSV.
- Task 5: Validate the complete Challenge 6 state.

## Task 1: Create and verify the Logic App

Create the Logic App that receives a Defender for Cloud recommendation payload. Use the supported Defender for Cloud connector trigger and keep the workflow to exactly one trigger and one Compose action.

1. In the Azure portal, open **Create a resource**, search for **Logic App**, and select **Create**.

   **Four of the portal's defaults are wrong for this lab. Change every one of them.**

   a. The first screen is **Select a hosting option**, and it defaults to **Standard → Workflow Service Plan**, which bills for a dedicated plan. Choose **Consumption → Multi-tenant**, then select **Select**. The next blade title should read **Create Logic App (Multi-tenant)** — if it does not, go back.

   b. **Resource Group** defaults to a **new** group called `(New) la-contoso-defender-recommendations_group`. You must change it to the existing lab group **ODL-DFC-<inject key="DeploymentID" enableCopy="false"/>**. The validator looks for the Logic App in the lab group, so leaving the default fails the challenge even though the workflow itself is correct.

   c. When you type the deployment ID into the Resource Group box, **two groups match** and the AKS node group `MC_ODL-DFC-<inject key="DeploymentID" enableCopy="false"/>_asclab-aks_<region>` is listed **first and pre-highlighted**. Do not press Enter — click the entry named exactly **ODL-DFC-<inject key="DeploymentID" enableCopy="false"/>**.

   d. **Region** defaults to whichever region the portal prefers, not yours. Set it to the **same region as your lab resource group**, shown on the resource group overview.

   Set **Logic App name** to exactly **la-contoso-defender-recommendations**, leave **Enable log analytics** as **No**, then select **Review + create** and **Create**.
2. Open **la-contoso-defender-recommendations**, select **Logic app designer**, and start with a blank workflow.
3. In the trigger search, search for **Microsoft Defender for Cloud** and select **When a Microsoft Defender for Cloud recommendation is created or triggered**. Create or select the Microsoft Defender for Cloud connection if prompted, and complete the sign-in/permission consent using your lab account.
4. Add exactly one action after the trigger: **Compose**. Set **Inputs** to the trigger's dynamic **Recommendation** payload value, or the complete recommendation payload exposed by the trigger. Do not add an email, notification, generic HTTP request, HTTP response, alert trigger, or other action.
5. Save the workflow. Review the designer or **Code view** and confirm the supported Defender for Cloud recommendation trigger and one—and only one—**Compose** action are present.
6. Return to **Microsoft Defender for Cloud** > **Workflow automation** and open **Add workflow automation**. Select **Refresh** in the Logic App selector and confirm that **la-contoso-defender-recommendations** appears. Do not continue until it is selectable.

> [!Important]
> If the Logic App does not appear after refreshing, verify that the workflow uses the supported Defender for Cloud connector trigger named **When a Microsoft Defender for Cloud recommendation is created or triggered**, that its connector connection is authorized, and that your account has the required Defender for Cloud and Logic Apps permissions (Owner is sufficient for this lab; Logic App Contributor is required to create or modify a workflow). Save the workflow again, return to **Add workflow automation**, and refresh the selector.

> [!Note]
> The supported trigger is documented in [Microsoft Defender for Cloud workflow automation supported triggers](https://learn.microsoft.com/azure/defender-for-cloud/workflow-automations#supported-triggers). This challenge uses the recommendation trigger only; it does not use the legacy alert-response trigger or a generic HTTP request trigger.

## Task 2: Create the recommendation-only workflow automation rule

Connect high-severity Defender for Cloud recommendations to the Logic App without enabling alert automation.

1. In **Microsoft Defender for Cloud**, open **Workflow automation** and select **Add workflow automation**.
2. Name the rule **war-contoso-high-severity-recommendations** and set its subscription scope to the lab subscription. If a description is required, state that it routes high-severity recommendations to **la-contoso-defender-recommendations**.
3. In the trigger conditions, choose the recommendation or assessment event source (it may be labeled **Security recommendations**), and set the severity condition to **High** (the selector may use a different label). Do not select **Security alerts**. The resulting scope must be recommendations only.
4. In the Logic App destination selector, select **la-contoso-defender-recommendations**. If it is not listed, stop and follow the checkpoint in Task 1: refresh the selector, then verify the supported Defender connector trigger, connection, and permissions.
5. Save/create and enable the rule. Reopen **war-contoso-high-severity-recommendations** and verify its enabled state, high-severity condition, recommendation-only scope, and Logic App target.

> [!Important]
> Do not create a second rule, add an alert trigger, or add another Logic App action. The required rule is **war-contoso-high-severity-recommendations**, targeting **la-contoso-defender-recommendations** for high-severity recommendations only.

## Task 3: Trace and close the exposure of the sensitive data

Use Defender for Cloud's risk analysis to trace how the workload exposes the storage account holding synthetic sensitive records, then close the exposure.

1. In Defender for Cloud, open **Recommendations**.
2. Above the list, open **Add filter** and filter on **Risk factors**. Review the recommendations that carry factors such as **Internet exposure**, **Sensitive data** and **Vulnerabilities**. These factors are produced by Defender CSPM, which is enabled on this subscription, and they are how Defender expresses why a finding matters rather than merely what it is.

   > If the **Risk factors** column is empty for every recommendation, CSPM risk analysis has not finished its first pass on this subscription. That is a timing matter, not a mistake. Record that the column is empty, skip to step 4, and complete the task — steps 4 to 6 are the graded part and do not depend on it.
3. Open one recommendation affecting an `asclab-*` resource — one carrying a risk factor if any do, otherwise any `asclab-*` recommendation — and record:
   - **Risk level** and **Risk factors** — note that the risk level is Defender's environmental judgement and is not the same as a CVE severity.
   - The **Description** and the affected resource.
   - Under **General details**: **Scope**, **Last change date** and **Freshness**.
   - **Tactics & techniques** — the MITRE ATT&CK mapping Defender assigns, for example *Initial Access*, *Exploit Public-Facing Application (T1190)*.
   - Under **Take action**, open the **Graph** tab and record the resource context Defender used to determine the risk level.
4. Write down the exposure chain this lab deploys, which you have now seen from both ends:
   - `asclab-win` is internet-reachable and carries a **system-assigned managed identity**.
   - That identity holds **Storage Blob Data Contributor** on the `asclabsa*` storage account.
   - That storage account holds the container with `customer-records.json`, the synthetic sensitive records.
   - The account still permits **anonymous (public) blob access**, so the container is reachable with no credentials at all.
5. Close the direct exposure. Challenge 2 disabled the storage account's **network** access; anonymous blob access is a separate account-level setting that is still open.

   Open the `asclabsa*` storage account in the lab resource group, select **Configuration** under **Settings**, set **Allow Blob anonymous access** to **Disabled**, and select **Save**. Wait for the update notification to complete.
6. Return to **Configuration** and confirm **Allow Blob anonymous access** now reads **Disabled**. This is the graded state for this task.
7. Return to **Recommendations** and refresh. If a recommendation covering anonymous or public blob access is listed for this account, confirm it moves to **Healthy**. If no such recommendation is listed, that is not a failure — continue.

> [!Note]
> Defender for Cloud assessments are asynchronous. A recommendation can take several assessment cycles to reflect a change you have already saved. Do not wait on it: this task is graded on the storage account setting in step 6, which takes effect immediately, not on Defender's view of it.

> [!Important]
> The required result is **Allow Blob anonymous access** set to **Disabled** on the `asclabsa*` storage account. No Secure Score value or delta is required, and no attack path needs to appear or disappear.

> [!Note]
> **Why this task no longer uses Attack path analysis.** Attack path analysis is built by the cloud security graph and needs roughly 48 hours after **Defender CSPM is enabled** before it produces a path — not 48 hours after the lab deploys. Because CSPM is enabled during this lab, that clock starts when you start, so no attack path can appear within a single session. Defender has also narrowed attack paths to externally sourced threats. The risk factors, MITRE mapping and Graph tab used above come from the same cloud security graph and are available immediately, so they teach the same tracing skill without the wait.

## Task 4: Export the default MCSB compliance report

Produce compliance evidence from the Microsoft cloud security benchmark (MCSB), which is already applied to the subscription by default.

1. In Defender for Cloud, open **Regulatory compliance** and select **Microsoft cloud security benchmark**. Confirm that it is visible as an applied standard. Do not add or assign MCSB as a new standard.
2. Review the standard and at least one control or assessment so the report context is clear. Do not pursue a particular compliance percentage.
3. **Open Microsoft cloud security benchmark first, then export.** **Download report** exports whichever standard you are currently inside, not the one named in this task. Click into the **Microsoft cloud security benchmark** tile so its controls are on screen, and only then select **Download report** and choose **CSV**. Save it with a recognizable name such as `MCSB-asclab-compliance.csv`.

   If you select **Download report** straight from the Regulatory compliance landing page, you will get a valid-looking CSV of a different standard — in testing it exported **Azure CSPM**, 171 rows, with no MCSB content at all — and step 4 below will fail even though the download succeeded.
4. Confirm locally that the downloaded file is a CSV containing MCSB evidence for the selected subscription. Open it and check the **complianceStandard** column reads **Microsoft cloud security benchmark** on every row — if it names any other standard, go back to step 3 and open the benchmark before exporting. A correct export for this lab runs to roughly a thousand rows and a couple of megabytes, and names `asclab-*` resources in the **resourceName** column. Retain it as learner evidence; the browser-downloaded file is not inspected by the validator.

> [!Note]
> Compliance assessments refresh asynchronously. If the MCSB standard or a control is temporarily unavailable, confirm the selected subscription and refresh the **Regulatory compliance** page. If the report command is unavailable while assessment data loads, wait and refresh; do not assign a second MCSB standard. The CSV is an evidence outcome and does not require a particular compliance percentage or Secure Score movement.

## Task 5: Validate the complete Challenge 6 state

Perform a final state review before submitting the challenge.

1. Confirm that **la-contoso-defender-recommendations** has the **When a Microsoft Defender for Cloud recommendation is created or triggered** trigger and exactly one **Compose** action containing the recommendation payload.
2. Confirm that **war-contoso-high-severity-recommendations** is enabled, targets **la-contoso-defender-recommendations**, and is scoped to high-severity **recommendations only**, with no alert trigger.
3. Confirm that **Allow Blob anonymous access** is **Disabled** on the `asclabsa*` storage account.
4. Confirm that the MCSB compliance report was downloaded in **CSV** format and retain the file as learner evidence.
5. Submit the challenge and wait for the validation result.

<validation step="validate-challenge-06"/>

## Summary

You created **la-contoso-defender-recommendations** with the supported **When a Microsoft Defender for Cloud recommendation is created or triggered** connector trigger and a single **Compose** action, connected it to the enabled recommendation-only rule **war-contoso-high-severity-recommendations**, traced the exposure of the sensitive records using Defender CSPM risk factors and the recommendation Graph, closed it by disabling anonymous blob access on the `asclabsa*` storage account, and exported the already-applied MCSB evidence as CSV. The validation checks the concrete Azure resource states; it does not inspect the browser download or require Secure Score movement.

## Conclusion

You have successfully completed the Hands-on Lab / Hackathon.

Happy Learning!
