# Challenge 3: Protect Workloads and Triage Sample Alerts

### Estimated Duration: 1.5 Hours

## Scenario

Workload-specific protection is initially off for Storage, Key Vault, and SQL. Enable the plans, create supported Defender for Cloud sample alerts, and investigate the exact alert types. Sample alerts use simulated resources.

## Overview

Use one subscription and the Azure portal. Enable three plans, create subscription sample alerts, and record MITRE context, affected simulated resource, and remediation guidance.

## Objectives

- Task 1: Enable the three workload plans.
- Task 2: Create sample alerts.
- Task 3: Triage the exact alert strings.

## Task 1: Enable the workload protection plans

1. Sign in to <https://portal.azure.com> with **User name:** <inject key="AzureAdUserEmail"></inject> and **Password:** <inject key="AzureAdUserPassword"></inject>.
2. Open **Microsoft Defender for Cloud > Environment settings**, select subscription <inject key="SubscriptionID"></inject>, and review the Defender plans.
3. Turn **Storage**, **Key Vault**, and **SQL** on, retaining defaults, and select **Save**. Do not change CSPM or Servers Plan 2.
4. Refresh and verify all three plans show **On**.

## Task 2: Create subscription sample alerts

1. Open **Security alerts > Sample alerts**.
2. Select subscription <inject key="SubscriptionID"></inject>, choose **Storage**, **Key Vault**, and **SQL**, and select **Create sample alerts**.
3. Wait a few minutes, refresh, and clear filters as needed. Do not generate real activity against the workload.

## Task 3: Triage the exact sample-alert types

1. Open **Storage.Blob_OpenACL.Sensitive** and record its MITRE mapping, simulated affected resource, and remediation guidance.
2. Open **KV_UnusualAccessSuspiciousIP** and record the same details.
3. Open **SQL.DB_PotentialSqlInjection** and record the same details.
4. State in your notes that sample resources do not prove `asclabsa*`, `asclab-kv*`, or `asclab-sql*` generated activity. Newly enabled-plan findings can take hours; sample alerts normally appear within minutes.

<validation step="validate-challenge-03"/>

## Summary

You enabled Storage, Key Vault, and SQL protection and triaged the three exact simulated sample-alert types with their investigation context.
