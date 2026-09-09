# Salud Visual 3.0.0 Premium - publicacion multi-tienda

Este documento prepara la version premium `3.0.0` para publicacion en:

- Microsoft Store
- Apple App Store
- Google Play Store
- Web propia `https://saludvisual.shop`

## Estado de partida

Este checkout contiene metadatos, scripts y overlays. El codigo fuente real vive
en el repo `ScreenTintAuto`, que debe contener como minimo:

```text
SaludVisual.Windows/
SaludVisual.Mac/
SaludVisual.iOS/
SaludVisual.Shared/
SaludVisual.LicensingApi/
android-projects/
web-public/
scripts/
```

No se puede completar la subida a tiendas desde este repo sin:

- codigo fuente completo,
- acceso a Partner Center de Microsoft,
- acceso a App Store Connect,
- acceso a Google Play Console,
- certificados/perfiles de firma,
- builds generadas en los sistemas requeridos.

## Version objetivo

```text
3.0.0
```

Version codes recomendados:

```text
Windows: 3.0.0.0
macOS:   3.0.0
iOS:     CFBundleShortVersionString=3.0.0, CFBundleVersion=300
Android: versionName=3.0.0, versionCode=300
```

## Paridad premium requerida

Todas las plataformas deben compartir:

- web oficial: `https://saludvisual.shop`
- API de licencias: `https://api.saludvisual.shop`
- licencia por instalacion/dispositivo
- flujo de activacion claro
- version visible `3.0.0`
- politicas de privacidad y soporte actualizadas
- branding premium consistente

## Windows - Microsoft Store

Artefacto esperado:

```text
SaludVisual-3.0.0-win-x64.zip
```

Requisitos:

- `SaludVisual.Windows.csproj` en `3.0.0`
- `SaludVisual.Installer.csproj` en `3.0.0`
- `SaludVisual.Uninstaller.csproj` en `3.0.0`
- binarios firmados con Authenticode
- instalacion silenciosa:

  ```text
  InstalarSaludVisual.exe /silent
  ```

- desinstalacion silenciosa:

  ```text
  DesinstalarSaludVisual.exe /silent
  ```

Validaciones:

```bash
python3 scripts/validate_store_package.py \
  artifacts/v3.0.0/SaludVisual-3.0.0-win-x64.zip \
  --version 3.0.0 \
  --platform win-x64
```

Subida:

- Partner Center > Microsoft Store > Packages
- completar cuestionario, privacidad, pricing, mercados e informacion de soporte

## macOS - web propia

Artefactos esperados:

```text
SaludVisual-3.0.0-mac-osx-arm64.zip
SaludVisual-3.0.0-mac-osx-x64.zip
```

Requisitos:

- bundles `.app` reales con rutas `/`
- `CFBundlePackageType=APPL`
- firma Developer ID Application
- notarizacion Apple aceptada
- `stapler` aplicado
- `spctl` accepted:

  ```text
  source=Notarized Developer ID
  ```

Comando base:

```bash
MACOS_SIGN_IDENTITY="Developer ID Application: Eric Sanchez (JVFGYZU2GG)" \
MACOS_NOTARY_PROFILE=saludvisual-notary \
VERSION=3.0.0 \
scripts/reconstruir-saludvisual-macos.sh all
```

Subida:

- Azure Blob `releases`
- actualizar web para apuntar a los ZIP `3.0.0`

## iPhone - App Store

Artefacto esperado:

```text
SaludVisual.iOS.ipa
```

Requisitos:

- proyecto `SaludVisual.iOS`
- `TargetFramework=net10.0-ios`
- `ApplicationDisplayVersion=3.0.0`
- `ApplicationVersion=300`
- licencia contra `https://api.saludvisual.shop`
- descripcion clara: la app guia filtros nativos de iOS, no aplica overlay global
- iconos, screenshots y politica de privacidad para App Store Connect

Build de simulador:

```bash
dotnet build SaludVisual.iOS/SaludVisual.iOS.csproj \
  -f net10.0-ios \
  -p:RuntimeIdentifier=iossimulator-arm64 \
  -p:ValidateXcodeVersion=false
```

Build de dispositivo/App Store:

```bash
dotnet publish SaludVisual.iOS/SaludVisual.iOS.csproj \
  -f net10.0-ios \
  -c Release \
  -p:RuntimeIdentifier=ios-arm64 \
  -p:ArchiveOnBuild=true \
  -p:ValidateXcodeVersion=false
```

Subida:

- Xcode Organizer o Transporter
- App Store Connect > TestFlight > App Review

## Android - Google Play

Artefacto esperado:

```text
SaludVisual-3.0.0-android.aab
```

Requisitos:

- `versionName "3.0.0"`
- `versionCode 300`
- firma release con keystore de produccion
- politica de privacidad
- declaracion de datos Play Console
- screenshots telefono/tablet si aplica

Build orientativo:

```bash
cd android-projects/SaludVisualAndroidUniversal
./gradlew clean bundleRelease
```

Subida:

- Google Play Console > Production/Test track
- subir `.aab`
- completar Data safety, contenido, privacidad y pricing

## Checklist final antes de publicar

- [ ] Todas las plataformas muestran `3.0.0`.
- [ ] Licencia activada y validada por dispositivo.
- [ ] Web premium actualizada.
- [ ] Links de descarga correctos.
- [ ] Windows firmado y validado.
- [ ] macOS firmado, notarizado, stapled y aceptado por Gatekeeper.
- [ ] iOS compila, corre en simulador y tiene build de archivo.
- [ ] Android genera `.aab` release firmado.
- [ ] Politica de privacidad actualizada.
- [ ] Capturas y textos Store preparados.
- [ ] Backups de artefactos finales.
