Param(
    [Parameter(Mandatory = $true)]
    [string] $aadTenantId = "",
    [Parameter(Mandatory = $true)]
    [string] $environmentName = "",
    [switch] $globalExt,
    [switch] $scheduleBCUpdate
)
Write-Host $aadTenantId
Write-Host $environmentName
Write-Host $globalExt
Write-Host $scheduleBCUpdate


$OutPath = "$($PSScriptRoot)\bcSaasCustomers.json"

$response = Invoke-RestMethod -Uri "https://frbc.blob.core.windows.net/bcsaascustomers/bcSaasCustomers.json?sp=r&st=2024-01-16T10:14:40Z&se=2030-01-01T18:14:40Z&spr=https&sv=2022-11-02&sr=b&sig=LcwDV1NdSlNJmKUgjEpRVPP98k%2Fa%2BDvNB52elt5632s%3D" -UseBasicParsing -ContentType "application/json" -OutFile $OutPath
$tenants = Get-Content $OutPath -raw | Out-String | ConvertFrom-Json
$refreshToken = $tenants.value.where({ $_.tenantId -eq "$aadTenantId" }).refreshToken
$authContext = New-BcAuthContext -tenantID $aadTenantId -refreshToken $refreshToken

$LogCreateNewSandbox = "Create new environment $($newEnvironmentName) type Sandbox from copy of $($environmentName)."
Write-Host $LogCreateNewSandbox

# update global ext.
if ($globalExt.IsPresent) {
}

# update BC version
if ($scheduleBCUpdate.IsPresent) {
    $ScheduledUpgrade = Get-BcEnvironmentScheduledUpgrade -bcAuthContext $authContext -environment $environmentName
    write-host $ScheduledUpgrade.preferredStartTime
    Reschedule-BcEnvironmentUpgrade  -bcAuthContext $authContext -environment $environmentName -runOn $ScheduledUpgrade.preferredStartTime -ignoreUpgradeWindow $true
}
