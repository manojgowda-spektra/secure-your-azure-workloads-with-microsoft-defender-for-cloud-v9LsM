using namespace System.Net

# $sub and $DID are injected by CloudLabs. Learner/service-generated state is checked after deployment.
#
# Trigger check, corrected 8 Oct 2026. The original matched only the trigger's VALUE against
# 'Microsoft Defender for Cloud|securitycenter|defender'. The Defender for Cloud Recommendation
# connector's managed API is named **ascassessment** (siblings: ascalert,
# ascregulatorycomplianceassessment), so a correctly built trigger body contains none of those three
# words - the Defender wording lives in the trigger NAME, which the original never read. The check
# now matches the name and the body together, and accepts the connector id directly.
#
# Task 3 check, replaced 10 Oct 2026. The original required Resource Graph evidence of a *healthy
# attack-path recommendation*. That could never pass. Attack path analysis is built by the cloud
# security graph roughly 48 hours after **Defender CSPM is enabled**, not 48 hours after the lab is
# deployed - CSPM went on at 2026-10-08 12:41 UTC on the test deployment and attack paths were still
# 0 when the environment expired ~9 hours before that window opened. Because the learner enables
# CSPM during the lab, the clock starts when they start, so no attack path can exist inside a
# 7h35m session. Defender has also narrowed attack paths to externally sourced threats.
#
# Challenge 6 Task 3 was therefore redesigned onto a deterministic state the learner can actually
# reach: the 'asclabsa*' storage account still permits anonymous (public) blob access after
# Challenge 2, which closes only its *network* access. The check below reads
# properties.allowBlobPublicAccess directly, so it no longer depends on Defender assessment timing
# - and it removes this validator's last Search-AzGraph call, so it no longer needs the
# Az.ResourceGraph module either.
#
# Severity rule, corrected 9 Oct 2026 against a rule actually built in the portal. The original
# required propertyJPath to be exactly '$.severity' with expectedValue 'High'. For a recommendation
# source the portal writes TWO rules, and neither matches that:
#     propertyJPath 'type'                         Contains 'Microsoft.Security/assessments'
#     propertyJPath 'properties.metadata.severity' Equals   'high'    <- lower case
# Path, casing and rule count were all wrong, so a correctly built automation could never pass. The
# check now accepts any path ending in 'severity' and compares the value case-insensitively.
$rg=(Get-AzResource -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'asclab*' } | Select-Object -First 1).ResourceGroupName; if(-not $rg){ throw 'Could not locate the lab resource group: no resource named asclab* found in the subscription.' };$automationName='war-contoso-high-severity-recommendations';$logicAppName='la-contoso-defender-recommendations';$count=0;$found=$false;$last='No validation attempt completed.'
function T($o,$n){if($null-eq $o){return ''};$p=$o.PSObject.Properties[$n];if($null-eq $p -or $null-eq $p.Value){return ''};[string]$p.Value}
function Reply($s,$m){if($s-eq 'Succeeded'){$body=@{Status = "Succeeded";Message = $m}|ConvertTo-Json -Depth 12 -Compress}else{$body=@{Status = "Failed";Message = $m}|ConvertTo-Json -Depth 12 -Compress};Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{StatusCode=[HttpStatusCode]::OK;Body=$body}) -Clobber}
function J($id,$v){$r=Invoke-AzRestMethod -Path "$id`?api-version=$v" -Method GET -ErrorAction Stop;if([string]::IsNullOrWhiteSpace($r.Content)){throw "Azure returned empty content for '$id'."};$r.Content|ConvertFrom-Json -Depth 100}
do{$count++;try{Set-AzContext -Subscription $sub -ErrorAction Stop|Out-Null;$rs=@(Get-AzResource -ResourceGroupName $rg -ExpandProperties -ErrorAction Stop);$a=@($rs|Where-Object{$_.Name-eq $automationName -and $_.ResourceType-match 'Microsoft.Security/automations'}|Select-Object -First 1);if($null-eq $a){throw "Workflow automation '$automationName' is not visible."};$ap=(J $a.ResourceId '2019-01-01-preview').properties;if([bool]$ap.isEnabled-ne $true){throw "Workflow automation '$automationName' is disabled."};$src=@($ap.sources);if($src.Count-ne 1 -or (T $src[0] 'eventSource')-ne 'Assessments'){throw 'Automation must have one Assessments source and no Alerts source.'};$rules=@($src[0].ruleSets|ForEach-Object{@($_.rules)});if(@($rules|Where-Object{(T $_ 'propertyJPath')-match '(?i)(^\$\.severity$|severity$)' -and (T $_ 'operator')-eq 'Equals' -and (T $_ 'expectedValue')-match '(?i)^high$'}).Count-eq 0){throw "Automation has no High-severity recommendation rule. Rules found: $(($rules|ForEach-Object{ (T $_ 'propertyJPath')+'='+(T $_ 'expectedValue') }) -join '; ')"};$acts=@($ap.actions);$la=@($rs|Where-Object{$_.Name-eq $logicAppName -and $_.ResourceType-match 'Microsoft.Logic/workflows'}|Select-Object -First 1);if($acts.Count-ne 1 -or (T $acts[0] 'actionType')-ne 'LogicApp' -or $null-eq $la){throw 'Automation must target the named Logic App.'};if((T $acts[0] 'logicAppResourceId').ToLowerInvariant() -ne $la.ResourceId.ToLowerInvariant()){throw 'Automation target does not match the named Logic App.'};$def=$la.Properties.definition;if($null-eq $def){$def=(J $la.ResourceId '2019-05-01').properties.definition};$tr=@($def.triggers.PSObject.Properties);if($tr.Count-ne 1){throw "Logic App must contain exactly one trigger; found $($tr.Count)."};$tname=[string]$tr[0].Name;$tj=($tr[0].Value|ConvertTo-Json -Depth 100 -Compress);$tblob="$tname $tj";if($tblob-notmatch '(?i)recommendation|assessment'){throw 'The Logic App trigger is not a Defender for Cloud recommendation trigger.'};if($tblob-notmatch '(?i)Microsoft[_ ]Defender[_ ]for[_ ]Cloud|securitycenter|defender|ascassessment'){throw 'The Logic App trigger does not use the Defender for Cloud connector.'};$wa=@($def.actions.PSObject.Properties);if($wa.Count-ne 1 -or $wa[0].Name-ne 'Compose' -or (T $wa[0].Value 'type')-ne 'Compose' -or $null-eq $wa[0].Value.inputs){throw 'Logic App must contain only Compose with payload input.'};$sa=@($rs|Where-Object{$_.ResourceType -eq 'Microsoft.Storage/storageAccounts' -and $_.Name -like 'asclabsa*'}|Select-Object -First 1);if($sa.Count -eq 0){throw "No storage account named 'asclabsa*' was found in '$rg'."};$sp=(J $sa[0].ResourceId '2023-01-01').properties;if($sp.allowBlobPublicAccess -ne $false){throw "Anonymous blob access is still allowed on '$($sa[0].Name)'. Challenge 6 Task 3 requires 'Allow Blob anonymous access' to be set to Disabled on the storage account Configuration blade."};$found=$true;Reply 'Succeeded' "Automation '$automationName' is enabled, recommendation-only, High severity, and targets '$logicAppName'; the Logic App has the Defender recommendation trigger and only Compose; anonymous blob access is disabled on '$($sa[0].Name)'."}catch{$last="Attempt $count of 3: $($_.Exception.Message)";Reply 'Failed' $last;if($count-lt 3){Start-Sleep -Seconds 10}}}while($count-lt 3 -and -not $found)
if(-not $found){Reply 'Failed' "Challenge 6 failed after 3 attempts in '$rg'. Last actionable reason: $last"}