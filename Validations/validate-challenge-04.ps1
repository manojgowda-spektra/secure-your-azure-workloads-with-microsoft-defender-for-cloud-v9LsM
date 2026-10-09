using namespace System.Net
# $sub and $DID are injected by CloudLabs.
#
# Resource group, corrected 6 Oct 2026. The query previously hardcoded '/resourceGroups/asclab/',
# which matches no resource in a CloudLabs deployment - the lab group is ODL-DFC-<DeploymentID> -
# so it returned zero rows and the challenge always failed. $rg is now discovered.
#
# Finding source, corrected 9 Oct 2026 against live scan output. Two further faults made this
# validator unpassable even after the resource group was fixed:
#
#   1. It queried 'microsoft.security/assessments/subassessments'. That table holds 0 rows in this
#      subscription. Defender emits container vulnerability findings as ordinary assessments named
#      'Update <package>' - 90 of them here: 54 on registry images, 27 on AKS workloads, 9 on VMs -
#      each carrying SoftwareName, FixedVersion and CvesDetails in properties.additionalData.
#   2. It required the literal image string 'contoso-vulnerable/aspnet-core:2.1'. The registry-side
#      finding never contains the tag: properties.resourceAdditionalData.Tags is [] on all four
#      scanned digests, and ImageUri is addressed by '@sha256:<digest>', not ':2.1'. The tag appears
#      only on the AKS runtime finding, so matching on it could never succeed against the registry.
#
# The repository name is the identity on the registry side. The AKS runtime linkage is measured and
# reported but deliberately NOT gated: the learner cannot control Defender sensor timing, and Task 4
# is a recording exercise with no learner-changed state to verify. Gating it would fail correct work
# for a reason the learner cannot influence.
$rg=(Get-AzResource -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'asclab*' } | Select-Object -First 1).ResourceGroupName; if(-not $rg){ throw 'Could not locate the lab resource group: no resource named asclab* found in the subscription.' };$repo='contoso-vulnerable/aspnet-core';$count=0;$found=$false;$detail='No attempt completed.'
function Reply($s,$m){$body=@{Status=$s;Message=$m}|ConvertTo-Json -Depth 12 -Compress;Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{StatusCode=[HttpStatusCode]::OK;Body=$body}) -Clobber}
do{$count++;try{Set-AzContext -Subscription $sub -ErrorAction Stop|Out-Null;$p=Get-AzSecurityPricing -Name Containers -ErrorAction Stop;if($p.PricingTier -ne 'Standard'){throw "Defender for Containers tier is '$($p.PricingTier)', expected Standard. Enable the Containers plan in Environment settings (Challenge 4, Task 1)."};$q="securityresources | where type =~ 'microsoft.security/assessments' | where tostring(properties.displayName) startswith 'Update ' | project nm=tostring(properties.displayName), st=tostring(properties.status.code), rid=tostring(properties.resourceDetails.Id), rad=tostring(properties.resourceAdditionalData)";$rows=@(Search-AzGraph -Query $q -Subscription $sub -First 5000 -ErrorAction Stop);if($rows.Count -eq 0){throw "No 'Update <package>' vulnerability assessments exist in the subscription yet. Registry image scanning runs after Defender for Containers is enabled and can take several hours to produce findings."};$rx=[regex]::Escape($repo);$reg=@($rows|Where-Object{$_.rid -match '(?i)/registries/asclabcr' -and $_.rid -match '(?i)securityentitydata/repositories' -and $_.rad -match "(?i)$rx" -and $_.st -eq 'Unhealthy'});if($reg.Count -eq 0){$anyReg=@($rows|Where-Object{$_.rid -match '(?i)/registries/'});throw "No Unhealthy 'Update <package>' finding targets repository '$repo' in an asclabcr* registry. Registry-scoped findings seen: $($anyReg.Count). Confirm the Containers plan is On and that the imported image has not been deleted or retagged."};$run=@($rows|Where-Object{$_.rad -match '(?i)asclab-aks' -and $_.rad -match "(?i)$rx"});$regPkgs=@($reg|ForEach-Object{$_.nm}|Sort-Object -Unique);$runPkgs=@($run|ForEach-Object{$_.nm}|Sort-Object -Unique);$shared=@($regPkgs|Where-Object{$runPkgs -contains $_});$link=if($run.Count -gt 0){"The same repository is also scanned at runtime on asclab-aks: $($run.Count) finding(s), $($shared.Count) package(s) in common with the registry image."}else{'Runtime findings for the AKS workload have not been produced yet; this is not required to pass.'};$found=$true;Reply 'Succeeded' "Defender for Containers is Standard. Repository '$repo' in the asclabcr* registry has $($reg.Count) Unhealthy 'Update <package>' finding(s) across $($regPkgs.Count) distinct package(s). $link"}catch{$detail=$_.Exception.Message;Reply 'Failed' "Challenge 4 attempt $count of 3 failed: $detail";if($count -lt 3){Start-Sleep -Seconds 10}}}while($count -lt 3 -and -not $found)
if(-not $found){Reply 'Failed' "Challenge 4 failed after 3 attempts in '$rg'. Last reason: $detail"}
