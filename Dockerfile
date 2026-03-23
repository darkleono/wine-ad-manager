FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalar dependencias (Agregamos 'wine' para tener el comando directo)
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    winbind \
    iproute2 \
    ca-certificates \
    python3 \
    python3-pip \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends wine64 wine32 wine \
    && pip3 install --no-cache-dir flask \
    && ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Copiar binarios y scripts a una carpeta de respaldo (para auto-poblar volúmenes)
COPY bin/ /app_defaults/
WORKDIR /app
RUN chmod +x /app_defaults/entrypoint.sh

# 3. Configuración de Wine
ENV WINEDEBUG=-all
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV DISPLAY=:99

# 4. Exponer puertos necesarios
EXPOSE 27000 2080 8080

# 5. Usar el nuevo script como punto de entrada
ENTRYPOINT ["/app_defaults/entrypoint.sh"]
