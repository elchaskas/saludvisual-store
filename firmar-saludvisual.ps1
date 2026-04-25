param(
    [Parameter(Mandatory = $true)]
    [string[]]$FilePath,

    [string]$SubjectContains = "Eric Sanchez Linares",
    [string]$TimestampServer = "http://timestamp.ssl.com",
    [switch]$UseMachineStore
)

$ErrorActionPreference = "Stop"

function Get-CodeSigningCertificate {
    param(
        [string]$SubjectContains,
        [switch]$UseMachineStore
    )

    $storeLocation = if ($UseMachineStore) { "Cert:\LocalMachine\My" } else { "Cert:\CurrentUser\My" }
    $certificates = Get-ChildItem $storeLocation -CodeSigningCert |
        Where-Object {
            $_.Subject -like "*$SubjectContains*" -and
            $_.HasPrivateKey -and
            $_.NotAfter -gt (Get-Date)
        } |
        Sort-Object NotAfter -Descending

    if (-not $certificates) {
        throw "No se encontro certificado de firma valido en $storeLocation con subject que contenga '$SubjectContains'."
    }

    return $certificates[0]
}

function Assert-SignableFile {
    param([string]$Path)

    if (!(Test-Path $Path)) {
        throw "No existe el archivo a firmar: $Path"
    }

    $extension = [System.IO.Path]::GetExtension($Path)
    if ($extension -ne ".exe") {
        throw "Solo se firman ejecutables .exe. Recibido: $Path"
    }
}

$certificate = Get-CodeSigningCertificate `
    -SubjectContains $SubjectContains `
    -UseMachineStore:$UseMachineStore

Write-Host "Certificado seleccionado:"
Write-Host "- Subject: $($certificate.Subject)"
Write-Host "- Thumbprint: $($certificate.Thumbprint)"
Write-Host "- Expira: $($certificate.NotAfter)"
Write-Host ""

foreach ($path in $FilePath) {
    Assert-SignableFile $path
    $resolvedPath = (Resolve-Path $path).Path

    Write-Host "Firmando $resolvedPath"
    $signature = Set-AuthenticodeSignature `
        -FilePath $resolvedPath `
        -Certificate $certificate `
        -HashAlgorithm SHA256 `
        -TimestampServer $TimestampServer

    if ($signature.Status -ne "Valid") {
        throw "Firma invalida para $resolvedPath. Estado: $($signature.Status). Mensaje: $($signature.StatusMessage)"
    }

    Write-Host "OK: $resolvedPath"
}

Write-Host ""
Write-Host "Firma completada correctamente."
