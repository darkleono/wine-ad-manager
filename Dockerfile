# Dockerfile para ejecutar .exe via Wine optimizado para Easypanel
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalar dependencias base, Wine e IpRoute2 (para forzar la MAC)
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    apt-utils \
    ca-certificates \
    xvfb \
    winbind \
    iproute2 \
    python3 \
    python3-pip \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends wine64 wine32 \
    && pip3 install --no-cache-dir flask \
    && ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 2. Configurar variables de entorno para Wine
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV DISPLAY=:99

# 3. Crear directorio de trabajo
WORKDIR /app

# 4. Copiar los binarios y el dashboard
COPY bin/ /app/

# 5. Script de arranque con forzado de MAC (Requiere Cap Add: NET_ADMIN en Easypanel)
RUN echo '#!/bin/bash\n\
    echo "--- Iniciando Configuración de Red ---"\n\
    # Forzar la MAC necesaria para la licencia (requiere NET_ADMIN)\n\
    ip link set dev eth0 down 2>/dev/null\n\
    ip link set dev eth0 address 66:12:8f:d2:36:30 2>/dev/null\n\
    ip link set dev eth0 up 2>/dev/null\n\
    \n\
    # Verificar si el cambio de MAC fue exitoso\n\
    echo "MAC actual detectada:"\n\
    cat /sys/class/net/eth0/address\n\
    \n\
    # Limpieza de locks de Xvfb\n\
    rm -f /tmp/.X99-lock /tmp/.X11-unix/X99\n\
    \n\
    # Resolución de host local\n\
    echo "127.0.0.1 win-license-lab" >> /etc/hosts\n\
    \n\
    # Iniciar Framebuffer virtual\n\
    Xvfb :99 -ac -screen 0 1024x768x16 &\n\
    sleep 2\n\
    \n\
    echo "Iniciando Dashboard en puerto 8080..."\n\
    python3 /app/app.py &\n\
    \n\
    echo "Iniciando Autodesk License Manager via Wine..."\n\
    touch /app/debug.log\n\
    wine /app/lmgrd.exe -z -c /app/licenses.lic -l /app/debug.log &\n\
    \n\
    sleep 2\n\
    tail -F /app/debug.log\n\
    ' > /usr/local/bin/run.sh && chmod +x /usr/local/bin/run.sh

CMD ["/usr/local/bin/run.sh"]
