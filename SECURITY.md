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

El puerto 8080 expone una API de administración. Implementaciones de seguridad:

1. **Autenticación**: ✅ Basic Auth implementado (configurar en `.dashboard_auth`)
2. **HTTPS**: Configurar reverse proxy con TLS
3. **IP Whitelist**: Restringir acceso a IPs conocidas

#### Configuración de Autenticación

1. Crear archivo de credenciales:
   ```bash
   cd wine-ad-manager/bin/
   cp .dashboard_auth.example .dashboard_auth
   ```

2. Editar `.dashboard_auth` con credenciales seguras:
   ```bash
   DASHBOARD_USER=admin
   DASHBOARD_PASS=your_secure_password_here
   DASHBOARD_AUTH_ENABLED=true
   ```

3. Verificar que el archivo esté en `.gitignore`:
   ```bash
   git status --porcelain | grep dashboard_auth
   # No debe aparecer nada
   ```

#### Configuración de IP Whitelist

Para restringir el acceso a IPs específicas de proveedores mexicanos:

1. Crear archivo de whitelist:
   ```bash
   cd wine-ad-manager/bin/
   cp .ip_whitelist.example .ip_whitelist
   ```

2. Editar `.ip_whitelist` con los rangos permitidos:
   - El archivo incluye rangos de TOTALPLAY, IZZI/Cablemas y TELMEX
   - Agregar IPs específicas de oficina/VPN según sea necesario

3. Verificar que el archivo esté en `.gitignore`:
   ```bash
   git status --porcelain | grep ip_whitelist
   # No debe aparecer nada
   ```

**Nota:** La implementación de IP Whitelist requiere configuración adicional a nivel de reverse proxy (Nginx/Traefik) o firewall del servidor.

## Container Security

### Non-Root User Implementation (Alert #3 - P1 Critical)

**Hallazgo Original:**
- Contenedor ejecutándose como usuario root
- WINEPREFIX=/root/.wine y procesos ejecutándose como superusuario
- Riesgo: Container breakout si Wine/FlexNet tienen vulnerabilidades

**Mitigación Implementada:**

1. **Usuario sin privilegios creado:**
   ```dockerfile
   RUN useradd -m -u 1001 -G audio,video licenseuser
   ```

2. **Wine ejecutándose como usuario no-root:**
   - WINEPREFIX movido de `/root/.wine` a `/home/licenseuser/.wine`
   - Variable `HOME=/home/licenseuser` configurada

3. **Gestión de privilegios con gosu:**
   - Contenedor inicia como root temporalmente para operaciones de red
   - Operaciones privilegiadas (MAC address, /etc/hosts) se ejecutan al inicio
   - Wine y lmgrd.exe ejecutan como `licenseuser` vía `gosu`
   - Dashboard Flask ejecuta como `licenseuser`

4. **Arquitectura de privilegios:**
   ```
   [START] root
      ├─ Cambio de MAC address (CAP_NET_ADMIN)
      ├─ Modificación /etc/hosts
      └─ [DROP PRIVILEGES via gosu]
          └─ licenseuser (uid 1001)
              ├─ Wine /app/lmgrd.exe
              └─ python3 /app/app.py
   ```

**Verificación:**
```bash
# Dentro del contenedor, verificar que Wine no corre como root
docker exec -it autodesk-win-wine ps aux | grep wine
# Debe mostrar: licenseuser ... wine /app/lmgrd.exe

# Verificar que el usuario es licenseuser
docker exec -it autodesk-win-wine whoami
# Debe mostrar: licenseuser (después del drop de privilegios)
```

**Archivos Modificados:**
- `wine-ad-manager/Dockerfile`: Usuario creado, WINEPREFIX cambiado, gosu instalado
- `wine-ad-manager/bin/entrypoint.sh`: Operaciones con gosu para drop de privilegios

**Referencia:** CIS Docker Benchmark 4.1, 4.2 - Non-root containers

---

## IP Whitelist Configuration (Alert #5)

### Configuración de Rangos IP para Proveedores Mexicanos

**Archivo de configuración:** `wine-ad-manager/bin/.ip_whitelist.example`

**Rangos incluidos:**

#### TOTALPLAY (AS18734 - Operbes, S.A. de C.V.)
```
148.229.0.0/16       # 65,536 IPs
187.164.0.0/18       # 16,384 IPs
189.202.128.0/17     # 32,768 IPs
189.204.128.0/17     # 32,768 IPs
201.140.96.0/19      # 8,192 IPs
201.148.0.0/18       # 16,384 IPs
```

#### IZZI / CABLEMAS (AS28509)
```
177.236.0.0/15       # 131,072 IPs
177.238.0.0/20       # 4,096 IPs
187.185.112.0/20     # 4,096 IPs
187.185.192.0/20     # 4,096 IPs
187.252.64.0/20      # 4,096 IPs
189.214.0.0/15       # 131,072 IPs
```

#### TELMEX (AS8151 - Uninet S.A. de C.V.)
```
148.212.0.0/15       # 131,072 IPs
148.217.0.0/16       # 65,536 IPs
148.219.0.0/16       # 65,536 IPs
187.131.0.0/16       # 65,536 IPs
187.157.0.0/16       # 65,536 IPs
187.203.0.0/16       # 65,536 IPs
189.161.0.0/16       # 65,536 IPs
189.170.0.0/15       # 131,072 IPs
201.99.0.0/16        # 65,536 IPs
201.100.0.0/15       # 131,072 IPs
```

### Implementación con Nginx Proxy Manager

**Requisitos:**
- Nginx Proxy Manager instalado (Easypanel, Docker standalone, etc.)
- Dominio configurado apuntando al servidor
- Puerto 8080 del contenedor accesible internamente

**Pasos de configuración:**

1. **Crear Access List en Nginx Proxy Manager:**
   - Ir a `Access Lists` → `Add Access List`
   - Nombre: `Autodesk-Mexico-ISPs`
   - Agregar cada rango CIDR en la sección `Authorization`:
     ```
     148.229.0.0/16
     187.164.0.0/18
     189.202.128.0/17
     189.204.128.0/17
     201.140.96.0/19
     201.148.0.0/18
     177.236.0.0/15
     177.238.0.0/20
     187.185.112.0/20
     187.185.192.0/20
     187.252.64.0/20
     189.214.0.0/15
     148.212.0.0/15
     148.217.0.0/16
     148.219.0.0/16
     187.131.0.0/16
     187.157.0.0/16
     187.203.0.0/16
     189.161.0.0/16
     189.170.0.0/15
     201.99.0.0/16
     201.100.0.0/15
     ```
   - Opcional: Agregar IPs específicas de oficina/VPN
   - Guardar

2. **Configurar Proxy Host:**
   - Ir a `Proxy Hosts` → `Add Proxy Host`
   - **Domain Names:** `licenses.tuempresa.com`
   - **Forward Hostname / IP:** IP interna del contenedor o `autodesk-win-wine`
   - **Forward Port:** `8080`
   - **SSL:**
     - Request new SSL Certificate (Let's Encrypt)
     - Forzar SSL
   - **Advanced:**
     - Seleccionar Access List: `Autodesk-Mexico-ISPs`
   - Guardar

3. **Verificar configuración:**
   ```bash
   # Desde una IP permitida (Totalplay/Izzi/Telmex)
   curl -I https://licenses.tuempresa.com
   # Debe retornar: HTTP 200 OK
   
   # Desde una IP no permitida
   curl -I https://licenses.tuempresa.com
   # Debe retornar: HTTP 403 Forbidden
   ```

4. **Configuración alternativa con Nginx manual:**
   
   Si no usas Nginx Proxy Manager, crear configuración manual:
   
   ```nginx
   # /etc/nginx/conf.d/autodesk-licenses.conf
   
   # Definir rangos permitidos
   geo $allowed_ip {
       default 0;
       
       # TOTALPLAY
       148.229.0.0/16 1;
       187.164.0.0/18 1;
       189.202.128.0/17 1;
       189.204.128.0/17 1;
       201.140.96.0/19 1;
       201.148.0.0/18 1;
       
       # IZZI/CABLEMAS
       177.236.0.0/15 1;
       177.238.0.0/20 1;
       187.185.112.0/20 1;
       187.185.192.0/20 1;
       187.252.64.0/20 1;
       189.214.0.0/15 1;
       
       # TELMEX
       148.212.0.0/15 1;
       148.217.0.0/16 1;
       148.219.0.0/16 1;
       187.131.0.0/16 1;
       187.157.0.0/16 1;
       187.203.0.0/16 1;
       189.161.0.0/16 1;
       189.170.0.0/15 1;
       201.99.0.0/16 1;
       201.100.0.0/15 1;
   }
   
   server {
       listen 80;
       server_name licenses.tuempresa.com;
       return 301 https://$server_name$request_uri;
   }
   
   server {
       listen 443 ssl http2;
       server_name licenses.tuempresa.com;
       
       ssl_certificate /etc/letsencrypt/live/licenses.tuempresa.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/licenses.tuempresa.com/privkey.pem;
       
       # SSL hardening
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
       ssl_prefer_server_ciphers on;
       ssl_session_cache shared:SSL:10m;
       
       # IP Whitelist
       if ($allowed_ip = 0) {
           return 403;
       }
       
       location / {
           proxy_pass http://autodesk-win-wine:8080;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```

**Notas importantes:**
- Los rangos CIDR pueden cambiar si los ISPs reasignan bloques de IP
- Recomendación: Actualizar la lista trimestralmente
- Fuente de datos: IPinfo.io (AS18734, AS28509, AS8151)
- Para verificar rangos actualizados: `https://ipinfo.io/AS<ASN_NUMBER>`

**Testing:**
```bash
# Verificar que el rango está en la lista correcta
whois 189.203.123.45 | grep -i "NetRange\|CIDR"
# Debe mostrar el rango de Telmex

# Probar acceso desde diferentes redes
# 1. Conectar VPN o red de oficina permitida
# 2. Acceder a https://licenses.tuempresa.com
# 3. Verificar que carga el dashboard
# 4. Probar desde IP no permitida (ej: móvil)
# 5. Verificar que retorna 403 Forbidden
```
