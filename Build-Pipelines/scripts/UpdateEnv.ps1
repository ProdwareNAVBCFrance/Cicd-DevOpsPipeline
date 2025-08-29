Param(
    [Parameter(Mandatory = $false)]
    [string] $aadTenantId = "",
    [Parameter(Mandatory = $false)]
    [string] $newEnvironmentName = "",
    [Parameter(Mandatory = $false)]
    [string] $environmentName = ""
)
Write-Host $aadTenantId
Write-Host $newEnvironmentName
Write-Host $environmentName


$aadAppRedirectUri = "http://localhost"                   # partner's AAD app redirect URI
$OutPath = "$($PSScriptRoot)\bcSaasCustomers.json"
$bcSaasCustomers = $env:bcSaasCustomers

$response = Invoke-RestMethod -Uri $bcSaasCustomers -UseBasicParsing -ContentType "application/json" -OutFile $OutPath
$tenants = Get-Content $OutPath -raw | Out-String | ConvertFrom-Json
$refreshToken = $tenants.value.where({ $_.tenantId -eq "$aadTenantId" }).refreshToken
$authContext = New-BcAuthContext -tenantID $aadTenantId -refreshToken $refreshToken

$LogCreateNewSandbox = "Create new environment $($newEnvironmentName) type Sandbox from copy of $($environmentName)."
Write-Host $LogCreateNewSandbox

# copy environment
# switch true delete the previous environment if present
Copy-BcEnvironment -bcAuthContext $authContext -environment $newEnvironmentName -sourceEnvironment $environmentName -force:$true -doNotWait:$false
# list all databse usage of all environments
Get-BcEnvironmentUsedStorage -bcAuthContext $authContext


