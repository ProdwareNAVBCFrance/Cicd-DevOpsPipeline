Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('AzureDevOps','GithubActions','GitLab')]
    [string] $environment = 'AzureDevOps'
)

$appFilesToSign = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY\Apps\*.app"
Get-ChildItem -Path $appFilesToSign | Format-List -Property * -Force   # see all members

Write-Host $ENV:SM_CLIENT_CERT_PASSWORD
Write-Host $ENV:SM_CLIENT_CERT_FILE
Write-Host $ENV:SM_HOST
Write-Host $ENV:SM_API_KEY
Write-Host $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY

. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $ENV:replacetargetversion
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName