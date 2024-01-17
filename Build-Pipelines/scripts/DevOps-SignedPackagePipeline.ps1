Param(
    [Parameter(Mandatory=$false)]
    [string] $version = "",
    [Parameter(Mandatory=$false)]
    [int] $appBuild = 0,
    [Parameter(Mandatory=$false)]
    [int] $appRevision = 0,
    [Parameter(Mandatory=$false)]
    [switch] $AppSourceProcess
)
$environment = 'AzureDevOps'
$buildArtifactFolder = $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY

$baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $ENV:replacetargetversion
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName

$params = @{}
$licenseFile = "$ENV:LicenseFile"

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
    -appFolders $appFolders `
    -enableCodeCop:$enableCodeCop `
    -enableAppSourceCop:$enableAppSourceCop `
    -enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
    -enableUICop:$enableUICop `
    -rulesetFile $rulesetFile `
    -useDefaultAppSourceRuleSet:$useDefaultAppSourceRuleSet `
    -azureDevOps `
    -AppSourceCopMandatoryAffixes $appSourceCopMandatoryAffixes `
    -AppSourceCopSupportedCountries $appSourceCopSupportedCountries `
    -buildArtifactFolder $buildArtifactFolder `
    -CreateRuntimePackages:$CreateRuntimePackages `
    -appBuild $appBuild -appRevision $appRevision `
    -keepContainer `
    -NewBcContainer {
        Param([Hashtable]$parameters)
        $parameters += @{ "dns" = "8.8.8.8" }
        New-BcContainer @parameters
        Invoke-ScriptInBcContainer $parameters.ContainerName -scriptblock {
            $progressPreference = 'SilentlyContinue'
        }
    }