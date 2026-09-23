# Sobrescribe SOLO tu carpeta web existente. No crea carpetas nuevas.
$ErrorActionPreference = "Stop"

$candidates = @(
  "D:\ScreenTintAuto\web 3.0",
  "D:\Salud Visual\web",
  "D:\ScreenTintAuto\web"
)

$dest = $null
foreach ($c in $candidates) {
  if (Test-Path -LiteralPath $c) { $dest = $c; break }
}

if (-not $dest) {
  Write-Host "ERROR: no existe ninguna de estas carpetas:"
  $candidates | ForEach-Object { Write-Host " - $_" }
  Write-Host "Dime la ruta exacta de tu carpeta web y lo ajusto. NO se ha creado nada nuevo."
  exit 1
}

Write-Host "Usando carpeta existente: $dest"

$zip = Join-Path $env:TEMP "saludvisual-store-branch.zip"
$extract = Join-Path $env:TEMP "saludvisual-store-branch"
Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
if (Test-Path -LiteralPath $extract) { Remove-Item -LiteralPath $extract -Recurse -Force }

Invoke-WebRequest -Uri "https://github.com/elchaskas/saludvisual-store/archive/refs/heads/cursor/mac-activation-parity-e403.zip" -OutFile $zip
Expand-Archive -Path $zip -DestinationPath $extract -Force
$srcRoot = Get-ChildItem -LiteralPath $extract -Directory | Select-Object -First 1
$web = Join-Path $srcRoot.FullName "source-overlays\ScreenTintAuto\web-public"

# Overwrite files in place
Copy-Item -LiteralPath (Join-Path $web "htdocs\*") -Destination $dest -Recurse -Force
$assetsDest = Join-Path $dest "assets"
if (-not (Test-Path -LiteralPath $assetsDest)) {
  # Solo crea assets DENTRO de la carpeta que ya existe, si faltaba
  New-Item -ItemType Directory -Path $assetsDest | Out-Null
}
Copy-Item -LiteralPath (Join-Path $web "assets\*") -Destination $assetsDest -Recurse -Force

# Cleanup temp only
Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $extract -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "LISTO. Archivos sobrescritos en: $dest"
Write-Host "Comprueba que index.html contiene: ericsanchezlinares.com y data-sv-build"
Write-Host "Luego sube ESA misma carpeta a IONOS (httpdocs), sobrescribiendo index.html y assets."
explorer $dest
