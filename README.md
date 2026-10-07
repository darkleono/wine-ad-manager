# Laboratorio: Autodesk License Manager (Windows .exe) en Docker via Wine

Este proyecto permite ejecutar la versión de Windows de Autodesk Network License Manager (`lmgrd.exe`) dentro de un contenedor Linux utilizando **Wine**.

## 📊 Estado del Desarrollo
- **Última Actualización:** 2026-03-24 | 05:40 AM (Sync CST + Quiet Mode)
- **Rama Actual:** `prod/easypanel-stack` (Commit: `453c8bb`)
- **Estado:** ✅ **FINALIZADO Y ESTABLE**
- **Novedades:** Control de logs por variable de entorno (`DASHBOARD_LOGS`), refresco web dinámico (`REFRESH_SECONDS`) y sincronización horaria CST con `tzdata`.
- **Avance Actual:** Despliegue exitoso en Easypanel (Modo App/Stack). Implementación de **Variables de Entorno** para MAC, Hostname y Puertos. Límites de borrow (7 días) operativos para AutoCAD 2025/2026.

## 🚀 Logros de este Laboratorio
- **Configuración Dinámica:** Soporte para variables de entorno (`MAC_ADDRESS`, `HOSTNAME_ID`, `PORT_MASTER`, `PORT_VENDOR`) para despliegue flexible.
- **Sincronización Total:** Se resolvió el error de "HostID mismatch" sincronizando la MAC Address del contenedor con el archivo de licencia.
- **Identidad Fija:** Uso de `mac_address` estática en Docker para garantizar que el HostID (66128fd23630) sea persistente.
- **Puertos Controlados:** Forzado de puertos Master (27000) y Vendor (2080) para facilitar la configuración del Firewall.
- **Eficiencia:** Imagen optimizada (~2.89GB) que consume mucha menos RAM que una VM tradicional.

## 📂 Estructura del Proyecto
- `Dockerfile`: Basado en Ubuntu con Wine 9.0 y Xvfb (monitor virtual).
- `docker-compose.yml`: Configuración del contenedor, red y volúmenes.
- `bin/`: Directorio donde deben residir los ejecutables (`lmgrd.exe`, `adskflex.exe`) y el archivo de licencia `licenses.lic`.
- `GUIA_ADMINISTRACION.md`: Documentación completa sobre cómo gestionar usuarios, puertos y vendors adicionales.

## 📂 Archivos Compose según Destino de Despliegue

El proyecto incluye distintas variantes de `docker-compose` según el entorno de infraestructura objetivo:

| Archivo | Entorno Recomendado | Características |
|---|---|---|
| **`docker-compose.yml`** | **Easypanel / PaaS** | Optimizado para orquestadores. Usa `expose` en lugar de `ports` y omite `container_name` para evitar advertencias y colisiones de red. |
| **`docker-compose_normal.yml`** | **Docker Standalone / VPS / Portainer** | Mapeo directo de puertos (`27000`, `2080`, `8080`) al host y nombre de contenedor fijo (`autodesk-win-wine`). |
| **`docker-compose.with-caddy.yml`** | **Producción con HTTPS Automático** | Integra proxy inverso Caddy con emisión automática de certificados SSL (Let's Encrypt), cabeceras de seguridad y filtrado por IP Whitelist. |

### Comandos de Ejecución:

```bash
# 1. En Easypanel (utiliza automáticamente docker-compose.yml)

# 2. En VPS o Docker directo (Standalone):
docker-compose -f docker-compose_normal.yml up -d --build

# 3. Con HTTPS y Caddy automático:
docker-compose -f docker-compose.with-caddy.yml up -d --build
```

---

## 🔐 Seguridad y Autenticación del Dashboard

El Dashboard Web incluye soporte nativo de **Basic Auth**. Puedes configurar las credenciales mediante **Variables de Entorno** (ideal para Easypanel) o mediante el archivo `/app/.dashboard_auth`:

### Variables de Entorno soportadas:
```env
DASHBOARD_USER=admin
DASHBOARD_PASS=SuperClave2026!
DASHBOARD_AUTH_ENABLED=true
```

* Si `DASHBOARD_AUTH_ENABLED` es `false` o no se definen credenciales, el dashboard funcionará en modo abierto.
* Si se configuran `DASHBOARD_USER` y `DASHBOARD_PASS`, el acceso web requerirá autenticación inmediata.

---

## 🧹 Tamaño de Imagen y Limpieza de Caché de Build

* **Tamaño final en disco:** ~2.8 GB (capas optimizadas con limpieza de `/var/cache`, man pages y temporales).
* **Consumo RAM:** ~200-250 MB en ejecución.

Si tras varias construcciones sucesivas en el host o Easypanel notas que el disco acumula espacio residual de BuildKit, ejecuta:

```bash
# Liberar caché acumulado de builds anteriores en el VPS
docker builder prune -a -f
docker image prune -f
```

---

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
- [GUIA_ADMINISTRACION.md](./GUIA_ADMINISTRACION.md): Documentación completa sobre cómo gestionar usuarios, borrow, volúmenes y recarga dinámica.
- [HTTPS-CONFIGURATION.md](./HTTPS-CONFIGURATION.md): Guía de configuración HTTPS/TLS (Nginx PM, Caddy, Traefik).
- [WALKTHROUGH.md](./WALKTHROUGH.md): Resultados del laboratorio.

## 🚀 Logros del Laboratorio
- **Persistencia Total:** Se implementaron volúmenes para que licencias y logs sobrevivan al reinicio del contenedor.
- **Detección de Borrow:** El Dashboard ahora identifica licencias prestadas y muestra el tiempo restante.
- **Recarga "al vuelo":** Implementado `lmutil lmreread` para aplicar cambios sin detener el servicio.
- **Visibilidad Avanzada:** Dashboard mejorado con badges de estado y mapeo de productos 2026.

---
*Este laboratorio ha demostrado ser una alternativa viable y ligera para la gestión centralizada de licencias en entornos de diseño y modelado 3D.*
