# Reescribe TODOS los index.html malos de Salud Visual en D: (no crea carpetas nuevas).
$ErrorActionPreference = "Stop"
$base = "https://raw.githubusercontent.com/elchaskas/saludvisual-store/cursor/mac-activation-parity-e403/source-overlays/ScreenTintAuto/web-public"
$pages = @(
  "htdocs/index.html",
  "htdocs/gracias.html",
  "htdocs/privacidad.html",
  "htdocs/soporte.html",
  "htdocs/installer-exit-codes.html",
  "htdocs/robots.txt",
  "htdocs/sitemap.xml"
)

$roots = @()
foreach ($r in @("D:\ScreenTintAuto", "D:\Salud Visual", "D:\ScreenTintAuto\web 3.0", "D:\Salud Visual\web")) {
  if (Test-Path -LiteralPath $r) { $roots += $r }
}
if ($roots.Count -eq 0) {
  Write-Host "No encuentro D:\ScreenTintAuto ni D:\Salud Visual. Abre PowerShell y ejecuta: Get-PSDrive"
  exit 1
}

Write-Host "Buscando index.html de Salud Visual en:"
$roots | ForEach-Object { Write-Host "  $_" }

$dirs = Get-ChildItem -Path $roots -Recurse -Filter index.html -File -ErrorAction SilentlyContinue |
  Where-Object {
    $raw = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction SilentlyContinue
    $raw -and ($raw -match "Salud Visual|saludvisual")
  } |
  ForEach-Object { $_.Directory.FullName } |
  Select-Object -Unique

if (-not $dirs) {
  Write-Host "No he encontrado ningun index.html de Salud Visual. Dime la ruta exacta del index.html que abres."
  exit 1
}

foreach ($dir in $dirs) {
  Write-Host ""
  Write-Host "SOBREESCRIBIENDO: $dir"
  foreach ($rel in $pages) {
    $name = Split-Path $rel -Leaf
    $out = Join-Path $dir $name
    Invoke-WebRequest -Uri "$base/$rel" -OutFile $out -UseBasicParsing
    Write-Host "  OK $name"
  }
  $check = Get-Content -LiteralPath (Join-Path $dir "index.html") -Raw
  if ($check -match "3\.0 Premium") {
    Write-Host "  FALLO: sigue diciendo 3.0 Premium"
  } elseif ($check -match "ericsanchezlinares\.com" -and $check -match "data-sv-build") {
    Write-Host "  VERIFICADO: index correcto (ericsanchezlinares.com + filtro)"
  } else {
    Write-Host "  AVISO: descarga hecha, revisa el archivo"
  }
}

Write-Host ""
Write-Host "Hecho en disco local. Para que cambie saludvisual.shop hay que subir ESE index.html a IONOS httpdocs (sobrescribir)."
Write-Host "Si activas Tailscale/SSH al VPS desde aqui, lo subo yo sin que tengas que tocar Plesk."
