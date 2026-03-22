# Dockerfile Optimizado para Servidor de Licencias Autodesk vía Wine
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalación mínima y optimizada
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    winbind \
    ca-certificates \
    python3 \
    python3-pip \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    wine64 \
    wine32 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 2. Instalar Flask para el dashboard
RUN pip3 install --no-cache-dir flask

# 3. Configuración de compatibilidad LSB
RUN ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3

# 4. Variables de entorno para Wine (Modo Headless)
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV DISPLAY=:99

WORKDIR /app

# 5. Script de arranque consolidado y ligero
RUN echo '#!/bin/bash\n\
    rm -f /tmp/.X99-lock /tmp/.X11-unix/X99\n\
    echo "127.0.0.1 win-license-lab" >> /etc/hosts\n\
    Xvfb :99 -ac -screen 0 1024x768x16 &\n\
    sleep 2\n\
    echo "Iniciando Dashboard Flask..."\n\
    python3 /app/app.py &\n\
    echo "Iniciando Autodesk License Manager..."\n\
    touch /app/debug.log\n\
    wine /app/lmgrd.exe -z -c /app/licenses.lic -l /app/debug.log &\n\
    sleep 2\n\
    tail -F /app/debug.log\n\
    ' > /usr/local/bin/run.sh && chmod +x /usr/local/bin/run.sh

CMD ["/usr/local/bin/run.sh"]
