#!/usr/bin/env bash
set -euo pipefail

TARGET_ROOT="${1:-/home/eric/work/ScreenTintAuto}"
OVERLAY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -d "$TARGET_ROOT" ]]; then
  echo "No existe el repo destino: $TARGET_ROOT" >&2
  exit 1
fi

if [[ ! -d "$TARGET_ROOT/.git" ]]; then
  echo "El destino no parece un repo Git: $TARGET_ROOT" >&2
  exit 1
fi

echo "Aplicando overlay iOS en:"
echo "$TARGET_ROOT"

cp -R "$OVERLAY_ROOT/SaludVisual.Shared" "$TARGET_ROOT/"
cp -R "$OVERLAY_ROOT/SaludVisual.iOS" "$TARGET_ROOT/"

if compgen -G "$TARGET_ROOT/*.sln" >/dev/null; then
  SLN_PATH="$(find "$TARGET_ROOT" -maxdepth 1 -name '*.sln' | sort | head -n 1)"
  echo "Anadiendo proyectos a solucion: $SLN_PATH"
  dotnet sln "$SLN_PATH" add \
    "$TARGET_ROOT/SaludVisual.Shared/SaludVisual.Shared.csproj" \
    "$TARGET_ROOT/SaludVisual.iOS/SaludVisual.iOS.csproj"
else
  echo "No se encontro .sln en la raiz; anade los .csproj manualmente si procede."
fi

echo
echo "Siguientes pasos:"
echo "  cd \"$TARGET_ROOT\""
echo "  git status --short"
echo "  dotnet workload restore SaludVisual.iOS/SaludVisual.iOS.csproj"
echo "  dotnet build SaludVisual.Shared/SaludVisual.Shared.csproj"
echo "  # En Mac con Xcode:"
echo "  dotnet build SaludVisual.iOS/SaludVisual.iOS.csproj -f net8.0-ios"
