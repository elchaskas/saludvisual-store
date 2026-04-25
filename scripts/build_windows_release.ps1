param(
    [string]$SourceRoot = ".",
    [string]$Version = "2.2.6",
    [string]$Runtime = "win-x64",
    [string]$Configuration = "Release",
    [string]$OutputRoot = "artifacts"
)

$ErrorActionPreference = "Stop"

$versionParts = $Version.Split(".")
if ($versionParts.Count -ne 3) {
    throw "Version must use MAJOR.MINOR.PATCH format. Received: $Version"
}

$fileVersion = "$Version.0"
$sourceRootPath = Resolve-Path $SourceRoot
$artifactRoot = Join-Path $sourceRootPath "$OutputRoot/v$Version"
$releaseRoot = Join-Path $artifactRoot "staging/$Runtime"
$publishRoot = Join-Path $artifactRoot "publish/$Runtime"

$projects = @(
    @{
        Name = "SaludVisual"
        Project = "SaludVisual.Windows/SaludVisual.Windows.csproj"
        Output = "app"
        Exe = "SaludVisual.exe"
    },
    @{
        Name = "InstalarSaludVisual"
        Project = "SaludVisual.Installer/SaludVisual.Installer.csproj"
        Output = "installer"
        Exe = "InstalarSaludVisual.exe"
    },
    @{
        Name = "DesinstalarSaludVisual"
        Project = "SaludVisual.Uninstaller/SaludVisual.Uninstaller.csproj"
        Output = "uninstaller"
        Exe = "DesinstalarSaludVisual.exe"
    }
)

Write-Host "Building Salud Visual $Version for $Runtime"
Write-Host "Source root: $sourceRootPath"

foreach ($project in $projects) {
    $projectPath = Join-Path $sourceRootPath $project.Project
    if (!(Test-Path $projectPath)) {
        throw "Missing project: $projectPath"
    }
}

if (Test-Path $publishRoot) {
    Remove-Item -Recurse -Force $publishRoot
}
if (Test-Path $releaseRoot) {
    Remove-Item -Recurse -Force $releaseRoot
}
New-Item -ItemType Directory -Force -Path $publishRoot | Out-Null
New-Item -ItemType Directory -Force -Path $releaseRoot | Out-Null

foreach ($project in $projects) {
    $projectPath = Join-Path $sourceRootPath $project.Project
    $outputPath = Join-Path $publishRoot $project.Output

    Write-Host "Publishing $($project.Name) -> $outputPath"
    dotnet publish $projectPath `
        -c $Configuration `
        -r $Runtime `
        --self-contained true `
        -p:PublishSingleFile=true `
        -p:Version=$Version `
        -p:FileVersion=$fileVersion `
        -p:AssemblyVersion=$fileVersion `
        -p:InformationalVersion=$Version `
        -o $outputPath

    $exePath = Join-Path $outputPath $project.Exe
    if (!(Test-Path $exePath)) {
        throw "Publish did not produce $exePath"
    }

    Copy-Item $exePath (Join-Path $releaseRoot $project.Exe) -Force
}

$iconCandidates = @(
    (Join-Path $sourceRootPath "salud-visual.ico"),
    (Join-Path $sourceRootPath "assets/salud-visual.ico"),
    (Join-Path $sourceRootPath "SaludVisual.Windows/salud-visual.ico")
)
foreach ($iconPath in $iconCandidates) {
    if (Test-Path $iconPath) {
        Copy-Item $iconPath (Join-Path $releaseRoot "salud-visual.ico") -Force
        break
    }
}

$cmdInstaller = Join-Path $releaseRoot "Instalar-SaludVisual-v2-SinAdmin.cmd"
@'
@echo off
setlocal

set "APP_NAME=SaludVisual"
set "TARGET_DIR=%LOCALAPPDATA%\SaludVisual"
set "TARGET_EXE=%TARGET_DIR%\SaludVisual.exe"
set "RUN_KEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"

echo [1/4] Creando carpeta de instalacion...
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

echo [2/4] Copiando archivos...
copy /Y "%~dp0SaludVisual.exe" "%TARGET_EXE%" >nul
if exist "%~dp0salud-visual.ico" copy /Y "%~dp0salud-visual.ico" "%TARGET_DIR%\salud-visual.ico" >nul

echo [3/4] Configurando inicio automatico...
reg add "%RUN_KEY%" /v "%APP_NAME%" /t REG_SZ /d "\"%TARGET_EXE%\"" /f >nul

echo [4/4] Iniciando aplicacion...
start "" "%TARGET_EXE%"

echo.
echo Instalacion completada.
echo App: "%TARGET_EXE%"
echo.
pause
'@ | Set-Content -Encoding ASCII $cmdInstaller

@"
Salud Visual $Version
Windows x64 (autocontenido)
Empaquetado: pendiente de firma
"@ | Set-Content -Encoding UTF8 (Join-Path $releaseRoot "VERSION.txt")

@"
Salud Visual v$Version (Windows x64)

Contenido del paquete:
- SaludVisual.exe
- InstalarSaludVisual.exe (instalador con interfaz grafica; recomendado)
- DesinstalarSaludVisual.exe
- VERSION.txt
- README.txt
- LEEME-INSTALADOR-GUI.txt

Microsoft Store Win32 commands:
- Install: InstalarSaludVisual.exe /silent
- Uninstall: DesinstalarSaludVisual.exe /silent

Instalacion para usuario final:
1) Ejecutar InstalarSaludVisual.exe y seguir el asistente.
2) No ejecutar el instalador desde dentro de %LOCALAPPDATA%\SaludVisual.

Log:
%LOCALAPPDATA%\SaludVisual\salud-visual.log
"@ | Set-Content -Encoding UTF8 (Join-Path $releaseRoot "README.txt")

@"
Salud Visual v$Version (Windows x64)

Instalacion recomendada:
1) Ejecutar InstalarSaludVisual.exe.
2) El asistente debe cerrar versiones anteriores, copiar la nueva version y configurar inicio automatico.

Microsoft Store Win32 commands:
- Install: InstalarSaludVisual.exe /silent
- Uninstall: DesinstalarSaludVisual.exe /silent

Uso:
- Icono en bandeja: pausar, intensidad, ubicacion manual, actualizar por IP, desinstalar, salir.
- Configuracion principal: HKCU\Software\ScreenTintAuto
- Log: %LOCALAPPDATA%\SaludVisual\salud-visual.log
"@ | Set-Content -Encoding UTF8 (Join-Path $releaseRoot "LEEME-INSTALADOR-GUI.txt")

Write-Host ""
Write-Host "Build complete. Staging folder:"
Write-Host $releaseRoot
Write-Host ""
Write-Host "Next step: sign these files before packaging:"
Write-Host "- $(Join-Path $releaseRoot 'SaludVisual.exe')"
Write-Host "- $(Join-Path $releaseRoot 'InstalarSaludVisual.exe')"
Write-Host "- $(Join-Path $releaseRoot 'DesinstalarSaludVisual.exe')"
