# Challenge 1: Onboard and Baseline

### Estimated Duration: 1 Hour 15 Minutes

## Scenario

Contoso has deployed a deliberately vulnerable Azure workload and allowed Microsoft Defender for Cloud to assess it for 48 hours before this session. Your first responsibility is to establish an evidence-based baseline without changing the preconfigured security posture. You will confirm the subscription context, identify the lab resource group and distinguish the `asclab-*` workload resources from the CloudLabs jump box, inspect the Defender for Cloud overview, and verify the capabilities that are already enabled.

## Overview

In this challenge, you will use the Azure portal as the control plane for an initial Defender for Cloud assessment. You will capture baseline observations for the secure score, control breakdown, unhealthy resource count, and recommendation counts by severity. These values are observations only: this challenge has no secure-score target and does not require secure-score movement. You will also verify that Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, and Microsoft Defender for Endpoint integration are already active.

Microsoft Learn identifies the Defender for Cloud overview as a place to review recommendations, inventory, secure score, and compliance information. Subscription coverage and plan configuration are reviewed through **Microsoft Defender for Cloud > Environment settings**.

## Objectives

- Task 1: Confirm the Azure subscription and workload scope.
- Task 2: Capture the Defender for Cloud baseline observations.
- Task 3: Verify the preconfigured Defender capabilities.

## Task 1: Confirm the Azure subscription and workload scope

In this task, you will confirm that the portal session is using the lab subscription and inventory the two resource groups separately.

1. Open <https://portal.azure.com> and sign in with the assigned lab account:
   - **Username:** <inject key="AzureAdUserEmail"></inject>
   - **Password:** <inject key="AzureAdUserPassword"></inject>
2. Confirm that the active directory and subscription context are the lab tenant and subscription. Record the subscription identifier shown for the session as <inject key="SubscriptionID"></inject>.
3. Open **Resource groups** in the Azure portal and locate **asclab**. Treat this as the workload scope. Confirm that it contains the Contoso workload resources, including the virtual machines, storage account, Key Vault, SQL resources, container registry, and AKS cluster.
4. Locate the jump box in the same resource group and treat it as the CloudLabs access aid, not as part of the workload baseline. Its resource name is **labvm-<inject key="DeploymentID" enableCopy="false"/>**.
5. Open **Microsoft Defender for Cloud** from the Azure portal search. Confirm that the selected subscription is the lab subscription rather than a different subscription or a workspace.

> [!Important]
> Do not modify resources during this inventory. In particular, do not enable or disable a Defender plan, delete a recommendation, change a network setting, or alter the jump box. This challenge establishes the starting state for later remediation challenges.

## Task 2: Capture the Defender for Cloud baseline observations

In this task, you will record the current posture measurements exactly as displayed, while treating them as baseline evidence rather than grading targets.

1. On the **Defender for Cloud Overview** page, record the current **secure score** and the date and time of the observation.
2. Open the secure-score or security-controls view and record the **control breakdown**: capture each displayed control name and its current status or contribution. Do not attempt to improve, reproduce, or target the score.
3. From the overview or inventory view, record the current **unhealthy resource count**. Ensure that the scope is the lab subscription and that you count only the `asclab-*` workload resources, excluding the jump box.
4. Open **Recommendations** and record the total recommendation count by severity: **High**, **Medium**, and **Low**. If the portal presents another severity category, record it as an additional observation rather than converting it into one of the three required categories.
5. Add a short interpretation to your lab notes: the workload was intentionally assessed for **48 hours**, so the recommendations and inventory represent an established pre-session baseline rather than a first-minute scan.
6. Preserve the values and observation time for comparison in later challenges. A later remediation may change these values, but no score value or score delta is graded in this challenge.

> [!Note]
> Counts and posture displays can refresh at different times. Record what the portal shows for the selected subscription at the time of observation. Do not wait for, or require, a particular secure-score value.

## Task 3: Verify the preconfigured Defender capabilities

In this task, you will verify the subscription's existing protection configuration without turning on additional capabilities.

1. In **Microsoft Defender for Cloud**, open **Environment settings** and select the lab subscription.
2. On the subscription's Defender plans configuration, verify that **Defender CSPM** is **On**. Record the displayed status and any available configuration detail.
3. Verify that **Defender for Servers** is **On** and configured for **Plan 2**. Record the displayed plan selection.
4. Verify that **agentless machine scanning** is enabled as part of the preconfigured Defender CSPM coverage. Treat the available agentless results as already soaked data; do not start a new scan or change the setting.
5. Verify that the **Microsoft Defender for Endpoint integration** is enabled for the subscription or workload coverage shown in the portal. Record the displayed integration status.
6. Review the subscription coverage or inventory view once more and confirm that the `asclab` workload is represented. Do not enable Defender for Storage, Defender for Key Vault, Defender for SQL, or Defender for Containers in this challenge; those plans are intentionally handled in Challenge 3 and Challenge 4.
7. Confirm that your baseline notes contain all of the following: subscription context, the workload scope (the `asclab-*` resources, excluding the jump box), secure score, control breakdown, unhealthy resource count, recommendation counts by severity, the 48-hour assessment explanation, and the four enabled-capability checks.
8. Submit the challenge validation after confirming the evidence is complete.

<validation step="validate-challenge-01"/>

## Success criteria

- The lab subscription is selected and the `asclab-*` workload resources are inventoried, excluding the jump box.
- Baseline notes record the current secure score, control breakdown, unhealthy resource count, and recommendation counts by severity with an observation time.
- The notes explain that Defender for Cloud assessed the environment for 48 hours before the session.
- Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, and Microsoft Defender for Endpoint integration are confirmed as enabled.
- No preconfigured capability is enabled or disabled during this challenge.
- The validation `validate-challenge-01` completes successfully.

## Summary

You established a subscription-scoped Defender for Cloud baseline, separated the vulnerable workload from the CloudLabs access resources, and verified the capabilities that were intentionally enabled before the lab. The measurements are evidence for later investigation and remediation, not score targets. Continue to Challenge 2 to remediate posture findings and create the named custom security standard.
