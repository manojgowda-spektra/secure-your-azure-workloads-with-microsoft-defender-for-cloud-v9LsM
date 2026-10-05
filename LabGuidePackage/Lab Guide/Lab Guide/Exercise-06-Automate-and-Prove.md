# Challenge 6: Automate and Prove

### Estimated Duration: 1 Hour 15 Minutes

## Scenario

Complete the investigation of the `asclab` workload by creating a minimal Logic App, routing high-severity recommendations through a recommendation-only workflow automation rule, remediating the attack-path recommendation, and exporting MCSB evidence. No secure-score movement or attack-path disappearance is required.

## Overview

Use the Azure portal. Create the named Logic App and exact workflow, create the named rule, trace the path from internet-exposed VM through identity to public storage, remediate the recommendation, verify its state is **Healthy**, and download the MCSB CSV.

## Objectives

- Create the Logic App.
- Create recommendation-only automation.
- Remediate and prove the attack-path recommendation.
- Export MCSB evidence.

## Sign in

Sign in to <https://portal.azure.com> with **Email:** <inject key="AzureAdUserEmail"></inject> and **Password:** <inject key="AzureAdUserPassword"></inject>. Confirm deployment <inject key="DeploymentID" enableCopy="false"/> and the lab subscription are selected.

## Task 1: Create and verify the Logic App

1. Create a Consumption **Logic App** in resource group `asclab`, region `eastus`, named **la-contoso-defender-recommendations**.
2. In Logic App Designer, start blank and add the trigger **When a Microsoft Defender for Cloud recommendation is created or triggered**.
3. Add exactly one action, **Compose**, whose input is the trigger's **Recommendation** payload. Save.
4. Verify the workflow has that supported Defender for Cloud recommendation trigger and only that Compose action; do not add connectors, alerts, email, generic HTTP actions, or response actions.

## Task 2: Create the recommendation-only rule

1. In **Defender for Cloud > Workflow automation**, select **Add workflow automation**.
2. Name it **war-contoso-high-severity-recommendations**.
3. Select **Security recommendations** with severity **High**; do not select **Security alerts**.
4. Target **la-contoso-defender-recommendations**, create the rule, enable it, and verify its scope and target.

## Task 3: Trace and remediate the attack-path recommendation

1. Open **Attack path analysis** and select the path from the internet-exposed VM through its system-assigned identity and excessive permissions to the public storage account containing synthetic sensitive records.
2. Inspect node insights and identify the recommendation that fixes the path, distinguishing it from additional recommendations.
3. Apply the prescribed Azure portal remediation, such as removing the unnecessary identity permission or correcting the exposed storage setting identified by the recommendation.
4. Refresh the attack-path recommendation and verify its remediation state is **Healthy**. Do not use graph disappearance as a condition; the path may remain listed for up to 24 hours.

## Task 4: Export MCSB evidence

1. Open **Regulatory compliance > Microsoft cloud security benchmark (MCSB)**. It is already applied; do not add it.
2. Select **Download report**, choose **CSV**, and retain the downloaded evidence, for example `MCSB-asclab-compliance.csv`.
3. Confirm the file is CSV evidence for the selected subscription. Do not assess a score or compliance percentage.

## Task 5: Validate

Confirm the named Logic App has the supported recommendation trigger and single Compose action; the named rule is enabled, high-severity, recommendation-only, and targets that Logic App; the remediated attack-path recommendation is **Healthy**; and MCSB CSV evidence was downloaded.

<validation step="validate-challenge-06"/>

## Summary

You created the exact Logic App and recommendation-only automation rule, remediated the attack-path recommendation to **Healthy**, and exported the already-applied MCSB standard as CSV. Graph removal and score movement are not graded.
