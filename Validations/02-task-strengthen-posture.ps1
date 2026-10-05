using namespace System.Net

# Note: $sub (subscription id) and $DID (deployment id) are injected by the platform.
$rg = "asclab"
$count = 0
$found = $false

function Get-PropertyValue {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)] [string] $Name
    )
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

do {
    $count = $count + 1
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null

        $storage = @(Get-AzStorageAccount -ResourceGroupName $rg -ErrorAction Stop | Where-Object { $_.StorageAccountName -like 'asclabsa*' })
        if ($storage.Count -ne 1) { throw "Expected exactly one storage account named asclabsa*, found $($storage.Count)." }
        $sa = $storage[0]
        $saPublic = [string](Get-PropertyValue -Object $sa -Name 'PublicNetworkAccess')
        $saTls = [string](Get-PropertyValue -Object $sa -Name 'MinimumTlsVersion')
        $saHttps = Get-PropertyValue -Object $sa -Name 'EnableHttpsTrafficOnly'
        if ($saPublic -notin @('Disabled','disabled')) { throw "Storage account '$($sa.StorageAccountName)' public network access is '$saPublic', not Disabled." }
        if ($saTls -ne 'TLS1_2') { throw "Storage account '$($sa.StorageAccountName)' MinimumTlsVersion is '$saTls', not TLS1_2." }
        if ($saHttps -ne $true) { throw "Storage account '$($sa.StorageAccountName)' HTTPS-only access is not enabled." }

        $sqlResources = @(Get-AzResource -ResourceGroupName $rg -ResourceType 'Microsoft.Sql/servers' -ExpandProperties -ErrorAction Stop | Where-Object { $_.Name -like 'asclab-sql*' })
        if ($sqlResources.Count -ne 1) { throw "Expected exactly one SQL server named asclab-sql*, found $($sqlResources.Count)." }
        $sql = $sqlResources[0]
        $sqlPublic = [string](Get-PropertyValue -Object $sql.Properties -Name 'publicNetworkAccess')
        if ($sqlPublic -notin @('Disabled','disabled')) { throw "SQL server '$($sql.Name)' publicNetworkAccess is '$sqlPublic', not Disabled." }
        $firewallRules = @(Get-AzSqlServerFirewallRule -ResourceGroupName $rg -ServerName $sql.Name -ErrorAction Stop)
        $internetRules = @($firewallRules | Where-Object { $_.StartIpAddress -eq '0.0.0.0' -and $_.EndIpAddress -eq '0.0.0.0' })
        if ($internetRules.Count -gt 0) { throw "SQL server '$($sql.Name)' still has an internet-wide firewall rule: $($internetRules[0].FirewallRuleName)." }

        $vaultResources = @(Get-AzResource -ResourceGroupName $rg -ResourceType 'Microsoft.KeyVault/vaults' -ExpandProperties -ErrorAction Stop | Where-Object { $_.Name -like 'asclab-kv*' })
        if ($vaultResources.Count -ne 1) { throw "Expected exactly one Key Vault named asclab-kv*, found $($vaultResources.Count)." }
        $vault = $vaultResources[0]
        $retention = Get-PropertyValue -Object $vault.Properties -Name 'softDeleteRetentionInDays'
        $softDelete = Get-PropertyValue -Object $vault.Properties -Name 'enableSoftDelete'
        if (($softDelete -ne $true) -and ($null -eq $retention -or [int]$retention -le 0)) {
            throw "Key Vault '$($vault.Name)' does not expose enabled soft delete or a positive soft-delete retention period."
        }

        $standardPath = "/subscriptions/$sub/providers/Microsoft.Security/securityStandards?api-version=2024-08-01"
        $standardResponse = Invoke-AzRestMethod -Path $standardPath -Method GET -ErrorAction Stop
        if ([int]$standardResponse.StatusCode -lt 200 -or [int]$standardResponse.StatusCode -ge 300) {
            throw "Microsoft.Security securityStandards API returned HTTP $($standardResponse.StatusCode)."
        }
        if ([string]::IsNullOrWhiteSpace($standardResponse.Content)) { throw 'The securityStandards API returned an empty response.' }
        $standardDocument = $standardResponse.Content | ConvertFrom-Json -ErrorAction Stop
        $standards = @($standardDocument.value | Where-Object { (Get-PropertyValue -Object $_.properties -Name 'displayName') -eq 'Contoso Secure Workload Baseline' })
        if ($standards.Count -ne 1) { throw "Expected exactly one custom standard named 'Contoso Secure Workload Baseline', found $($standards.Count)." }
        $standard = $standards[0]
        $assessments = @(Get-PropertyValue -Object $standard.properties -Name 'assessments')
        if ($assessments.Count -ne 1) { throw "Custom standard 'Contoso Secure Workload Baseline' must contain exactly one assessment, found $($assessments.Count)." }
        $assessmentKey = [string](Get-PropertyValue -Object $assessments[0] -Name 'assessmentKey')
        $requiredPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/2a1a9cdf-e04d-429a-8416-3bfb72a1b26f'
        $requiredPolicyGuid = '2a1a9cdf-e04d-429a-8416-3bfb72a1b26f'
        $normalizedAssessment = $assessmentKey.Trim().ToLowerInvariant()
        if ($normalizedAssessment -ne $requiredPolicyId.ToLowerInvariant() -and $normalizedAssessment -ne $requiredPolicyGuid) {
            throw "Custom standard assessment key is '$assessmentKey', not built-in policy definition ID '$requiredPolicyId'."
        }

        $found = $true
        $message = @{
            Status  = "Succeeded"
            Message = "Challenge 2 passed in resource group '$rg': storage '$($sa.StorageAccountName)' is Disabled/public-network restricted with TLS1_2 and HTTPS-only; SQL '$($sql.Name)' has publicNetworkAccess Disabled and no 0.0.0.0 firewall rule; Key Vault '$($vault.Name)' has soft delete; standard 'Contoso Secure Workload Baseline' contains exactly built-in policy definition '2a1a9cdf-e04d-429a-8416-3bfb72a1b26f'."
        } | ConvertTo-Json -Depth 10 -Compress
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $message
        }) -Clobber
    }
    catch {
        $message = @{
            Status  = "Failed"
            Message = "Challenge 2 state check failed on attempt $count of 3: $($_.Exception.Message)"
        } | ConvertTo-Json -Depth 10 -Compress
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $message
        }) -Clobber
        if ($count -lt 3) { Start-Sleep -Seconds 10 }
    }
} while ($count -lt 3 -and -not $found)

if (-not $found) {
    $message = @{
        Status  = "Failed"
        Message = "Challenge 2 resources or required custom standard were not in the prescribed state in resource group '$rg' after 3 attempts."
    } | ConvertTo-Json -Depth 10 -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $message
    }) -Clobber
}
