# Challenge 2: Strengthen Posture

### Estimated Duration: 1 Hour

## Scenario

The `asclab` workload exposes storage and SQL too broadly, and Key Vault recovery protection is not enabled. Remediate the prescribed settings and create one named custom security standard. Microsoft cloud security benchmark (MCSB) is already applied; do not add it.

## Overview

Use the Azure portal to harden storage, SQL, and Key Vault, then create exactly **Contoso Secure Workload Baseline** with one built-in policy definition.

## Objectives

- Task 1: Inspect the workload.
- Task 2: Harden storage, SQL, and Key Vault.
- Task 3: Create and verify the custom standard.

## Task 1: Inspect the workload

1. Sign in at <https://portal.azure.com> with **Email:** <inject key="AzureAdUserEmail"></inject> and **Password:** <inject key="AzureAdUserPassword"></inject>.
2. Select subscription <inject key="SubscriptionID"></inject>, open **Defender for Cloud > Environment settings > Security policies**, and keep the page available.
3. In resource group **asclab** locate `asclabsa*`, `asclab-sql*`, and `asclab-kv*`. Do not use `lab-vm`.

## Task 2: Harden storage, SQL, and Key Vault

1. On `asclabsa*` **Configuration**, set **Minimum TLS version** to **Version 1.2** and **Secure transfer required** to **Enabled**; save.
2. On its **Networking** page, set public network access to **Disabled**; save and verify.
3. On `asclab-sql*` **Networking**, disable public access. If the portal shows selected networks instead, remove internet firewall rules and do not leave a `0.0.0.0` rule.
4. On `asclab-kv*` **Properties**, enable soft delete/recovery and save. Do not delete or purge the vault.

## Task 3: Create and verify the custom security standard

1. In **Defender for Cloud > Environment settings > subscription > Security policies**, select **+ Create > Standard**.
2. Enter exactly **Contoso Secure Workload Baseline**.
3. Select exactly **Storage accounts should restrict network access using virtual network rules**, definition ID `/providers/Microsoft.Authorization/policyDefinitions/2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`; select no other definition, then create.
4. Verify the named standard contains exactly that definition. Verify **Microsoft cloud security benchmark (MCSB)** appears separately as the automatically applied standard. Do not add MCSB.
5. Recheck storage public access disabled, TLS `TLS1_2`, HTTPS-only enabled, SQL internet access closed, and Key Vault soft delete enabled. Use resource state rather than score movement.

<validation step="validate-challenge-02"/>

## Summary

You remediated the five prescribed settings and created the exact one-definition **Contoso Secure Workload Baseline** while preserving the automatically applied MCSB standard.
