# Challenge 4: Secure Containers

### Estimated Duration: 1 Hour 15 Minutes

## Scenario

The `asclab-aks` cluster runs a deliberately vulnerable image imported into `asclabcr*`. Enable Defender for Containers and investigate the registry and runtime findings without replacing the fixed image.

## Overview

The fixed source is `mcr.microsoft.com/dotnet/core/aspnet:2.1`; the destination is `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core:2.1`. Use Azure portal views to identify the highest-severity CVE, introducing base image, and AKS linkage.

## Objectives

- Task 1: Enable Defender for Containers.
- Task 2: Inspect the fixed ACR image.
- Task 3: Relate registry findings to AKS runtime findings.

## Task 1: Enable Defender for Containers

1. Sign in to <https://portal.azure.com> using **Email:** <inject key="AzureAdUserEmail"></inject> and **Password:** <inject key="AzureAdUserPassword"></inject>.
2. Open **Defender for Cloud > Environment settings**, select subscription <inject key="SubscriptionID"></inject>, turn **Containers** on, and save.
3. Confirm registry access, Kubernetes API access, and Defender sensor settings as presented. Do not create an external or DevOps connector.

## Task 2: Investigate the ACR image

1. In **Defender for Cloud > Recommendations**, locate **Azure registry container images should have vulnerabilities resolved** for the registry whose login server begins `asclabcr`.
2. Verify the reference ends `/contoso-vulnerable/aspnet-core:2.1`.
3. Record source `mcr.microsoft.com/dotnet/core/aspnet:2.1`, destination `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core:2.1`, severity, CVE details, affected package, and remediation guidance.
4. Identify the highest-severity CVE and the introducing base image. Do not delete, retag, rebuild, or remediate this fixed image.

## Task 3: Confirm the AKS linkage

1. Open **Kubernetes services > asclab-aks** in resource group **asclab**.
2. Open its **Microsoft Defender for Cloud** security dashboard and inspect vulnerability findings.
3. Confirm repository `contoso-vulnerable/aspnet-core` and tag `2.1` on the running image.
4. Compare registry and runtime evidence: login server, repository, tag, cluster `asclab-aks`, CVE, package, and severity. Review DevOps security only as orientation; create no connector.

<validation step="validate-challenge-04"/>

## Summary

You enabled Defender for Containers, investigated the fixed image and its highest-severity vulnerability, and confirmed the identical repository and tag are running in AKS.
