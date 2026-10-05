using namespace System.Net

# Note: $sub (subscription id) and $DID (deployment id) are injected by the platform.
$rg = "asclab"
$automationName = "war-contoso-high-severity-recommendations"
$logicAppName = "la-contoso-defender-recommendations"
$count = 0
$found = $false
$lastFailure = "No validation attempt completed."

do {
    $count = $count + 1
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null

        $automation = Get-AzResource `
            -ResourceId "/subscriptions/$sub/providers/Microsoft.Security/automations/$automationName" `
            -ExpandProperties -ErrorAction Stop
        if (-not $automation) {
            throw "Workflow automation '$automationName' was not found at subscription scope."
        }

        $automationProperties = $automation.Properties
        if (-not $automationProperties) {
            throw "Workflow automation '$automationName' returned no properties."
        }
        if ([bool]$automationProperties.isEnabled -ne $true) {
            throw "Workflow automation '$automationName' is not enabled."
        }

        $sources = @($automationProperties.sources)
        if ($sources.Count -ne 1 -or [string]$sources[0].eventSource -ne "Assessments") {
            throw "Workflow automation '$automationName' must have exactly one source with eventSource 'Assessments' (recommendations only); alerts or additional sources are not permitted."
        }

        $actions = @($automationProperties.actions)
        if ($actions.Count -ne 1) {
            throw "Workflow automation '$automationName' must have exactly one action; found $($actions.Count)."
        }
        if ([string]$actions[0].actionType -ne "LogicApp") {
            throw "Workflow automation '$automationName' action type is '$($actions[0].actionType)', not 'LogicApp'."
        }

        $logicApp = Get-AzResource `
            -ResourceGroupName $rg `
            -ResourceType "Microsoft.Logic/workflows" `
            -Name $logicAppName `
            -ExpandProperties -ErrorAction Stop
        if (-not $logicApp) {
            throw "Logic App '$logicAppName' was not found in resource group '$rg'."
        }

        $expectedLogicAppId = $logicApp.ResourceId.ToLowerInvariant()
        $configuredLogicAppId = ([string]$actions[0].logicAppResourceId).ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($configuredLogicAppId) -or $configuredLogicAppId -ne $expectedLogicAppId) {
            throw "Workflow automation '$automationName' targets '$configuredLogicAppId'; expected Logic App '$logicAppName' resource ID '$($logicApp.ResourceId)'."
        }

        $definition = $logicApp.Properties.definition
        if (-not $definition) {
            throw "Logic App '$logicAppName' returned no workflow definition."
        }
        $triggers = @($definition.triggers.PSObject.Properties)
        if ($triggers.Count -ne 1) {
            throw "Logic App '$logicAppName' must have exactly one trigger; found $($triggers.Count)."
        }
        $trigger = $triggers[0].Value
        if ([string]$trigger.type -ne "Request" -or [string]$trigger.kind -ne "Http") {
            throw "Logic App '$logicAppName' trigger must be the HTTP request trigger (type 'Request', kind 'Http'); found type '$($trigger.type)', kind '$($trigger.kind)'."
        }

        $workflowActions = @($definition.actions.PSObject.Properties)
        if ($workflowActions.Count -ne 1) {
            throw "Logic App '$logicAppName' must have exactly one action; found $($workflowActions.Count)."
        }
        $compose = $workflowActions[0]
        if ($compose.Name -ne "Compose" -or [string]$compose.Value.type -ne "Compose") {
            throw "Logic App '$logicAppName' sole action must be named 'Compose' and have type 'Compose'; found '$($compose.Name)' with type '$($compose.Value.type)'."
        }
        if ($null -eq $compose.Value.inputs) {
            throw "Logic App '$logicAppName' Compose action has no recommendation-payload input."
        }

        $attackPathQuery = @"
securityresources
| where type =~ 'microsoft.security/assessments'
| extend displayName = tostring(properties.displayName), statusCode = tostring(properties.status.code), categories = tostring(properties.metadata.categories)
| where categories has 'AttackPath' or displayName has 'attack path'
| project name, displayName, statusCode, categories
"@
        $attackPathRecommendations = @(Search-AzGraph -Query $attackPathQuery -Subscription $sub -First 100 -ErrorAction Stop)
        if ($attackPathRecommendations.Count -eq 0) {
            throw "No cloud-visible Defender attack-path recommendation was returned by Azure Resource Graph."
        }
        $healthyAttackPath = @($attackPathRecommendations | Where-Object { [string]$_.statusCode -ieq "Healthy" })
        if ($healthyAttackPath.Count -eq 0) {
            $seen = (($attackPathRecommendations | ForEach-Object { "$($_.displayName): $($_.statusCode)" }) -join "; ")
            throw "No attack-path recommendation is healthy; observed: $seen"
        }

        $found = $true
        $healthyNames = (($healthyAttackPath | ForEach-Object { $_.displayName }) -join "; ")
        $successMessage = "Enabled recommendation-only workflow automation '$automationName' targets Logic App '$logicAppName'; the Logic App has one HTTP request trigger and one Compose action; healthy attack-path recommendation(s): $healthyNames."
        $message = @{
            Status  = "Succeeded"
            Message = $successMessage
        } | ConvertTo-Json -Compress -Depth 12
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $message
        }) -Clobber
    }
    catch {
        $lastFailure = "Attempt $count of 3 failed: $($_.Exception.Message)"
        $message = @{
            Status  = "Failed"
            Message = $lastFailure
        } | ConvertTo-Json -Compress -Depth 12
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::OK
            Body       = $message
        }) -Clobber
        if (-not $found -and $count -lt 3) {
            Start-Sleep -Seconds 10
        }
    }
} while ($count -lt 3 -and -not $found)

if (-not $found) {
    $message = @{
        Status  = "Failed"
        Message = "Challenge 6 validation failed after 3 attempts in resource group '$rg'. Last error: $lastFailure"
    } | ConvertTo-Json -Compress -Depth 12
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $message
    }) -Clobber
}