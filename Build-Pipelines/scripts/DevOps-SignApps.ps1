Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('AzureDevOps','GithubActions','GitLab')]
    [string] $environment = 'AzureDevOps'
)

$appFilesPathToSign = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY\Apps\"
$FilesToSign = Get-ChildItem -Path $appFilesPathToSign -Filter *.app
foreach ($f in $FilesToSign) {
    signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a $f.FullName
}

$appFilesPathToSign = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY\RuntimePackages\"
$FilesToSign = Get-ChildItem -Path $appFilesPathToSign -Filter *.app
foreach ($f in $FilesToSign) {
    signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a $f.FullName
}


. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $ENV:replacetargetversion
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName