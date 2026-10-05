using namespace System.Net

# Note: $sub (subscription id) and $DID (deployment id) are injected by the platform.
$count = 0
$found = $false

$requiredPlans = @('StorageAccounts', 'KeyVaults', 'SqlServers')
$requiredAlerts = @(
    'Storage.Blob_OpenACL.Sensitive'
    'KV_UnusualAccessSuspiciousIP'
    'SQL.DB_PotentialSqlInjection'
)

do {
    $count = $count + 1
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null

        # Microsoft.Security/pricings is a subscription-level resource. Standard is
        # the documented enabled pricing tier for Defender for Cloud plans.
        $pricingResources = @(Get-AzResource -ResourceType 'Microsoft.Security/pricings' -ExpandProperties -ErrorAction Stop)
        if ($pricingResources.Count -eq 0) {
            throw "No Microsoft.Security/pricings resources were returned for subscription '$sub'."
        }

        $missingPlans = [System.Collections.Generic.List[string]]::new()
        $nonStandardPlans = [System.Collections.Generic.List[string]]::new()
        foreach ($planName in $requiredPlans) {
            $matches = @($pricingResources | Where-Object { $_.Name -ceq $planName })
            if ($matches.Count -eq 0) {
                [void]$missingPlans.Add($planName)
                continue
            }

            $standardMatch = $matches | Where-Object {
                $_.Properties -and $_.Properties.pricingTier -ceq 'Standard'
            }
            if (-not $standardMatch) {
                $tiers = (($matches | ForEach-Object { [string]$_.Properties.pricingTier }) -join ', ')
                [void]$nonStandardPlans.Add("$planName (pricingTier=$tiers)")
            }
        }

        if ($missingPlans.Count -gt 0 -or $nonStandardPlans.Count -gt 0) {
            $details = @()
            if ($missingPlans.Count -gt 0) { $details += "missing plans: $($missingPlans -join ', ')" }
            if ($nonStandardPlans.Count -gt 0) { $details += "plans not Standard: $($nonStandardPlans -join '; ')" }
            throw "Defender workload plans are not enabled as required: $($details -join ' | ')."
        }

        # The documented Defender for Cloud subscription alerts endpoint returns
        # alert objects whose exact detection identifier is properties.alertType.
        $alertPath = "/subscriptions/$sub/providers/Microsoft.Security/alerts?api-version=2022-01-01"
        $alertResponse = Invoke-AzRestMethod -Path $alertPath -Method GET -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($alertResponse.Content)) {
            throw "The Defender for Cloud alerts API returned an empty response for subscription '$sub'."
        }

        $alertDocument = $alertResponse.Content | ConvertFrom-Json -ErrorAction Stop
        $alerts = @($alertDocument.value)
        if ($alerts.Count -eq 0) {
            throw "The Defender for Cloud alerts API returned zero alerts; required sample alerts cannot be proven."
        }

        $alertTypes = @($alerts | ForEach-Object {
            if ($null -ne $_.properties -and $null -ne $_.properties.alertType) { [string]$_.properties.alertType }
        } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        $missingAlerts = @($requiredAlerts | Where-Object { $alertTypes -cnotcontains $_ })
        if ($missingAlerts.Count -gt 0) {
            throw "Required Defender sample alert type string(s) were not returned by the subscription alerts API: $($missingAlerts -join ', '). Returned alertType count: $($alertTypes.Count)."
        }

        $found = $true
        $message = @{
            Status  = "Succeeded"
            Message = "Defender for Storage, Key Vault, and SQL are Standard in subscription '$sub'; exact sample alert types Storage.Blob_OpenACL.Sensitive, KV_UnusualAccessSuspiciousIP, and SQL.DB_PotentialSqlInjection were found. Deployment '$DID' was evaluated."
        } | ConvertTo-Json -Depth 10 -Compress
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $message
        }) -Clobber
    }
    catch {
        $message = @{
            Status  = "Failed"
            Message = "Challenge 3 validation failed on attempt $count of 3 for subscription '$sub' (deployment '$DID'): $($_.Exception.Message)"
        } | ConvertTo-Json -Depth 10 -Compress
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $message
        }) -Clobber
        if ($count -lt 3) { Start-Sleep -Seconds 10 }
    }
} while ($count -lt 3 -and -not $found)

# Post-loop fallback: always provide a final structured response after all attempts fail.
if (-not $found) {
    $message = @{
        Status  = "Failed"
        Message = "Challenge 3 validation failed: required Defender plans and exact sample alert strings were not proven in subscription '$sub' after 3 attempts (deployment '$DID')."
    } | ConvertTo-Json -Depth 10 -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $message
    }) -Clobber
}
