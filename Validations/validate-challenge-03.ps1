using namespace System.Net

# $sub and $DID are injected by CloudLabs. Sample alerts are learner-created Defender state.
#
# Alerts are read through Azure Resource Graph, not through
# /subscriptions/{sub}/providers/Microsoft.Security/alerts. That ARM path returns {"value":[]} on
# every api-version even with sample alerts live in the subscription (measured 6 Oct 2026, twice,
# five minutes apart, with 35 alerts present). The securityresources table is what the portal reads,
# and its properties are PascalCase.
#
# Defender prefixes every sample alert type with SIMULATED_. The prefix is stripped before
# comparison so the check holds whether or not Microsoft keeps it.

$count=0;$found=$false;$detail='No validation attempt completed.'
$plans=@('StorageAccounts','KeyVaults','SqlServers')
$expected=@('Storage.Blob_OpenACL','SQL.DB_PotentialSqlInjection')
$graphQuery="securityresources | where type =~ 'microsoft.security/locations/alerts' | project t=tostring(properties.AlertType)"
function Reply($s,$m){if($s -eq 'Succeeded'){$body=@{Status = "Succeeded";Message = $m}|ConvertTo-Json -Compress}else{$body=@{Status = "Failed";Message = $m}|ConvertTo-Json -Compress};Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{StatusCode=[HttpStatusCode]::OK;Body=$body}) -Clobber}
do{
  $count++
  try{
    Set-AzContext -Subscription $sub -ErrorAction Stop|Out-Null
    $pricing=@(Get-AzSecurityPricing -ErrorAction Stop)
    foreach($p in $plans){$m=@($pricing|Where-Object{$_.Name-ceq $p});if($m.Count-ne 1 -or $m[0].PricingTier-ne 'Standard'){throw "Plan '$p' is not exactly one Standard pricing record."}}
    $payload=@{subscriptions=@($sub);query=$graphQuery}|ConvertTo-Json -Depth 5 -Compress
    $r=Invoke-AzRestMethod -Method POST -Path "/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01" -Payload $payload -ErrorAction Stop
    if($r.StatusCode-ne 200){throw "Resource Graph returned HTTP $($r.StatusCode)."}
    if([string]::IsNullOrWhiteSpace($r.Content)){throw 'Resource Graph returned empty content.'}
    $rows=@(($r.Content|ConvertFrom-Json).data)
    if($rows.Count-eq 0){throw 'No Defender security alerts found in this subscription. Create them from Security alerts > Sample alerts, then allow a few minutes.'}
    $types=@($rows|ForEach-Object{($_.t -replace '^SIMULATED_','')})
    $missing=@($expected|Where-Object{$types-notcontains $_})
    if($missing.Count){throw "Missing sample alert type(s): $($missing -join ', ')."}
    if(-not @($types|Where-Object{$_ -like 'KV_*'}).Count){throw 'No Key Vault sample alert (KV_*) found for this subscription.'}
    $found=$true
    Reply 'Succeeded' "Subscription '$sub' has Storage, Key Vault and Azure SQL at Standard, and the required sample alerts are present: $($expected -join ', '), plus a Key Vault alert."
  }catch{
    $detail=$_.Exception.Message
    Reply 'Failed' "Challenge 3 attempt $count of 3 failed closed: $detail"
    if($count-lt 3){Start-Sleep -Seconds 10}
  }
}while($count-lt 3 -and -not $found)
if(-not $found){Reply 'Failed' "Challenge 3 failed after 3 attempts. Last observation: $detail"}
