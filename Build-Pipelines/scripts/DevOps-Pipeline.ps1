Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('AzureDevOps','GithubActions','GitLab')]
    [string] $environment = 'AzureDevOps',
    [Parameter(Mandatory=$false)]
    [string] $version = "Default",
    [Parameter(Mandatory=$false)]
    [int] $appBuild = 0,
    [Parameter(Mandatory=$false)]
    [int] $appRevision = 0,
    [Parameter(Mandatory=$false)]
    [switch] $AppSourceProcess,
    [Parameter(Mandatory=$false)]
    [switch] $PackageRelease
)

if ($environment -eq "AzureDevOps") {
    $buildArtifactFolder = $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY
}
elseif ($environment -eq "GitHubActions") {
    $buildArtifactFolder = Join-Path $ENV:GITHUB_WORKSPACE "output"
    New-Item $buildArtifactFolder -ItemType Directory | Out-Null
}

$baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
# . (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $ENV:replacetargetversion
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $version
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName

if ($PackageRelease) {
    $doNotRunTests = $PackageRelease
    $CreateRuntimePackages = $PackageRelease
}

if (!$AppSourceProcess) {
    $additionalCountries = ""
}

# Disable previous version and test apps for nextmajorsaas
# Temporary solution until we have a better way to handle this
# if ($version -eq "nextmajorsaas") {
#     $previousApps = ""
#     $testFolders = ""
#     $doNotRunTests = $true
# }

$params = @{}
$licenseFile = "$ENV:LicenseFile"


# $codeSigncertPfxFile = "$ENV:CodeSignCertPfxFile"
# if (!$doNotSignApps -and $codeSigncertPfxFile) {
#     if ("$ENV:CodeSignCertPfxPassword" -ne "") {
#         $codeSignCertPfxPassword = try { "$ENV:CodeSignCertPfxPassword" | ConvertTo-SecureString } catch { ConvertTo-SecureString -String "$ENV:CodeSignCertPfxPassword" -AsPlainText -Force }
#         $params = @{
#             "codeSignCertPfxFile" = $codeSignCertPfxFile
#             "codeSignCertPfxPassword" = $codeSignCertPfxPassword
#         }
#     }
#     else {
#         $codeSignCertPfxPassword = $null
#     }
# }

$allTestResults = "testresults*.xml"
$testResultsFile = Join-Path $baseFolder "TestResults.xml"
$testResultsFiles = Join-Path $baseFolder $allTestResults
if (Test-Path $testResultsFiles) {
    Remove-Item $testResultsFiles -Force
}

Run-AlPipeline @params `
    -pipelinename $pipelineName `
    -containerName $containerName `
    -imageName $imageName `
    -artifact $artifact `
    -accept_insiderEula `
    -memoryLimit $memoryLimit `
    -baseFolder $baseFolder `
    -licenseFile $LicenseFile `
    -installApps $installApps `
    -previousApps $previousApps `
    -appFolders $appFolders `
    -testFolders $testFolders `
    -doNotRunTests:$doNotRunTests `
    -testResultsFile $testResultsFile `
    -testResultsFormat 'JUnit' `
    -installTestFramework:$installTestFramework `
    -installTestLibraries:$installTestFramework `
    -installTestRunner:$installTestFramework `
    -installPerformanceToolkit:$installPerformanceToolkit `
    -enableCodeCop:$enableCodeCop `
    -enableAppSourceCop:$enableAppSourceCop `
    -enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
    -enableUICop:$enableUICop `
    -rulesetFile $rulesetFile `
    -useDefaultAppSourceRuleSet:$useDefaultAppSourceRuleSet `
    -azureDevOps:($environment -eq 'AzureDevOps') `
    -gitLab:($environment -eq 'GitLab') `
    -gitHubActions:($environment -eq 'GitHubActions') `
    -AppSourceCopMandatoryAffixes $appSourceCopMandatoryAffixes `
    -AppSourceCopSupportedCountries $appSourceCopSupportedCountries `
    -additionalCountries $additionalCountries `
    -buildArtifactFolder $buildArtifactFolder `
    -CreateRuntimePackages:$CreateRuntimePackages `
    -appBuild $appBuild -appRevision $appRevision `
    -enableTaskScheduler:$enableTaskScheduler `
    -keepContainer:$false `
    -generateDependencyArtifact:$PackageRelease `
    -NewBcContainer {
        Param([Hashtable]$parameters)
        $parameters += @{ "dns" = "8.8.8.8" }
        New-BcContainer @parameters
        Invoke-ScriptInBcContainer $parameters.ContainerName -scriptblock {
            $progressPreference = 'SilentlyContinue'
        }
    }

if ($environment -eq 'AzureDevOps') {
    Write-Host "##vso[task.setvariable variable=TestResults]$allTestResults"
}