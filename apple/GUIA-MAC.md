# Guía para crear la app de iPhone en tu Mac (paso a paso)

Esta guía te lleva de cero a tener la app **SinApuestas** corriendo en tu iPhone.
La app usa la tecnología oficial de Apple (**Screen Time / Family Controls**):
le pide permiso al iPhone, tú aceptas, y bloquea las apps y sitios de apuestas.

> Para **probarla en tu propio iPhone** NO necesitas esperar a Apple: se conecta
> por cable a la Mac y listo. La revisión de Apple solo hace falta para
> publicarla en la App Store y que otros la bajen.

---

## Lo que necesitas
- Una **Mac** (la tienes ✅)
- **Xcode** — gratis en la Mac App Store (busca "Xcode", ~7 GB, tarda un rato)
- Tu **iPhone** y un cable
- Un **Apple ID** (el mismo del iPhone sirve para probar; para publicar en la
  App Store hace falta la cuenta de desarrollador, 99 USD/año)

---

## Paso 1 — Crear el proyecto en Xcode
1. Abre **Xcode** → **Create New Project**
2. Elige **iOS → App** → **Next**
3. Rellena:
   - Product Name: **SinApuestas**
   - Team: elige tu Apple ID (si no aparece, "Add Account" e inicia sesión)
   - Organization Identifier: `com.tunombre` (lo que sea, sin espacios)
   - Interface: **SwiftUI** · Language: **Swift**
4. **Next** → guarda el proyecto en una carpeta.

## Paso 2 — Meter el código de SinApuestas
1. En la carpeta `apple/SinApuestasApp/` de este proyecto están los archivos:
   `SinApuestasApp.swift`, `ContentView.swift`, `BlockModel.swift`.
2. Arrástralos a la barra izquierda de Xcode (reemplaza los que Xcode creó con
   el mismo nombre; para `BlockModel.swift` y `ContentView.swift` elige
   "Replace" / arrástralos y borra los viejos).
3. Cuando pregunte, marca **"Copy items if needed"**.

## Paso 3 — Activar el permiso de Screen Time
1. Selecciona el proyecto **SinApuestas** (arriba en la barra izquierda).
2. Pestaña **Signing & Capabilities**.
3. Toca **+ Capability** (arriba a la izquierda) → busca y agrega
   **Family Controls**.
   - Esto crea el permiso que deja a la app usar Screen Time.
4. Verifica que en **Signing** esté tu Apple ID en "Team" y que diga
   "Automatically manage signing".

## Paso 4 — Probar en tu iPhone
1. Conecta el iPhone a la Mac con el cable. Si pregunta, toca "Confiar".
2. Arriba en Xcode, donde dice el dispositivo, elige **tu iPhone**.
3. Toca el botón **▶︎ (Play)**.
4. La primera vez, en el iPhone: **Ajustes → General → VPN y gestión de
   dispositivos** → confía en tu certificado de desarrollador.
5. Vuelve a darle ▶︎. La app se abre en tu iPhone.

## Paso 5 — Usar la app
1. Toca **"Conceder permiso"** → el iPhone muestra la ventana de Apple pidiendo
   permiso de Tiempo en Pantalla → **Permitir**.
2. Toca **"Seleccionar apps y sitios"** → elige las casas de apuestas que
   tengas y sus webs.
3. Elige los días de compromiso → **Activar bloqueo**.
4. Intenta abrir una app/sitio de apuestas → queda **escudado** (bloqueado). 🎉

---

## Paso 6 (opcional) — Publicar en la App Store
Para que cualquiera la baje (no solo tu iPhone):
1. Inscríbete en el **Apple Developer Program** (99 USD/año) en
   developer.apple.com.
2. Solicita el permiso de distribución de **Family Controls** (gratis) en:
   https://developer.apple.com/contact/request/family-controls-distribution
   (Apple lo aprueba para apps de bienestar como esta.)
3. En Xcode: **Product → Archive** → **Distribute App → App Store Connect**.
4. En App Store Connect completa la ficha (usa los textos de
   `docs/store-listing.md`) y envía a revisión.
5. Apple revisa en ~2–7 días. Al aprobarse, aparece en la App Store.

---

## Si te trabas
Cualquier error que te salga en Xcode, tómale captura y pásamela: te digo qué
tocar. Los errores más comunes son de "Signing" (elegir tu Apple ID en Team) o
de que falte agregar la capacidad **Family Controls** en el Paso 3.
