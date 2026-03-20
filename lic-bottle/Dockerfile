# Dockerfile para ejecutar .exe via Wine
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalar dependencias base y Wine
RUN apt-get update && apt-get install -y \
    software-properties-common \
    apt-utils \
    curl \
    unzip \
    xvfb \
    winbind \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y wine64 wine32

# 2. Configurar variables de entorno para Wine
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV DISPLAY=:99

# 3. Crear directorio de trabajo
WORKDIR /app

# 4. Copiar los binarios que descargues (deberías ponerlos en una subcarpeta bin/)
# COPY bin/ /app/

# script para arrancar Xvfb y luego el exe con limpieza y resolucion de host
RUN echo '#!/bin/bash\n\
    rm -f /tmp/.X99-lock /tmp/.X11-unix/X99\n\
    # Limpiar cualquier entrada previa del hostname y forzar resolucion local\n\
    HNAME=$(hostname)\n\
    sed -i "/$HNAME/d" /etc/hosts\n\
    echo "127.0.0.1 localhost" > /etc/hosts\n\
    echo "127.0.0.1 $HNAME win-license-lab" >> /etc/hosts\n\
    # Verificar red\n\
    echo "Configuracion de red interna:"\n\
    cat /etc/hosts\n\
    Xvfb :99 -ac -screen 0 1024x768x16 &\n\
    sleep 2\n\
    echo "Iniciando License Manager via Wine (Foreground)..."\n\
    touch /app/debug.log\n\
    # Lanzamos lmgrd y luego leemos el log continuamente\n\
    # Usamos ruta completa para mayor seguridad\n\
    wine /app/lmgrd.exe -z -c /app/licenses.lic -l /app/debug.log &\n\
    sleep 2\n\
    tail -F /app/debug.log\n\
    ' > /usr/local/bin/run.sh && chmod +x /usr/local/bin/run.sh

CMD ["/usr/local/bin/run.sh"]
