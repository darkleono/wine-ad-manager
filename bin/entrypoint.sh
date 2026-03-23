#!/bin/bash
set -e

echo "--- Gestión de Persistencia y Volúmenes ---"
# Si el archivo de licencia no existe en /app, significa que el volumen está vacío
if [ ! -f "/app/licenses.lic" ]; then
    echo "--- Volúmen vacío detectado. Poblado con archivos por defecto ---"
    # Copiamos todo excepto el propio entrypoint que ya está corriendo desde /app_defaults/
    cp -rv /app_defaults/* /app/
else
    echo "--- Volúmen existente detectado. Respetando archivos actuales ---"
fi

echo "--- Iniciando Configuración de Red ---"
# Variables de entorno con defaults
MAC_TARGET="${MAC_ADDRESS:-66:12:8f:d2:36:30}"
HOST_TARGET="${HOSTNAME_ID:-win-license-lab}"
PORT_WEB="${PORT_DASHBOARD:-8080}"

# Forzar la MAC necesaria para la licencia (requiere NET_ADMIN)
ip link set dev eth0 down 2>/dev/null || true
ip link set dev eth0 address "$MAC_TARGET" 2>/dev/null || true
ip link set dev eth0 up 2>/dev/null || true

echo "MAC actual en el contenedor:"
cat /sys/class/net/eth0/address || echo "No se pudo leer la MAC"

# Limpieza de locks de Xvfb
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Resolución de host local (indispensable para FlexLM)
echo "127.0.0.1 $HOST_TARGET" >> /etc/hosts
echo "IP local resuelta para: $HOST_TARGET"

# Iniciar Framebuffer virtual
Xvfb :99 -ac -screen 0 1x1x8 &
sleep 2

echo "Iniciando Dashboard en puerto $PORT_WEB..."
# Pasamos el puerto a app.py
python3 /app/app.py --port "$PORT_WEB" &

echo "Iniciando Autodesk License Manager via Wine..."
touch /app/debug.log
# Ejecutamos lmgrd y usamos tail para mantener el log visible
wine /app/lmgrd.exe -z -c /app/licenses.lic -l /app/debug.log &

sleep 2
exec tail -F /app/debug.log
