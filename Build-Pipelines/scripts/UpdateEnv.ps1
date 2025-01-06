$aadTenantId = {$env:aadTenantId}
$newEnvironmentName = {$env:newEnvironmentName}
$environmentName = {$env:environmentName}

Write-Host $aadTenantId
Write-Host $newEnvironmentName
Write-Host $environmentName


$aadAppRedirectUri = "http://localhost"                   # partner's AAD app redirect URI

$response = Invoke-RestMethod -Uri "https://frbc.blob.core.windows.net/bcsaascustomers/bcSaasCustomers.json?sp=r&st=2024-01-16T10:14:40Z&se=2030-01-01T18:14:40Z&spr=https&sv=2022-11-02&sr=b&sig=LcwDV1NdSlNJmKUgjEpRVPP98k%2Fa%2BDvNB52elt5632s%3D" -UseBasicParsing -ContentType "application/json" -OutFile $OutPath
$tenants = Get-Content $OutPath -raw | Out-String | ConvertFrom-Json
$refreshToken = $tenants.value.where({$_.tenantId -eq "$aadTenantId"}).refreshToken
$authContext = New-BcAuthContext -tenantID $aadTenantId -refreshToken $refreshToken

# Delete environment
$LogDeleteSandbox = 'Delete $($newEnvironmentName) sandbox.'
Write-Host $LogDeleteSandbox

# Remove the environment and wait for the deletion to complete
Remove-BcEnvironment -bcAuthContext $authContext -environment $newEnvironmentName -doNotWait:$false

$LogCreateNewSandbox = 'Create new environment $($newEnvironmentName) type Sandbox from copy of $($environmentName).'
Write-Host $LogCreateNewSandbox

# copy environment
Copy-BcEnvironment -bcAuthContext $authContext -environment $newEnvironmentName -sourceEnvironment $environmentName -doNotWait:$false


