# Guía de Seguridad - Autodesk License Server

## Gestión de Credenciales

### Archivos Sensibles

Los siguientes archivos **NUNCA** deben incluirse en el repositorio:

- `.enviroment` - Credenciales de servidores VPS
- `.env` - Variables de entorno generales
- `*.key`, `*.pem` - Claves privadas y certificados
- `licence/*.lic` - Archivos de licencia de Autodesk

### Configuración Inicial

1. Copiar el template de ejemplo:
   ```bash
   cp .enviroment.example .enviroment
   ```

2. Completar con los valores reales de producción

3. Verificar que el archivo esté en `.gitignore`:
   ```bash
   git status --porcelain | grep enviroment
   # No debe aparecer nada
   ```

### Rotación de Credenciales

Si por error se commitearon credenciales:

1. **Inmediato**: Rotar TODAS las contraseñas expuestas
2. **Remover del historial**: Usar `git filter-branch` o BFG Repo-Cleaner
3. **Forzar push**: `git push --force` (coordina con el equipo)

```bash
# Ejemplo con BFG para limpiar archivo sensible
bfg --delete-files .enviroment
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

## Puertos Expuestos

El servidor requiere puertos públicos para licencias flotantes:

| Puerto | Servicio | Acceso |
|--------|----------|--------|
| 27000 | lmgrd (FlexNet) | Público (requerido) |
| 2080 | adskflex vendor | Público (requerido) |
| 8080 | Dashboard web | Recomendado: restringir por IP |

### Endurecimiento del Dashboard

El puerto 8080 expone una API de administración. Recomendaciones:

1. **Autenticación**: Implementar Basic Auth (ver `feature/api-auth`)
2. **HTTPS**: Configurar reverse proxy con TLS
3. **IP Whitelist**: Restringir acceso a IPs conocidas

## NetAdmin Capability

El contenedor requiere `NET_ADMIN` para:

- Cambiar MAC address virtual (asociado a la licencia)
- Simular el servidor físico Dell Optiplex original

Esto es **necesario** para el funcionamiento correcto del servidor de licencias virtualizado.

---

**Reportar vulnerabilidades al equipo de seguridad interna.**
