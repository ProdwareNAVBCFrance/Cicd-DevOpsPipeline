Param(
    [string] $bcContainerHelperVersion = "",
    [string] $genericImageName = ""
)

if ($bcContainerHelperVersion -eq "") { $bcContainerHelperVersion = "latest" }
if ($bccontainerHelperVersion -eq "dev") { $bccontainerHelperVersion = "https://github.com/microsoft/navcontainerhelper/archive/dev.zip" }

if ($bccontainerHelperVersion -like "https://*") {
    $path = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
}
else {
    $bcbaseurl = "https://bccontainerhelper.blob.core.windows.net/public"
    

    
    $latestVersion = "latest"
    $previewVersion = "preview"
    if ($bccontainerHelperVersion -eq "latest") {
        $bccontainerHelperVersion = $latestVersion
    }
    elseif ($bccontainerHelperVersion -eq "preview") {
        $bccontainerHelperVersion = $previewVersion
    }
    $basePath = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules\BcContainerHelper"
    if (!(Test-Path $basePath)) { New-Item $basePath -ItemType Directory | Out-Null }
    $path = Join-Path $basePath $bccontainerHelperVersion
    $bccontainerHelperVersion = "$bcbaseurl/$bccontainerHelperVersion.zip"
}

$bchMutexName = "bcContainerHelper"
$bchMutex = New-Object System.Threading.Mutex($false, $bchMutexName)
try {
    try { $bchMutex.WaitOne() | Out-Null } catch {}
    if (!(Test-Path $path)) {
        $tempName = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
        Write-Host "Downloading $bccontainerHelperVersion"
        (New-Object System.Net.WebClient).DownloadFile($bccontainerHelperVersion, "$tempName.zip")
        Expand-Archive -Path "$tempName.zip" -DestinationPath $tempName
        $folder = (Get-Item -Path (Join-Path $tempName '*')).FullName
        [System.IO.Directory]::Move($folder,$path)
    }
}
finally {
    $bchMutex.ReleaseMutex()
}
. (Join-Path $path "BcContainerHelper.ps1")

if ($genericImageName) {
    $bcContainerHelperConfig.genericImageName = $genericImageName
}
