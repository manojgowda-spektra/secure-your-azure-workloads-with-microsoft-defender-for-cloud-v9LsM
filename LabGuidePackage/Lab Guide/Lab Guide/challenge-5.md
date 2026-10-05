# Challenge 5

### Estimated Duration: 1 Hour 20 Minutes

## Scenario

Contoso's deliberately vulnerable workload includes two internet-exposed management paths: RDP on **asclab-win** and SSH on **asclab-linux**. In this challenge, you will use Microsoft Defender for Cloud just-in-time (JIT) machine access to replace persistent exposure with bounded, audited access. The subscription was prepared and assessed for 48 hours before the session, so agentless machine-scanning results are already available for interpretation.

## Overview

Configure JIT for the two workload virtual machines, verify the required policy values, request temporary access, and inspect the resulting network state. Then interpret the pre-existing agentless findings for software, vulnerabilities, and secrets on disk.

| Virtual machine | Protocol and port | Maximum request duration | Allowed source |
|---|---|---|---|
| **asclab-win (<inject key="DeploymentID" enableCopy="false"/>)** | RDP, `3389` | `PT3H` | `Any` |
| **asclab-linux (<inject key="DeploymentID" enableCopy="false"/>)** | SSH, `22` | `PT3H` | `Any` |

The bounded access request must use exactly `PT15M`. The validation checks both JIT configurations, including ports, maximum duration, and source setting.

## Objectives

- Configure JIT protection for RDP port `3389` on **asclab-win**.
- Configure JIT protection for SSH port `22` on **asclab-linux**.
- Set the maximum request duration to `PT3H` and allowed source to `Any` for both ports.
- Request temporary access for exactly `PT15M` and verify the temporary network change.
- Interpret agentless results collected during the preceding 48-hour assessment period.

## Sign in to the Azure portal

1. Open <https://portal.azure.com>.
2. Sign in with:
   - User name: <inject key="AzureAdUserEmail"></inject>
   - Password: <inject key="AzureAdUserPassword"></inject>
3. Confirm that the selected subscription is the subscription used for deployment. If more than one subscription is listed, select the one associated with deployment <inject key="DeploymentID" enableCopy="false"/>.

> [!Important]
> Work only with the workload resource group `asclab`. The separate `lab-vm` resource group contains the access jump box and is not the target of this challenge.

## Task 1: Configure JIT for the Windows VM

Protect the RDP management port on **asclab-win**.

1. You can enable JIT from either of these documented portal routes:
   - **Microsoft Defender for Cloud:** search for and open **Microsoft Defender for Cloud**, select **Workload protections**, and select **Just-in-time VM access** in the advanced protections area.
   - **Virtual machines:** search for and open **Virtual machines**, select **asclab-win**, select **Configuration**, and under **Just-in-time access** select **Enable just-in-time**.
2. If you used the **Virtual machines** route, the default JIT configuration is now enabled for **asclab-win**. For detailed editing, return to **Microsoft Defender for Cloud > Just-in-time VM access**, open the **Configured** tab, right-click **asclab-win**, and select **Edit**.
3. If you used the **Microsoft Defender for Cloud** route, open the **Not configured** tab, locate **asclab-win** in resource group `asclab`, select it, and select **Enable JIT on VMs**.
4. In **JIT VM access configuration**, retain or add the RDP entry for port `3389`.
5. Set the protocol to TCP, **Allowed source IPs** to **Any**, and **Maximum request time** to 3 hours. The required stored maximum is the ISO 8601 value `PT3H`.
6. Select **OK**, then **Save**.
7. Return to the **Configured** tab and open the configuration for **asclab-win**. Confirm port `3389`, source **Any**, and the 3-hour maximum are shown.

> [!Note]
> Microsoft Learn documents both portal routes: **Virtual machines > select VM > Configuration > Just-in-time access > Enable just-in-time** for default protection, and **Microsoft Defender for Cloud > Just-in-time VM access** for detailed editing. JIT uses a network security group (NSG) or Azure Firewall to restrict management ports. The portal may show the duration as 3 hours even though the underlying policy value is `PT3H`.

## Task 2: Configure JIT for the Linux VM

Protect the SSH management port on **asclab-linux**.

1. Use either documented portal route for **asclab-linux**:
   - From **Virtual machines**, select **asclab-linux**, select **Configuration**, and under **Just-in-time access** select **Enable just-in-time**.
   - Or, from **Microsoft Defender for Cloud**, select **Workload protections > Just-in-time VM access**, open **Not configured**, select **asclab-linux**, and select **Enable JIT on VMs**.
2. For detailed editing, use **Microsoft Defender for Cloud > Just-in-time VM access**, open **Configured**, right-click **asclab-linux**, and select **Edit**.
3. In the JIT VM access configuration, retain or add the SSH entry for port `22`.
4. Set the protocol to TCP, **Allowed source IPs** to **Any**, and **Maximum request time** to 3 hours. The required stored maximum is `PT3H`.
5. Select **OK**, then **Save**.
6. In the **Configured** tab, open the configuration for **asclab-linux** and confirm port `22`, source **Any**, and the 3-hour maximum.
7. Record the final settings:

   | Resource | Required JIT state |
   |---|---|
   | `asclab-win` | RDP `3389`, maximum `PT3H`, source `Any` |
   | `asclab-linux` | SSH `22`, maximum `PT3H`, source `Any` |

## Task 3: Request bounded access and verify the network state

Open each management port for a short, controlled period and verify the effective inbound state.

1. On the **Configured** tab, select **asclab-win**, then select **Request access**.
2. Select port `3389`, set the source to **Any**, and choose an access duration of exactly 15 minutes. This is the portal representation of `PT15M`.
3. Select **Open ports** and wait for the request to show as approved or active.
4. Open the connection details for **asclab-win** and record the request time, expiry time, port, and source.
5. Open **asclab-win** in resource group `asclab`, select **Networking**, and inspect its associated NSG rules while the request is active. Confirm the temporary allow state is scoped to the requested port and source.
6. Wait until the 15-minute window expires, or use the available close or revoke control after recording the active state. Refresh the NSG view and confirm the temporary allow state is no longer active.
7. Repeat the request for **asclab-linux**, selecting port `22`, source **Any**, and exactly 15 minutes (`PT15M`). Record the active state and then allow it to expire or close it.

> [!Important]
> JIT is request-based. A configured VM is not automatically open for management traffic. After the approved period expires, Defender for Cloud restores the network controls. Existing connections can remain established, so close any test connection before finishing.

> [!Tip]
> If the portal displays a clock time rather than `PT15M`, verify that the selected interval is 15 minutes. Do not select the 3-hour maximum for this request: `PT3H` is the policy maximum, while `PT15M` is the requested access interval.

## Task 4: Interpret the 48-hour agentless machine-scanning results

Review findings collected before the session rather than enabling scanning from a cold state.

1. In Microsoft Defender for Cloud, select **Inventory** or **Recommendations**, depending on which view is available.
2. Filter the scope to resource group `asclab` and inspect **asclab-win**, **asclab-win2**, and **asclab-linux**.
3. Locate the agentless machine-scanning results for each VM. Review the available categories:
   - Software inventory and versions.
   - Vulnerabilities associated with installed software or the machine image.
   - Secrets detected on disk, if present.
4. Open at least one result in each available category. Record the affected VM, finding title or identifier, severity, evidence location or description, and recommended remediation.
5. Record why the results are usable now: Defender CSPM, Defender for Servers Plan 2, agentless machine scanning, and Microsoft Defender for Endpoint integration were enabled, and the workload was assessed for 48 hours before this session.
6. Do not enable or disable agentless scanning. Treat the findings as pre-existing evidence and focus on interpretation and remediation priority.

> [!Note]
> Finding availability and refresh time can vary. Do not invent a finding if a category is empty. Distinguish an absent result from a clean result.

## Validation

Before submitting, confirm that:

- JIT is configured for **asclab-win** and **asclab-linux**.
- RDP port `3389` and SSH port `22` are protected.
- Both maximum request durations are `PT3H`.
- Both allowed source settings are **Any**.
- A bounded request was made for exactly `PT15M` for each management path, with the temporary network state observed and then closed or allowed to expire.
- The pre-existing 48-hour agentless results were reviewed and interpreted without changing the scanning configuration.

<validation step="validate-challenge-05"/>

## Summary

You reduced persistent exposure on both workload management paths by configuring JIT for RDP `3389` and SSH `22`, using a `PT3H` maximum and `Any` source setting. You also performed bounded `PT15M` access requests and interpreted the agentless software, vulnerability, and on-disk secret results collected during the preceding 48-hour assessment period.