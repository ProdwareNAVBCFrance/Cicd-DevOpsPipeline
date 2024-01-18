Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('AzureDevOps','GithubActions','GitLab')]
    [string] $environment = 'AzureDevOps'
)

Write-Host -ForegroundColor Yellow @'
 ____  _             _                                     
/ ___|(_) __ _ _ __ (_)_ __   __ _    __ _ _ __  _ __  ___ 
\___ \| |/ _` | '_ \| | '_ \ / _` |  / _` | '_ \| '_ \/ __|
 ___) | | (_| | | | | | | | | (_| | | (_| | |_) | |_) \__ \
|____/|_|\__, |_| |_|_|_| |_|\__, |  \__,_| .__/| .__/|___/
         |___/               |___/        |_|   |_|        
'@

$appFilesPathToSign = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY\Apps\"
$FilesToSign = Get-ChildItem -Path $appFilesPathToSign -Filter *.app
foreach ($f in $FilesToSign) {
    signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a $f.FullName
}


Write-Host -ForegroundColor Yellow @'
 ____  _             _                                _   _                    
/ ___|(_) __ _ _ __ (_)_ __   __ _   _ __ _   _ _ __ | |_(_)_ __ ___   ___ ___ 
\___ \| |/ _` | '_ \| | '_ \ / _` | | '__| | | | '_ \| __| | '_ ` _ \ / _ / __|
 ___) | | (_| | | | | | | | | (_| | | |  | |_| | | | | |_| | | | | | |  __\__ \
|____/|_|\__, |_| |_|_|_| |_|\__, | |_|   \__,_|_| |_|\__|_|_| |_| |_|\___|___/
         |___/               |___/                                                                                
'@

$appFilesPathToSign = "$ENV:BUILD_ARTIFACTSTAGINGDIRECTORY\RuntimePackages\"
$FilesToSign = Get-ChildItem -Path $appFilesPathToSign -Filter *.app
foreach ($f in $FilesToSign) {
    signtool sign /tr http://timestamp.digicert.com /td sha256 /fd sha256 /a $f.FullName
}