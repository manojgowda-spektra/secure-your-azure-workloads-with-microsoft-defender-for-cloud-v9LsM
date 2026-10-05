using namespace System.Net
# $sub and $DID are injected by CloudLabs.
$count=0; $found=$false; $detail='No attempt completed.'
function Enabled($p,$n){ @($p.Extensions | Where-Object {$_.Name -eq $n -and [string]$_.IsEnabled -eq 'True'}).Count -gt 0 }
do {
  $count++
  try {
    Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null
    $p=@(Get-AzSecurityPricing -ErrorAction Stop)
    $c=@($p|Where-Object Name -eq 'CloudPosture'); $s=@($p|Where-Object Name -eq 'VirtualMachines')
    if($c.Count -ne 1){throw "Expected one CloudPosture pricing record; found $($c.Count)."}
    if($c[0].PricingTier -ne 'Standard'){throw "Defender CSPM tier is '$($c[0].PricingTier)', expected Standard."}
    if($s.Count -ne 1){throw "Expected one VirtualMachines pricing record; found $($s.Count)."}
    if($s[0].PricingTier -ne 'Standard' -or $s[0].SubPlan -ne 'P2'){throw "Defender for Servers is not Standard Plan 2 (tier '$($s[0].PricingTier)', subplan '$($s[0].SubPlan)')."}
    if(-not (Enabled $c[0] 'AgentlessVmScanning' -or Enabled $s[0] 'AgentlessVmScanning')){throw 'AgentlessVmScanning is not enabled.'}
    $found=$true; $body=@{Status='Succeeded';Message="Subscription '$sub' has Defender CSPM Standard, Defender for Servers Plan 2, and AgentlessVmScanning enabled."}|ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{StatusCode=[HttpStatusCode]::OK;Body=$body}) -Clobber
  } catch { $detail=$_.Exception.Message; $body=@{Status='Failed';Message="Challenge 1 attempt $count of 3 failed: $detail"}|ConvertTo-Json -Compress; Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{StatusCode=[HttpStatusCode]::OK;Body=$body}) -Clobber; Start-Sleep -Seconds 10 }
} while($count -lt 3 -and -not $found)
if(-not $found){$body=@{Status='Failed';Message="Challenge 1 failed after 3 attempts for subscription '$sub'. Last reason: $detail"}|ConvertTo-Json -Compress;Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{StatusCode=[HttpStatusCode]::OK;Body=$body}) -Clobber}