# SinApuestas 🛡️

App Android para **bloquear el acceso a apuestas desde tu celular**: bloquea los
sitios web de casas de apuestas y las apps de apuestas instaladas, con un
"candado de compromiso" para que no puedas desactivarla en un impulso.

## Qué hace (y qué no)

**Importante ser honestos:** ninguna app puede *cerrar o bloquear tus cuentas*
en una casa de apuestas — eso solo se logra con la **autoexclusión**, que se
solicita directamente al operador o al regulador (en Panamá, la Junta de
Control de Juegos; en España, el RGIAJ de jugarbien.es). Lo que esta app sí
hace es cortar el acceso desde el teléfono:

1. **Bloqueo de sitios web** — Una VPN local (no envía tu tráfico a ningún
   servidor externo) filtra las consultas DNS del teléfono. Si el dominio está
   en la lista de apuestas (`app/src/main/res/raw/blocked_domains.txt`),
   responde "este dominio no existe" y el sitio nunca carga, en cualquier
   navegador y en las apps que usan esos dominios.
2. **Bloqueo de apps instaladas** — Un servicio de accesibilidad detecta cuando
   se abre una app de apuestas (`blocked_packages.txt`) y la cubre al instante
   con una pantalla de apoyo, regresándote al inicio.
3. **Candado de compromiso** — Al activar la protección eliges 7, 30 o 90 días.
   Durante ese período la app no permite desactivarla desde su interfaz.
   Android siempre permite desconectar una VPN desde Ajustes del sistema, así
   que es una barrera de fricción (suficiente para frenar un impulso), no un
   candado absoluto.

## Cómo compilarla

1. Abre la carpeta `sinapuestas/` en **Android Studio** (Hedgehog o más nuevo).
2. Deja que sincronice Gradle (AGP 8.5, Kotlin 1.9, compileSdk 34, minSdk 26 —
   Android 8.0 en adelante).
3. Conecta tu teléfono con depuración USB y dale **Run**, o genera el APK con
   `Build > Build APK(s)` e instálalo.

## Cómo usarla

1. Abre SinApuestas, elige el período de compromiso y toca **Activar
   protección**. Acepta la solicitud de VPN (es local, tu tráfico no sale del
   teléfono).
2. Toca **Activar bloqueo de apps instaladas** y habilita «SinApuestas» en los
   ajustes de accesibilidad (opcional pero recomendado si tienes apps de
   apuestas instaladas).
3. Listo. El filtro se reactiva solo al reiniciar el teléfono.

## Personalizar las listas

- Sitios web: agrega un dominio por línea en
  `app/src/main/res/raw/blocked_domains.txt` (se bloquean también todos sus
  subdominios).
- Apps: agrega tokens del nombre de paquete en
  `app/src/main/res/raw/blocked_packages.txt` (para saber el paquete de una
  app, mira la URL de su página en Play Store: `...id=com.ejemplo.app`).

## Limitaciones conocidas

- Solo filtra DNS sobre IPv4/UDP. Si un navegador usa su propio "DNS privado"
  (DNS-over-HTTPS), puede saltarse el filtro — desactiva el DNS privado en
  Ajustes de red para máxima cobertura.
- No funciona a la vez con otra VPN (Android solo permite una activa).
- En iPhone no se puede instalar esta app; ahí la vía equivalente es
  **Tiempo en pantalla → Restricciones de contenido** bloqueando los sitios,
  con un código que guarde otra persona.

## Si las apuestas te están haciendo daño

Este bloqueador es una herramienta de apoyo, no un tratamiento. Combínalo con:

- **Autoexclusión** ante cada casa de apuestas donde tengas cuenta (pídela por
  escrito y solicita el cierre de la cuenta).
- Bloqueo de pagos al rubro de juego: muchos bancos permiten bloquear
  transacciones con código de comercio de apuestas (MCC 7995) — pregunta en tu
  banco.
- Hablar con alguien: Jugadores Anónimos tiene grupos en toda América Latina
  (jugadoresanonimos.org).
