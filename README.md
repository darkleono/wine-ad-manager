# Autodesk License Server Dockerized (ad-lic-hp)

Este repositorio contiene la configuración necesaria para desplegar un servidor de licencias de Autodesk (NLM) utilizando Docker, optimizado para entornos corporativos con acceso limitado a internet.

## Características
- **Base:** Rocky Linux 9 (AMD64).
- **Control de MAC:** Configurado vía `docker-compose.yml` para estabilidad de licencias.
- **Administración Avanzada:** Soporte para archivo de opciones (`adskflex.opt`) para control de Borrowing y Timeouts.
- **Eficiencia:** Bajo consumo de recursos y sin necesidad de licencias de Windows.

## Guías
- [Guía de Administración](guia_administracion.md): Conceptos básicos y comandos de control.
- [Walkthrough de Despliegue](walkthrough.md): Pasos técnicos para la puesta en marcha.

## Requisitos
- Docker y Docker Compose instalados.
- Binario RPM de Autodesk en la carpeta `bin/`.
- Archivo de licencia `.lic` en la carpeta `licence/`.

## Instrucciones Rápidas
1. Clonar el repositorio.
2. Colocar el archivo `.lic` y el RPM.
3. Configurar la MAC en `docker-compose.yml`.
4. Ejecutar `docker-compose up -d --build`.
