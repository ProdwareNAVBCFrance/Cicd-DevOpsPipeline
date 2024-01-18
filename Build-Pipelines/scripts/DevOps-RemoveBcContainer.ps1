Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('AzureDevOps','GithubActions','GitLab')]
    [string] $environment = 'AzureDevOps'
)

. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $ENV:replacetargetversion
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName
Remove-BcContainer -containerName $containerName