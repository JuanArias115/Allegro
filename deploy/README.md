# Despliegue de Allegro (backend + infraestructura)

Referencia de la infraestructura de **producción**. El despliegue del backend es
automático (ver `.github/workflows/deploy.yml`); Nginx se administra **aparte**.

## Datos de producción

| Dato | Valor |
|---|---|
| Dominio público | `https://allegro.juanariasdev.com` |
| Contenedor de la API | `allegro-api` |
| Puerto interno | `8080` (no se publica al host) |
| Red Docker externa | `allegro_ingress` |
| Base de datos | `allegro-db` (PostgreSQL 16, sin publicar 5432) |
| Certificados TLS | `/etc/letsencrypt/live/allegro.juanariasdev.com/` |
| Directorio en el servidor | `/opt/allegro` |

## Archivos

- `docker-compose.production.yml` — stack de producción (imagen de GHCR).
- `.env.production.example` — plantilla de variables (sin secretos). El `.env` real vive en `/opt/allegro/.env` y no se versiona.
- `deploy.sh` / `rollback.sh` — despliegue y reversión.
- `nginx/allegro.conf` — **plantilla** de los server blocks de Allegro (ver abajo).

## Nginx (administrado fuera del workflow de la app)

`nginx/allegro.conf` es una **plantilla/referencia versionada** con SOLO los
bloques de Allegro. No reemplaza el `nginx.conf` compartido del servidor (que
también sirve otras apps). Características:

- HTTP en `allegro.juanariasdev.com` con ruta ACME y redirección a HTTPS.
- HTTPS con TLS 1.2/1.3 y certificados en `/etc/letsencrypt/live/allegro.juanariasdev.com/`.
- Proxy a `http://allegro-api:8080` con **resolución dinámica** (`resolver 127.0.0.11`),
  porque la IP del contenedor cambia tras cada despliegue.
- Cabeceras `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto`.

Aplicar cambios de Nginx (manual):

```bash
# 1) Copiar/incluir el sitio (ajusta la ruta a la convención del servidor)
sudo cp deploy/nginx/allegro.conf /etc/nginx/conf.d/allegro.conf
# 2) Validar SIEMPRE antes de recargar
sudo nginx -t
# 3) Recargar sin downtime solo si la validación pasó
sudo nginx -s reload   # o: sudo systemctl reload nginx
```

> Nginx corre como contenedor en la red `allegro_ingress` para poder resolver
> `allegro-api` por DNS de Docker. No edites la configuración global compartida.

## Renovación de certificados

Los certificados se renuevan con certbot (fuera de esta app). Tras renovar,
recargar Nginx (`nginx -s reload`). Ejemplo de prueba de renovación:

```bash
sudo certbot renew --dry-run
```

## Despliegue

Automático en cada push a `main` que toque `backend/**` o `deploy/**`. También
manual:

```bash
cd /opt/allegro
bash deploy.sh <SHA>     # fija el tag, hace pull + up -d y espera /health/ready
```

## Rollback

```bash
cd /opt/allegro
bash rollback.sh <SHA-anterior>   # reusa una imagen ya publicada en GHCR
```
