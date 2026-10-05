# Challenge 2: Strengthen Posture and Add a Custom Standard

### Estimated Duration: 1 Hour(s)

## Scenario

Contoso's deliberately vulnerable workload exposes storage and database services more broadly than required, and its Key Vault does not have recovery protection enabled. You will investigate the existing Microsoft Defender for Cloud recommendations, remediate the prescribed resource settings, and create a narrowly scoped custom security standard. The Microsoft cloud security benchmark (MCSB) is already applied to the subscription; verify it rather than adding it again.

## Overview

Work in the **asclab — deployment <inject key="DeploymentID" enableCopy="false"/>** workload resource group. Resource names include a deployment-specific suffix, so select each resource in the lab resource group rather than guessing the suffix.

You will:

1. Harden the `asclabsa*` storage account.
2. Disable public network access to the `asclab-sql*` logical SQL server.
3. Enable soft delete for the `asclab-kv*` Key Vault.
4. Create exactly one custom standard named **Contoso Secure Workload Baseline** with exactly one built-in policy definition.
5. Verify the custom standard and the automatically applied MCSB standard.

## Objectives

- Task 1: Inspect the existing posture and identify workload resources.
- Task 2: Harden the storage account.
- Task 3: Disable SQL public network access and enable Key Vault soft delete.
- Task 4: Create and verify the custom security standard.
- Task 5: Confirm MCSB default behavior and validate the challenge.

## Task 1: Inspect the existing posture

In this task, establish the starting state before changing resources.

1. Sign in to the [Azure portal](https://portal.azure.com/) using **Email**: <inject key="AzureAdUserEmail"></inject> and **Password**: <inject key="AzureAdUserPassword"></inject>.
2. Search for **Microsoft Defender for Cloud**, and open it.
3. Select **Environment settings**, select the subscription used for this lab, and open **Security policies**. Leave the policy page open in another browser tab.
4. Search for **Resource groups**, open the resource groups page, and select **asclab**. Do not use `the jump box` for this challenge.
5. Locate the storage account whose name begins with `asclabsa`, the logical SQL server whose name begins with `asclab-sql`, and the Key Vault whose name begins with `asclab-kv`.
6. Open **Microsoft Defender for Cloud > Recommendations**, filter the scope to the subscription, and use affected-resource details to confirm that findings relate to the `asclab` workload. Record observations if useful, but do not use a secure-score target or score change as a completion condition.

> [!Important]
> Recommendations can take time to refresh after a resource change. Validation checks resource properties and custom-standard definition, not secure-score movement.

## Task 2: Harden the storage account

In this task, disable public network access, require TLS 1.2, and require HTTPS for the `asclabsa*` storage account.

1. Open the storage account whose name begins with `asclabsa` in the lab resource group.
2. Under **Settings**, select **Configuration**.
3. Set **Minimum TLS version** to **Version 1.2**.
4. Set **Secure transfer required** to **Enabled**. This setting requires requests to use HTTPS.
5. Select **Save**, and wait for the update notification to complete.
6. Select **Networking** in the storage account resource menu.
7. In **Firewalls and virtual networks** or **Public network access**, set public network access to **Disabled**. If the portal presents a connectivity choice instead, select the option that denies public network access and does not leave an internet firewall rule active.
8. Select **Save** if the networking page presents a separate save operation.
9. Return to **Configuration** and verify **Minimum TLS version** is **Version 1.2** and **Secure transfer required** is **Enabled**. Return to **Networking** and verify public network access is disabled.

> [!Note]
> The Azure Storage properties behind these controls are `minimumTlsVersion` and `supportsHttpsTrafficOnly`. The required state is TLS `TLS1_2`, HTTPS-only access enabled, and public network access disabled.

## Task 3: Disable SQL public network access and enable Key Vault soft delete

In this task, disable the workload SQL server's public network access and enable recoverability for the Key Vault.

1. Open the logical SQL server whose name begins with `asclab-sql` in the lab resource group. If you opened `asclab-db`, select its server link first.
2. Under **Security**, select **Networking**.
3. In **Public access** or **Public network access**, set **Public network access** to **Disabled**, then select **Save**. This is the single authoritative graded SQL state and closes the public endpoint rather than adding another allow rule.
4. Only if the portal or API does not expose **Public network access**, use **Selected networks** as a fallback: remove every internet firewall rule, turn off **Allow Azure services and resources to access this server**, and save. Do not leave a `0.0.0.0` rule.
5. Verify the SQL networking page or API shows **Public network access: Disabled** when available. The validator grades **Disabled** when that state is exposed; firewall-rule removal is only the conditional fallback when public network access cannot be surfaced.
6. Open the Key Vault whose name begins with `asclab-kv` in the lab resource group.
7. Under **Settings**, select **Properties**.
8. In **Soft-delete**, select **Enable Recovery** or the equivalent enabled recovery option, and select **Save**. If soft delete is already enabled, leave it enabled and continue.
9. Refresh **Properties** and verify that soft delete is enabled. Do not delete the vault, purge a deleted vault, or change secrets.

> [!Important]
> Azure SQL's [current connectivity guidance](https://learn.microsoft.com/azure/azure-sql/database/connectivity-settings#change-public-network-access) documents setting **Public network access** to **Disabled**; when disabled, public-endpoint connections are denied and firewall-rule changes are not available. Soft delete protects a deleted vault and its objects during the retention period. It is distinct from purge protection. This challenge requires soft delete only.

## Task 4: Create the custom security standard

In this task, create exactly one custom standard containing exactly one existing built-in policy definition.

1. Return to **Microsoft Defender for Cloud**. Select **Environment settings**, choose the lab subscription, and select **Security policies**.
2. Select **+ Create**, then select **Standard**. Do not select **Create custom recommendation**.
3. In the standard name field, enter exactly **Contoso Secure Workload Baseline**. Do not add a suffix, deployment ID, or punctuation.
4. In the recommendations or policy list, search for the exact name **Storage accounts should restrict network access using virtual network rules**.
5. Confirm that the selected row is the built-in Azure Policy definition with this exact definition ID:
   `/providers/Microsoft.Authorization/policyDefinitions/2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`
6. If the initial list does not show the definition ID, use the row's **Source** column, open the row's details pane, or follow the policy-definition link to confirm that it is the built-in Azure Policy definition with ID `2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`. Then select that definition. The portal labels and ID visibility can vary.
7. Select that one definition and no other recommendation or policy. The custom standard must contain exactly one item.
8. Review the selection and select **Create**. Wait for the creation confirmation.
9. Reopen **Security policies** for the subscription, locate **Contoso Secure Workload Baseline**, open its details, and verify that its contents show exactly the named storage network-access definition and the definition ID ending in `2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`.

> [!Important]
> This follows Microsoft's [custom standard guidance](https://learn.microsoft.com/azure/defender-for-cloud/create-custom-recommendations#create-a-custom-standard): create the standard from **Security policies > + Create > Standard**, review the optional **Source** column for Azure subscriptions, select the required recommendation, and create the standard. Do not create an Azure Policy artifact, policy initiative, or separate custom policy definition. Do not add MCSB to the custom standard.

## Task 5: Confirm MCSB default behavior and validate the challenge

In this task, confirm that the built-in benchmark remains applied automatically alongside the new custom standard.

1. On the subscription's **Security policies** page, locate **Microsoft cloud security benchmark**. Depending on the portal version, it may be displayed as **Microsoft cloud security benchmark (MCSB)**.
2. Confirm that MCSB is present as an automatically applied standard for the subscription. Do not select **Add standard**, **+ Create**, or an equivalent action for MCSB.
3. Confirm that **Contoso Secure Workload Baseline** appears separately beside MCSB.
4. Recheck the five prescribed settings:
   - Storage account `asclabsa*`: public network access **Disabled**.
   - Storage account `asclabsa*`: minimum TLS **TLS1_2** / portal label **Version 1.2**.
   - Storage account `asclabsa*`: secure transfer required **Enabled**.
   - SQL server `asclab-sql*`: **Public network access Disabled**. If that property is unavailable in the portal/API, confirm the conditional fallback: no internet-wide firewall rule and Azure services access disabled.
   - Key Vault `asclab-kv*`: soft delete **enabled**.
5. Return to **Microsoft Defender for Cloud > Recommendations** and use resource and recommendation details to verify that the updated state is observable. Allow time for recommendation data to refresh; a secure-score value or delta is not a requirement.
6. When all five resource settings and the exact standard contents are confirmed, run the challenge validation.

<validation step="validate-challenge-02"/>

## Summary

You hardened the vulnerable storage, disabled public network access for the SQL server, and enabled Key Vault soft delete, created **Contoso Secure Workload Baseline** with exactly the built-in definition `2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`, and verified that MCSB remains visible because it is applied to the subscription by default. The challenge is complete when the resource properties, custom-standard contents, and MCSB presence are observable; secure-score movement is not graded.
