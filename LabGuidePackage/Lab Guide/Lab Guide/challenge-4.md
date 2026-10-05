# Challenge 4: Secure Containers

### Estimated Duration: 1 Hour(s) 15 Minutes

## Scenario

Contoso runs a deliberately vulnerable container image in Azure Kubernetes Service (AKS). The image was imported into the Azure Container Registry (ACR) named `asclabcr*`, and the `asclab-aks` cluster was configured to run it. You will use Microsoft Defender for Cloud to enable container protection, investigate registry and runtime vulnerability findings, identify the highest-severity CVE and introducing base image, and document the relationship between the registry image and the AKS workload. The fixed image is **source** `mcr.microsoft.com/dotnet/core/aspnet:2.1` and **destination** `contoso-vulnerable/aspnet-core:2.1` in `asclabcr*`.

## Overview

Enable Defender for Containers, inspect the ACR vulnerability assessment, compare it with AKS runtime evidence, and review the available DevOps security information without creating a connector. The workload is in the **lab resource group — deployment <inject key="DeploymentID" enableCopy="false"></inject>**. Use the Azure portal only.

The deployment imported the public image with Azure Container Registry import. It did not use a local Docker installation, Docker build, build agent, registry credentials, or Docker Hub credentials. AKS runs the resulting ACR image reference with the exact repository and tag shown below.

## Objectives

- Task 1: Enable Defender for Containers.
- Task 2: Locate the fixed ACR image vulnerability finding.
- Task 3: Analyze the highest-severity CVE and introducing base image.
- Task 4: Confirm the identical image is running in AKS.
- Task 5: Review DevOps security without creating a connector.

## Task 1: Enable Defender for Containers

In this task, enable the subscription plan and confirm the settings used for ACR and AKS visibility.

1. Sign in to <https://portal.azure.com> using **Email:** <inject key="AzureAdUserEmail"></inject> and **Password:** <inject key="AzureAdUserPassword"></inject>.
2. Open **Microsoft Defender for Cloud** and select **Environment settings** under **Management**.
3. Select the subscription identified by <inject key="SubscriptionID"></inject>. On the Defender plans page, locate **Containers** and set it to **On**.
4. Open the Containers plan settings. Confirm that registry access is enabled for vulnerability assessment of images in connected registries. Confirm Kubernetes API access and the Defender sensor are enabled when those settings are presented.
5. Select **Continue** and **Save** as presented by the portal. Reopen the subscription settings and verify that **Containers** is **On**.
6. Do not open an AWS, GCP, external-registry, or DevOps onboarding flow.

> [!Important]
> Registry vulnerability assessment and runtime inventory are asynchronous. Keep the fixed image unchanged while Defender processes the findings.

## Task 2: Investigate the ACR image

In this task, locate the vulnerability assessment for the fixed image in ACR.

1. In Microsoft Defender for Cloud, open **Recommendations** and select the vulnerability-related view. If grouped and flat views are available, use the flat view.
2. Locate **Azure registry container images should have vulnerabilities resolved**. Filter or inspect affected resources until you find the ACR whose login server begins with `asclabcr`.
3. Open the finding and verify that the image reference ends with `/contoso-vulnerable/aspnet-core:2.1`.
4. Record the image provenance and destination exactly:
   - Source: `mcr.microsoft.com/dotnet/core/aspnet:2.1`
   - Destination: `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core:2.1`
5. Record the finding severity, affected ACR resource, assessment status, and remediation guidance. Open the associated vulnerability or CVE details when available.

> [!Note]
> `az acr import` performs a server-side copy and does not require a local Docker installation. The source value is the deployment provenance; the assessment target is the copy stored in ACR. Registry assessment and recommendation updates can take time.

## Task 3: Analyze the vulnerability chain

In this task, interpret the vulnerability evidence without changing the fixed workload.

1. In the image details, sort or review associated vulnerabilities by severity. Identify the highest-severity CVE for `contoso-vulnerable/aspnet-core:2.1` and record its CVE identifier, severity, affected package, and fixed version when shown.
2. Read the CVE details and remediation guidance. Determine whether the affected package belongs to the application layer or is inherited from the base image.
3. Identify the introducing base image in the image metadata or vulnerability details and confirm it is `mcr.microsoft.com/dotnet/core/aspnet:2.1`.
4. Record that the .NET Core 2.1 image is intentionally retained as an end-of-support vulnerable image for this lab. A production response would select a supported base image, rebuild or import a corrected image, and redeploy it.
5. Do not delete, retag, rebuild, or remediate the fixed image. The finding must remain available for validation.

> [!Tip]
> The repository and tag are the identity check. Do not substitute another ASP.NET image or treat a similarly named recommendation as this workload.

## Task 4: Confirm the AKS linkage

In this task, confirm that the registry finding represents the image running in AKS.

1. In the Azure portal, open **Kubernetes services** and select **`asclab-aks`** in resource group **`asclab`**.
2. Open the cluster's **Microsoft Defender for Cloud** security dashboard. In the **Vulnerabilities** view, review running-container image findings when available.
3. Locate the workload whose image reference is `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core:2.1`. Confirm both values:
   - Repository: `contoso-vulnerable/aspnet-core`
   - Tag: `2.1`
4. Return to **Microsoft Defender for Cloud** > **Recommendations** and inspect **Azure running container images should have vulnerabilities resolved**, if present. Compare the runtime finding with the registry finding: image reference, cluster association, workload, affected package, CVE, and severity.
5. Record the linkage: an ACR login server beginning `asclabcr`, repository `contoso-vulnerable/aspnet-core`, tag `2.1`, cluster `asclab-aks`, and the highest-severity CVE.

<validation step="validate-challenge-04"/>

## Task 5: Review DevOps security without a connector

In this task, review the available integration concepts without onboarding an external organization.

1. In Microsoft Defender for Cloud, open the available container or DevOps security area and review the source-code, pipeline, registry, and image-security integrations it describes.
2. Confirm that this lab has no connected DevOps organization or external registry. Do not select **Add connector**, authorize an organization, create credentials, or configure a pipeline.
3. Return to the container recommendations and verify that your evidence remains scoped to the Azure resources in `asclab`, the `asclabcr*` registry, and `asclab-aks`.

> [!Important]
> This task is orientation only. No connector is required or created, and no external service is used.

## Summary

You enabled Defender for Containers, investigated the exact ACR image `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core:2.1`, and recorded its source provenance `mcr.microsoft.com/dotnet/core/aspnet:2.1`. You identified the highest-severity CVE and introducing base image, confirmed that `asclab-aks` runs the identical repository and tag, compared registry and runtime findings, and reviewed DevOps security without creating a connector.