Write-Host -ForegroundColor Yellow @'
  ____                _         _   _        ____      _   
 / ___|_ __ ___  __ _| |_ ___  | \ | |_   _ / ___| ___| |_ 
| |   | '__/ _ \/ _` | __/ _ \ |  \| | | | | |  _ / _ \ __|
| |___| | |  __/ (_| | ||  __/ | |\  | |_| | |_| |  __/ |_ 
 \____|_|  \___|\__,_|\__\___| |_| \_|\__,_|\____|\___|\__|
|  _ \ __ _  ___| | ____ _  __ _  ___                      
| |_) / _` |/ __| |/ / _` |/ _` |/ _ \                     
|  __/ (_| | (__|   < (_| | (_| |  __/                     
|_|   \__,_|\___|_|\_\__,_|\__, |\___|                     
                          |___/                           
'@
#  created with https://www.asciiart.eu/text-to-ascii-art

$appFilesPathToPackage = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY\Apps\"

$tempNugetFolder = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY\NugetTmp"
if (-Not (Test-Path -Path $tempNugetFolder)) {
  New-Item -Path $tempNugetFolder -ItemType Directory
}

$nugetFolder = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY\Nuget"
if (-Not (Test-Path -Path $nugetFolder)) {
  New-Item -Path $nugetFolder -ItemType Directory
}

$FilesToPackage = Get-ChildItem -Path $appFilesPathToPackage -Filter *.app
foreach ($f in $FilesToPackage) {
    $NuGetPackagePath = New-BcNuGetPackage -appfile $f.FullName -destinationFolder $tempNugetFolder
    Copy-Item $NuGetPackagePath -Destination $nugetFolder -Force
    $NuGetPackageName = Split-Path -Path $NuGetPackagePath -Leaf
    Write-Host "Package created: $NuGetPackageName"
    Remove-Item -Path "$tempNugetFolder\*" -Recurse -Force
}