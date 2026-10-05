Param(
    [string]$AzureUserName,
    [string]$AzurePassword,
    [string]$AzureTenantID,
    [string]$AzureSubscriptionID,
    [string]$ODLID,
    [string]$InstallCloudLabsShadow,
    [string]$DeploymentID,
    [string]$vmAdminUsername,
    [string]$vmAdminPassword,
    [string]$trainerUserName,
    [string]$trainerUserPassword
)

$ErrorActionPreference = 'Stop'
$logPath = 'C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt'
New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
Start-Transcript -Path $logPath -Append

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    $labFiles = 'C:\LabFiles'
    New-Item -ItemType Directory -Path $labFiles -Force | Out-Null
    New-Item -ItemType Directory -Path 'C:\Users\Public\Desktop' -Force | Out-Null

    # CloudLabs credential bootstrap. CreateCredFile downloads AzureCreds.txt and
    # AzureCreds.ps1 and publishes the substituted files in the standard locations.
    $commonUrl = 'https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/CloudLabsCommon.ps1'
    $commonPath = Join-Path $labFiles 'CloudLabsCommon.ps1'
    Invoke-WebRequest -Uri $commonUrl -OutFile $commonPath -UseBasicParsing
    . $commonPath
    if (-not (Get-Command CreateCredFile -ErrorAction SilentlyContinue)) {
        throw 'CloudLabs CreateCredFile was not found in CloudLabsCommon.ps1.'
    }
    CreateCredFile -AzureUserName $AzureUserName -AzurePassword $AzurePassword `
        -AzureTenantID $AzureTenantID -AzureSubscriptionID $AzureSubscriptionID `
        -ODLID $ODLID -DeploymentID $DeploymentID

    # VM Shadow instructor account; deliberately not an administrator account.
    if ($InstallCloudLabsShadow -ne 'false' -and $trainerUserName -and $trainerUserPassword) {
        $securePassword = ConvertTo-SecureString $trainerUserPassword -AsPlainText -Force
        if (-not (Get-LocalUser -Name $trainerUserName -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $trainerUserName -Password $securePassword -PasswordNeverExpires `
                -UserMayNotChangePassword -Description 'CloudLabs instructor account for VM Shadow' | Out-Null
        }
        Add-LocalGroupMember -Group 'Remote Desktop Users' -Member $trainerUserName -ErrorAction SilentlyContinue
    }

    if (-not (Get-Command az.exe -ErrorAction SilentlyContinue)) {
        $azMsi = Join-Path $env:TEMP 'azure-cli.msi'
        Invoke-WebRequest -Uri 'https://aka.ms/installazurecliwindows' -OutFile $azMsi -UseBasicParsing
        Start-Process msiexec.exe -ArgumentList "/i `"$azMsi`" /qn /norestart" -Wait -NoNewWindow
        Remove-Item $azMsi -Force -ErrorAction SilentlyContinue
    }
    $az = (Get-Command az.exe -ErrorAction Stop).Source

    # ARM owns the workload. Authenticate only to wait for and verify its state.
    if (-not $AzureUserName -or -not $AzurePassword -or -not $AzureTenantID -or -not $AzureSubscriptionID) {
        throw 'CloudLabs Azure sign-in values are incomplete.'
    }
    & $az login --username $AzureUserName --password $AzurePassword --tenant $AzureTenantID --output none
    & $az account set --subscription $AzureSubscriptionID

    $rg = 'asclab'
    $suffix10 = $DeploymentID.Substring(0, [Math]::Min(10, $DeploymentID.Length)).ToLowerInvariant()
    $suffix12 = $DeploymentID.Substring(0, [Math]::Min(12, $DeploymentID.Length)).ToLowerInvariant()
    $storageName = "asclabsa$suffix10"
    $keyVaultName = "asclab-kv$suffix12"
    $sqlName = "asclab-sql$suffix10"
    $acrName = "asclabcr$suffix10"
    $image = 'contoso-vulnerable/aspnet-core:2.1'
    $sourceImage = 'mcr.microsoft.com/dotnet/core/aspnet:2.1'

    function Get-Tsv([string[]]$Arguments) {
        $value = (& $az @Arguments --output tsv 2>$null | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) { return $null }
        return $value
    }
    function Wait-ForResource([string]$ResourceId, [string]$Label, [int]$TimeoutSeconds = 3600) {
        $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
        do {
            $state = Get-Tsv @('resource','show','--ids',$ResourceId,'--query','properties.provisioningState')
            if ($state -eq 'Succeeded') { Write-Output "$Label is ready."; return }
            if ($state -and $state -in @('Failed','Canceled')) { throw "$Label provisioning state is $state." }
            Start-Sleep -Seconds 15
        } while ((Get-Date) -lt $deadline)
        throw "Timed out waiting for $Label."
    }

    # Poll the ARM-owned resource group and every exact workload resource before
    # allowing the bootstrap to publish completion.
    $rgDeadline = (Get-Date).AddSeconds(3600)
    do {
        $rgState = Get-Tsv @('group','show','--name',$rg,'--query','properties.provisioningState')
        if ($rgState -eq 'Succeeded') { break }
        Start-Sleep -Seconds 15
    } while ((Get-Date) -lt $rgDeadline)
    if ($rgState -ne 'Succeeded') { throw "Timed out waiting for workload resource group $rg." }

    $resources = @(
        @{ Id = (& $az resource show -g $rg -n 'asclab-win' --resource-type 'Microsoft.Compute/virtualMachines' --query id -o tsv); Label = 'asclab-win' },
        @{ Id = (& $az resource show -g $rg -n 'asclab-win2' --resource-type 'Microsoft.Compute/virtualMachines' --query id -o tsv); Label = 'asclab-win2' },
        @{ Id = (& $az resource show -g $rg -n 'asclab-linux' --resource-type 'Microsoft.Compute/virtualMachines' --query id -o tsv); Label = 'asclab-linux' },
        @{ Id = (& $az resource show -g $rg -n $storageName --resource-type 'Microsoft.Storage/storageAccounts' --query id -o tsv); Label = $storageName },
        @{ Id = (& $az resource show -g $rg -n $keyVaultName --resource-type 'Microsoft.KeyVault/vaults' --query id -o tsv); Label = $keyVaultName },
        @{ Id = (& $az resource show -g $rg -n $sqlName --resource-type 'Microsoft.Sql/servers' --query id -o tsv); Label = $sqlName },
        @{ Id = (& $az resource show -g $rg -n $acrName --resource-type 'Microsoft.ContainerRegistry/registries' --query id -o tsv); Label = $acrName },
        @{ Id = (& $az resource show -g $rg -n 'asclab-aks' --resource-type 'Microsoft.ContainerService/managedClusters' --query id -o tsv); Label = 'asclab-aks' }
    )
    foreach ($resource in $resources) {
        if ([string]::IsNullOrWhiteSpace($resource.Id)) { throw "ARM-owned resource $($resource.Label) was not found in $rg." }
        Wait-ForResource $resource.Id $resource.Label
    }

    # ARM normally imports the image. Verify it and use the documented, idempotent
    # registry-side import only if the ARM import was not present.
    $imagePresent = Get-Tsv @('acr','repository','show','--name',$acrName,'--image',$image,'--query','name')
    if ([string]::IsNullOrWhiteSpace($imagePresent)) {
        & $az acr import --name $acrName --source $sourceImage --image $image
        if ($LASTEXITCODE -ne 0) { throw "ACR fallback import failed for $image." }
    }
    $imagePresent = Get-Tsv @('acr','repository','show','--name',$acrName,'--image',$image,'--query','name')
    if ($imagePresent -ne 'contoso-vulnerable/aspnet-core') { throw "Required ACR image $image was not verified." }

    # Wait for AKS control-plane and workload readiness, including the exact image.
    $aksDeadline = (Get-Date).AddSeconds(1800)
    $imageReady = $false
    do {
        $podImages = Get-Tsv @('aks','command','invoke','-g',$rg,'-n','asclab-aks','--command',"kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}'")
        if ($podImages -and $podImages -match [regex]::Escape($image)) { $imageReady = $true; break }
        Start-Sleep -Seconds 20
    } while ((Get-Date) -lt $aksDeadline)
    if (-not $imageReady) { throw "AKS workload did not report the required image $image." }

    @(
        'Contoso Defender for Cloud workload', 'Resource group: asclab',
        "Storage: $storageName", "Key Vault: $keyVaultName", "SQL: $sqlName / asclab-db",
        "ACR image: $acrName.azurecr.io/$image", "Source: $sourceImage", 'AKS: asclab-aks'
    ) | Set-Content -Path (Join-Path $labFiles 'Workload-Inventory.txt') -Encoding UTF8
    $completion = [ordered]@{ status = 'Ready'; resourceGroup = $rg; acrImage = "$acrName.azurecr.io/$image"; completedUtc = (Get-Date).ToUniversalTime().ToString('o') }
    $completion | ConvertTo-Json | Set-Content -Path (Join-Path $labFiles 'CloudLabsBootstrap.completed.json') -Encoding UTF8
    'READY' | Set-Content -Path (Join-Path $labFiles 'CloudLabsBootstrap.completed') -Encoding ASCII
    Write-Output 'CloudLabs bootstrap completed: ARM workload verified and AKS image is ready.'
}
catch {
    Write-Error ("CloudLabs bootstrap failed: " + $_.Exception.Message)
    throw
}
finally {
    Stop-Transcript
}
