#!/bin/bash
set -e

echo "--- Gestión de Persistencia y Volúmenes ---"
# Si el archivo de licencia no existe en /app, significa que el volumen está vacío
if [ ! -f "/app/licenses.lic" ]; then
    echo "--- Volúmen vacío detectado. Poblado con archivos por defecto ---"
    cp -rv /app_defaults/* /app/
else
    echo "--- Volúmen existente detectado. Respetando archivos actuales ---"
fi

echo "--- Iniciando Configuración de Red ---"
HOST_TARGET="${HOSTNAME_ID:-win-license-lab}"
PORT_WEB="${PORT_DASHBOARD:-8080}"

# Limpieza de locks de Xvfb
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

# Resolución de host local (indispensable para FlexLM)
echo "127.0.0.1 $HOST_TARGET" >> /etc/hosts

# Iniciar Framebuffer virtual
Xvfb :99 -ac -screen 0 1x1x8 &
sleep 2

echo "Iniciando Dashboard en puerto $PORT_WEB..."
# Ejecutamos el Dashboard en segundo plano
python3 /app/app.py --port "$PORT_WEB" &

# Lógica para configurar MAX_BORROW_HOURS dinámicamente
if [ -n "$MAX_BORROW_HOURS" ]; then
    echo "--- Configurando MAX_BORROW_HOURS a $MAX_BORROW_HOURS horas ---"
    touch /app/adskflex.opt
    # Eliminamos configuraciones globales previas y añadimos la nueva
    sed -i '/MAX_BORROW_HOURS \*/d' /app/adskflex.opt
    echo "MAX_BORROW_HOURS * $MAX_BORROW_HOURS" >> /app/adskflex.opt
fi

echo "Iniciando Autodesk License Manager via Wine..."
# IMPORTANTE: Para evitar logs duplicados, NO usamos -l ni tail.
# Ejecutamos lmgrd directamente redirigiendo su salida al contenedor.
exec wine /app/lmgrd.exe -z -c /app/licenses.lic
