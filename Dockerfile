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
    tzdata \
    gosu \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends wine64 wine32 wine \
    && pip3 install --no-cache-dir flask \
    && ln -s /lib64/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* /usr/share/man/* /var/cache/apt/*

WORKDIR /app

# 2. Crear usuario sin privilegios para Wine y Dashboard
RUN useradd -m -u 1001 -G audio,video licenseuser \
    && mkdir -p /home/licenseuser/.wine \
    && chown -R licenseuser:licenseuser /home/licenseuser \
    && mkdir -p /app \
    && chown -R licenseuser:licenseuser /app

# 3. Copiar binarios y scripts a una carpeta de respaldo (para auto-poblar volúmenes)
COPY bin/ /app_defaults/
RUN chmod +x /app_defaults/entrypoint.sh \
    && chown -R licenseuser:licenseuser /app_defaults

# 4. Configuración de Wine optimizada (Memoria reducida)
ENV WINEDEBUG=-all
ENV WINEPREFIX=/home/licenseuser/.wine
ENV WINEARCH=win64
ENV WINEDLLOVERRIDES="mscoree,mshtml="
ENV DISPLAY=:99
ENV HOME=/home/licenseuser

# 5. Pre-inicializar Wine durante el build para evitar consumo de RAM por wineboot en caliente
RUN gosu licenseuser wineboot -i \
    && gosu licenseuser wineserver -w \
    && rm -rf /tmp/* /tmp/.wine*

# 6. Exponer puertos necesarios
EXPOSE 27000 2080 8080

# 7. Usar el nuevo script como punto de entrada
ENTRYPOINT ["/app_defaults/entrypoint.sh"]
