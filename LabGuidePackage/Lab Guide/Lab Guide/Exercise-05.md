# Challenge 5: Harden VM Access

### Estimated Duration: 1 Hour 20 Minutes

## Scenario

`asclab-win` exposes RDP and `asclab-linux` exposes SSH through internet-open NSGs. Configure Microsoft Defender for Cloud just-in-time (JIT) access and interpret agentless findings already collected during the 48-hour assessment.

## Overview

Required policy values are RDP `3389`, SSH `22`, maximum `PT3H`, source `Any`; each learner request is exactly `PT15M`.

## Objectives

- Configure JIT for both VMs.
- Exercise bounded access.
- Interpret pre-existing agentless results.

## Sign in

1. Open <https://portal.azure.com> and sign in with <inject key="AzureAdUserEmail"></inject> and <inject key="AzureAdUserPassword"></inject>.
2. Select the subscription associated with deployment <inject key="DeploymentID" enableCopy="false"/> and work in `asclab`, not `lab-vm`.

## Task 1: Configure JIT

1. Open **Defender for Cloud > Workload protections > Just-in-time VM access**.
2. For **asclab-win**, select **Enable JIT on VMs**, retain/add TCP port `3389`, set **Allowed source IPs** to **Any**, and set **Maximum request time** to 3 hours (`PT3H`); save.
3. For **asclab-linux**, configure TCP port `22` with **Any** and maximum `PT3H`; save.
4. In **Configured**, verify both policies and record the final values.

## Task 2: Request bounded access

1. For `asclab-win`, select **Request access**, port `3389`, source **Any**, and exactly 15 minutes (`PT15M`); open the port.
2. Observe the active request and temporary NSG allow state. Close it or allow it to expire, then refresh.
3. Repeat for `asclab-linux`, port `22`, exactly `PT15M`, and record the active state before closing or expiry.

## Task 3: Interpret agentless results

1. In **Inventory** or **Recommendations**, filter resource group `asclab` and inspect `asclab-win`, `asclab-win2`, and `asclab-linux`.
2. Review available software, vulnerability, and on-disk secret results. Record affected VM, finding identifier, severity, evidence, and recommended remediation.
3. Explain that CSPM, Servers Plan 2, agentless scanning, Endpoint integration, and 48-hour assessment make the results pre-existing. Do not change scanning settings.

<validation step="validate-challenge-05"/>

## Summary

You configured JIT with `PT3H` and `Any`, exercised `PT15M` access for RDP and SSH, and interpreted the pre-existing agentless findings without requiring score movement.
