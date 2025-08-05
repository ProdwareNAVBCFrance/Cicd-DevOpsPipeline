Param(
[Parameter(Mandatory = $false)]
[ValidateSet('AzureDevOps', 'GithubActions', 'GitLab')]
[string] $environment = 'AzureDevOps',
[Parameter(Mandatory = $false)]
[string] $version = "",
[Parameter(Mandatory = $false)]
[int] $appBuild = 0,
[Parameter(Mandatory = $false)]
[int] $appRevision = 0,
[Parameter(Mandatory = $false)]
[switch] $AppSourceProcess
)
Write-Host $appBuild
Write-Host $appRevision
Write-Host $AppSourceProcess
Write-Host $env:ArtifactsFeedPat

if ($environment -eq "AzureDevOps") {
    $buildArtifactFolder = $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY
}
elseif ($environment -eq "GitHubActions") {
    $buildArtifactFolder = Join-Path $ENV:GITHUB_WORKSPACE "output"
    New-Item $buildArtifactFolder -ItemType Directory | Out-Null
}

$baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $env:replacetargetversion
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName

if (!$AppSourceProcess) {
    $additionalCountries = ""
}
$allTestResults = "testresults*.xml"
$testResultsFile = Join-Path $baseFolder "TestResults.xml"
$testResultsFiles = Join-Path $baseFolder $allTestResults
if (Test-Path $testResultsFiles) {
    Remove-Item $testResultsFiles -Force
}
#$disabledTests = (Get-Content $disabledTestsFile | ConvertFrom-Json)

# Get packages from NuGet >>
if ($settings.additionalNuGetFeeds) {
    $bcContainerHelperConfig.TrustedNuGetFeeds = @()
    # Access and set to $bcContainerHelperConfig
    foreach ($feed in $settings.additionalNuGetFeeds) {
        if ($feed.token -eq "internal") {
            $feedtoken = $env:ArtifactsFeedPat
        }
        else {
            $feedtoken = $feed.token
        }
        
        switch ($feed.source) {
            "latest" {
                $bcContainerHelperConfig.TrustedNuGetFeeds += [PSCustomObject]@{ "Url" = $env:nugetFeedUrlForLatest; "Token" = $feedtoken }
            }
            "release" {
                $bcContainerHelperConfig.TrustedNuGetFeeds += [PSCustomObject]@{ "Url" = $env:nugetFeedUrlForRelease; "Token" = $feedtoken }
                
            }
            Default {
                $bcContainerHelperConfig.TrustedNuGetFeeds += [PSCustomObject]@{ "Url" = $feed.source; "Token" = $feedtoken }
            }
        }
    }

    $params += @{
    "InstallMissingDependencies" = {
        Param([Hashtable]$parameters)
        $parameters.missingDependencies | ForEach-Object {
            $appid = $_.Split(':')[0]
            $appName = $_.Split(':')[1]
            $version = $appName.SubString($appName.LastIndexOf('_') + 1)
            $version = [System.Version]$version.SubString(0, $version.Length - 4)
            $publishParams = @{
                "packageName" = $appId
                "version"     = $version
            }
            if ($parameters.ContainsKey('CopyInstalledAppsToFolder')) {
                $publishParams += @{
                    "CopyInstalledAppsToFolder" = $parameters.CopyInstalledAppsToFolder
                }
            }
            if ($parameters.ContainsKey('containerName')) {
                Publish-BcNuGetPackageToContainer -containerName $parameters.containerName -tenant $parameters.tenant -skipVerification -appSymbolsFolder $parameters.appSymbolsFolder @publishParams -ErrorAction SilentlyContinue -Select LatestMatching
            }
            else {
                Download-BcNuGetPackageToFolder -folder $parameters.appSymbolsFolder @publishParams -Select LatestMatching | Out-Null
            }
        }
    }
}
}


# Get packages from NuGet <<


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
-installTestLibraries:$installTestLibraries `
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
