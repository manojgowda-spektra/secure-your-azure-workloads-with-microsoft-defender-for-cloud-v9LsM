Param (
    [Parameter(Mandatory = $true)]
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

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append

[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"

# The jump box is an access aid, not a lab target. ARM owns the asclab workload and the
# deployment script owns the registry import and the AKS deployment. This script only
# publishes the lab credentials, sets up VM Shadow and installs the desktop tooling, so it
# finishes in minutes and never approaches the Custom Script Extension's 90 minute limit.

Function CreateCredFile($AzureUserName, $AzurePassword, $AzureTenantID, $AzureSubscriptionID, $DeploymentID)
{
    $WebClient = New-Object System.Net.WebClient
    New-Item -ItemType directory -Path C:\LabFiles -Force

    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/AzureCreds.txt","C:\LabFiles\AzureCreds.txt")
    $WebClient.DownloadFile("https://experienceazure.blob.core.windows.net/templates/cloudlabs-common/AzureCreds.ps1","C:\LabFiles\AzureCreds.ps1")

    (Get-Content -Path "C:\LabFiles\AzureCreds.txt") |
        ForEach-Object {
            $_ -Replace "AzureUserNameValue", "$AzureUserName" `
               -Replace "AzurePasswordValue", "$AzurePassword" `
               -Replace "AzureTenantIDValue", "$AzureTenantID" `
               -Replace "AzureSubscriptionIDValue", "$AzureSubscriptionID" `
               -Replace "DeploymentIDValue", "$DeploymentID"
        } | Set-Content -Path "C:\LabFiles\AzureCreds.txt"

    (Get-Content -Path "C:\LabFiles\AzureCreds.ps1") |
        ForEach-Object {
            $_ -Replace "AzureUserNameValue", "$AzureUserName" `
               -Replace "AzurePasswordValue", "$AzurePassword" `
               -Replace "AzureTenantIDValue", "$AzureTenantID" `
               -Replace "AzureSubscriptionIDValue", "$AzureSubscriptionID" `
               -Replace "DeploymentIDValue", "$DeploymentID"
        } | Set-Content -Path "C:\LabFiles\AzureCreds.ps1"

    Copy-Item "C:\LabFiles\AzureCreds.txt" -Destination "C:\Users\Public\Desktop"
}

CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID

Function updateVMShadowFile
{
    # Replace vmAdminUsernameValue with VM Admin UserName in script content
    $drivepath = "C:\Users\Public\Documents"
    if (Test-Path "$drivepath\Shadow.ps1") {
        (Get-Content -Path "$drivepath\Shadow.ps1") |
            ForEach-Object {
                $_ -Replace "vmAdminUsernameValue", "$vmAdminUsername"
            } | Set-Content -Path "$drivepath\Shadow.ps1"
    }

    # Update trainer user password
    if ($trainerUserName -and $trainerUserPassword) {
        net user $trainerUserName $trainerUserPassword
    }
}

updateVMShadowFile

# Workload reference for the learner. Names are derived the same way the ARM template
# derives them, from the whole deployment id, so the two cannot drift.
Function WriteWorkloadInventory
{
    $suffix = "$DeploymentID".ToLowerInvariant()
    @(
        "Contoso Defender for Cloud workload",
        "",
        "Everything below is created by the deployment and has already been assessed by",
        "Defender for Cloud before your session begins. Do not create any of it.",
        "",
        "Windows VMs       : asclab-win (unpatched), asclab-win2 (patched control)",
        "Linux VM          : asclab-linux (unpatched)",
        "Storage account   : asclabsa$suffix",
        "Public container  : asclab-public-container",
        "Key Vault         : asclab-kv$suffix",
        "SQL server        : asclab-sql$suffix / asclab-db",
        "Container registry: asclabcr$suffix",
        "AKS cluster       : asclab-aks",
        "Vulnerable image  : contoso-vulnerable/aspnet-core:2.1",
        "",
        "The jump box is an access aid only. All lab work is done in the Azure portal."
    ) | Set-Content -Path "C:\LabFiles\Workload-Inventory.txt" -Encoding UTF8

    Copy-Item "C:\LabFiles\Workload-Inventory.txt" -Destination "C:\Users\Public\Desktop" -Force -ErrorAction SilentlyContinue
}

WriteWorkloadInventory

# Install Chocolatey if not already installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Install Visual Studio Code and Git
choco install vscode git -y

Start-Sleep -Seconds 10

Stop-Transcript
