#!/bin/bash
set -e

echo "--- Gestión de Persistencia y Volúmenes ---"
# Asegurar directorios requeridos en /app
mkdir -p /app/templates

# Sincronizar siempre el código del dashboard y plantillas actualizadas desde la imagen
echo "Sincronizando Dashboard y binarios actualizados..."
cp -rf /app_defaults/templates/* /app/templates/ 2>/dev/null || true
cp -f /app_defaults/app.py /app/app.py 2>/dev/null || true
cp -f /app_defaults/lmutil_linux /app/lmutil_linux 2>/dev/null || true
chmod +x /app/lmutil_linux 2>/dev/null || true

# Copiar archivos de configuración o licencias solo si no existen (para no sobreescribir licencias del usuario)
for file in /app_defaults/*; do
    filename=$(basename "$file")
    if [ ! -e "/app/$filename" ]; then
        echo "Poblando archivo inicial: $filename"
        cp -r "$file" "/app/"
    fi
done

# Garantizar permisos de usuario sin privilegios en todo /app
chown -R licenseuser:licenseuser /app 2>/dev/null || true

echo "--- Iniciando Configuración de Red ---"
# Nota: El cambio de MAC requiere CAP_NET_ADMIN (ya concedido via cap_add)
# Si el contenedor se ejecuta como root inicialmente, realizar operaciones de red
if [ -n "$MAC_ADDRESS" ]; then
    echo "Intentando asignar MAC: $MAC_ADDRESS a eth0..."
    # Intentar con privilegios elevados si están disponibles
    if [ "$(id -u)" -eq 0 ] || command -v sudo >/dev/null 2>&1; then
        ip link set eth0 down 2>/dev/null || echo "Fallo al bajar eth0 (puede requerir NET_ADMIN)"
        ip link set eth0 address "$MAC_ADDRESS" 2>/dev/null || echo "Fallo al cambiar MAC (puede requerir NET_ADMIN)"
        ip link set eth0 up 2>/dev/null || echo "Fallo al subir eth0"
        echo "Estado final de red:"
        ip addr show eth0 | grep ether || echo "No se pudo obtener la MAC final"
    else
        echo "ADVERTENCIA: No se puede cambiar MAC sin privilegios NET_ADMIN"
        echo "El contenedor debe ejecutarse con cap_add: NET_ADMIN"
    fi
fi

HOST_TARGET="${HOSTNAME_ID:-win-license-lab}"
PORT_WEB="${PORT_DASHBOARD:-8080}"

# Limpieza de locks de Xvfb (puede requerir permisos si se ejecuta como root)
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null || true

# Resolución de host local (indispensable para FlexLM)
# Intentar escribir en /etc/hosts si tenemos permisos
if [ -w /etc/hosts ]; then
    echo "127.0.0.1 $HOST_TARGET" >> /etc/hosts
else
    echo "ADVERTENCIA: No se puede modificar /etc/hosts. Asegurar que $HOST_TARGET resuelve a 127.0.0.1"
fi

# Iniciar Framebuffer virtual
Xvfb :99 -ac -screen 0 1x1x8 &
sleep 2

echo "Iniciando Dashboard en puerto $PORT_WEB..."
# Ejecutamos el Dashboard en segundo plano como usuario sin privilegios
gosu licenseuser python3 -u /app/app.py --port "$PORT_WEB" &

# Lógica para configurar MAX_BORROW_HOURS dinámicamente
if [ -n "$MAX_BORROW_HOURS" ]; then
    echo "--- Configurando MAX_BORROW_HOURS a $MAX_BORROW_HOURS horas ---"
    touch /app/adskflex.opt
    # Eliminamos configuraciones globales previas y añadimos la nueva
    sed -i '/MAX_BORROW_HOURS \*/d' /app/adskflex.opt
    echo "MAX_BORROW_HOURS * $MAX_BORROW_HOURS" >> /app/adskflex.opt
    chown licenseuser:licenseuser /app/adskflex.opt 2>/dev/null || true
fi

echo "Iniciando Autodesk License Manager via Wine..."
# IMPORTANTE: Para evitar logs duplicados, NO usamos -l ni tail.
# Ejecutamos lmgrd directamente redirigiendo su salida al contenedor.
# Wine se ejecuta como usuario sin privilegios (licenseuser) vía gosu
exec gosu licenseuser wine /app/lmgrd.exe -z -c /app/licenses.lic
