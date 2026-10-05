using namespace System.Net

# Note: $sub (subscription id) and $DID (deployment id) are injected by the platform.
# This validator runs with the CloudLabs validation identity.
$count = 0
$found = $false
$rg = "asclab"

function Get-PropertyValue {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name
    )

    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Test-EnabledExtension {
    param(
        [Parameter(Mandatory = $true)]$Plan,
        [Parameter(Mandatory = $true)][string]$ExtensionName
    )

    $extensions = Get-PropertyValue -Object $Plan -Name 'extensions'
    if ($null -eq $extensions) {
        return $false
    }

    foreach ($extension in @($extensions)) {
        if ((Get-PropertyValue -Object $extension -Name 'name') -eq $ExtensionName) {
            $enabled = Get-PropertyValue -Object $extension -Name 'isEnabled'
            return ($enabled -eq $true -or "$enabled" -ieq 'true')
        }
    }
    return $false
}

do {
    $count = $count + 1
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null

        # Acquire an ARM token explicitly so the check is authenticated as the
        # platform validation identity before querying Microsoft.Security.
        $null = Get-AzAccessToken -ResourceUrl 'https://management.azure.com/' -ErrorAction Stop

        $path = "/subscriptions/$sub/providers/Microsoft.Security/pricings?api-version=2024-01-01"
        $response = Invoke-AzRestMethod -Path $path -Method GET -ErrorAction Stop
        if ($null -eq $response -or $response.StatusCode -lt 200 -or $response.StatusCode -ge 300) {
            throw "Microsoft.Security pricings returned no successful response."
        }
        if ([string]::IsNullOrWhiteSpace($response.Content)) {
            throw "Microsoft.Security pricings returned an empty response."
        }

        $document = $response.Content | ConvertFrom-Json -ErrorAction Stop
        $pricingItems = @($document.value)
        if ($pricingItems.Count -eq 0) {
            throw "Microsoft.Security pricings returned zero subscription plan records."
        }

        $plans = @{}
        foreach ($item in $pricingItems) {
            $planName = [string]$item.name
            if ([string]::IsNullOrWhiteSpace($planName)) {
                continue
            }
            if ($plans.ContainsKey($planName)) {
                throw "Microsoft.Security pricings returned duplicate records for plan '$planName'."
            }
            $plans[$planName] = $item
        }

        if (-not $plans.ContainsKey('CloudPosture')) {
            throw "Defender CSPM plan record 'CloudPosture' was not returned."
        }
        if (-not $plans.ContainsKey('VirtualMachines')) {
            throw "Defender for Servers plan record 'VirtualMachines' was not returned."
        }

        $cspm = $plans['CloudPosture']
        $servers = $plans['VirtualMachines']
        $cspmProperties = Get-PropertyValue -Object $cspm -Name 'properties'
        $serverProperties = Get-PropertyValue -Object $servers -Name 'properties'
        if ($null -eq $cspmProperties -or $null -eq $serverProperties) {
            throw "One or more Defender plan records omitted the required properties object."
        }

        $cspmTier = [string](Get-PropertyValue -Object $cspmProperties -Name 'pricingTier')
        if ($cspmTier -ine 'Standard') {
            throw "Defender CSPM (CloudPosture) pricingTier is '$cspmTier'; expected 'Standard'."
        }

        $serverTier = [string](Get-PropertyValue -Object $serverProperties -Name 'pricingTier')
        if ($serverTier -ine 'Standard') {
            throw "Defender for Servers (VirtualMachines) pricingTier is '$serverTier'; expected 'Standard'."
        }
        $serverSubPlan = [string](Get-PropertyValue -Object $serverProperties -Name 'subPlan')
        if ($serverSubPlan -ine 'P2') {
            throw "Defender for Servers subPlan is '$serverSubPlan'; expected 'P2' (Plan 2)."
        }

        # Microsoft.Security exposes agentless machine scanning as the
        # AgentlessVmScanning extension on the CloudPosture plan.
        if (-not (Test-EnabledExtension -Plan $cspmProperties -ExtensionName 'AgentlessVmScanning')) {
            throw "Defender CSPM AgentlessVmScanning extension is missing or not enabled."
        }

        $found = $true
        $message = @{
            Status  = 'Succeeded'
            Message = "Subscription '$sub' has Defender CSPM CloudPosture Standard, Defender for Servers VirtualMachines Standard P2, and the AgentlessVmScanning extension enabled."
        } | ConvertTo-Json -Compress
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $message
        }) -Clobber
    }
    catch {
        $message = @{
            Status  = 'Failed'
            Message = "Challenge 1 validation error on subscription '$sub'. Attempt $count of 3. $($_.Exception.Message)"
        } | ConvertTo-Json -Compress
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $message
        }) -Clobber
        if ($count -lt 3) {
            Start-Sleep -Seconds 10
        }
    }
} while ($count -lt 3 -and -not $found)

if (-not $found) {
    $message = @{
        Status  = 'Failed'
        Message = "Challenge 1 validation failed closed: Defender CSPM, Defender for Servers Plan 2, and AgentlessVmScanning were not all verifiably enabled on subscription '$sub' after 3 attempts."
    } | ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $message
    }) -Clobber
}
