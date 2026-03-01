# Laboratorio: Autodesk License Manager (Windows .exe) en Docker

Este entorno es un experimento para ejecutar la versión de Windows de Autodesk Network License Manager (`lmgrd.exe`) dentro de un contenedor Linux utilizando **Wine**.

> [!WARNING]
> **Uso Educativo/Laboratorio**: Esta configuración es más pesada y compleja que la versión nativa de Linux. Se recomienda usar la versión nativa (la del proyecto principal) para producción.

## Estructura de este Lab
- `Dockerfile`: Basado en Ubuntu (mejor soporte para Wine), configura el entorno gráfico virtual (Xvfb) y Wine.
- `docker-compose.yml`: Orquestación del contenedor.
- `bin/`: (Debes crearla) Aquí debes colocar el instalador de Windows que descargues.

## Instrucciones de Uso
1. Coloca los ejecutables de Autodesk para Windows (`lmgrd.exe`, `adskflex.exe`, `lmutil.exe`) en una carpeta llamada `bin/` dentro de este directorio.
2. Coloca tu licencia en `bin/licencia.lic`.
3. Ejecuta el build:
   ```bash
   docker-compose up --build
   ```

## Notas Técnicas
- **Wine**: Actúa como capa de compatibilidad.
- **Xvfb**: Crea un monitor virtual "fantasma" porque muchos `.exe` de Windows fallan si no detectan una pantalla, aunque sean de línea de comandos.
- **Arquitectura**: Al estar en Mac Apple Silicon, Docker usará `x86_64` emulado para que Wine pueda ejecutar los binarios de Windows.
