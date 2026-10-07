# HTTPS/TLS Configuration Options for Dashboard

Este documento presenta tres opciones para implementar HTTPS en el Dashboard de Autodesk License Server.

---

## Opción 1: Nginx Proxy Manager (Recomendado para Easypanel)

### Requisitos
- Nginx Proxy Manager instalado (disponible en Easypanel)
- Dominio apuntando al servidor (ej: `licenses.tuempresa.com`)
- Puerto 8080 accesible internamente

### Pasos

1. **Crear Proxy Host:**
   - Ir a Nginx Proxy Manager → Proxy Hosts → Add Proxy Host
   - Domain Names: `licenses.tuempresa.com`
   - Forward Hostname / IP: `autodesk-win-wine` (o IP interna)
   - Forward Port: `8080`

2. **Configurar SSL:**
   - Tab "SSL"
   - SSL Certificate: "Request a new SSL Certificate"
   - Domain: `licenses.tuempresa.com`
   - Email: `admin@tuempresa.com`
   - ✅ Force SSL
   - ✅ HTTP/2 Support
   - ✅ HSTS Enabled

3. **Configurar Access List (IP Whitelist):**
   - Advanced → Access List: `Autodesk-Mexico-ISPs`
   - Ver documentación en SECURITY.md para crear la lista

4. **Guardar y verificar:**
   - Acceder a `https://licenses.tuempresa.com`
   - Verificar certificado SSL válido
   - Verificar redirección HTTP → HTTPS

---

## Opción 2: Caddy Reverse Proxy (Automático)

### Ventajas
- HTTPS automático con Let's Encrypt
- Configuración mínima
- Renovación automática de certificados

### Docker Compose con Caddy

Crear archivo `docker-compose.with-caddy.yml`:

```yaml
version: '3.8'

services:
  # Autodesk License Server (sin exponer puerto 8080 al host)
  autodesk-licenser:
    build: .
    image: darkleono/wine-ad-manager:latest
    platform: linux/amd64
    container_name: ${CONTAINER_NAME:-autodesk-win-wine}
    hostname: ${HOSTNAME_ID:-win-license-lab}
    mac_address: ${MAC_ADDRESS:-66:12:8f:d2:36:30}
    cap_add:
      - NET_ADMIN
    expose:
      - "8080"
    volumes:
      - license_data:/app
    environment:
      - MAC_ADDRESS=${MAC_ADDRESS:-66:12:8f:d2:36:30}
      - HOSTNAME_ID=${HOSTNAME_ID:-win-license-lab}
      - PORT_DASHBOARD=${PORT_DASHBOARD:-8080}
      - TZ=America/Mexico_City
      - DASHBOARD_LOGS=${DASHBOARD_LOGS:-false}
      - REFRESH_SECONDS=${REFRESH_SECONDS:-60}
    restart: always
    networks:
      - license-network

  # Caddy Reverse Proxy con HTTPS automático
  caddy:
    image: caddy:2-alpine
    container_name: caddy-proxy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - license-network
    depends_on:
      - autodesk-licenser

volumes:
  license_data:
  caddy_data:
  caddy_config:

networks:
  license-network:
    driver: bridge
```

### Caddyfile

```caddyfile
# Caddyfile - Configuración de HTTPS automático
# Colocar en la raíz del proyecto

licenses.tuempresa.com {
    # IP Whitelist - Solo permitir ISPs mexicanos
    @totalplay remote_ip 148.229.0.0/16 187.164.0.0/18 189.202.128.0/17 189.204.128.0/17 201.140.96.0/19 201.148.0.0/18
    @izzi remote_ip 177.236.0.0/15 177.238.0.0/20 187.185.112.0/20 187.185.192.0/20 187.252.64.0/20 189.214.0.0/15
    @telmex remote_ip 148.212.0.0/15 148.217.0.0/16 148.219.0.0/16 187.131.0.0/16 187.157.0.0/16 187.203.0.0/16 189.161.0.0/16 189.170.0.0/15 201.99.0.0/16 201.100.0.0/15
    
    # Permitir solo IPs autorizadas
    handle @totalplay {
        reverse_proxy autodesk-win-wine:8080
    }
    handle @izzi {
        reverse_proxy autodesk-win-wine:8080
    }
    handle @telmex {
        reverse_proxy autodesk-win-wine:8080
    }
    
    # Bloquear todo lo demás
    handle {
        respond "Access Denied - IP not allowed" 403
    }
    
    # Logging
    log {
        output file /var/log/caddy/licenses.log
        format console
    }
}
```

### Despliegue con Caddy

```bash
# 1. Crear Caddyfile con tu dominio
vim Caddyfile

# 2. Desplegar con el nuevo compose
docker-compose -f docker-compose.with-caddy.yml up -d

# 3. Verificar logs de Caddy (debe obtener certificado automáticamente)
docker logs caddy-proxy

# 4. Verificar HTTPS
curl -I https://licenses.tuempresa.com
```

---

## Opción 3: Traefik (Para Kubernetes/Docker Swarm)

### docker-compose.with-traefik.yml

```yaml
version: '3.8'

services:
  autodesk-licenser:
    build: .
    image: darkleono/wine-ad-manager:latest
    platform: linux/amd64
    container_name: ${CONTAINER_NAME:-autodesk-win-wine}
    hostname: ${HOSTNAME_ID:-win-license-lab}
    mac_address: ${MAC_ADDRESS:-66:12:8f:d2:36:30}
    cap_add:
      - NET_ADMIN
    expose:
      - "8080"
    volumes:
      - license_data:/app
    environment:
      - MAC_ADDRESS=${MAC_ADDRESS:-66:12:8f:d2:36:30}
      - HOSTNAME_ID=${HOSTNAME_ID:-win-license-lab}
      - PORT_DASHBOARD=${PORT_DASHBOARD:-8080}
      - TZ=America/Mexico_City
      - DASHBOARD_LOGS=${DASHBOARD_LOGS:-false}
      - REFRESH_SECONDS=${REFRESH_SECONDS:-60}
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.licenses.rule=Host(`licenses.tuempresa.com`)"
      - "traefik.http.routers.licenses.entrypoints=websecure"
      - "traefik.http.routers.licenses.tls.certresolver=letsencrypt"
      - "traefik.http.services.licenses.loadbalancer.server.port=8080"
      # IP Whitelist middleware
      - "traefik.http.middlewares.licenses-ipwhitelist.ipwhitelist.sourcerange=148.229.0.0/16,187.164.0.0/18,189.202.128.0/17,189.204.128.0/17,201.140.96.0/19,201.148.0.0/18,177.236.0.0/15,177.238.0.0/20,187.185.112.0/20,187.185.192.0/20,187.252.64.0/20,189.214.0.0/15,148.212.0.0/15,148.217.0.0/16,148.219.0.0/16,187.131.0.0/16,187.157.0.0/16,187.203.0.0/16,189.161.0.0/16,189.170.0.0/15,201.99.0.0/16,201.100.0.0/15"
      - "traefik.http.routers.licenses.middlewares=licenses-ipwhitelist"
    restart: always
    networks:
      - traefik-network

  traefik:
    image: traefik:v2.10
    container_name: traefik
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.email=admin@tuempresa.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
    ports:
      - "80:80"
      - "443:443"
      - "8081:8080"  # Traefik dashboard (opcional)
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - traefik_letsencrypt:/letsencrypt
    networks:
      - traefik-network

volumes:
  license_data:
  traefik_letsencrypt:

networks:
  traefik-network:
    external: true
```

---

## Comparación de Opciones

| Característica | Nginx Proxy Manager | Caddy | Traefik |
|---------------|---------------------|-------|---------|
| Facilidad de uso | ⭐⭐⭐⭐⭐ (GUI) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Configuración | Web UI | 1 archivo | Labels Docker |
| HTTPS automático | ✅ | ✅ | ✅ |
| Renovación SSL | ✅ | ✅ | ✅ |
| IP Whitelist | Access Lists | Caddyfile | Middleware |
| Recursos | Medio | Bajo | Medio-Alto |
| Ideal para | Easypanel/VPS | Docker simple | Swarm/K8s |

---

## Recomendación por Escenario

1. **Easypanel:** Usar Nginx Proxy Manager (ya integrado)
2. **Docker Compose simple:** Usar Caddy (mínima configuración)
3. **Producción escalable:** Usar Traefik (más features)

---

## Verificación de HTTPS

Después de implementar cualquier opción:

```bash
# 1. Verificar certificado SSL
openssl s_client -connect licenses.tuempresa.com:443 -servername licenses.tuempresa.com | grep "Verify return code"

# 2. Verificar redirección HTTP → HTTPS
curl -I http://licenses.tuempresa.com
# Debe retornar: 301 o 308 redirect

# 3. Verificar HTTPS funcional
curl -I https://licenses.tuempresa.com
# Debe retornar: HTTP 200 OK

# 4. Verificar headers de seguridad
curl -I https://licenses.tuempresa.com | grep -E "Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options"

# 5. Test con SSL Labs (externo)
# https://www.ssllabs.com/ssltest/analyze.html?d=licenses.tuempresa.com
# Objetivo: Grade A o A+
```

---

## Security Headers Recomendados

Para cualquier opción, agregar estos headers:

```nginx
# En Nginx Proxy Manager → Advanced → Custom Nginx Configuration
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

```caddyfile
# En Caddyfile
header {
    Strict-Transport-Security "max-age=31536000; includeSubDomains"
    X-Frame-Options "SAMEORIGIN"
    X-Content-Type-Options "nosniff"
    X-XSS-Protection "1; mode=block"
    Referrer-Policy "strict-origin-when-cross-origin"
}
```

---

## Troubleshooting

### Error: "Connection refused"
```bash
# Verificar que el contenedor está corriendo
docker ps | grep autodesk-win-wine

# Verificar que el puerto 8080 responde internamente
docker exec autodesk-win-wine curl -I http://localhost:8080
```

### Error: "SSL certificate not trusted"
```bash
# Caddy: Verificar logs de obtención de certificado
docker logs caddy-proxy | grep -i "certificate"

# Nginx PM: Verificar estado del certificado en la UI
```

### Error: "403 Forbidden (IP not allowed)"
```bash
# Verificar tu IP actual
curl -4 ifconfig.me

# Verificar que está en el rango correcto
whois $(curl -4 ifconfig.me) | grep -i "NetRange\|CIDR"

# Agregar tu IP temporalmente para pruebas
# En Nginx PM: Access Lists → Add IP
# En Caddyfile: Agregar línea @allowed remote_ip TU_IP/32
```
