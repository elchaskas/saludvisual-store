#!/usr/bin/env python3
"""Validate Salud Visual ZIP packages before Store submission."""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path


REQUIRED_WINDOWS_FILES = {
    "DesinstalarSaludVisual.exe",
    "InstalarSaludVisual.exe",
    "LEEME-INSTALADOR-GUI.txt",
    "README.txt",
    "SaludVisual.exe",
    "VERSION.txt",
}

RECOMMENDED_WINDOWS_FILES = {
    "Instalar-SaludVisual-v2-SinAdmin.cmd",
    "salud-visual.ico",
}

STORE_INSTALL_COMMAND = "InstalarSaludVisual.exe /silent"
STORE_UNINSTALL_COMMAND = "DesinstalarSaludVisual.exe /silent"


def _read_text(archive: zipfile.ZipFile, name: str) -> str:
    data = archive.read(name)
    return data.decode("utf-8-sig")


def _validate_windows_package(path: Path, version: str) -> list[str]:
    errors: list[str] = []

    try:
        with zipfile.ZipFile(path) as archive:
            names = set(archive.namelist())
            missing = sorted(REQUIRED_WINDOWS_FILES - names)
            if missing:
                errors.append(f"Faltan archivos requeridos: {', '.join(missing)}")

            missing_recommended = sorted(RECOMMENDED_WINDOWS_FILES - names)
            if missing_recommended:
                print(
                    "Advertencia: faltan archivos recomendados: "
                    + ", ".join(missing_recommended),
                    file=sys.stderr,
                )

            for exe_name in (
                "InstalarSaludVisual.exe",
                "DesinstalarSaludVisual.exe",
                "SaludVisual.exe",
            ):
                if exe_name in names and archive.getinfo(exe_name).file_size <= 0:
                    errors.append(f"{exe_name} esta vacio")

            if "VERSION.txt" in names:
                version_text = _read_text(archive, "VERSION.txt")
                if f"Salud Visual {version}" not in version_text:
                    errors.append("VERSION.txt no contiene la version esperada")

            for text_name in ("README.txt", "LEEME-INSTALADOR-GUI.txt"):
                if text_name not in names:
                    continue

                text = _read_text(archive, text_name)
                if f"v{version}" not in text:
                    errors.append(f"{text_name} no menciona v{version}")
                if STORE_INSTALL_COMMAND not in text:
                    errors.append(
                        f"{text_name} no documenta '{STORE_INSTALL_COMMAND}'"
                    )
                if STORE_UNINSTALL_COMMAND not in text:
                    errors.append(
                        f"{text_name} no documenta '{STORE_UNINSTALL_COMMAND}'"
                    )

            if "README.txt" in names:
                readme = _read_text(archive, "README.txt")
                if "Microsoft Store" not in readme:
                    errors.append("README.txt no menciona Microsoft Store")

            if "Instalar-SaludVisual-v2-SinAdmin.cmd" in names:
                cmd = _read_text(archive, "Instalar-SaludVisual-v2-SinAdmin.cmd")
                if "%LOCALAPPDATA%\\SaludVisual" not in cmd:
                    errors.append("El instalador CMD no usa %LOCALAPPDATA%\\SaludVisual")
                if "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" not in cmd:
                    errors.append("El instalador CMD no configura el inicio automatico HKCU")
    except zipfile.BadZipFile:
        errors.append("El archivo no es un ZIP valido")

    return errors


def _validate_filename(path: Path, version: str, platform: str) -> list[str]:
    expected = f"SaludVisual-{version}-{platform}.zip"
    if path.name != expected:
        return [f"Nombre de archivo esperado: {expected}"]
    return []


def _validate_version(version: str) -> list[str]:
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        return ["La version debe tener formato MAJOR.MINOR.PATCH"]
    return []


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Valida un ZIP de Salud Visual antes de subirlo a la Store."
    )
    parser.add_argument("zip_path", type=Path, help="Ruta del paquete ZIP")
    parser.add_argument("--version", default="2.2.6", help="Version esperada")
    parser.add_argument(
        "--platform",
        default="win-x64",
        choices=("win-x64",),
        help="Plataforma del paquete a validar",
    )
    args = parser.parse_args()

    errors = []
    errors.extend(_validate_version(args.version))
    errors.extend(_validate_filename(args.zip_path, args.version, args.platform))

    if not args.zip_path.exists():
        errors.append(f"No existe el archivo: {args.zip_path}")
    elif args.platform == "win-x64":
        errors.extend(_validate_windows_package(args.zip_path, args.version))

    if errors:
        print("Validacion fallida:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"OK: {args.zip_path} listo para revision de Store.")
    print(f"Install command: {STORE_INSTALL_COMMAND}")
    print(f"Uninstall command: {STORE_UNINSTALL_COMMAND}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
