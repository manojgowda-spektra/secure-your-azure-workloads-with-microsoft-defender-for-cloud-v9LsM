# Challenge 6

### Estimated Duration: 1.25 Hours

## Scenario

You are completing the investigation of the deliberately vulnerable **asclab (<inject key="DeploymentID" enableCopy="false"/>)** workload. In this challenge, you will create a minimal Logic App with the supported Microsoft Defender for Cloud recommendation trigger, connect it to a recommendation-only workflow automation rule, investigate the pre-existing attack path, remediate the recommendation that makes the path possible, and export Microsoft cloud security benchmark (MCSB) compliance evidence. The required state is the configuration and remediation result; no Secure Score change or attack-path removal is required.

## Overview

Work in the Azure portal. Create and verify the Logic App, create the named high-severity recommendation rule, trace the internet-exposed VM through its over-permissioned identity to the public storage account, remediate the recommendation that breaks the path, and download the MCSB report as CSV.

> [!Important]
> Sign in to <https://portal.azure.com> with **Email:** <inject key="AzureAdUserEmail"></inject> and **Password:** <inject key="AzureAdUserPassword"></inject>. Confirm that the selected directory and subscription are the lab subscription before making changes.

## Objectives

- Task 1: Create and verify the recommendation-receiving Logic App.
- Task 2: Create a recommendation-only workflow automation rule.
- Task 3: Trace and remediate the pre-existing attack path.
- Task 4: Export MCSB compliance evidence as CSV.
- Task 5: Validate the complete Challenge 6 state.

## Task 1: Create and verify the Logic App

Create the Logic App that receives a Defender for Cloud recommendation payload. Use the supported Defender for Cloud connector trigger and keep the workflow to exactly one trigger and one Compose action.

1. In the Azure portal, open **Create a resource**, search for **Logic App**, and select **Create**. Use the lab subscription, resource group **asclab**, region **East US**, and the exact name **la-contoso-defender-recommendations**. Select a Consumption workflow when the hosting model is requested, complete validation, and create the resource.
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

## Task 3: Trace and remediate the attack-path recommendation

Use the cloud security graph to investigate and remediate the recommendation that enables the pre-existing path.

1. In Defender for Cloud, open **Attack path analysis** and select the path that begins with the internet-exposed VM and leads toward the storage account containing synthetic sensitive records.
2. Inspect the selected node's **Insight** details and trace the sequence from the internet-exposed VM, through its attached system-assigned identity and excessive permissions, to the public storage account. Record the resource names and configuration weakness.
3. Select **Recommendations** or **Remediation** for the path. Distinguish **Recommendations**—steps that fix the attack path—from **Additional recommendations**, which lower risk but do not fully fix it.
4. Open the recommendation that breaks the path and follow its **Take action** remediation guidance. Apply the prescribed fix in the Azure portal, such as removing the unnecessary identity permission or correcting the exposed storage access identified by the recommendation. Change no unrelated resources.
5. Return to the recommendation and refresh its details. Confirm that the remediated recommendation's state is **Healthy**.

> [!Note]
> Defender for Cloud assessments are asynchronous. If the recommendation remains unhealthy or shows an assessment-in-progress state, wait several minutes, refresh the recommendation details, and check again. If the portal still shows the old state, verify that the prescribed change was saved on the correct resource and subscription, then allow the next assessment cycle to complete before submitting. An attack path can remain listed for up to 24 hours after it is resolved; do not wait for the graph entry to disappear.

> [!Important]
> The required result is the recommendation's **Healthy** remediation state. The graph path does not need to disappear, and no Secure Score value or delta is required.

## Task 4: Export the default MCSB compliance report

Produce compliance evidence from the Microsoft cloud security benchmark (MCSB), which is already applied to the subscription by default.

1. In Defender for Cloud, open **Regulatory compliance** and select **Microsoft cloud security benchmark**. Confirm that it is visible as an applied standard. Do not add or assign MCSB as a new standard.
2. Review the standard and at least one control or assessment so the report context is clear. Do not pursue a particular compliance percentage.
3. Select **Download report** on the Regulatory compliance page and choose **CSV**. Save the file with a recognizable name such as `MCSB-asclab-compliance.csv`.
4. Confirm locally that the downloaded file is a CSV containing MCSB evidence for the selected subscription. Retain it as learner evidence; the browser-downloaded file is not inspected by the validator.

> [!Note]
> Compliance assessments refresh asynchronously. If the MCSB standard or a control is temporarily unavailable, confirm the selected subscription and refresh the **Regulatory compliance** page. If the report command is unavailable while assessment data loads, wait and refresh; do not assign a second MCSB standard. The CSV is an evidence outcome and does not require a particular compliance percentage or Secure Score movement.

## Task 5: Validate the complete Challenge 6 state

Perform a final state review before submitting the challenge.

1. Confirm that **la-contoso-defender-recommendations** has the **When a Microsoft Defender for Cloud recommendation is created or triggered** trigger and exactly one **Compose** action containing the recommendation payload.
2. Confirm that **war-contoso-high-severity-recommendations** is enabled, targets **la-contoso-defender-recommendations**, and is scoped to high-severity **recommendations only**, with no alert trigger.
3. Confirm that the remediated attack-path recommendation is **Healthy**. The graph path does not need to disappear.
4. Confirm that the MCSB compliance report was downloaded in **CSV** format and retain the file as learner evidence.
5. Submit the challenge and wait for the validation result.

<validation step="validate-challenge-06"/>

## Summary

You created **la-contoso-defender-recommendations** with the supported **When a Microsoft Defender for Cloud recommendation is created or triggered** connector trigger and a single **Compose** action, connected it to the enabled recommendation-only rule **war-contoso-high-severity-recommendations**, remediated the attack-path recommendation to a **Healthy** state, and exported the already-applied MCSB evidence as CSV. The validation checks the concrete Azure resource states; it does not inspect the browser download, require Secure Score movement, or require attack-path removal.