#!/usr/bin/env bash
set -euo pipefail

VERSION="${VERSION:-2.2.8}"
CONFIGURATION="${CONFIGURATION:-Release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_ROOT="$ROOT_DIR/artifacts/v$VERSION"

usage() {
  cat <<'USAGE'
Reconstruye Salud Visual para macOS generando bundles .app reales.

Uso:
  scripts/reconstruir-saludvisual-macos.sh [arm64|x64|all]

Variables:
  VERSION=2.2.8
  CONFIGURATION=Release

Ejemplos:
  VERSION=2.2.8 scripts/reconstruir-saludvisual-macos.sh arm64
  VERSION=2.2.8 scripts/reconstruir-saludvisual-macos.sh all
USAGE
}

TARGET="${1:-arm64}"
case "$TARGET" in
  arm64) PLATFORMS=("mac-osx-arm64:osx-arm64") ;;
  x64) PLATFORMS=("mac-osx-x64:osx-x64") ;;
  all) PLATFORMS=("mac-osx-arm64:osx-arm64" "mac-osx-x64:osx-x64") ;;
  -h|--help) usage; exit 0 ;;
  *) echo "Destino no valido: $TARGET" >&2; usage >&2; exit 2 ;;
esac

require_file() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "Falta archivo requerido: $path" >&2
    exit 1
  fi
}

write_info_plist() {
  local app_name="$1"
  local executable="$2"
  local identifier="$3"
  local plist_path="$4"

  cat > "$plist_path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$app_name</string>
  <key>CFBundleExecutable</key>
  <string>$executable</string>
  <key>CFBundleIdentifier</key>
  <string>$identifier</string>
  <key>CFBundleName</key>
  <string>$executable</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundleIconFile</key>
  <string>Icon</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
</dict>
</plist>
PLIST
}

stage_app() {
  local publish_dir="$1"
  local staging_dir="$2"
  local app_dir="$3"
  local executable="$4"
  local display_name="$5"
  local identifier="$6"

  local source_exe="$publish_dir/$executable"
  require_file "$source_exe"

  rm -rf "$app_dir"
  mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"

  cp "$source_exe" "$app_dir/Contents/MacOS/$executable"
  chmod 755 "$app_dir/Contents/MacOS/$executable"

  if [[ -f "$ROOT_DIR/SaludVisual.Mac/Icon.icns" ]]; then
    cp "$ROOT_DIR/SaludVisual.Mac/Icon.icns" "$app_dir/Contents/Resources/Icon.icns"
  fi
  if [[ -f "$ROOT_DIR/salud-visual.ico" ]]; then
    cp "$ROOT_DIR/salud-visual.ico" "$app_dir/Contents/Resources/salud-visual.ico"
  fi

  write_info_plist "$display_name" "$executable" "$identifier" "$app_dir/Contents/Info.plist"

  /usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$app_dir/Contents/Info.plist" >/dev/null
  if [[ ! -x "$app_dir/Contents/MacOS/$executable" ]]; then
    echo "El ejecutable no tiene permisos de ejecucion: $app_dir/Contents/MacOS/$executable" >&2
    exit 1
  fi

  mkdir -p "$staging_dir"
}

build_platform() {
  local platform_runtime="$1"
  local platform="${platform_runtime%%:*}"
  local runtime="${platform_runtime##*:}"
  local publish_root="$ARTIFACT_ROOT/publish/$platform"
  local staging_root="$ARTIFACT_ROOT/staging/$platform"
  local package_path="$ARTIFACT_ROOT/SaludVisual-$VERSION-$platform.zip"

  echo "== Construyendo $platform ($runtime) =="
  rm -rf "$publish_root" "$staging_root"
  mkdir -p "$publish_root/app" "$publish_root/installer" "$staging_root"

  dotnet publish "$ROOT_DIR/SaludVisual.Mac/SaludVisual.Mac.csproj" \
    -c "$CONFIGURATION" \
    -r "$runtime" \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:Version="$VERSION" \
    -p:InformationalVersion="$VERSION" \
    -o "$publish_root/app"

  dotnet publish "$ROOT_DIR/SaludVisual.MacInstaller/SaludVisual.MacInstaller.csproj" \
    -c "$CONFIGURATION" \
    -r "$runtime" \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:Version="$VERSION" \
    -p:InformationalVersion="$VERSION" \
    -o "$publish_root/installer"

  stage_app \
    "$publish_root/app" \
    "$staging_root" \
    "$staging_root/SaludVisual.app" \
    "SaludVisual" \
    "Salud Visual" \
    "shop.saludvisual.mac"

  stage_app \
    "$publish_root/installer" \
    "$staging_root" \
    "$staging_root/InstalarSaludVisual.app" \
    "InstalarSaludVisual" \
    "Instalar Salud Visual" \
    "shop.saludvisual.mac.installer"

  cat > "$staging_root/LEEME-macOS.txt" <<README
Salud Visual v$VERSION para macOS

Instalacion:
1. Abre InstalarSaludVisual.app.
2. Si macOS bloquea la app por seguridad, usa clic derecho > Abrir.
3. La app principal es SaludVisual.app.

Web oficial:
https://saludvisual.shop
README

  rm -f "$package_path"
  if command -v ditto >/dev/null 2>&1; then
    (cd "$staging_root" && ditto -c -k --sequesterRsrc --keepParent . "$package_path")
  else
    (cd "$staging_root" && zip -qry "$package_path" .)
  fi

  echo "Paquete listo: $package_path"
  echo "Comprobando bundles reales:"
  find "$staging_root" -maxdepth 2 -type d -name "*.app" -print
}

require_file "$ROOT_DIR/SaludVisual.Mac/SaludVisual.Mac.csproj"
require_file "$ROOT_DIR/SaludVisual.MacInstaller/SaludVisual.MacInstaller.csproj"

for platform_runtime in "${PLATFORMS[@]}"; do
  build_platform "$platform_runtime"
done

echo
echo "Reconstruccion macOS finalizada."
