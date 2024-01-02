﻿Param(
    [Parameter(Mandatory=$false)]
    [string] $version = "ci"
)

$baseFolder = (Get-Item (Join-Path $PSScriptRoot "..")).FullName
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment 'Local' -version $version
# Requires Admin rights
#. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName

if (("$vaultNameForLocal" -eq "") -or !(Get-AzKeyVault -VaultName $vaultNameForLocal)) {
    throw "You need to setup a Key Vault for use with local pipelines"
}
Get-AzKeyVaultSecret -VaultName $vaultNameForLocal | ForEach-Object {
    Write-Host "Get Secret $($_.Name)Secret"
    Set-Variable -Name "$($_.Name)Secret" -Value (Get-AzKeyVaultSecret -VaultName $vaultNameForLocal -Name $_.Name -WarningAction SilentlyContinue)
}
$licenseFile = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($LicenseFileSecret.SecretValue))
$credential = New-Object pscredential 'admin', $passwordSecret.SecretValue

$allTestResults = "testresults*.xml"
$testResultsFile = Join-Path $baseFolder "TestResults.xml"
$testResultsFiles = Join-Path $baseFolder $allTestResults
if (Test-Path $testResultsFiles) {
    Remove-Item $testResultsFiles -Force
}

Run-AlPipeline `
    -pipelineName $pipelineName `
    -containerName $containerName `
    -imageName $imageName `
    -artifact $artifact `
    -accept_insiderEula `
    -memoryLimit $memoryLimit `
    -baseFolder $baseFolder `
    -licenseFile $licenseFile `
    -installApps $installApps `
    -appFolders $appFolders `
    -testFolders $testFolders `
    -testResultsFile $testResultsFile `
    -testResultsFormat 'JUnit' `
    -installTestFramework:$installTestFramework `
    -installTestLibraries:$installTestFramework `
    -installTestRunner:$installTestFramework `
    -installPerformanceToolkit:$installPerformanceToolkit `
    -credential $credential `
    -doNotRunTests `
    -previousApps $previousApps `
    -enableCodeCop:$enableCodeCop `
    -enableAppSourceCop:$enableAppSourceCop `
    -enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
    -enableUICop:$enableUICop `
    -escapeFromCops:$escapeFromCops `
    -rulesetFile $rulesetFile `
    -useDefaultAppSourceRuleSet:$useDefaultAppSourceRuleSet `
    -AppSourceCopMandatoryAffixes $appSourceCopMandatoryAffixes `
    -AppSourceCopSupportedCountries $appSourceCopSupportedCountries `
    -additionalCountries $additionalCountries `
    -useDevEndpoint `
    -updateLaunchJson "Local Sandbox" `
    -keepContainer `
    -enableTaskScheduler:$enableTaskScheduler `
    -NewBcContainer {
        Param([Hashtable]$parameters)
        $parameters += @{ "dns" = "8.8.8.8" }
        New-BcContainer @parameters
        Invoke-ScriptInBcContainer $parameters.ContainerName -scriptblock {
            $progressPreference = 'SilentlyContinue'
        }
    }

    .(Join-Path $PSScriptRoot "Local-DevEnv-AddTasks.ps1") -version $version