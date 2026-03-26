# Guía de Administración: Licencias en Red via Wine

Esta guía detalla la configuración técnica para administrar el servidor de licencias `wine-ad-manager` basado en Wine.

## 1. Conceptos de Red y Puertos
Se han fijado los puertos para evitar asignaciones dinámicas:
- **Puerto 27000 (Host) -> 27000 (Internal):** Puerto del Master Daemon (`lmgrd`).
- **Puerto 2080 (Host) -> 2080 (Internal):** Puerto del Vendor Daemon (`adskflex`).
- **Puerto 8080 (Host) -> 8080 (Internal):** Dashboard Web.

> [!IMPORTANT]
> Los clientes deben configurarse usando: `27000@IP_DEL_SERVIDOR`.

### Configuración en Clientes (Windows)
1.  **Variable de Entorno:** `ADSKFLEX_LICENSE_FILE` = `27000@IP_DEL_SERVIDOR`.
2.  **Archivo LICPATH.lic:** Localizado en la carpeta del producto (AutoCAD/Revit).

## 2. Configuración mediante Variables de Entorno (Producción)
Para mayor flexibilidad en Easypanel (Modo App o Stack), el servidor ahora utiliza variables de entorno. Esto permite cambiar la identidad del servidor sin editar el código del repositorio.
- **Modo Silencio Dinámico:** Controla los logs de red con `DASHBOARD_LOGS=false` en el `.env` o `docker-compose`.
- **Sincronización CST (México):** El contenedor ya corre sincronizado con la hora local de México (`America/Mexico_City`).
- **Filtrado de Red:** El Dashboard ignora el ruido de IPs automatizadas de red para mantener logs limpios.
- **Refresco Configurable:** Frecuencia de actualización web ajustable vía `REFRESH_SECONDS` (defecto 60s).

### Variables Requeridas:
| Variable | Valor | Descripción |
| :--- | :--- | :--- |
| **`MAC_ADDRESS`** | `66:12:8f:d2:36:30` | Obligatoria para validar el HostID de la licencia. |
| **`HOSTNAME_ID`** | `win-license-lab` | Debe coincidir con el nombre en el archivo `.lic`. |
| **`PORT_MASTER`** | `27000` | Puerto principal de escucha. |
| **`PORT_VENDOR`** | `2080` | Puerto del motor adskflex. |
| **`PORT_DASHBOARD`** | `8080` | Puerto de la interfaz web. |

> [!TIP]
> En Easypanel (Modo App), además de poner estas variables en la pestaña **"Entorno"**, debes ir a **"Avanzado" -> "Mapear Puertos"** y añadir manualmente los mapeos TCP para 27000, 2080 y 8080.

## 3. Estabilidad del HostID

## 3. Administración de Vendors (Ej: Solidworks, Rhino)
Para agregar nuevos programas, se recomienda la **Opción de Instancias Independientes**:
1. Reusa esta misma imagen de Docker.
2. Crea un nuevo servicio en `docker-compose.yml` con su propia subcarpeta, su propia dirección MAC y puertos diferentes (ej. 27002, 2082).
3. Esto garantiza aislamiento total: si un manager falla, los otros siguen operando.

## 4. Préstamo de Licencias (Borrowing)
Para limitar el tiempo que un usuario puede llevarse la licencia fuera de la oficina:
1. Crea un archivo `adskflex.opt` en la carpeta `bin/`.
2. Ejemplo: `MAX_BORROW_HOURS 87224ACD_2020_0F 336` (2 semanas).
3. Asegúrate de que la línea VENDOR en el `.lic` apunte al archivo:
   `VENDOR adskflex port=2080 options=adskflex.opt`

## 5. Gestión Dinámica y Volúmenes (Persistencia)
Para evitar reconstruir la imagen cada vez que cambie algo, el proyecto usa volúmenes de Docker:

### A. Ubicación de archivos y Auto-poblado (Named Volumes)
Todos los archivos críticos residen en el volumen nombrado **`license_data`** gestionado por Docker/Easypanel. El origen local de estos archivos en el repositorio es la carpeta **`bin/`**.
- **Primera ejecución:** Al mapear este volumen por primera vez, el contenedor detectará que está vacío y **copiará automáticamente** el contenido de `bin/` (almacenado internamente en `/app_defaults/*`) al volumen para que sean accesibles.
- **Persistencia:** Cualquier cambio que hagas en el volumen (editando archivos desde la UI de Easypanel o mediante el Dashboard) persistirá entre reinicios.

### B. Recarga "al vuelo" (Sin Reiniciar)
Si haces un cambio en el archivo de opciones (ej. añadir un usuario a la blacklist), no necesitas reiniciar el contenedor. Ejecuta:
```bash
docker exec -it autodesk-win-wine ./lmutil_linux lmreread -c licenses.lic
```
*También puedes usar el botón **"Recargar Archivo LIC"** desde el Dashboard Web.*

## 6. Mantenimiento y Dashboard
- **Dashboard Web:** Accede a `http://IP-SERVIDOR:8080` para ver quién tiene licencias "Prestadas" (Borrow) y activos.
- **Ver Status (Manual):** `docker exec -it autodesk-win-wine ./lmutil_linux lmstat -a`
- **Reinicio Forzado:** `docker-compose restart` si necesitas un reinicio completo.

Para confirmar que el servidor está operando correctamente tras el despliegue, el log de inicio (`docker logs autodesk-licenser`) debe mostrar este patrón exacto:

### A. Red y MAC address (Éxito de forzado)
```text
--- Iniciando Configuración de Red ---
MAC actual en el contenedor:
66:12:8f:d2:36:30
```
> [!TIP]
> Si ves una MAC diferente (ej. empezando por 02:42), significa que el contenedor no tiene permisos `NET_ADMIN`. Revisa la configuración de Easypanel.

### B. HostID y Licencia (Éxito de Validación)
En el log de Autodesk (`debug.log`), busca estas líneas:
```text
(adskflex) HostID node-locked in license file: 66128fd23630 
(adskflex) HostID of the License Server: "66128fd23630 ..."
(adskflex) adskflex using TCP-port 2080
(lmgrd) adskflex started on win-license-lab
```
> [!SUCCESS]
> Cuando el HostID de la licencia coincide con el del servidor, el motor `adskflex` se activa y las licencias están listas para ser repartidas.

---
---
 
 ## 7. Protocolo### 🤫 Control de Logs y Ruido (Modo Silencio)
Para mantener la consola limpia de peticiones de red, usa estas variables en tu `docker-compose.yml`:
- `DASHBOARD_LOGS=false`: Silencia las peticiones de la API (200 OK).
- `REFRESH_SECONDS=60`: Controla cada cuántos segundos se actualiza la Web.

### 🕒 Sincronización Horaria
Para que los préstamos de licencias (Borrowing) coincidan con el reloj de tu Mac/Servidor:
- Asegúrate de tener `TZ=America/Mexico_City` en las variables de entorno. El archivo `Dockerfile` ya incluye `tzdata` para soportarlo.

### 📡 Filtrado de Red (SOS)
Si ves peticiones constantes de la IP `185.125.190.82` (Canonical), el sistema ya las filtra automáticamente por software para que no ensucien tu log de usuarios.
de Resolución de Incidentes (SOS)
 Si el servidor deja de entregar licencias o los usuarios reportan errores, sigue estos pasos en orden para recuperar el servicio en minutos, sin depender de soporte externo.
 
 ### Paso 1: Verificar el Estado General
 Entra al Dashboard (`http://tu-ip:8080`). 
 - **Si el dashboard NO carga:** El contenedor está detenido. En Easypanel, dale a "Restart".
 - **Si el dashboard carga pero dice "Server Down":** El servicio `lmgrd` falló. Ve al Paso 3.
 
 ### Paso 2: El error de "HostID mismatch"
 Si los logs dicen que el HostID no coincide, verifica que la MAC Address del contenedor no haya sido borrada o cambiada.
 - En el `docker-compose.yml` (o en la UI de Easypanel), confirma que la MAC sea exactamente: `66:12:8f:d2:36:30`.
 - Sin esta MAC, las licencias Autodesk nunca arrancarán.
 
 ### Paso 3: Forzar Recarga de Licencias
 Si has editado el `.lic` o el `.opt` y no ves los cambios, no reinicies todo el contenedor. Usa el botón **"Recargar Archivo LIC"** en el Dashboard. Esto ejecuta internamente `lmreread`, que refresca la configuración sin desconectar a los usuarios que ya están trabajando.
 
 ### Paso 4: Revisar el Log Maestro (debug.log)
 Si nada funciona, el archivo de log te dirá la verdad. Está en tu volumen de datos: `license_data/debug.log`.
 - Busca palabras clave como `DENIED`, `EXITING DUE TO SIGNAL` o `INVALID LICENSE KEY`.
 - Si ves un error de "Port in use", reinicia el contenedor para limpiar las conexiones TCP colgadas.
 
 ### Paso 5: El "Botón de Pánico" (Reinicio Limpio)
 Si el servidor se queda en un estado inconsistente:
 1. Asegúrate de que tus archivos en `bin/` estén correctos.
 2. Reinicia el contenedor desde Easypanel.
 3. El `entrypoint.sh` se encargará de re-configurar la red y levantar los servicios desde cero automáticamente.
 
 ---
 
 **Nota sobre versiones "Lite":** Se está explorando el uso de Alpine Linux con Wine-staging para reducir el peso de la imagen de 2.9GB a menos de 1GB en futuras iteraciones.
