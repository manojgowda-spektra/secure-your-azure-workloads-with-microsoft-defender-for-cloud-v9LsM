# Challenge 2: Strengthen Posture and Add a Custom Standard

### Estimated Duration: 1 Hour(s)

## Scenario

Contoso's deliberately vulnerable workload exposes storage and database services more broadly than required, and its Key Vault does not have recovery protection enabled. You will investigate the existing Microsoft Defender for Cloud recommendations, remediate the prescribed resource settings, and create a narrowly scoped custom security standard. The Microsoft cloud security benchmark (MCSB) is already applied to the subscription; verify it rather than adding it again.

## Overview

Work in the **asclab — deployment <inject key="DeploymentID" enableCopy="false"/>** workload resource group. Resource names include a deployment-specific suffix, so select each resource in the lab resource group rather than guessing the suffix.

You will:

1. Harden the `asclabsa*` storage account.
2. Disable public network access to the `asclab-sql*` logical SQL server.
3. Disable public network access on the `asclab-kv*` Key Vault.
4. Create exactly one custom standard named **Contoso Secure Workload Baseline** with exactly one built-in policy definition.
5. Verify the custom standard and the automatically applied MCSB standard.

## Objectives

- Task 1: Inspect the existing posture and identify workload resources.
- Task 2: Harden the storage account.
- Task 3: Disable public network access on the SQL server and on the Key Vault.
- Task 4: Create and verify the custom security standard.
- Task 5: Confirm MCSB default behavior and validate the challenge.

## Task 1: Inspect the existing posture

In this task, establish the starting state before changing resources.

1. Sign in to the [Azure portal](https://portal.azure.com/) using **Email**: <inject key="AzureAdUserEmail"></inject> and **Password**: <inject key="AzureAdUserPassword"></inject>.
2. Search for **Microsoft Defender for Cloud**, and open it.
3. Select **Environment settings**, select the subscription used for this lab, and open **Security policies**. Leave the policy page open in another browser tab.
4. Search for **Resource groups**, open the resource groups page, and select the lab resource group **ODL-DFC-<inject key="DeploymentID" enableCopy="false"/>**. The jump box in that group is not a target for this challenge.
5. Locate the storage account whose name begins with `asclabsa`, the logical SQL server whose name begins with `asclab-sql`, and the Key Vault whose name begins with `asclab-kv`.
6. Open **Microsoft Defender for Cloud > Recommendations**, filter the scope to the subscription, and use affected-resource details to confirm that findings relate to the `asclab-*` workload. Record observations if useful, but do not use a secure-score target or score change as a completion condition.

> [!Important]
> Recommendations can take time to refresh after a resource change. Validation checks resource properties and custom-standard definition, not secure-score movement.

## Task 2: Harden the storage account

In this task, disable public network access, require TLS 1.2, and require HTTPS for the `asclabsa*` storage account.

1. Open the storage account whose name begins with `asclabsa` in the lab resource group.
2. Under **Settings**, select **Configuration**.
3. Set **Secure transfer required** to **Enabled**. This setting requires requests to use HTTPS.
4. Scroll down to **Minimum TLS version** and set it to **Version 1.2**. The account starts on **Version 1.0** and the portal shows a retirement warning beside it; the dropdown offers only Version 1.0 and Version 1.2, because Azure has retired 1.1.
5. Select **Save**, and wait for the update notification to complete.
6. Select **Networking** under **Security + networking** in the storage account resource menu, and stay on the **Public access** tab.

7. **Public network access** is not a toggle on this page. It shows the current value, `Enabled from all networks`, with a **Manage** button beneath it. Select **Manage**.

8. In the **Public network access** pane, choose **Disable** — the middle of three options, described as *"Restrict inbound access while allowing outbound access."* The label is **Disable**, not "Disabled". Do not choose **Secured by perimeter**, which needs a network security perimeter this lab does not deploy.

9. A confirmation dialog appears: *"Disabling public network access will make this resource not available publicly."* Select **Proceed**. If this dialog is dismissed or ignored the selection silently reverts to **Enable** and your save will appear to do nothing, so confirm **Disable** is still selected before continuing.

10. Select **Save** at the bottom of the pane and wait for *"Successfully updated storage account"*.

11. Return to **Configuration** and verify **Minimum TLS version** is **Version 1.2** and **Secure transfer required** is **Enabled**. Return to **Networking** and verify **Public network access** now reads **Disabled**.

> [!Note]
> The Azure Storage properties behind these controls are `minimumTlsVersion` and `supportsHttpsTrafficOnly`. The required state is TLS `TLS1_2`, HTTPS-only access enabled, and public network access disabled.

## Task 3: Close public network access on the SQL server and the Key Vault

In this task, close the public endpoint on both the workload SQL server and the Key Vault.

1. Open the logical SQL server whose name begins with `asclab-sql` in the lab resource group. If you opened `asclab-db`, select its server link first.
2. Under **Security**, select **Networking**, and stay on the **Public access** tab.

3. **Do the firewall rule first — the order matters.** With **Selected networks** still chosen, find the **Firewall rules** section and delete the rule named **AllowAll**, which spans `0.0.0.0` to `255.255.255.255`. Select **Save**.

   The **Firewall rules** section is only rendered while **Selected networks** is chosen. The moment you switch to **Disable** the whole section disappears from the page, and you can no longer remove the rule through the portal. Both states are graded, so a learner who disables public access first has to switch back to **Selected networks** to reach the rule again.

4. Now set **Public network access** to **Disable** — the label is **Disable**, not "Disabled" — and select **Save**. The page then reads *"Only approved private endpoint connections will be accepted by this resource."*

5. Verify both states, because the validator checks both:
   - **Public network access** is **Disable**.
   - No firewall rule remains that starts at `0.0.0.0`. The lab ships exactly one such rule, `AllowAll`.
6. Open the Key Vault whose name begins with `asclab-kv` in the lab resource group.
7. Under **Settings**, select **Networking**, and stay on the **Firewalls and virtual networks** tab.
8. Under **Allow access from**, the vault is set to **Allow public access from all networks**, with the warning *"Traffic from all public networks can access this resource."* Select **Disable public access**, then select **Apply**.
9. Refresh the page and confirm **Disable public access** is selected. Do not delete the vault, purge a deleted vault, or change secrets.

> [!Note]
> Soft delete is **not** part of this challenge. Azure now enables it on every new Key Vault and no longer allows it to be turned off, so there is nothing for you to change — the vault already arrives with `enableSoftDelete: true`. Public network access is the Key Vault weakness this lab can still demonstrate, and it is what is graded.

> [!Important]
> Azure SQL's [current connectivity guidance](https://learn.microsoft.com/azure/azure-sql/database/connectivity-settings#change-public-network-access) documents setting **Public network access** to **Disabled**. Note that the Azure portal stops showing the firewall-rule controls once public access is disabled, which is why this task removes the `AllowAll` rule first.

## Task 4: Create the custom security standard

In this task, create exactly one custom standard containing exactly one existing built-in policy definition.

1. Return to **Microsoft Defender for Cloud**. Select **Environment settings**, choose the lab subscription, and select **Security policies**.
2. Select **+ Create**, then **Custom standard** from the menu. The other entry is **Custom recommendation** — do not use it. The **Create a new standard** wizard opens with three tabs: **Basics**, **Recommendations**, **Review + create**.

3. On **Basics**, in **Name**, enter exactly **Contoso Secure Workload Baseline**. Do not add a suffix, deployment ID, or punctuation — the validator matches this string character for character. Leave **Description** empty. Select **Next**.

4. On **Recommendations**, use the **Search** box and search for the exact name **Storage accounts should restrict network access using virtual network rules**. That narrows several hundred rows to a single result.

5. Confirm the row shows **Type: Built-in** and **Source: Azure Policy**. This is the built-in definition `2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`; the grid does not display the GUID, so the **Source** column is how you tell it apart from a Defender for Cloud recommendation of a similar name.

6. Tick the checkbox on that row, and that row only. The custom standard must contain exactly one item. Leave the search filter in place so no other row can be selected by accident.

7. Select **Review + create**. Confirm the summary reads **Name: Contoso Secure Workload Baseline** and **Recommendations: 1 selected** before going further. If it says anything other than 1, go back and clear the extra selections.

8. Select **Create**.

9. Reopen **Security policies** for the subscription and confirm **Contoso Secure Workload Baseline** is listed with Type **Custom**.

> [!Note]
> Behind the scenes the portal stores your selection as an Azure Policy initiative and links the standard to it. You do not create that initiative yourself and you should not edit it; it is mentioned only so the single policy definition inside it is not a surprise if you go looking.

> [!Important]
> This follows Microsoft's [custom standard guidance](https://learn.microsoft.com/azure/defender-for-cloud/create-custom-recommendations#create-a-custom-standard): create the standard from **Security policies > + Create > Custom standard**, use the **Source** column to identify the Azure Policy definition, select the required recommendation, and create the standard. Do not create an Azure Policy artifact, policy initiative, or separate custom policy definition yourself. Do not add MCSB to the custom standard.

## Task 5: Confirm MCSB default behavior and validate the challenge

In this task, confirm that the built-in benchmark remains applied automatically alongside the new custom standard.

1. On the subscription's **Security policies** page, use the **Search** box to find **Microsoft cloud security benchmark**. The list holds around 58 standards across two pages, so searching is quicker than scrolling.

   Two rows match. Take the one named exactly **Microsoft cloud security benchmark**, with Type **Default**, **Assigned on: Subscription** and Status **On**. The second row, **Microsoft cloud security benchmark v2**, is Type **Compliance** and Status **Off** — it is not the one this task refers to and you should not enable it.

2. Confirm that MCSB is present as an automatically applied standard for the subscription — Type **Default** and Status **On** are what show that. Do not select **Add standard**, **+ Create**, or an equivalent action for MCSB.
3. Confirm that **Contoso Secure Workload Baseline** appears separately beside MCSB.
4. Recheck the five prescribed settings:
   - Storage account `asclabsa*`: public network access **Disabled**.
   - Storage account `asclabsa*`: minimum TLS **TLS1_2** / portal label **Version 1.2**.
   - Storage account `asclabsa*`: secure transfer required **Enabled**.
   - SQL server `asclab-sql*`: **Public network access Disabled**. If that property is unavailable in the portal/API, confirm the conditional fallback: no internet-wide firewall rule and Azure services access disabled.
   - Key Vault `asclab-kv*`: public network access **disabled**.
5. Return to **Microsoft Defender for Cloud > Recommendations** and use resource and recommendation details to verify that the updated state is observable. Allow time for recommendation data to refresh; a secure-score value or delta is not a requirement.
6. When all five resource settings and the exact standard contents are confirmed, run the challenge validation.

<validation step="validate-challenge-02"/>

## Summary

You hardened the vulnerable storage, closed the public endpoint on both the SQL server and the Key Vault, created **Contoso Secure Workload Baseline** with exactly the built-in definition `2a1a9cdf-e04d-429a-8416-3bfb72a1b26f`, and verified that MCSB remains visible because it is applied to the subscription by default. The challenge is complete when the resource properties, custom-standard contents, and MCSB presence are observable; secure-score movement is not graded.
