# Salud Visual iPhone - plan de paridad

Este documento define la app iPhone como producto separado de macOS. La app
macOS (`SaludVisual.Mac`) no se puede reutilizar directamente en iOS porque
iPhone usa iOS/iPadOS, empaquetado `.ipa` y reglas de sandbox distintas.

## Objetivo

Crear una app iPhone que acompañe a la version Windows ya vendida en la web
propia de Salud Visual:

- Web oficial: `https://saludvisual.shop`
- API de licencias: `https://api.saludvisual.shop`
- Activacion por licencia: misma API `/v1/licenses/activate` y
  `/v1/licenses/validate`
- Licencia por instalacion/dispositivo

## Restriccion importante de iOS

iOS no permite que una app normal aplique un overlay global encima de otras apps.
Por tanto, la app iPhone no debe prometer el mismo filtro global que Windows/Mac.

La solucion correcta en iPhone es guiar y automatizar, dentro de lo permitido por
iOS, las funciones nativas:

- Filtros de color
- Reducir punto blanco
- Night Shift
- Atajos/Shortcuts
- Notificaciones recordatorio
- Instrucciones guiadas para Accesibilidad

## Producto iPhone propuesto

La app debe funcionar como asistente Salud Visual para iOS:

1. Pantalla de bienvenida con marca Salud Visual.
2. Activacion de licencia.
3. Validacion periodica de licencia.
4. Selector de objetivo:
   - descanso nocturno
   - reduccion de luz blanca
   - filtro rojo/calido
   - recordatorios por horario
5. Guia paso a paso para configurar filtros nativos:
   - Ajustes > Accesibilidad > Pantalla y tamano del texto > Filtros de color
   - Ajustes > Pantalla y brillo > Night Shift
   - Ajustes > Accesibilidad > Funcion rapida
6. Guia para crear automatizaciones en Atajos:
   - al atardecer
   - a una hora concreta
   - al abrir/cerrar apps concretas, si el usuario lo desea
7. Notificaciones locales para recordar activar/desactivar ajustes cuando iOS no
   permita automatizacion silenciosa.
8. Enlaces a web, soporte y compra de licencia.

## Estructura recomendada en el repo real

En `/home/eric/work/ScreenTintAuto`:

```text
SaludVisual.iOS/
SaludVisual.Shared/
SaludVisual.Windows/
SaludVisual.Mac/
SaludVisual.LicensingApi/
web-public/
```

`SaludVisual.Shared` debe contener:

- constantes de producto
- URL web oficial
- URL API licencias
- cliente HTTP de licencias
- modelos de activacion/validacion
- generacion de fingerprint por plataforma
- version comun

## Tecnologia recomendada

Opcion preferida si se quiere mantener .NET:

- .NET MAUI para iOS (`net10.0-ios` en el Mac actual con Xcode 26)
- Requiere Mac con Xcode para compilar/publicar
- Permite compartir cliente de licencias con Windows/Mac si se extrae a
  `SaludVisual.Shared`

Opcion nativa:

- SwiftUI
- Mejor integracion con iOS
- Requiere reimplementar cliente de licencias en Swift

Para el estado actual del proyecto, la opcion mas coherente es .NET MAUI porque
el backend y las apps existentes son .NET.

## Flujo de licencia iPhone

1. La app pide clave de licencia.
2. Genera fingerprint iOS estable y no invasivo:
   - identificador de instalacion guardado en Keychain
   - no usar datos privados innecesarios
3. Llama:

   ```http
   POST https://api.saludvisual.shop/v1/licenses/activate
   ```

   con:

   ```json
   {
     "licenseKey": "SV-...",
     "deviceFingerprint": "ios:..."
   }
   ```

4. Guarda estado en Keychain.
5. En arranques posteriores llama:

   ```http
   POST https://api.saludvisual.shop/v1/licenses/validate
   ```

6. Si la validacion falla, vuelve a pantalla de activacion.

## Versionado

Windows esta actualmente en `2.2.8`. iPhone debe arrancar como:

```text
2.2.8
```

para mantener paridad comercial con web/API, aunque la funcionalidad sea propia
de iOS.

## Pantallas iniciales

1. `WelcomePage`
   - marca
   - explicacion honesta: "En iPhone usamos los filtros nativos de iOS"
2. `LicenseActivationPage`
   - clave de licencia
   - boton activar
3. `DashboardPage`
   - estado licencia
   - accesos a guias
4. `FilterGuidePage`
   - filtros de color
   - reducir punto blanco
   - Night Shift
5. `ShortcutGuidePage`
   - automatizaciones en Atajos
6. `SupportPage`
   - saludvisual.shop
   - soporte

## Pasos para implementar en el repo real

1. Crear `SaludVisual.Shared`.
2. Mover/duplicar de forma controlada el cliente de licencia de Windows a
   `SaludVisual.Shared`.
3. Crear `SaludVisual.iOS` con .NET MAUI.
4. Implementar almacenamiento seguro con Keychain.
5. Implementar pantallas de activacion y guias iOS.
6. Anadir deep links cuando iOS los permita; si una ruta de Ajustes no es
   aceptada por App Store, usar instrucciones visuales dentro de la app.
7. Probar en simulador y dispositivo real.
8. Preparar privacidad/App Store:
   - no recopilar datos sensibles
   - declarar uso de red para licencias
   - explicar que se usan ajustes nativos de iOS

## Criterios de aceptacion

- La app iPhone compila en Mac/Xcode.
- La app activa una licencia real contra `api.saludvisual.shop`.
- La licencia queda asociada a un fingerprint iOS.
- La app valida la licencia al arrancar.
- El usuario puede configurar filtros nativos siguiendo la guia.
- La app no afirma aplicar overlays globales en iOS.
- Version visible: `2.2.8`.
- Enlaces de compra/soporte apuntan a `https://saludvisual.shop`.
