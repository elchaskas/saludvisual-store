#!/usr/bin/env python3
"""Validate Salud Visual ZIP packages before Store submission."""

from __future__ import annotations

import argparse
import hashlib
import re
import struct
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
WINDOWS_EXECUTABLES = (
    "InstalarSaludVisual.exe",
    "DesinstalarSaludVisual.exe",
    "SaludVisual.exe",
)


def _read_text(archive: zipfile.ZipFile, name: str) -> str:
    data = archive.read(name)
    return data.decode("utf-8-sig")


def _contains_text(data: bytes, text: str) -> bool:
    return text.encode("utf-8") in data or text.encode("utf-16le") in data


def _has_authenticode_signature(data: bytes) -> bool:
    if data[:2] != b"MZ":
        return False

    try:
        pe_offset = struct.unpack_from("<I", data, 0x3C)[0]
        if data[pe_offset : pe_offset + 4] != b"PE\0\0":
            return False

        optional_header_offset = pe_offset + 24
        magic = struct.unpack_from("<H", data, optional_header_offset)[0]
        if magic == 0x10B:
            data_directories_offset = optional_header_offset + 96
        elif magic == 0x20B:
            data_directories_offset = optional_header_offset + 112
        else:
            return False

        cert_offset, cert_size = struct.unpack_from(
            "<II", data, data_directories_offset + 32
        )
    except struct.error:
        return False

    return cert_offset > 0 and cert_size > 0


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _validate_against_previous_package(
    archive: zipfile.ZipFile, previous_path: Path
) -> list[str]:
    errors: list[str] = []

    try:
        with zipfile.ZipFile(previous_path) as previous:
            previous_names = set(previous.namelist())
            for exe_name in WINDOWS_EXECUTABLES:
                if exe_name not in archive.namelist() or exe_name not in previous_names:
                    continue

                current_hash = _sha256(archive.read(exe_name))
                previous_hash = _sha256(previous.read(exe_name))
                if current_hash == previous_hash:
                    errors.append(
                        f"{exe_name} es identico al paquete anterior; "
                        "Store puede rechazarlo como misma copia"
                    )
    except zipfile.BadZipFile:
        errors.append(f"El paquete anterior no es un ZIP valido: {previous_path}")

    return errors


def _validate_windows_package(
    path: Path, version: str, previous_package: Path | None
) -> list[str]:
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

            previous_minor_version = ".".join(version.split(".")[:2] + ["5"])
            for exe_name in WINDOWS_EXECUTABLES:
                if exe_name in names and archive.getinfo(exe_name).file_size <= 0:
                    errors.append(f"{exe_name} esta vacio")
                    continue

                if exe_name not in names:
                    continue

                exe_data = archive.read(exe_name)
                if not _has_authenticode_signature(exe_data):
                    errors.append(f"{exe_name} no contiene firma Authenticode")
                if not _contains_text(exe_data, version):
                    errors.append(f"{exe_name} no contiene la version embebida {version}")
                if previous_minor_version != version and _contains_text(
                    exe_data, previous_minor_version
                ):
                    errors.append(
                        f"{exe_name} todavia contiene referencias a "
                        f"{previous_minor_version}"
                    )

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

            if previous_package:
                errors.extend(_validate_against_previous_package(archive, previous_package))
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
    parser.add_argument(
        "--previous-package",
        type=Path,
        help="ZIP de la version anterior para detectar binarios reutilizados",
    )
    args = parser.parse_args()

    errors = []
    errors.extend(_validate_version(args.version))
    errors.extend(_validate_filename(args.zip_path, args.version, args.platform))

    if not args.zip_path.exists():
        errors.append(f"No existe el archivo: {args.zip_path}")
    elif args.previous_package and not args.previous_package.exists():
        errors.append(f"No existe el paquete anterior: {args.previous_package}")
    elif args.platform == "win-x64":
        errors.extend(
            _validate_windows_package(args.zip_path, args.version, args.previous_package)
        )

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
