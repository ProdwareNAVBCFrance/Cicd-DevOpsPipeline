Param(
   [Parameter(Mandatory=$true)]
   [int] $appRevision = 0
)

$settings = (Get-Content (Join-Path $PSScriptRoot "settings.json") | ConvertFrom-Json)

$appBuild = get-date -Format $settings.appBuild
Write-Host "Set appBuild = $appBuild"
Write-Host "##vso[task.setvariable variable=appBuild]$appBuild"

$appVersion = $settings.appVersion
Write-Host "##vso[build.updatebuildnumber]$appversion.$appBuild.$appRevision"