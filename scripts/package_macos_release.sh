#!/usr/bin/env bash
set -euo pipefail

VERSION="2.2.6"
PLATFORM="mac-osx-arm64"
ARTIFACT_ROOT="artifacts"
REQUIRE_SIGNATURE="false"
WORKING_DIR="$(pwd)"

usage() {
  cat <<'USAGE'
Package a staged Salud Visual macOS build.

Options:
  --version VERSION       Version in MAJOR.MINOR.PATCH format. Default: 2.2.6
  --platform PLATFORM     mac-osx-arm64 or mac-osx-x64. Default: mac-osx-arm64
  --artifact-root PATH    Artifact root. Default: artifacts
  --require-signature     Fail unless codesign verifies SaludVisual.app.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --artifact-root) ARTIFACT_ROOT="$2"; shift 2 ;;
    --require-signature) REQUIRE_SIGNATURE="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Version must use MAJOR.MINOR.PATCH format. Received: $VERSION" >&2
  exit 2
fi

case "$PLATFORM" in
  mac-osx-arm64|mac-osx-x64) ;;
  *) echo "Unsupported platform: $PLATFORM" >&2; exit 2 ;;
esac

RELEASE_ROOT="$ARTIFACT_ROOT/v$VERSION/staging/$PLATFORM"
PACKAGE_DIR="$ARTIFACT_ROOT/v$VERSION"
PACKAGE_PATH="$PACKAGE_DIR/SaludVisual-$VERSION-$PLATFORM.zip"
APP_PATH="$RELEASE_ROOT/SaludVisual.app"
CONFIG_PATH="$APP_PATH/Contents/Resources/activation-config.json"
if [[ "$PACKAGE_PATH" != /* ]]; then
  PACKAGE_PATH="$WORKING_DIR/$PACKAGE_PATH"
fi

for required in \
  "$APP_PATH/Contents/Info.plist" \
  "$APP_PATH/Contents/MacOS/SaludVisual" \
  "$CONFIG_PATH" \
  "$RELEASE_ROOT/README.txt" \
  "$RELEASE_ROOT/VERSION.txt" \
  "$RELEASE_ROOT/LICENSE-ACTIVATION.txt"; do
  if [[ ! -e "$required" ]]; then
    echo "Missing required package file: $required" >&2
    exit 1
  fi
done

if ! grep -q "\"licenseMode\": \"per-installation\"" "$CONFIG_PATH"; then
  echo "activation-config.json must set licenseMode=per-installation" >&2
  exit 1
fi
if ! grep -q "\"productUrl\"" "$CONFIG_PATH"; then
  echo "activation-config.json must include productUrl" >&2
  exit 1
fi
if ! grep -q "\"licenseApiUrl\"" "$CONFIG_PATH"; then
  echo "activation-config.json must include licenseApiUrl" >&2
  exit 1
fi
if ! grep -q "$VERSION" "$APP_PATH/Contents/Info.plist"; then
  echo "Info.plist must include version $VERSION" >&2
  exit 1
fi

if command -v codesign >/dev/null 2>&1; then
  if ! codesign --verify --deep --strict "$APP_PATH"; then
    if [[ "$REQUIRE_SIGNATURE" == "true" ]]; then
      echo "codesign verification failed for $APP_PATH" >&2
      exit 1
    fi
    echo "Warning: codesign verification failed; package will be unsigned." >&2
  fi
elif [[ "$REQUIRE_SIGNATURE" == "true" ]]; then
  echo "codesign is required but not available." >&2
  exit 1
fi

mkdir -p "$PACKAGE_DIR"
rm -f "$PACKAGE_PATH"

if command -v ditto >/dev/null 2>&1; then
  ditto -c -k --keepParent "$RELEASE_ROOT" "$PACKAGE_PATH"
else
  (cd "$RELEASE_ROOT" && zip -qry "$PACKAGE_PATH" .)
fi

echo "Package ready:"
echo "$PACKAGE_PATH"
