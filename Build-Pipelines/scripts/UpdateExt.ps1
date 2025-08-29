Param(
    [Parameter(Mandatory = $true)]
    [string] $aadTenantId = "",
    [Parameter(Mandatory = $true)]
    [string] $environmentName = "",
    [switch] $globalExt,
    [switch] $scheduleBCUpdate,
    [switch] $useEnvironmentUpdateWindow = $false
)
Write-Host $aadTenantId
Write-Host $environmentName
Write-Host $globalExt
Write-Host $scheduleBCUpdate

$applicationFamily = "BusinessCentral"
$apiVersion = "v2.6"
$ignoreUpgradeWindow = -not $useEnvironmentUpdateWindow
$OutPath = "$($PSScriptRoot)\bcSaasCustomers.json"
$bcSaasCustomers = $env:bcSaasCustomers

$response = Invoke-RestMethod -Uri $bcSaasCustomers -UseBasicParsing -ContentType "application/json" -OutFile $OutPath
$tenants = Get-Content $OutPath -raw | Out-String | ConvertFrom-Json
$refreshToken = $tenants.value.where({ $_.tenantId -eq "$aadTenantId" }).refreshToken
$authContext = New-BcAuthContext -tenantID $aadTenantId -refreshToken $refreshToken

$Log = "Update environment $($environmentName)."
Write-Host $Log

# update global ext.
if ($globalExt.IsPresent) {
    $Log = "Update global apps on $($environmentName)."
    Write-Host $Log
    $bearerAuthValue = "Bearer $($authContext.AccessToken)"
    $headers = @{ "Authorization" = $bearerAuthValue }
    #Get availableupdates for global apps
    try {
        $publishedApps = (Invoke-RestMethod -Method Get -UseBasicParsing -Uri "https://api.businesscentral.dynamics.com/admin/$apiVersion/applications/$applicationFamily/environments/$environmentName/apps/availableUpdates" -Headers $headers).Value
    }
    catch {
        Write-Host $_.Exception.Message
    }
    #filter on non Microsoft apps
    $Partners = $publishedApps | Where-Object { $_.publisher -ne "Microsoft" }
    #Write-Host $Partners
    foreach ($app in $Partners) {
        Write-Host "Updating $($app.appId) to version $($app.version) on $($environmentName)"
        $authContext = Renew-BcAuthContext -bcAuthContext $authContext
        $bearerAuthValue = "Bearer $($authContext.AccessToken)"
        $headers = @{ "Authorization" = $bearerAuthValue }
        <#
    { 
      "useEnvironmentUpdateWindow": false/true, // If set to true, the operation will be executed only in the environment update window. It will appear as "scheduled" before it runs in the window.
      "targetVersion": "1.2.3.4", // Always required. There's no option to update to the latest. You have to first do a "availableAppUpdates", call then use the version here.
      "allowPreviewVersion": false/true,  
      "installOrUpdateNeededDependencies": false/true, // Value indicating whether any other app dependencies should be installed or updated; otherwise, information about missing app dependencies will be returned as error details
    }
    #>
        $body = @{ "useEnvironmentUpdateWindow" = $useEnvironmentUpdateWindow }
        $body += @{ "targetVersion" = "$($app.version)" } 
        $body += @{ "installOrUpdateNeededDependencies" = $true } 
        Write-Host ($body | ConvertTo-Json)
        try {
            $operation = Invoke-RestMethod -Method Post -UseBasicParsing -Uri "https://api.businesscentral.dynamics.com/admin/$apiVersion/applications/BusinessCentral/environments/$environmentName/apps/$($app.appId)/Update" -Headers $headers -ContentType "application/json" -Body ($body | ConvertTo-Json)
        }
        catch {
            Write-Host $_.Exception.Message
        }
        Write-Host $operation
    }
}

# update BC version
if ($scheduleBCUpdate.IsPresent) {
    $ScheduledUpgrade = Get-BcEnvironmentScheduledUpgrade -bcAuthContext $authContext -environment $environmentName
    if ($ScheduledUpgrade) {
        $UpdateWindow = Get-BcEnvironmentUpdateWindow  -bcAuthContext $authContext -environment $environmentName
        Reschedule-BcEnvironmentUpgrade  -bcAuthContext $authContext -environment $environmentName -runOn $UpdateWindow.preferredStartTimeUtc -ignoreUpgradeWindow $ignoreUpgradeWindow
        #$dateTime = (Get-Date).AddMinutes(1)
        #Reschedule-BcEnvironmentUpgrade  -bcAuthContext $authContext -environment $environmentName -runOn $dateTime -ignoreUpgradeWindow $true
    }
    else {
        $Log = "Environment $($newEnvironmentName) is up to date."
        Write-Host $Log    
    }
}
