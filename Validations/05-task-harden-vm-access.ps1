using namespace System.Net

# Note: $sub (subscription id) and $DID (deployment id) are injected by the platform.
$rg = "asclab"
$count = 0
$found = $false
$failure = "JIT validation has not run."

function Get-PropertyValue {
    param(
        [Parameter(Mandatory = $true)] $Object,
        [Parameter(Mandatory = $true)] [string] $Name
    )

    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function Test-AnySource {
    param([Parameter(Mandatory = $true)] $Port)

    # The Defender for Cloud API represents portal "Any" as "*" in
    # allowedSourceAddressPrefix. Accept the documented portal label as well
    # when returned by a compatible API surface, but fail closed otherwise.
    $single = Get-PropertyValue -Object $Port -Name "allowedSourceAddressPrefix"
    if ($null -ne $single -and ([string]$single -eq "*" -or [string]$single -eq "Any")) {
        return $true
    }

    $many = Get-PropertyValue -Object $Port -Name "allowedSourceAddressPrefixes"
    if ($null -ne $many) {
        $values = @($many | ForEach-Object { [string]$_ })
        return ($values.Count -eq 1 -and ($values[0] -eq "*" -or $values[0] -eq "Any"))
    }

    return $false
}

function Find-VMPolicy {
    param(
        [Parameter(Mandatory = $true)] $VirtualMachines,
        [Parameter(Mandatory = $true)] [string] $VmName
    )

    $matches = @($VirtualMachines | Where-Object {
        $id = [string](Get-PropertyValue -Object $_ -Name "id")
        $id -match "/virtualMachines/$([regex]::Escape($VmName))$"
    })
    if ($matches.Count -ne 1) {
        throw "Expected exactly one JIT virtualMachines entry for '$VmName'; found $($matches.Count)."
    }
    return $matches[0]
}

do {
    $count = $count + 1
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null

        $uri = "/subscriptions/$sub/providers/Microsoft.Security/locations/eastus/jitNetworkAccessPolicies/default?api-version=2020-01-01"
        $response = Invoke-AzRestMethod -Method GET -Path $uri -ErrorAction Stop
        if ($null -eq $response -or [string]::IsNullOrWhiteSpace($response.Content)) {
            throw "JIT policy REST response was empty for subscription '$sub', location 'eastus'."
        }

        $document = $response.Content | ConvertFrom-Json -ErrorAction Stop
        $properties = Get-PropertyValue -Object $document -Name "properties"
        $virtualMachines = Get-PropertyValue -Object $properties -Name "virtualMachines"
        if ($null -eq $virtualMachines) {
            throw "JIT policy response has no properties.virtualMachines collection."
        }

        $win = Find-VMPolicy -VirtualMachines $virtualMachines -VmName "asclab-win"
        $linux = Find-VMPolicy -VirtualMachines $virtualMachines -VmName "asclab-linux"

        $winPorts = @(Get-PropertyValue -Object $win -Name "ports")
        $linuxPorts = @(Get-PropertyValue -Object $linux -Name "ports")
        if ($winPorts.Count -ne 1) { throw "JIT policy for 'asclab-win' must contain exactly one port rule (3389); found $($winPorts.Count)." }
        if ($linuxPorts.Count -ne 1) { throw "JIT policy for 'asclab-linux' must contain exactly one port rule (22); found $($linuxPorts.Count)." }

        $winPort = $winPorts[0]
        $linuxPort = $linuxPorts[0]
        $winNumber = [int](Get-PropertyValue -Object $winPort -Name "number")
        $linuxNumber = [int](Get-PropertyValue -Object $linuxPort -Name "number")
        if ($winNumber -ne 3389) { throw "JIT policy for 'asclab-win' has port $winNumber; expected 3389." }
        if ($linuxNumber -ne 22) { throw "JIT policy for 'asclab-linux' has port $linuxNumber; expected 22." }

        $winDuration = [string](Get-PropertyValue -Object $winPort -Name "maxRequestAccessDuration")
        $linuxDuration = [string](Get-PropertyValue -Object $linuxPort -Name "maxRequestAccessDuration")
        if ($winDuration -ne "PT3H") { throw "JIT port 3389 on 'asclab-win' has maxRequestAccessDuration '$winDuration'; expected literal 'PT3H'." }
        if ($linuxDuration -ne "PT3H") { throw "JIT port 22 on 'asclab-linux' has maxRequestAccessDuration '$linuxDuration'; expected literal 'PT3H'." }
        if (-not (Test-AnySource -Port $winPort)) { throw "JIT port 3389 on 'asclab-win' is not configured with allowed source 'Any'." }
        if (-not (Test-AnySource -Port $linuxPort)) { throw "JIT port 22 on 'asclab-linux' is not configured with allowed source 'Any'." }

        $found = $true
        $message = @{
            Status  = "Succeeded"
            Message = "JIT policy in subscription '$sub' (eastus) contains exactly one RDP rule for asclab-win on port 3389 and one SSH rule for asclab-linux on port 22; both have maxRequestAccessDuration PT3H and allowed source Any."
        } | ConvertTo-Json -Compress
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [HttpStatusCode]::OK; Body = $message }) -Clobber
    }
    catch {
        $failure = $_.Exception.Message
        $message = @{
            Status  = "Failed"
            Message = "JIT validation failed on attempt $count of 3 for workload resource group '$rg': $failure"
        } | ConvertTo-Json -Compress
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [HttpStatusCode]::OK; Body = $message }) -Clobber
        if (-not $found) { Start-Sleep -Seconds 10 }
    }
} while ($count -lt 3 -and -not $found)

if (-not $found) {
    $message = @{
        Status  = "Failed"
        Message = "JIT policies for asclab-win (3389) and asclab-linux (22) were not validated after 3 attempts in workload resource group '$rg'. Last error: $failure"
    } | ConvertTo-Json -Compress
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ StatusCode = [HttpStatusCode]::OK; Body = $message }) -Clobber
}
