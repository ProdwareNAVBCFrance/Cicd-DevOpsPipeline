Param(
    [Parameter(Mandatory=$false)]
    [string] $version = "ci"
)

. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment 'Local' -version $version

#Sample additional task
# Copy-CompanyInBcContainer -destinationCompanyName "Master1" -sourceCompanyName "CRONUS International Ltd." -containerName $containerName -tenant "Default"

