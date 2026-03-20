# Guía de Administración: Licencias en Red via Wine

Esta guía detalla la configuración técnica para administrar el servidor de licencias `lic-bottle` basado en Wine.

## 1. Conceptos de Red y Puertos
Se han fijado los puertos para evitar asignaciones dinámicas:
- **Puerto 27001 (Externo) -> 27000 (Interno):** Puerto del Master Daemon (`lmgrd`).
- **Puerto 2081 (Externo) -> 2080 (Interno):** Puerto del Vendor Daemon (`adskflex`).

> [!IMPORTANT]
> Los clientes deben configurarse usando el puerto externo: `27001@IP_DEL_SERVIDOR`.

### Configuración en Clientes (Windows)
1.  **Variable de Entorno:** `ADSKFLEX_LICENSE_FILE` = `27001@IP_DEL_SERVIDOR`.
2.  **Archivo LICPATH.lic:** Localizado en la carpeta del producto (AutoCAD/Revit).

## 2. Estabilidad del HostID
El HostID en Wine depende de la dirección MAC.
- **FIJAR MAC:** En `docker-compose.yml`, usa `mac_address: 66:12:8f:d2:36:30`.
- **SERVER Line:** En `licenses.lic`, usa `SERVER win-license-lab 66128fd23630 27000`.

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
- **Logs:** Consultar `bin/debug.log` para ver errores de conexión.
- **Reinicio:** `docker-compose restart` tras cambiar el archivo de licencia u opciones.

---
**Nota sobre versiones "Lite":** Se está explorando el uso de Alpine Linux con Wine-staging para reducir el peso de la imagen de 2.9GB a menos de 1GB en futuras iteraciones.
