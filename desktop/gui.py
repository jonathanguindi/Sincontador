#!/usr/bin/env python3
"""
SinApuestas — App de escritorio con ventana (Windows / macOS / Linux).

Esta es la experiencia "de app": abres la ventana, eliges qué bloquear,
la computadora te pide permiso de administrador (la ventanita del sistema),
aceptas, y queda TODO bloqueado. No hay que usar la terminal.

Cómo funciona por dentro:
  1. Al abrir, si no tiene permisos de administrador, se REINICIA pidiéndolos
     con la ventana nativa del sistema (UAC en Windows, contraseña en Mac).
  2. Ya con permiso, muestra la ventana con un botón grande "Bloquear todo".
  3. Al bloquear, escribe la lista en el archivo hosts y deja el vigilante
     corriendo para que nadie lo quite fácilmente.

Requiere Python 3 (trae tkinter incluido). Reutiliza la lógica de blocker.py.
"""

import os
import sys
import ctypes
import subprocess
import threading
import time

# --- Reutilizamos toda la lógica ya probada del bloqueador ---
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import blocker  # noqa: E402


# --------------------------------------------------------------------------- #
# 1) Pedir permisos de administrador (ventana nativa del sistema)
# --------------------------------------------------------------------------- #
def is_admin() -> bool:
    try:
        if os.name == "nt":
            return ctypes.windll.shell32.IsUserAnAdmin() != 0
        return os.geteuid() == 0
    except Exception:
        return False


def relaunch_as_admin() -> bool:
    """Reinicia esta misma app pidiendo permisos. Devuelve True si lo intentó."""
    script = os.path.abspath(__file__)
    py = sys.executable

    if os.name == "nt":
        # Windows: dispara la ventana UAC ("¿Permitir cambios?").
        params = f'"{script}"'
        ctypes.windll.shell32.ShellExecuteW(None, "runas", py, params, None, 1)
        return True

    if sys.platform == "darwin":
        # macOS: ventana nativa que pide la contraseña del usuario.
        osa = (
            f'do shell script "{py} {script}" '
            f'with administrator privileges'
        )
        subprocess.Popen(["osascript", "-e", osa])
        return True

    # Linux: intenta con pkexec (ventana gráfica) o su falla a sudo en terminal.
    for elevator in ("pkexec", "sudo"):
        if _which(elevator):
            subprocess.Popen([elevator, py, script])
            return True
    return False


def _which(cmd: str) -> bool:
    return any(
        os.access(os.path.join(p, cmd), os.X_OK)
        for p in os.environ.get("PATH", "").split(os.pathsep)
    )


# --------------------------------------------------------------------------- #
# 2) La ventana de la app
# --------------------------------------------------------------------------- #
def run_app() -> None:
    import tkinter as tk
    from tkinter import messagebox

    cfg = blocker.load_config()

    root = tk.Tk()
    root.title("SinApuestas — Bloqueo de apuestas")
    root.geometry("460x560")
    root.configure(bg="#0F766E")

    tk.Label(root, text="SinApuestas 🛡️", font=("Helvetica", 22, "bold"),
             bg="#0F766E", fg="white").pack(pady=(24, 4))
    tk.Label(root, text="Bloquea las apuestas en esta computadora",
             font=("Helvetica", 12), bg="#0F766E", fg="#CCFBF1").pack()

    card = tk.Frame(root, bg="white")
    card.pack(fill="both", expand=True, padx=20, pady=20)

    # --- Estado actual ---
    already_on = cfg.get("protection_on", False)

    if already_on:
        days = blocker.remaining_days(cfg)
        status = ("Protección ACTIVA 🛡️\n"
                  + (f"Faltan {days} días de compromiso" if days else
                     "Puedes desactivar con tu contraseña"))
        tk.Label(card, text=status, font=("Helvetica", 13, "bold"),
                 bg="white", fg="#0F766E", justify="center").pack(pady=20)

        tk.Label(card, text="Contraseña para desactivar:", bg="white").pack()
        pwd_off = tk.Entry(card, show="•", width=28)
        pwd_off.pack(pady=6)

        def desactivar():
            if not blocker.check_password(cfg, pwd_off.get()):
                messagebox.showerror("SinApuestas", "Contraseña incorrecta.")
                return
            if blocker.commitment_active(cfg):
                messagebox.showinfo(
                    "SinApuestas",
                    f"Aún faltan {blocker.remaining_days(cfg)} días de tu "
                    "compromiso. Ánimo, vas bien. 💪")
                return
            cfg["protection_on"] = False
            blocker.save_config(cfg)
            blocker.remove_block()
            messagebox.showinfo("SinApuestas", "Protección desactivada.")
            root.destroy()

        tk.Button(card, text="Desactivar protección", command=desactivar,
                  bg="#DC2626", fg="white", font=("Helvetica", 12, "bold"),
                  relief="flat", pady=8).pack(pady=10, fill="x", padx=30)
        root.mainloop()
        return

    # --- Configurar y activar ---
    tk.Label(card, text="Elige qué bloquear:", bg="white",
             font=("Helvetica", 12, "bold")).pack(pady=(16, 4), anchor="w", padx=24)

    v_apuestas = tk.BooleanVar(value=True)
    tk.Checkbutton(card, text="Todas las casas de apuestas y casinos",
                   variable=v_apuestas, bg="white").pack(anchor="w", padx=24)
    tk.Label(card, text="(bet365, betcris, stake, 1xbet, betano y cientos más)",
             bg="white", fg="#64748B", font=("Helvetica", 9)).pack(anchor="w", padx=44)

    tk.Label(card, text="Agregar otros sitios (opcional, separados por coma):",
             bg="white", font=("Helvetica", 10)).pack(anchor="w", padx=24, pady=(12, 2))
    extra = tk.Entry(card, width=40)
    extra.pack(padx=24, fill="x")

    tk.Label(card, text="Contraseña (ideal que la ponga otra persona):",
             bg="white", font=("Helvetica", 10)).pack(anchor="w", padx=24, pady=(12, 2))
    pwd1 = tk.Entry(card, show="•", width=40)
    pwd1.pack(padx=24, fill="x")
    pwd2 = tk.Entry(card, show="•", width=40)
    pwd2.pack(padx=24, fill="x", pady=(4, 0))
    tk.Label(card, text="(repite la contraseña)", bg="white", fg="#64748B",
             font=("Helvetica", 9)).pack(anchor="w", padx=24)

    tk.Label(card, text="Días de compromiso:", bg="white",
             font=("Helvetica", 10)).pack(anchor="w", padx=24, pady=(12, 2))
    days_var = tk.IntVar(value=30)
    row = tk.Frame(card, bg="white")
    row.pack(anchor="w", padx=24)
    for d in (7, 30, 90, 365):
        tk.Radiobutton(row, text=str(d), variable=days_var, value=d,
                       bg="white").pack(side="left")

    def activar():
        p1, p2 = pwd1.get(), pwd2.get()
        if len(p1) < 4:
            messagebox.showerror("SinApuestas", "La contraseña debe tener 4+ caracteres.")
            return
        if p1 != p2:
            messagebox.showerror("SinApuestas", "Las contraseñas no coinciden.")
            return
        # Agregar sitios extra que escribió el usuario
        extras = [s.strip().lower() for s in extra.get().split(",") if s.strip()]
        if extras:
            path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "domains.txt")
            with open(path, "a", encoding="utf-8") as fh:
                fh.write("\n# Agregados por el usuario\n" + "\n".join(extras) + "\n")
        blocker.save_config({
            "salt": (salt := blocker.secrets.token_hex(16)),
            "hash": blocker.hash_password(p1, salt),
            "protection_on": True,
            "lock_until": time.time() + days_var.get() * 86400,
        })
        blocker.apply_block()
        _install_service()
        messagebox.showinfo(
            "SinApuestas",
            "¡Listo! 🛡️ Las apuestas están bloqueadas en esta computadora.\n"
            "El bloqueo se mantiene solo, aunque reinicies.")
        root.destroy()

    tk.Button(card, text="🛡️  Bloquear todo", command=activar,
              bg="#0F766E", fg="white", font=("Helvetica", 15, "bold"),
              relief="flat", pady=12).pack(pady=20, fill="x", padx=30)

    root.mainloop()


def _install_service() -> None:
    """Deja el vigilante corriendo en segundo plano (best-effort)."""
    try:
        py = sys.executable
        blk = os.path.join(os.path.dirname(os.path.abspath(__file__)), "blocker.py")
        if sys.platform == "darwin" or os.name != "nt":
            subprocess.Popen([py, blk, "run"],
                             stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.Popen([py, blk, "run"],
                             creationflags=0x08000000)  # CREATE_NO_WINDOW
    except Exception:
        pass


# --------------------------------------------------------------------------- #
# Arranque
# --------------------------------------------------------------------------- #
def main() -> None:
    if not is_admin():
        if relaunch_as_admin():
            sys.exit(0)  # la copia con permisos toma el control
        # Si no se pudo elevar, seguimos igual (avisará al escribir hosts)
    run_app()


if __name__ == "__main__":
    main()
