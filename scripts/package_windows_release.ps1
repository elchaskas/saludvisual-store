param(
    [string]$Version = "2.2.6",
    [string]$Runtime = "win-x64",
    [string]$ArtifactRoot = "artifacts",
    [string]$PublisherSubject = "Eric Sanchez Linares"
)

$ErrorActionPreference = "Stop"

$versionParts = $Version.Split(".")
if ($versionParts.Count -ne 3) {
    throw "Version must use MAJOR.MINOR.PATCH format. Received: $Version"
}

$fileVersion = "$Version.0"
$releaseRoot = Join-Path $ArtifactRoot "v$Version/staging/$Runtime"
$packageDir = Join-Path $ArtifactRoot "v$Version"
$packagePath = Join-Path $packageDir "SaludVisual-$Version-$Runtime.zip"

$executables = @(
    "SaludVisual.exe",
    "InstalarSaludVisual.exe",
    "DesinstalarSaludVisual.exe"
)

foreach ($exe in $executables) {
    $exePath = Join-Path $releaseRoot $exe
    if (!(Test-Path $exePath)) {
        throw "Missing executable: $exePath"
    }

    $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exePath)
    if ($versionInfo.FileVersion -ne $fileVersion) {
        throw "$exe has FileVersion '$($versionInfo.FileVersion)'. Expected '$fileVersion'."
    }
    if ($versionInfo.ProductVersion -notlike "$Version*") {
        throw "$exe has ProductVersion '$($versionInfo.ProductVersion)'. Expected '$Version'."
    }

    $signature = Get-AuthenticodeSignature $exePath
    if ($signature.Status -ne "Valid") {
        throw "$exe does not have a valid Authenticode signature. Status: $($signature.Status)"
    }
    if ($signature.SignerCertificate.Subject -notlike "*$PublisherSubject*") {
        throw "$exe signer '$($signature.SignerCertificate.Subject)' does not match '$PublisherSubject'."
    }
}

$requiredFiles = @(
    "README.txt",
    "LEEME-INSTALADOR-GUI.txt",
    "VERSION.txt"
)
foreach ($file in $requiredFiles) {
    $filePath = Join-Path $releaseRoot $file
    if (!(Test-Path $filePath)) {
        throw "Missing required package file: $filePath"
    }
}

@"
Salud Visual $Version
Windows x64 (autocontenido)
Empaquetado: $(Get-Date -Format "yyyy-MM-dd HH:mm")
"@ | Set-Content -Encoding UTF8 (Join-Path $releaseRoot "VERSION.txt")

New-Item -ItemType Directory -Force -Path $packageDir | Out-Null
if (Test-Path $packagePath) {
    Remove-Item -Force $packagePath
}

Compress-Archive `
    -Path (Join-Path $releaseRoot "*") `
    -DestinationPath $packagePath `
    -Force

Write-Host "Package ready:"
Write-Host $packagePath
