#!/usr/bin/env bash
set -euo pipefail

VERSION="2.2.6"
PLATFORM="mac-osx-arm64"
CONFIGURATION="Release"
SOURCE_ROOT="."
OUTPUT_ROOT="artifacts"
PROJECT_PATH=""
PRODUCT_URL="${SALUD_VISUAL_PRODUCT_URL:-}"
LICENSE_API_URL="${SALUD_VISUAL_LICENSE_API_URL:-}"

usage() {
  cat <<'USAGE'
Build a Salud Visual macOS release staging folder.

Required:
  --product-url URL       Official product web page bundled in the app package.
  --license-api-url URL   Activation API used for one license per installation.

Options:
  --source-root PATH      Checkout containing the macOS project. Default: .
  --project PATH          Project path relative to source root.
  --version VERSION       Version in MAJOR.MINOR.PATCH format. Default: 2.2.6
  --platform PLATFORM     mac-osx-arm64 or mac-osx-x64. Default: mac-osx-arm64
  --configuration CONFIG  dotnet configuration. Default: Release
  --output-root PATH      Artifact root. Default: artifacts
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-root) SOURCE_ROOT="$2"; shift 2 ;;
    --project) PROJECT_PATH="$2"; shift 2 ;;
    --version) VERSION="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --configuration) CONFIGURATION="$2"; shift 2 ;;
    --output-root) OUTPUT_ROOT="$2"; shift 2 ;;
    --product-url) PRODUCT_URL="$2"; shift 2 ;;
    --license-api-url) LICENSE_API_URL="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must use MAJOR.MINOR.PATCH format. Received: $VERSION" >&2
  exit 2
fi

case "$PLATFORM" in
  mac-osx-arm64) RUNTIME="osx-arm64" ;;
  mac-osx-x64) RUNTIME="osx-x64" ;;
  *) echo "Unsupported platform: $PLATFORM" >&2; exit 2 ;;
esac

if [[ -z "$PRODUCT_URL" ]]; then
  echo "Missing --product-url or SALUD_VISUAL_PRODUCT_URL." >&2
  exit 2
fi
if [[ -z "$LICENSE_API_URL" ]]; then
  echo "Missing --license-api-url or SALUD_VISUAL_LICENSE_API_URL." >&2
  exit 2
fi

SOURCE_ROOT="$(cd "$SOURCE_ROOT" && pwd)"
ARTIFACT_ROOT="$SOURCE_ROOT/$OUTPUT_ROOT/v$VERSION"
PUBLISH_ROOT="$ARTIFACT_ROOT/publish/$PLATFORM"
STAGING_ROOT="$ARTIFACT_ROOT/staging/$PLATFORM"

if [[ -z "$PROJECT_PATH" ]]; then
  for candidate in \
    "SaludVisual.Mac/SaludVisual.Mac.csproj" \
    "SaludVisual.MacOS/SaludVisual.MacOS.csproj" \
    "SaludVisual/SaludVisual.csproj"; do
    if [[ -f "$SOURCE_ROOT/$candidate" ]]; then
      PROJECT_PATH="$candidate"
      break
    fi
  done
fi

if [[ -z "$PROJECT_PATH" || ! -f "$SOURCE_ROOT/$PROJECT_PATH" ]]; then
  echo "Missing macOS project. Pass --project relative/to/Project.csproj." >&2
  exit 1
fi

rm -rf "$PUBLISH_ROOT" "$STAGING_ROOT"
mkdir -p "$PUBLISH_ROOT" "$STAGING_ROOT"

echo "Building Salud Visual $VERSION for $PLATFORM ($RUNTIME)"
dotnet publish "$SOURCE_ROOT/$PROJECT_PATH" \
  -c "$CONFIGURATION" \
  -r "$RUNTIME" \
  --self-contained true \
  -p:PublishSingleFile=true \
  -p:Version="$VERSION" \
  -p:FileVersion="$VERSION.0" \
  -p:AssemblyVersion="$VERSION.0" \
  -p:InformationalVersion="$VERSION" \
  -o "$PUBLISH_ROOT"

APP_SOURCE=""
if [[ -d "$PUBLISH_ROOT/SaludVisual.app" ]]; then
  APP_SOURCE="$PUBLISH_ROOT/SaludVisual.app"
else
  APP_SOURCE="$STAGING_ROOT/SaludVisual.app"
  mkdir -p "$APP_SOURCE/Contents/MacOS" "$APP_SOURCE/Contents/Resources"
  if [[ -x "$PUBLISH_ROOT/SaludVisual" ]]; then
    cp "$PUBLISH_ROOT/SaludVisual" "$APP_SOURCE/Contents/MacOS/SaludVisual"
  elif [[ -x "$PUBLISH_ROOT/SaludVisual.Mac" ]]; then
    cp "$PUBLISH_ROOT/SaludVisual.Mac" "$APP_SOURCE/Contents/MacOS/SaludVisual"
  else
    echo "Publish did not produce SaludVisual executable in $PUBLISH_ROOT" >&2
    exit 1
  fi
  chmod 755 "$APP_SOURCE/Contents/MacOS/SaludVisual"
  cat > "$APP_SOURCE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Salud Visual</string>
  <key>CFBundleExecutable</key>
  <string>SaludVisual</string>
  <key>CFBundleIdentifier</key>
  <string>com.saludvisual.app</string>
  <key>CFBundleName</key>
  <string>SaludVisual</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
</dict>
</plist>
PLIST
fi

if [[ "$APP_SOURCE" != "$STAGING_ROOT/SaludVisual.app" ]]; then
  cp -R "$APP_SOURCE" "$STAGING_ROOT/SaludVisual.app"
fi

RESOURCE_ROOT="$STAGING_ROOT/SaludVisual.app/Contents/Resources"
mkdir -p "$RESOURCE_ROOT"
cat > "$RESOURCE_ROOT/activation-config.json" <<JSON
{
  "application": "Salud Visual",
  "version": "$VERSION",
  "platform": "$PLATFORM",
  "productUrl": "$PRODUCT_URL",
  "licenseApiUrl": "$LICENSE_API_URL",
  "licenseMode": "per-installation"
}
JSON

cat > "$STAGING_ROOT/VERSION.txt" <<VERSION_TXT
Salud Visual $VERSION
macOS $PLATFORM
Empaquetado: pendiente de firma/notarizacion
VERSION_TXT

cat > "$STAGING_ROOT/README.txt" <<README_TXT
Salud Visual v$VERSION (macOS $PLATFORM)

Web oficial:
$PRODUCT_URL

Licencia de activacion:
- Cada instalacion de macOS debe activar una licencia propia.
- La app incluye activation-config.json con licenseMode=per-installation.
- Endpoint de activacion: $LICENSE_API_URL

Distribucion:
1) Firmar SaludVisual.app con Developer ID Application.
2) Notarizar el ZIP/DMG final con Apple.
3) Validar el paquete con scripts/validate_store_package.py.
README_TXT

cat > "$STAGING_ROOT/LICENSE-ACTIVATION.txt" <<LICENSE_TXT
Salud Visual v$VERSION - macOS

Web oficial:
$PRODUCT_URL

Licencia por instalacion:
- Cada Mac genera/usa una activacion propia.
- No se debe compartir una licencia de Windows con macOS.
- La configuracion incluida en la app apunta a:
  $LICENSE_API_URL
LICENSE_TXT

echo "Build complete. Staging folder:"
echo "$STAGING_ROOT"
