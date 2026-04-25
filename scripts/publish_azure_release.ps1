param(
    [string]$Version = "2.2.6",
    [string]$PackagePath = "artifacts/v2.2.6/SaludVisual-2.2.6-win-x64.zip",
    [string]$StorageAccountName = "stsaludvisual73023",
    [string]$ContainerName = "releases",
    [switch]$DeleteExisting,
    [string[]]$DeleteVersions = @(),
    [switch]$ConfirmDelete,
    [string]$ConfirmDeleteText = ""
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "No se encontro '$Name'. Instala Azure CLI antes de publicar."
    }
}

Require-Command "az"

$package = Get-Item $PackagePath
$expectedName = "SaludVisual-$Version-win-x64.zip"
if ($package.Name -ne $expectedName) {
    throw "Nombre de paquete invalido. Esperado: $expectedName. Recibido: $($package.Name)"
}

Write-Host "Paquete que se publicara en Azure:"
Write-Host "- $($package.FullName)"

if ($DeleteExisting) {
    if (-not $ConfirmDelete) {
        throw "Para borrar blobs existentes agrega tambien -ConfirmDelete."
    }

    Write-Host "Eliminando blobs existentes de la version $Version..."
    $existing = az storage blob list `
        --account-name $StorageAccountName `
        --container-name $ContainerName `
        --prefix "SaludVisual-$Version-" `
        --auth-mode login `
        --query "[].name" `
        --output tsv

    foreach ($blob in $existing) {
        if (-not $blob) {
            continue
        }

        Write-Host "Borrando $blob"
        az storage blob delete `
            --account-name $StorageAccountName `
            --container-name $ContainerName `
            --name $blob `
            --auth-mode login `
            --only-show-errors | Out-Null
    }
}

if ($DeleteVersions.Count -gt 0) {
    $expectedConfirmText = "BORRAR " + ($DeleteVersions -join ",")
    if ($ConfirmDeleteText -ne $expectedConfirmText) {
        throw "Para borrar versiones especificas usa -ConfirmDeleteText `"$expectedConfirmText`"."
    }

    foreach ($deleteVersion in $DeleteVersions) {
        Write-Host "Eliminando blobs de la version $deleteVersion..."
        $versionBlobs = az storage blob list `
            --account-name $StorageAccountName `
            --container-name $ContainerName `
            --prefix "SaludVisual-$deleteVersion-" `
            --auth-mode login `
            --query "[].name" `
            --output tsv

        foreach ($blob in $versionBlobs) {
            if (-not $blob) {
                continue
            }

            Write-Host "Borrando $blob"
            az storage blob delete `
                --account-name $StorageAccountName `
                --container-name $ContainerName `
                --name $blob `
                --auth-mode login `
                --only-show-errors | Out-Null
        }
    }
}

Write-Host "Subiendo $($package.Name)"
az storage blob upload `
    --account-name $StorageAccountName `
    --container-name $ContainerName `
    --name $package.Name `
    --file $package.FullName `
    --auth-mode login `
    --overwrite true `
    --content-type "application/zip" `
    --only-show-errors | Out-Null

Write-Host "Publicacion Azure completada."
