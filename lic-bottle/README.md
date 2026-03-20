# Laboratorio: Autodesk License Manager (Windows .exe) en Docker via Wine

Este proyecto permite ejecutar la versión de Windows de Autodesk Network License Manager (`lmgrd.exe`) dentro de un contenedor Linux utilizando **Wine**. Es una solución ideal para centralizar licencias de versiones antiguas (Legacy) o cuando no se dispone de binarios nativos de Linux, ahorrando el consumo de recursos de una Máquina Virtual completa de Windows.

## 🚀 Logros de este Laboratorio
- **Sincronización Total:** Se resolvió el error de "HostID mismatch" sincronizando la MAC Address del contenedor con el archivo de licencia.
- **Identidad Fija:** Uso de `mac_address` estática en Docker para garantizar que el HostID (66128fd23630) sea persistente.
- **Puertos Controlados:** Forzado de puertos Master (27000) y Vendor (2080) para facilitar la configuración del Firewall.
- **Eficiencia:** Imagen optimizada (~2.89GB) que consume mucha menos RAM que una VM tradicional.

## 📂 Estructura del Proyecto
- `Dockerfile`: Basado en Ubuntu con Wine 9.0 y Xvfb (monitor virtual).
- `docker-compose.yml`: Configuración del contenedor, red y volúmenes.
- `bin/`: Directorio donde deben residir los ejecutables (`lmgrd.exe`, `adskflex.exe`) y el archivo de licencia `licenses.lic`.
- `GUIA_ADMINISTRACION.md`: Documentación completa sobre cómo gestionar usuarios, puertos y vendors adicionales.

## 🛠️ Instrucciones de Inicio Rápido

1. **Preparar archivos:** Coloca tus binarios de Windows y tu archivo `.lic` en la carpeta `bin/`.
2. **Configurar MAC:** Edita `docker-compose.yml` y asegúrate de que la `mac_address` coincida con la de tu licencia.
3. **Desplegar:**
   ```bash
   docker-compose up -d --build
   ```
4. **Verificar:**
   ```bash
   docker exec -it autodesk-win-wine ./lmutil lmstat -a
   ```

## 📖 Documentación Relacionada
- [Guía de Administración Detallada](./GUIA_ADMINISTRACION.md)
- [Walkthrough de Resultados](./WALKTHROUGH.md)

---
*Este laboratorio ha demostrado ser una alternativa viable y ligera para la gestión centralizada de licencias en entornos de diseño y modelado 3D.*
