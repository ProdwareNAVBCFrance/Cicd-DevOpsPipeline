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
$vaultName = "FR-BC"


#Connect-AzAccount
Set-AzContext -Subscription "c72d522a-0da0-47de-b0ce-83bf2f3ade83" -Tenant "bbfde416-ad70-4316-81eb-73b70da0b6cd"
if (!($refreshTokenSecret)) {
    Write-Host -ForegroundColor Yellow "Reading Key Vault"
    Get-AzKeyVaultSecret $vaultName  | % {
        Write-Host $_.Name
        Set-Variable `
            -Name "$($_.Name)Secret" `
            -Value (Get-AzKeyVaultSecret $vaultName -Name $_.Name)
    }
}

Write-Host -ForegroundColor Yellow "SaaS Settings"
$bcSaasCustomers = $bcSaasCustomersSecret.SecretValue | Get-PlainText

$response = Invoke-RestMethod -Uri $bcSaasCustomers -UseBasicParsing -ContentType "application/json" -OutFile $OutPath
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


