# Challenge 5: Harden VM Access with JIT and Agentless Scanning

### Estimated Duration: 1 Hour 20 Minutes

## Scenario

Contoso's deliberately vulnerable workload includes two internet-exposed management paths: RDP on **asclab-win** and SSH on **asclab-linux**. In this challenge, you will use Microsoft Defender for Cloud just-in-time (JIT) machine access to replace persistent exposure with bounded, audited access. The subscription was prepared and assessed for 48 hours before the session, so agentless machine-scanning results are already available for interpretation.

## Overview

Configure JIT for the two workload virtual machines, verify the required policy values, request temporary access, and inspect the resulting network state. Then interpret the pre-existing agentless findings for software, vulnerabilities, and secrets on disk.

| Virtual machine | Protocol and port | Maximum request duration | Allowed source |
|---|---|---|---|
| **asclab-win (<inject key="DeploymentID" enableCopy="false"/>)** | RDP, `3389` | `PT3H` | `Any` |
| **asclab-linux (<inject key="DeploymentID" enableCopy="false"/>)** | SSH, `22` | `PT3H` | `Any` |

The **policy maximum** is `PT3H`. The **access request** you then raise is a separate, shorter window — the portal offers 1, 2 or 3 hours, so you will request **1 hour**. Validation checks the two JIT configurations — ports, maximum duration and source — not the request itself.

## Objectives

- Configure JIT protection for RDP port `3389` on **asclab-win**.
- Configure JIT protection for SSH port `22` on **asclab-linux**.
- Set the maximum request duration to `PT3H` and allowed source to `Any` for both ports.
- Request temporary access for 1 hour and verify the temporary network change.
- Interpret agentless results collected during the preceding 48-hour assessment period.

## Sign in to the Azure portal

1. Open <https://portal.azure.com>.
2. Sign in with:
   - User name: <inject key="AzureAdUserEmail"></inject>
   - Password: <inject key="AzureAdUserPassword"></inject>
3. Confirm that the selected subscription is the subscription used for deployment. If more than one subscription is listed, select the one associated with deployment <inject key="DeploymentID" enableCopy="false"/>.

> [!Important]
> Work only with the `asclab-*` workload resources. The jump box in the same resource group is an access aid and is not the target of this challenge.

## Task 1: Configure JIT for the Windows VM

Protect the RDP management port on **asclab-win**.

1. Use the **Virtual machines** route to enable JIT: search for and open **Virtual machines**, select **asclab-win**, select **Configuration**, and under **Just-in-time VM access** select **Enable just-in-time**. The setting applies immediately — there is no **Save** on this blade, and the text changes to *"Just-in-time VM access (JIT) is enabled."*

   The alternative route, **Microsoft Defender for Cloud > Workload protections > Just-in-time VM access > Not Configured**, lists a VM only once Defender has inventoried it, which can lag the subscription setup. If that tab is empty, do not wait — use the Virtual machines route above. Once a VM has a JIT configuration it appears on the **Configured** tab straight away, which is where the rest of this challenge works.

   If the blade still reads *"To improve security, enable a just-in-time access"* after you reload it, the change did not take. Select **Enable just-in-time** again and reload to confirm.
2. If you used the **Virtual machines** route, the default JIT configuration is now enabled for **asclab-win**. For detailed editing, return to **Microsoft Defender for Cloud > Just-in-time VM access**, open the **Configured** tab, right-click **asclab-win**, and select **Edit**.
3. If you used the **Microsoft Defender for Cloud** route, open the **Not configured** tab, locate **asclab-win** in the lab resource group, select it, and select **Enable JIT on VMs**.
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
4. Confirm **Allowed source IPs** is **Any** and **Maximum request time** is 3 hours — the required stored maximum is `PT3H`. Enabling JIT from the VM blade already produces these defaults for port `22`, so you may have nothing to change. The default protocol is **Any** rather than TCP; set it to TCP if you want the tighter rule, but the validator checks port, maximum duration and source, not protocol.
5. Select **OK**, then **Save**.
6. In the **Configured** tab, open the configuration for **asclab-linux** and confirm port `22`, source **Any**, and the 3-hour maximum.
7. Record the final settings:

   | Resource | Required JIT state |
   |---|---|
   | `asclab-win` | RDP `3389`, maximum `PT3H`, source `Any` |
   | `asclab-linux` | SSH `22`, maximum `PT3H`, source `Any` |

## Task 3: Request bounded access and verify the network state

Open each management port for a short, controlled period and verify the effective inbound state.

1. On the **Configured** tab, tick the checkbox beside **asclab-win**, then select **Request access**.
2. In the request pane, set the **Toggle** for port `3389` to **On**.
3. For **Allowed source IP**, select **IP Range** and enter `0.0.0.0/0` in the **IP range** box. The request pane has no "Any" button — `0.0.0.0/0` is how you express it here.

   Do **not** use **My IP** unless you know your connection is IPv4. If your connection is IPv6, the request is rejected with *"The provided access request contains a source IP address in IPv6 format, which is unsupported by Just-In-Time Network Access."* That is a limitation of JIT, not a mistake on your part.
4. Set **Time range (hours)** to **1**, the shortest the slider allows. The slider runs from 1 to 3 hours, bounded by the `PT3H` policy maximum you configured.
5. Enter a short justification, then select **Open ports**.
6. Reopen the request and record the request time, expiry time, port and source. The request status reads **Initiated** and the expiry is one hour after submission.
7. Open **asclab-win** in the lab resource group, select **Networking**, and inspect the NSG `asclab-workload-nsg-<inject key="DeploymentID" enableCopy="false"/>` while the request is active. You should see three generations of rule:

   | Priority | Rule | Effect |
   |---|---|---|
   | `100` | `MicrosoftDefenderForCloud-JITRule-…` | **Allow** `3389` from the source you requested — the temporary grant |
   | `1000` | `MicrosoftDefenderForCloud-JITRule_…` | **Deny** `3389` from `*` — added when you enabled JIT |
   | `1001` | `AllowRdp` | the lab's original permissive rule, now overridden by the deny above it |

   Note what this shows: enabling JIT did not remove the insecure `AllowRdp` rule. It inserted a deny at a stronger priority, and grants access only through a temporary rule at priority `100`.
8. Use the close or revoke control after recording the active state, or let the hour elapse. Refresh the NSG view and confirm the priority `100` allow rule is gone.
9. Repeat the request for **asclab-linux**, selecting port `22`, source `0.0.0.0/0`, and 1 hour. Record the active state and then close it.

> [!Important]
> JIT is request-based. A configured VM is not automatically open for management traffic. After the approved period expires, Defender for Cloud restores the network controls. Existing connections can remain established, so close any test connection before finishing.

> [!Tip]
> Keep the two durations distinct. `PT3H` is the **policy maximum** stored on the JIT configuration and is what the validator checks. The **request** is a separate, shorter window chosen on the slider — 1 hour here. Requesting the full 3 hours would also be valid, but 1 hour keeps the exposure short.

## Task 4: Interpret the 48-hour agentless machine-scanning results

Review findings collected before the session rather than enabling scanning from a cold state.

1. In Microsoft Defender for Cloud, select **Inventory** or **Recommendations**, depending on which view is available.
2. Filter the scope to lab resource group and inspect **asclab-win**, **asclab-win2**, and **asclab-linux**.
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
- A bounded one-hour request was made for each management path, with the temporary priority `100` allow rule observed and then closed or allowed to expire.
- The pre-existing 48-hour agentless results were reviewed and interpreted without changing the scanning configuration.

<validation step="validate-challenge-05"/>

## Summary

You reduced persistent exposure on both workload management paths by configuring JIT for RDP `3389` and SSH `22`, using a `PT3H` maximum and `Any` source setting. You also raised bounded one-hour access requests, saw Defender insert a temporary allow rule above its own deny rule while leaving the lab's original permissive rule in place, and interpreted the agentless software, vulnerability, and on-disk secret results collected during the preceding 48-hour assessment period.