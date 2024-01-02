Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('AzureDevOps','GithubActions','GitLab')]
    [string] $environment = 'AzureDevOps',
    [Parameter(Mandatory=$false)]
    [string] $againstNextMajor = "False"
)

# $baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $ENV:replacetargetversion
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName

$licenseFile = "$ENV:LicenseFile"

# $allTestResults = "testresults*.xml"
# $testResultsFile = Join-Path $baseFolder "TestResults.xml"
# $testResultsFiles = Join-Path $baseFolder $allTestResults
# if (Test-Path $testResultsFiles) {
#     Remove-Item $testResultsFiles -Force
# }

switch ($againstNextMajor) {
    "True" {
        Run-AlValidation -apps $previewApps `
                 -countries $additionalCountries `
                 -affixes $appSourceCopMandatoryAffixes `
                 -installApps $installApps `
                 -licenseFile $LicenseFile `
                 -memoryLimit 24G `
                 -previousApps $previousApps `
                 -failOnError `
                 -validateNextMajor
      }

    Default {
        Run-AlValidation -apps $previewApps `
                -countries $additionalCountries `
                -affixes $appSourceCopMandatoryAffixes `
                -installApps $installApps `
                -licenseFile $LicenseFile `
                -memoryLimit 24G `
                -previousApps $previousApps `
                -failOnError `
                -validateCurrent `
                -validateVersion $appRequiredBCVersion
    }
}

# if ($environment -eq 'AzureDevOps') {
#     Write-Host "##vso[task.setvariable variable=TestResults]$allTestResults"
# }


