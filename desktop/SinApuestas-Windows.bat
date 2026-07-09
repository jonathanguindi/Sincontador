@echo off
REM SinApuestas para Windows — doble clic para abrir la app.
REM Abre la ventana sin consola; la app pedira permiso de administrador (UAC).
cd /d "%~dp0"
start "" pythonw gui.py
if errorlevel 1 start "" python gui.py
