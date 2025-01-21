Param(
    [Parameter(Mandatory=$false)]
    [string] $aadTenantId = "",
    [Parameter(Mandatory=$false)]
    [string] $newEnvironmentName = "",
    [Parameter(Mandatory=$false)]
    [string] $environmentName = ""
)
Write-Host $aadTenantId
Write-Host $newEnvironmentName
Write-Host $environmentName


$aadAppRedirectUri = "http://localhost"                   # partner's AAD app redirect URI
$OutPath = "$($PSScriptRoot)\bcSaasCustomers.json"

$response = Invoke-RestMethod -Uri "https://frbc.blob.core.windows.net/bcsaascustomers/bcSaasCustomers.json?sp=r&st=2024-01-16T10:14:40Z&se=2030-01-01T18:14:40Z&spr=https&sv=2022-11-02&sr=b&sig=LcwDV1NdSlNJmKUgjEpRVPP98k%2Fa%2BDvNB52elt5632s%3D" -UseBasicParsing -ContentType "application/json" -OutFile $OutPath
$tenants = Get-Content $OutPath -raw | Out-String | ConvertFrom-Json
$refreshToken = $tenants.value.where({$_.tenantId -eq "$aadTenantId"}).refreshToken
$authContext = New-BcAuthContext -tenantID $aadTenantId -refreshToken $refreshToken

$LogCreateNewSandbox = "Create new environment $($newEnvironmentName) type Sandbox from copy of $($environmentName)."
Write-Host $LogCreateNewSandbox

# copy environment
# switch true delete the previous environment if present
Copy-BcEnvironment -bcAuthContext $authContext -environment $newEnvironmentName -sourceEnvironment $environmentName -force:$true -doNotWait:$false
# list all databse usage of all environments
Get-BcEnvironmentUsedStorage -bcAuthContext $authContext


