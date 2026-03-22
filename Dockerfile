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
    && apt-get install -y wine64 wine32 \
    && apt-get install -y python3 python3-pip \
    && pip3 install flask \
    && ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3

# 2. Configurar variables de entorno para Wine
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV DISPLAY=:99

# 3. Crear directorio de trabajo
WORKDIR /app

# 4. Copiar los binarios que descargues (deberías ponerlos en una subcarpeta bin/)
COPY bin/ /app/

# script para arrancar Xvfb y luego el exe con limpieza y resolucion de host
RUN echo '#!/bin/bash\n\
    rm -f /tmp/.X99-lock /tmp/.X11-unix/X99\n\
    # Limpiar cualquier entrada previa del hostname y forzar resolucion local\n\
    HNAME=$(hostname)\n\
    # No usamos sed -i porque Docker bloquea el renombramiento de /etc/hosts\n\
    # Simplemente añadimos la resolución local al final\n\
    echo "127.0.0.1 win-license-lab" >> /etc/hosts\n\
    # Verificar red\n\
    echo "Configuracion de red interna:"\n\
    cat /etc/hosts\n\
    Xvfb :99 -ac -screen 0 1024x768x16 &\n\
    sleep 2\n\
    echo "Iniciando License Manager via Wine (Foreground)..."\n\
    touch /app/debug.log\n\
    # Lanzamos el Dashboard en 8080 en el background\n\
    export FLASK_APP=/app/app.py\n\
    python3 /app/app.py &\n\
    # Lanzamos lmgrd y luego leemos el log continuamente\n\
    wine /app/lmgrd.exe -z -c /app/licenses.lic -l /app/debug.log &\n\
    sleep 2\n\
    tail -F /app/debug.log\n\
    ' > /usr/local/bin/run.sh && chmod +x /usr/local/bin/run.sh

CMD ["/usr/local/bin/run.sh"]
