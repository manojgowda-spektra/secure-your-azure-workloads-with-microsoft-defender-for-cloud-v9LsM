# Challenge 4: Secure Containers

### Estimated Duration: 1 Hour(s) 15 Minutes

## Scenario

Contoso runs a deliberately vulnerable container image in Azure Kubernetes Service (AKS). The image was imported into the Azure Container Registry (ACR) named `asclabcr*`, and the `asclab-aks` cluster was configured to run it. You will use Microsoft Defender for Cloud to enable container protection, investigate the registry and runtime vulnerability findings it produces, record the CVE evidence for an affected package, and document the relationship between the image stored in the registry and the container running in the cluster. The imported image is **source** `mcr.microsoft.com/dotnet/core/aspnet:2.1` and **destination** `contoso-vulnerable/aspnet-core:2.1` in `asclabcr*`.

## Overview

Enable Defender for Containers, inspect the registry image findings, compare them with the AKS runtime findings, and review the available DevOps security information without creating a connector. The workload is in the **lab resource group — deployment <inject key="DeploymentID" enableCopy="false"/>**. Use the Azure portal only.

The deployment imported the public image with Azure Container Registry import. It did not use a local Docker installation, Docker build, build agent, registry credentials, or Docker Hub credentials. AKS runs the resulting ACR image reference with the exact repository and tag shown below.

## Objectives

- Task 1: Enable Defender for Containers.
- Task 2: Locate the registry image vulnerability findings.
- Task 3: Record the CVE evidence for an affected package.
- Task 4: Confirm the same image is running in AKS.
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
> Registry vulnerability assessment and runtime inventory are asynchronous. The first findings for this workload typically appear a few hours after the plan is enabled, and the runtime (cluster) findings arrive after the registry ones. Keep the imported image unchanged while Defender processes it.

## Task 2: Locate the registry image findings

In this task, find the vulnerability findings Defender has produced for the imported image.

1. In Microsoft Defender for Cloud, open **Recommendations**.
2. Use the recommendation list's **own** search box, the one with the placeholder **Search by title / resource**, directly above the list. Do not use the dark Azure search bar at the very top of the portal — that one searches resources, services and docs, and will not filter this list. Type `aspnet-core`.

   The list filters to this workload and drops unrelated container findings such as `azurefile` and `azfilesrefresh`, which belong to cluster system components rather than to the Contoso workload.
3. Read the result titles. Defender reports container vulnerabilities as one recommendation **per affected package**, named **`Update <package>`** — for example **Update microsoft.aspnetcore.server.kestrel.core**, **Update messagepack**, **Update newtonsoft.json**.

   > There is no single roll-up recommendation for this workload. Do not search for a recommendation named "Azure registry container images should have vulnerabilities resolved" or "Azure running container images should have vulnerabilities resolved" — neither exists in this subscription, and looking for them is the most common way to get stuck on this challenge.
4. Look at the resource type shown next to the affected resource name. The same package appears twice, once for each place Defender assessed it:

   | Resource type | Where the finding comes from |
   |---|---|
   | **Container image** | the image stored in the `asclabcr*` registry |
   | **Container** | the container running in the `asclab-aks` cluster |

   For this task, work with the **Container image** rows. You will use the **Container** rows in Task 4.
5. Record the image provenance and destination:
   - Source: `mcr.microsoft.com/dotnet/core/aspnet:2.1`
   - Destination: `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core`
6. Record the count of distinct `Update <package>` findings you can see for this workload, and their risk levels.

> [!Note]
> `az acr import` performs a server-side copy and does not require a local Docker installation. The source value is the deployment provenance; the assessment target is the copy stored in ACR.

> [!Note]
> The registry findings do not carry the `2.1` tag, and the portal will not show one for them. `mcr.microsoft.com/dotnet/core/aspnet:2.1` is a multi-architecture image, so the import copied a manifest list plus the per-platform manifests beneath it. Only the manifest list is tagged `2.1`; Defender scans the untagged per-platform manifests and addresses them by digest. You can see this for yourself in Task 4. One side effect is a finding named **Update windows_10** — it comes from the Windows images inside that manifest list and is not part of the Linux container the cluster runs.

## Task 3: Record the CVE evidence

In this task, interpret the vulnerability evidence without changing the workload.

1. From the filtered list, select a finding whose resource type is **Container image** — for example **Update microsoft.aspnetcore.server.kestrel.core**.
2. Read the **Description**. It states the package and how many known vulnerabilities it carries, in the form *"Update &lt;package&gt; to a later version to mitigate N known vulnerabilities affecting your devices"*.
3. In the **General details** section, record **Scope**, **Last change date**, **Freshness** and **Attack Paths**.
4. Scroll to **Take action** and select the **Associated CVEs** tab. This is where the CVE evidence lives — it is not on the first pane of the finding.
5. The tab lists one row per CVE with the columns **Title**, **CVSS**, **Fix version** and **Discovery Sources**. Record, for the finding you opened:
   - the CVE identifier,
   - the CVSS score,
   - the affected package (the recommendation title),
   - the fix version,
   - the discovery source.

   As an example of the shape of the answer, in testing **Update microsoft.aspnetcore.server.kestrel.core** listed **CVE-2025-55315**, CVSS **9.9**, fix version **2.3.6**, discovered by **MDVM**. Your own CVE list will differ as the vulnerability feed is updated — record what you see rather than reproducing this example.
6. Open two or three more **Container image** findings and compare their Associated CVEs. Record the highest CVSS score you find across them and the package it belongs to.
7. Note the distinction between the two severity values on screen. The recommendation's **Risk level** may read **Medium** while the CVE it carries scores **9.9**. Risk level is Defender's assessment of the risk this finding poses to this resource in this environment; CVSS is the intrinsic severity of the vulnerability. They are not the same measure, and they will often disagree.
8. Determine whether each affected package is application-layer or inherited. The `microsoft.aspnetcore.*`, `system.*`, `newtonsoft.json` and `messagepack` packages are .NET libraries carried inside the image.
9. Record that the .NET Core 2.1 image is intentionally retained as an end-of-support vulnerable image for this lab. A production response would select a supported base image, rebuild or import a corrected image, and redeploy it.
10. Do not delete, retag, rebuild, or remediate the image. The findings must remain available for validation.

> [!Note]
> Defender does not report an "introducing base image" for this workload. The provenance `mcr.microsoft.com/dotnet/core/aspnet:2.1` is known from the deployment, recorded in Task 2, and is not something you can read back out of the finding. Do not spend time looking for it in the portal.

> [!Tip]
> The repository name is the identity check. Do not substitute another ASP.NET image or treat a similarly named recommendation on a different resource as this workload.

## Task 4: Confirm the AKS linkage

In this task, confirm that the registry findings and the running container describe the same image.

1. In the Azure portal, open **Container registries**, select **`asclabcr<inject key="DeploymentID" enableCopy="false"/>`** in the lab resource group **ODL-DFC-<inject key="DeploymentID" enableCopy="false"/>**, and select **Repositories** under **Services**.
2. Select the repository **`contoso-vulnerable/aspnet-core`**. On its **Essentials** panel, record:
   - **Tag count** and **Manifest count** — the manifest count is much larger than the tag count, because the multi-architecture import brought in one manifest per platform and only the manifest list is tagged.
   - The **Tags** table, which lists tag **`2.1`** and its **Digest**. Record that digest.
3. Return to **Microsoft Defender for Cloud** > **Recommendations** and search `aspnet-core` again in the **Search by title / resource** box.
4. This time compare the two resource types against each other:
   - the **Container image** rows — the registry side, from Task 2,
   - the **Container** rows — the running container in `asclab-aks`.

   Record which `Update <package>` titles appear on **both** sides. In testing, every package reported on the running container was also reported on the registry image. That overlap is the linkage: the vulnerabilities Defender found in the stored image are the vulnerabilities now running in the cluster.
5. Open one of the **Container** rows and record its resource name, risk level and Associated CVEs, then compare them with the **Container image** row for the same package. The CVE identifier and fix version should agree.
6. Record the complete linkage: registry `asclabcr*`, repository `contoso-vulnerable/aspnet-core`, tag `2.1`, the tagged digest, cluster `asclab-aks`, the packages common to both sides, and the highest CVSS you recorded in Task 3.

> [!Note]
> The recommendation pane identifies the affected resource by its short name, `aspnet-core`. It does not print the cluster name, registry name, image tag or digest, so take those from the registry blade in steps 1 and 2 rather than expecting to find them on the finding itself.

> [!Note]
> Runtime (**Container**) findings depend on the Defender sensor and appear later than the registry ones. If you only see **Container image** rows, the cluster assessment has not completed yet. Record what you have, continue, and re-check later — the validation for this challenge does not require the runtime findings to be present.

<validation step="validate-challenge-04"/>

## Task 5: Review DevOps security without a connector

In this task, review the available integration concepts without onboarding an external organization.

1. In Microsoft Defender for Cloud, open the available container or DevOps security area and review the source-code, pipeline, registry, and image-security integrations it describes.
2. Confirm that this lab has no connected DevOps organization or external registry. Do not select **Add connector**, authorize an organization, create credentials, or configure a pipeline.
3. Return to the container recommendations and verify that your evidence remains scoped to the `asclab-*` Azure resources, the `asclabcr*` registry, and `asclab-aks`.

> [!Important]
> This task is orientation only. No connector is required or created, and no external service is used.

## Summary

You enabled Defender for Containers and located the vulnerability findings it produces for `asclabcr*.azurecr.io/contoso-vulnerable/aspnet-core`, which Defender reports as one **`Update <package>`** recommendation per affected package rather than as a single roll-up. You recorded CVE identifiers, CVSS scores and fix versions from the **Associated CVEs** tab, noted why a finding's risk level and its CVE's CVSS score differ, and confirmed the registry-to-runtime linkage by matching the packages reported against the stored **Container image** with those reported against the **Container** running in `asclab-aks`. You also reviewed DevOps security without creating a connector.
