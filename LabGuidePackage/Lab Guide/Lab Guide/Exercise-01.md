# Challenge 1: Onboard and Baseline

### Estimated Duration: 1 Hour 15 Minutes

## Scenario

Contoso operates a deliberately vulnerable Azure workload assessed for 48 hours before this session. Establish an evidence-based Microsoft Defender for Cloud baseline without changing preconfigured security posture.

## Overview

Confirm the subscription and resource scopes, record baseline observations, and verify the capabilities already enabled. Baseline values are observations only: no secure-score target or movement is required.

## Objectives

- Task 1: Confirm the Azure subscription and workload scope.
- Task 2: Capture baseline observations.
- Task 3: Verify preconfigured Defender capabilities.

## Task 1: Confirm the Azure subscription and workload scope

1. Open <https://portal.azure.com> and sign in:
   - **Username:** <inject key="AzureAdUserEmail"></inject>
   - **Password:** <inject key="AzureAdUserPassword"></inject>
2. Confirm the lab tenant and record subscription <inject key="SubscriptionID"></inject>.
3. In **Resource groups**, inspect **asclab** as the workload scope. Confirm it contains the VMs, storage, Key Vault, SQL, ACR, and AKS resources.
4. Inspect **lab-vm** separately as the CloudLabs access scope. The jump box is **labvm-<inject key="DeploymentID" enableCopy="false"/>**.
5. Open **Microsoft Defender for Cloud** and confirm the lab subscription is selected. Do not modify resources.

## Task 2: Capture the Defender for Cloud baseline observations

1. In **Defender for Cloud Overview**, record the current secure score and observation time.
2. Record the security-control breakdown, unhealthy resource count, and recommendation counts by **High**, **Medium**, and **Low** severity.
3. Note that the workload was assessed for **48 hours** before the session.
4. Preserve the observations for comparison. No score value or score delta is graded.

## Task 3: Verify the preconfigured Defender capabilities

1. Open **Microsoft Defender for Cloud > Environment settings** and select the lab subscription.
2. Verify **Defender CSPM**, **Defender for Servers Plan 2**, **agentless machine scanning**, and **Microsoft Defender for Endpoint integration** are enabled.
3. Do not enable or disable any plan. Defender for Storage, Key Vault, SQL, and Containers are handled in later challenges.
4. Confirm your notes contain the subscription context, separate `asclab` and `lab-vm` scope, all baseline observations, the 48-hour explanation, and the four capability checks.

<validation step="validate-challenge-01"/>

## Success criteria

The subscription and resource scopes are recorded, baseline observations are captured with a timestamp, the 48-hour assessment is understood, and the four preconfigured capabilities are confirmed. No score movement is required.

## Summary

You established the Defender for Cloud baseline and verified pre-existing protection without changing the environment. Continue to Challenge 2 for posture remediation.
