#!/bin/bash
# SinApuestas para Mac — doble clic para abrir la app.
# La primera vez, Mac puede pedir "clic derecho > Abrir" por seguridad.
cd "$(dirname "$0")"
python3 gui.py
