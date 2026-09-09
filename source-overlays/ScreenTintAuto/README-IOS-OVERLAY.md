# Overlay iOS para ScreenTintAuto

Este overlay crea la base de la app iPhone de Salud Visual dentro del repo real
`ScreenTintAuto`.

## Contenido

```text
SaludVisual.Shared/
SaludVisual.iOS/
scripts/aplicar-ios-overlay.sh
```

## Que implementa

- Proyecto compartido `SaludVisual.Shared`:
  - `ProductInfo`
  - modelos de licencia
  - `LicenseApiClient`
- App iPhone `SaludVisual.iOS`:
  - activacion de licencia contra `https://api.saludvisual.shop`
  - fingerprint iOS basado en instalacion y guardado en Keychain
  - estado de licencia guardado en Keychain
  - dashboard inicial
  - guia de filtros nativos iOS
  - guia de automatizaciones con Atajos
  - enlaces a `https://saludvisual.shop`

## Aplicar en el VPS

Desde el repo donde tengas este overlay:

```bash
chmod +x source-overlays/ScreenTintAuto/scripts/aplicar-ios-overlay.sh
source-overlays/ScreenTintAuto/scripts/aplicar-ios-overlay.sh /home/eric/work/ScreenTintAuto
```

Luego en el repo real:

```bash
cd /home/eric/work/ScreenTintAuto
git status --short
dotnet build SaludVisual.Shared/SaludVisual.Shared.csproj
```

La app iOS debe compilarse en Mac con Xcode:

```bash
dotnet workload restore SaludVisual.iOS/SaludVisual.iOS.csproj
dotnet build SaludVisual.iOS/SaludVisual.iOS.csproj -f net10.0-ios
```

## Limitacion iOS

iOS no permite overlays globales de terceros sobre otras apps. Por eso esta app
usa un flujo compatible con App Store: activar licencia, guiar filtros nativos de
iOS y ayudar a crear automatizaciones en Atajos.

## Reconstruir macOS correctamente

Tambien se incluye `scripts/reconstruir-saludvisual-macos.sh` para regenerar los
paquetes macOS con carpetas `.app` reales. Evita el error visto en paquetes con
rutas Windows tipo `SaludVisual.app\Contents\...`.

En el Mac:

```bash
cd /ruta/a/ScreenTintAuto
chmod +x scripts/reconstruir-saludvisual-macos.sh
VERSION=3.0.0 scripts/reconstruir-saludvisual-macos.sh arm64
```

Para ambas arquitecturas:

```bash
VERSION=3.0.0 scripts/reconstruir-saludvisual-macos.sh all
```

Para publicar desde la web a clientes finales, firma y notariza:

```bash
cd /ruta/a/ScreenTintAuto

MACOS_SIGN_IDENTITY="Developer ID Application: Eric Sanchez Linares (...)" \
MACOS_NOTARY_PROFILE=saludvisual-notary \
VERSION=3.0.0 \
scripts/reconstruir-saludvisual-macos.sh all
```

El perfil `saludvisual-notary` se crea una vez en el llavero del Mac:

```bash
xcrun notarytool store-credentials saludvisual-notary \
  --apple-id "TU_APPLE_ID" \
  --team-id "TU_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

El script:

1. crea bundles `.app` reales,
2. firma con Developer ID,
3. verifica `codesign`,
4. notariza el ZIP,
5. aplica `stapler` a las apps,
6. verifica con `spctl`,
7. recrea el ZIP final con los tickets stapled.
