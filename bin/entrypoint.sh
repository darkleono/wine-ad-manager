#!/bin/bash
set -e

echo "--- Iniciando Configuración de Red ---"
# Forzar la MAC necesaria para la licencia (requiere NET_ADMIN en Easypanel)
ip link set dev eth0 down 2>/dev/null || true
ip link set dev eth0 address 66:12:8f:d2:36:30 2>/dev/null || true
ip link set dev eth0 up 2>/dev/null || true

echo "MAC actual en el contenedor:"
cat /sys/class/net/eth0/address || echo "No se pudo leer la MAC"

# Limpieza de locks de Xvfb
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Resolución de host local (indispensable para FlexLM)
echo "127.0.0.1 win-license-lab" >> /etc/hosts

# Iniciar Framebuffer virtual en el background (Resolución mínima para ahorrar RAM)
Xvfb :99 -ac -screen 0 1x1x8 &
sleep 2

echo "Iniciando Dashboard en puerto 8080..."
python3 /app/app.py &

echo "Iniciando Autodesk License Manager via Wine..."
touch /app/debug.log
# Ejecutamos lmgrd y usamos tail para mantener el log visible
wine /app/lmgrd.exe -z -c /app/licenses.lic -l /app/debug.log &

sleep 2
exec tail -F /app/debug.log
