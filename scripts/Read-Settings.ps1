Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Local', 'AzureDevOps', 'GithubActions', 'GitLab')]
    [string] $environment = 'Local',
    [string] $version = ""
)

$agentName = ""
if ($environment -ne 'Local') {
    $agentName = $ENV:AGENT_NAME
}

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)
if ("$version" -eq "") {
    $version = $settings.versions[0].version
    Write-Host "Version not defined, using $version"
}

if ($version -eq "Default") {
    $version = $settings.targetVersion
}

$buildversion = $settings.versions | Where-Object { $_.version -eq $version }
if ($buildversion) {
    Write-Host "Set artifact = $($buildVersion.artifact)"
    Set-Variable -Name "artifact" -Value $buildVersion.artifact
    Write-Host "Set olderLicenseFile = $($buildVersion.olderLicenseFile)"
    Set-Variable -Name "olderLicenseFile" -Value $buildVersion.olderLicenseFile    
}
else {
    throw "Unknown version: $version"
}

$pipelineName = "$($settings.Name)-$version-$env:username"
Write-Host "Set pipelineName = $pipelineName"

if ($agentName) {
    $containerName = "$($agentName -replace '[^a-zA-Z0-9---]', '')-$($pipelineName -replace '[^a-zA-Z0-9---]', '')".ToLowerInvariant()
}
else {
    $containerName = "$($pipelineName.Replace('.','-') -replace '[^a-zA-Z0-9---]', '')".ToLowerInvariant()
}
Write-Host "Set containerName = $containerName"
if ($environment -eq 'AzureDevOps') {
    Write-Host "##vso[task.setvariable variable=containerName]$containerName"
}

"installApps", "previousApps", "previewApps", "appSourceCopMandatoryAffixes", "appSourceCopSupportedCountries", "appFolders", "testFolders", "memoryLimit", "additionalCountries", "genericImageName", "vaultNameForLocal", "bcContainerHelperVersion", "rulesetFile", "disabledTestsFile", "appRequiredBCVersion" | ForEach-Object {
    $str = ""
    if ($buildversion.PSObject.Properties.Name -eq $_) {
        $str = $buildversion."$_"
    }
    elseif ($settings.PSObject.Properties.Name -eq $_) {
        $str = $settings."$_"
    }
    Write-Host "Set $_ = '$str'"
    Set-Variable -Name $_ -Value "$str"
}

"installTestFramework", "installTestLibraries", "installPerformanceToolkit", "enableCodeCop", "enableAppSourceCop", "enablePerTenantExtensionCop", "enableUICop", "doNotSignApps", "doNotRunTests", "cacheImage", "CreateRuntimePackages", "escapeFromCops", "useDefaultAppSourceRuleSet", "enableTaskScheduler" | ForEach-Object {
    $str = "False"
    if ($buildversion.PSObject.Properties.Name -eq $_) {
        $str = $buildversion."$_"
    }
    elseif ($settings.PSObject.Properties.Name -eq $_) {
        $str = $settings."$_"
    }
    Write-Host "Set $_ = $str"
    Set-Variable -Name $_ -Value ($str -eq "True")
}

$imageName = ""
# Cache image on local
# if ($cacheImage -and ("$AgentName" -ne "Hosted Agent" -and "$agentName" -ne "" -and "$AgentName" -notlike "Azure Pipelines*")) {
if ($cacheImage -and ("$AgentName" -ne "Hosted Agent" -and "$AgentName" -notlike "Azure Pipelines*")) {
    $imageName = "bcimage"
}

# //TODO: Enable for local and pipelines
# Sort-AppFoldersByDependencies -appFolders $appFolders.Split(',') -baseFolder $ENV:BUILD_REPOSITORY_LOCALPATH -WarningAction SilentlyContinue | ForEach-Object {
    
#     $appProjectFolder = Join-Path $ENV:BUILD_REPOSITORY_LOCALPATH $_

#     if ($ENV:appVersion) {
#         $currentversion = [System.Version]::Parse($ENV:appVersion)
#         Write-Host "Using Version $currentversion"
#         $appJsonFile = Join-Path $appProjectFolder "app.json"
#         $appJson = Get-Content $appJsonFile | ConvertFrom-Json
#         if (!($appJson.version.StartsWith("$($currentversion.Major).$($currentversion.Minor)."))) {
#             throw "Major and Minor version of app doesn't match with pipeline"
#         }
#     }
# }