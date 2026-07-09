# SinApuestas — Computadora (Windows / macOS / Linux)

App para bloquear las apuestas en tu computadora **sin VPN**. Es una app con
ventana: la abres, eliges qué bloquear, la computadora te pide permiso, aceptas
y queda **todo bloqueado**. No hay que usar la terminal.

## Cómo usarla (fácil, doble clic)

Necesitas **Python 3** instalado (en Mac ya viene; en Windows se baja gratis de
python.org — marca "Add Python to PATH" al instalar).

- **Windows:** doble clic en **`SinApuestas-Windows.bat`**
- **Mac:** doble clic en **`SinApuestas-Mac.command`**
  *(la primera vez, si Mac lo bloquea: clic derecho → Abrir → Abrir)*

Al abrir:
1. La computadora te pide **permiso de administrador** (ventana del sistema).
   Acéptalo — es lo que le da poder para bloquear.
2. Elige qué bloquear (viene marcado "todas las casas de apuestas y casinos") y,
   si quieres, escribe otros sitios.
3. Pon una **contraseña** (ideal que la ponga otra persona) y los **días de
   compromiso**.
4. Toca **"🛡️ Bloquear todo"**. ¡Listo!

El bloqueo se mantiene solo, aunque reinicies la computadora. Para desactivarlo,
abres la app otra vez y pones la contraseña (solo funciona si ya pasó el período
de compromiso).

## ¿Qué bloquea?
Cientos de casas de apuestas y casinos de todo el mundo (bet365, betcris, stake,
1xbet, betano, caliente y muchas más), por IPv4 e IPv6. Además, un "vigilante"
repara el bloqueo si alguien intenta quitarlo.

## Para técnicos: modo por línea de comandos
Si prefieres la terminal, `blocker.py` sigue disponible:
`sudo python3 blocker.py setup | status | stop | apply`. Y `update_worldwide.py`
descarga listas públicas gigantes para cobertura mundial. Ver comentarios en los
archivos.

## Limitación honesta
Con permisos de administrador, alguien decidido puede detener el servicio. Por
eso lo más fuerte es que **la contraseña la tenga otra persona** y usar un
período de compromiso largo. La mayoría de casas de apuestas en computadora se
usan por navegador, así que quedan cubiertas.
