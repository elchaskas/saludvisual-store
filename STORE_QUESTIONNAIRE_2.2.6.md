# Salud Visual v2.2.6 - datos para cuestionario Microsoft Store

## Informacion de paquete Win32

- Nombre de aplicacion: Salud Visual
- Version: 2.2.6
- Plataforma: Windows x64 / Win32
- Archivo para subir: `SaludVisual-2.2.6-win-x64.zip`
- Instalador: `InstalarSaludVisual.exe`
- Desinstalador: `DesinstalarSaludVisual.exe`
- Aplicacion principal: `SaludVisual.exe`
- Tipo de instalacion: por usuario, sin privilegios de administrador
- Carpeta de instalacion: `%LOCALAPPDATA%\SaludVisual`
- Inicio automatico: `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`
- Log local: `%LOCALAPPDATA%\SaludVisual\salud-visual.log`

## Comandos Microsoft Store

- Install command:

  ```text
  InstalarSaludVisual.exe /silent
  ```

- Uninstall command:

  ```text
  DesinstalarSaludVisual.exe /silent
  ```

## Codigos de retorno

### Instalador

- `0`: instalacion correcta
- `1`: error generico
- `2`: payload de aplicacion no encontrado

### Desinstalador

- `0`: desinstalacion correcta
- `1`: error generico

## Capacidades / comportamiento

- La aplicacion aplica un filtro visual de temperatura/intensidad de color para
  reducir fatiga visual.
- Se ejecuta en segundo plano con icono en la bandeja del sistema.
- Permite pausar/reanudar el filtro y ajustar configuracion desde la interfaz.
- Puede usar ubicacion por IP o ubicacion manual para ajustar dia/noche.
- No requiere servicios Windows ni instalacion por maquina.
- No requiere permisos de administrador para instalar o desinstalar.

## Datos y privacidad

- La configuracion principal se almacena localmente en:
  `HKCU\Software\ScreenTintAuto`
- El log tecnico se almacena localmente en:
  `%LOCALAPPDATA%\SaludVisual\salud-visual.log`
- La aplicacion no requiere cuenta de usuario.
- La aplicacion no vende datos personales.
- Si se usa ubicacion por IP, la finalidad es ajustar automaticamente el modo
  dia/noche; tambien existe configuracion manual.

## Firma y publicador

- Los ejecutables deben estar firmados antes de empaquetar.
- Certificado esperado: `CN = Eric Sanchez Linares`
- Cadena observada en `v2.2.5`: SSL.com Code Signing.
- Validar firma antes de subir:

  ```powershell
  Get-AuthenticodeSignature .\SaludVisual.exe
  Get-AuthenticodeSignature .\InstalarSaludVisual.exe
  Get-AuthenticodeSignature .\DesinstalarSaludVisual.exe
  ```

## Checklist final antes de enviar

1. Confirmar que el ZIP se llama `SaludVisual-2.2.6-win-x64.zip`.
2. Confirmar que los tres `.exe` tienen version `2.2.6.0`.
3. Confirmar que los tres `.exe` tienen firma Authenticode valida.
4. Confirmar que el ZIP no reutiliza binarios identicos de `2.2.5`.
5. Ejecutar:

   ```bash
   python3 scripts/validate_store_package.py \
     artifacts/v2.2.6/SaludVisual-2.2.6-win-x64.zip \
     --previous-package artifacts/v2.2.5/SaludVisual-2.2.5-win-x64.zip
   ```

6. Probar instalacion silenciosa:

   ```powershell
   .\InstalarSaludVisual.exe /silent
   echo $LASTEXITCODE
   ```

7. Probar desinstalacion silenciosa:

   ```powershell
   .\DesinstalarSaludVisual.exe /silent
   echo $LASTEXITCODE
   ```
