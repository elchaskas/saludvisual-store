# Salud Visual v2.2.6 - preparacion para Microsoft Store

Este repositorio contiene los metadatos y controles de publicacion para la entrega
de Salud Visual en Microsoft Store. El codigo fuente y los binarios finales no estan
incluidos en este checkout; por eso la generacion del paquete requiere partir de los
proyectos usados para compilar los artefactos de la version anterior.

## Version objetivo

- Version: `2.2.6`
- Plataforma Store: Windows x64 / Win32
- Paquete esperado: `SaludVisual-2.2.6-win-x64.zip`
- Instalador recomendado: `InstalarSaludVisual.exe`
- Comando de instalacion silenciosa: `InstalarSaludVisual.exe /silent`
- Comando de desinstalacion silenciosa: `DesinstalarSaludVisual.exe /silent`
- Codigos de retorno: ver `RETURN_CODES.md`

## Contenido requerido del ZIP Windows

El ZIP para Store debe incluir, como minimo:

- `InstalarSaludVisual.exe`
- `DesinstalarSaludVisual.exe`
- `SaludVisual.exe`
- `VERSION.txt`
- `README.txt`
- `LEEME-INSTALADOR-GUI.txt`

Archivos opcionales pero recomendados:

- `salud-visual.ico`
- `Instalar-SaludVisual-v2-SinAdmin.cmd`

## Checklist antes de subir a Store

1. Compilar los proyectos Windows en modo Release para `win-x64`.
2. Confirmar que todos los binarios reportan version de producto `2.2.6`.
3. Firmar digitalmente `SaludVisual.exe`, `InstalarSaludVisual.exe` y
   `DesinstalarSaludVisual.exe`.
4. Empaquetar el contenido como `SaludVisual-2.2.6-win-x64.zip`.
5. Ejecutar la validacion local:

   ```bash
   python3 scripts/validate_store_package.py SaludVisual-2.2.6-win-x64.zip
   ```

6. Probar instalacion silenciosa en una maquina Windows limpia:

   ```powershell
   .\InstalarSaludVisual.exe /silent
   echo $LASTEXITCODE
   ```

7. Probar desinstalacion silenciosa:

   ```powershell
   .\DesinstalarSaludVisual.exe /silent
   echo $LASTEXITCODE
   ```

8. Verificar que ambos comandos devuelven `0` en caso exitoso.

## Importante: no reutilizar binarios 2.2.5

El paquete `v2.2.5` publicado en GitHub contiene ejecutables firmados con
version embebida `2.2.5.0`:

- `SaludVisual.exe`
- `InstalarSaludVisual.exe`
- `DesinstalarSaludVisual.exe`

Renombrar el ZIP, cambiar solo `README.txt`/`VERSION.txt` o parchear esos
`.exe` no produce una version Store valida:

- Si se dejan los `.exe` intactos, Microsoft Store puede detectarlo como la
  misma copia/binario que el envio anterior.
- Si se editan los `.exe` para cambiar `2.2.5` por `2.2.6`, se invalida la
  firma Authenticode existente.

La ruta segura para `2.2.6` es rebuild de los tres ejecutables con version
`2.2.6.0` y firma nueva con el certificado de publicador usado para `2.2.5`
(`CN = Eric Sanchez Linares`, cadena SSL.com Code Signing).

Se probo crear un candidato `SaludVisual-2.2.6-win-x64.zip` partiendo del ZIP
`2.2.5` y cambiando solo textos (`README.txt`, `LEEME-INSTALADOR-GUI.txt` y
`VERSION.txt`). El validador lo rechaza porque los tres `.exe` siguen siendo
binarios `2.2.5`, firmados e identicos al envio anterior.

Para detectar ese caso antes de subir a Partner Center:

```bash
python3 scripts/validate_store_package.py \
  SaludVisual-2.2.6-win-x64.zip \
  --previous-package artifacts/v2.2.5/SaludVisual-2.2.5-win-x64.zip
```

## Nota de estado

Al preparar esta rama se confirmo que:

- El release `v2.2.5` existe en GitHub con artefactos Windows y macOS.
- Los ejecutables Windows de `v2.2.5` estan firmados y contienen version
  embebida `2.2.5.0`; no deben reutilizarse para `2.2.6`.
- No hay artefactos publicos `2.2.6` en el contenedor Azure usado por releases
  previos.
- Este repositorio no contiene los proyectos `.csproj` necesarios para recompilar
  la aplicacion desde cero.
