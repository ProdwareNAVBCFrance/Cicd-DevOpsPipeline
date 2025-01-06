$aadTenantId = {$env:aadTenantId}
$newEnvironmentName = {$env:newEnvironmentName}
$environmentName = {$env:environmentName}
$bcSaasCustomers = {$env:bcSaasCustomers}

Write-Host $aadTenantId
Write-Host $newEnvironmentName
Write-Host $environmentName


$aadAppRedirectUri = "http://localhost"                   # partner's AAD app redirect URI

$response = Invoke-RestMethod -Uri "$bcSaasCustomers" -UseBasicParsing -ContentType "application/json" -OutFile $OutPath
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


