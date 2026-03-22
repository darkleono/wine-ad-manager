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

## 2. Estabilidad del HostID
El HostID en Wine depende de la dirección MAC.
- **FIJAR MAC:** En `docker-compose.yml`, se usa `mac_address: 66:12:8f:d2:36:30`.
- **SERVER Line:** En `licenses.lic`, se usa `SERVER win-license-lab 66128fd23630 27000`.

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

## 5. Mantenimiento
- **Ver Status:** `docker exec -it autodesk-win-wine ./lmutil lmstat -a`
- **Dashboard API:** `/api/status` para ver el JSON estructurado de usuarios.
- **Reinicio:** `docker-compose restart` tras cambiar el archivo de licencia u opciones.

## 6. Verificación de Funcionamiento (100% OK)

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
**Nota sobre versiones "Lite":** Se está explorando el uso de Alpine Linux con Wine-staging para reducir el peso de la imagen de 2.9GB a menos de 1GB en futuras iteraciones.
