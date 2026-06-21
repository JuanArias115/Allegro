# Allegro 🌿

Aplicación interna para administrar un glamping muy pequeño, operado por **una sola persona** y compuesto por **dos domos**. Permite ver qué pasa hoy, gestionar reservas evitando cruces, registrar abonos y consumos, hacer checkout y preparar mensajes de WhatsApp.

> No es un sistema hotelero complejo. No incluye facturación electrónica, contabilidad avanzada, múltiples propiedades ni integración con canales externos (Airbnb/Booking).

## Arquitectura

```
/backend     API REST en ASP.NET Core (.NET 8 LTS) + EF Core + PostgreSQL
/mobile      App Flutter (Material 3, Riverpod, go_router)
/docs        Documentación adicional (Firebase, arquitectura)
docker-compose.yml   PostgreSQL + API para desarrollo local
.env.example         Variables de entorno de ejemplo
```

**Backend** — Clean Architecture en capas:

| Proyecto | Responsabilidad |
|---|---|
| `Allegro.Domain` | Entidades y reglas de negocio (saldo, cruces). |
| `Allegro.Application` | Casos de uso, DTOs, validaciones (FluentValidation). |
| `Allegro.Infrastructure` | EF Core, PostgreSQL, migraciones, seed. |
| `Allegro.Api` | Controllers REST, OpenAPI, autenticación, health checks. |
| `Allegro.Tests` | Pruebas xUnit de las reglas críticas. |

**Frontend** — capas claras: `models` (inmutables) → `data` (repositorios) → `providers` (Riverpod) → `features` (pantallas). La lógica de negocio importante vive en el backend, no en los widgets.

## Requisitos

- [Docker](https://www.docker.com/) y Docker Compose (para backend + PostgreSQL).
- [Flutter](https://docs.flutter.dev/) estable (3.35+) y Dart 3.9+ (para la app móvil).
- No necesitas instalar .NET localmente: el backend compila y migra dentro de Docker.

## Configuración de variables de entorno

```bash
cp .env.example .env
# Edita .env y cambia al menos POSTGRES_PASSWORD.
```

Variables principales (ver `.env.example` para la lista completa):

| Variable | Descripción |
|---|---|
| `POSTGRES_*` | Credenciales y nombre de la base de datos. |
| `ConnectionStrings__Default` | Cadena de conexión usada por la API. |
| `APPLY_MIGRATIONS` | Aplica migraciones al iniciar (`true` en local). |
| `SEED_DEMO_DATA` | Siembra reservas de demostración. **Solo `true` en desarrollo.** |
| `AUTH_MODE` | `local` (desarrollo) o `firebase`. |
| `FIREBASE_PROJECT_ID` | Requerido cuando `AUTH_MODE=firebase`. |
| `LOCAL_DEV_TOKEN` | Token aceptado en modo local. |

> **Nunca** se versionan credenciales reales ni archivos de Firebase. `.env` y los archivos de Firebase están en `.gitignore`.

## Iniciar PostgreSQL y el backend (Docker Compose)

```bash
docker compose up -d --build
```

Esto levanta:

- `allegro-db` — PostgreSQL 16 con volumen persistente y health check.
- `allegro-api` — la API en `http://localhost:8080`, que **aplica las migraciones desde una base vacía** y siembra datos iniciales.

Verifica:

```bash
curl http://localhost:8080/health                # Healthy
# Swagger (solo en Development):
open http://localhost:8080/swagger
```

Las peticiones requieren cabecera de autorización. En modo local:

```bash
curl -H "Authorization: Bearer allegro-dev-token" http://localhost:8080/api/today
```

## Ejecutar la app Flutter

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # emulador Android
# En simulador iOS usa http://localhost:8080
```

Por defecto la app arranca en **modo local** (sin Firebase) usando `LOCAL_DEV_TOKEN`. Para apuntar a otro servidor o activar Firebase usa `--dart-define`:

```bash
flutter run --dart-define=AUTH_MODE=firebase
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080
```

## Migraciones de base de datos

Las migraciones se aplican automáticamente al iniciar la API (`APPLY_MIGRATIONS=true`). Para crear una nueva migración (requiere el contenedor del SDK de .NET 8):

```bash
docker run --rm -v "$PWD/backend":/src -w /src mcr.microsoft.com/dotnet/sdk:8.0 \
  bash -c "dotnet tool install -g dotnet-ef --version 8.0.8 && \
           export PATH=\$PATH:/root/.dotnet/tools && \
           dotnet ef migrations add NombreMigracion \
             --project src/Allegro.Infrastructure \
             --startup-project src/Allegro.Infrastructure \
             --output-dir Migrations"
```

## Ejecutar las pruebas

Backend (xUnit, sobre SQLite en memoria):

```bash
docker run --rm -v "$PWD/backend":/src -w /src mcr.microsoft.com/dotnet/sdk:8.0 \
  dotnet test Allegro.sln -c Release
```

Frontend (Flutter):

```bash
cd mobile
flutter analyze
flutter test
```

## Configurar Firebase más adelante

La app ya está preparada para Firebase Authentication. Ver **[docs/firebase.md](docs/firebase.md)** para los pasos detallados (añadir `google-services.json` / `GoogleService-Info.plist`, `firebase_options.dart`, y configurar `AUTH_MODE=firebase` + `FIREBASE_PROJECT_ID` en el backend). Mientras tanto, el **modo local** permite trabajar en desarrollo sin credenciales (nunca habilitado por defecto en producción).

## Decisiones de diseño importantes

- **.NET 8 LTS** y **EF Core 8** por estabilidad; el backend se construye y migra dentro de Docker (no requiere SDK local).
- **Saldo siempre calculado** (`alojamiento + consumos − abonos`); el precio de cada consumo se **congela** al registrarlo, de modo que cambiar el catálogo no altera cuentas pasadas.
- **Anti-cruce** garantizado en el backend con intervalo semiabierto `[llegada, salida)`; las reservas canceladas no bloquean disponibilidad.
- **Operaciones financieras en transacciones** (abonos, consumos, checkout).
- **El checkout no finaliza solo**: requiere confirmación explícita del usuario.
- **Sin borrado físico** de reservas importantes: se conservan con estado `Cancelada`/`Finalizada` para el historial.
- **Fechas en UTC** para instantes; las fechas de calendario (llegada/salida) se guardan como `date`. "Hoy" se calcula en la zona horaria del negocio (`BUSINESS_TIMEZONE`, por defecto `America/Bogota`).
- **Moneda COP** con formato `es_CO`.
- **Modelos inmutables** y mapeo manual en Flutter (sin generación de código) para mantener el proyecto simple.

## Despliegue en producción (solo backend)

El backend se despliega automáticamente por **GitHub Actions** a un servidor Linux con Docker. El frontend Flutter no se despliega aquí.

### Flujo

- **CI** (`.github/workflows/ci.yml`) — en cada Pull Request: restaura, compila y ejecuta las pruebas .NET.
- **Deploy** (`.github/workflows/deploy.yml`) — en cada push a `main`:
  1. Ejecuta las pruebas .NET (si fallan, no despliega).
  2. Construye la imagen y la publica en GHCR con las etiquetas `latest` y el SHA del commit: `ghcr.io/juanarias115/allegro-api`.
  3. Entra por SSH al servidor (secrets `DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_PORT`, `DEPLOY_SSH_KEY`, `DEPLOY_KNOWN_HOSTS`), copia `deploy/` a `/opt/allegro`, hace `docker compose pull` + `up -d` y **espera el health check**. Si `/health/ready` no responde correctamente, el despliegue falla.
- Permisos del workflow: `contents: read`, `packages: write`.

### Servidor (`/opt/allegro`)

- `docker-compose.production.yml` — servicios `allegro-api` (imagen de GHCR, **no compila** en el servidor) y `allegro-db` (PostgreSQL 16). PostgreSQL en volumen persistente, **sin publicar el 5432**; la API **no publica puertos**, solo expone el `8080` interno y se conecta a la red externa `allegro_ingress` para que el proxy la alcance por el nombre `allegro-api`.
- `.env` — secretos de producción (cadena de conexión, contraseña de PostgreSQL, `FIREBASE_PROJECT_ID`, etc.). **No se versiona.** Plantilla: [`deploy/.env.production.example`](deploy/.env.production.example).

### Variables de entorno (producción)

| Variable | Descripción |
|---|---|
| `IMAGE_TAG` | Imagen a desplegar (el pipeline la fija al SHA). |
| `POSTGRES_DB` / `POSTGRES_USER` / `POSTGRES_PASSWORD` | Base de datos PostgreSQL. |
| `ConnectionStrings__Default` | Conexión de la API (host = `allegro-db`). |
| `APPLY_MIGRATIONS` | `true` → aplica migraciones al iniciar (idempotente). |
| `AUTH_MODE` | **Siempre `firebase`** en producción (el backend rechaza `local`). |
| `FIREBASE_PROJECT_ID` | Proyecto de Firebase para validar los tokens. |
| `BUSINESS_TIMEZONE` | Zona horaria del negocio (ej. `America/Bogota`). |

`SEED_DEMO_DATA` se fuerza a `false` en el Compose de producción. Para Firebase, ver también [docs/firebase.md](docs/firebase.md).

### Rollback

Para volver a una versión anterior, en el servidor:

```bash
cd /opt/allegro
bash rollback.sh <SHA-anterior>   # reusa la imagen ya publicada en GHCR
```

`rollback.sh` fija ese tag, hace `pull` + `up -d` y espera el health check.

### Preparación inicial del servidor (una sola vez)

```bash
sudo mkdir -p /opt/allegro
# copiar deploy/.env.production.example -> /opt/allegro/.env y completar valores
docker network create allegro_ingress   # si aún no existe
```

> El despliegue automático aún **no se ha ejecutado**; el repositorio queda preparado. Nginx se conecta manualmente después (no se modifica aquí).
