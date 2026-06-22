# Aplicación web administrativa (admin-web) + extensiones backend

Web de administración para Allegro Eco Glamping (Angular) y las ampliaciones del backend .NET
que la soportan. La app Flutter sigue siendo la herramienta operativa móvil; la web se enfoca en
administración, configuración y análisis.

## Requisitos

- **Backend**: .NET 8 SDK, PostgreSQL 16 (vía Docker). Build/test del backend dentro del contenedor
  `mcr.microsoft.com/dotnet/sdk:8.0`.
- **Frontend**: Node 22+, Angular CLI 21. `admin-web/` usa Angular standalone, zoneless, signals,
  TypeScript estricto, Angular Material, ECharts y Firebase Web SDK. Pruebas con **vitest**.

## Desarrollo local

### Backend
```bash
# Migraciones + pruebas
docker run --rm -v "$PWD/backend":/src -w /src mcr.microsoft.com/dotnet/sdk:8.0 dotnet test Allegro.sln
# Levantar API + Postgres
docker compose up
```
En desarrollo, `AUTH_MODE=local` acepta un token estático. La **web siempre usa Firebase**, así que
para probarla en local apunta a un backend con `AUTH_MODE=firebase` (con credenciales) o al backend
de producción.

### Frontend
```bash
cd admin-web
npm ci
npm start        # ng serve (usa environment.development.ts)
npm run build    # build de producción
npm test         # pruebas (vitest)
npm run lint     # eslint
```

## Configuración de Firebase Web (frontend)

La configuración **pública** de Firebase Web va en `admin-web/src/environments/`:
- `environment.ts` (producción) y `environment.development.ts` (desarrollo).

En desarrollo se pueden reemplazar los placeholders de `environment.development.ts`. En producción
no es necesario recompilar: el contenedor genera `config.json` desde las variables públicas
`FIREBASE_WEB_*` de `/opt/allegro/.env`. Es el **mismo proyecto** que usa Flutter. **No** se guardan
credenciales administrativas ni archivos service-account en el frontend.

`googleAuthEnabled` activa el botón de Google (solo funciona si Google está habilitado como proveedor
en Firebase Authentication).

## Configuración de Firebase Admin (backend)

El backend usa **Firebase Admin SDK** (paquete `FirebaseAdmin`) cuando `AUTH_MODE=firebase`. Las
credenciales administrativas:
- **Nunca** en Git.
- Se obtienen por **Application Default Credentials (ADC)** o la ruta de
  `GOOGLE_APPLICATION_CREDENTIALS`.

### Montar el secreto en producción (ejemplo conceptual)
Monta el JSON de service-account como secreto (no lo incluyas en la imagen) y apunta la variable:
```yaml
# docker-compose.production.yml (fragmento conceptual)
services:
  allegro-api:
    environment:
      AUTH_MODE: firebase
      FIREBASE_PROJECT_ID: <project-id>
      GOOGLE_APPLICATION_CREDENTIALS: /run/secrets/firebase-admin.json
    secrets:
      - firebase-admin.json
secrets:
  firebase-admin.json:
    file: ./secrets/firebase-admin.json   # fuera de git; provisto en el servidor
```
Sin credenciales válidas, la gestión de usuarios no está disponible (en modos no-firebase se usa un
stub seguro que no expone nada).

## Variables de entorno (backend)

| Variable | Propósito |
|---|---|
| `AUTH_MODE` | `firebase` (producción) o `local` (desarrollo). |
| `FIREBASE_PROJECT_ID` | Proyecto Firebase (requerido con `AUTH_MODE=firebase`). |
| `GOOGLE_APPLICATION_CREDENTIALS` | Ruta al service-account de Firebase Admin (secreto). |
| `Authorization__RequireAppAccessClaim` | `false` por defecto. Cuando es `true`, los endpoints normales exigen el claim `app_access=true`. |
| `Cors__AllowedOrigins__0..n` | Orígenes permitidos para la web (CORS). En producción, define el dominio de la web. |
| `LOCAL_DEV_TOKEN` / `LOCAL_DEV_ROLE` | Solo desarrollo (`AUTH_MODE=local`): token estático y rol simulado (default `admin`). |
| `BUSINESS_TIMEZONE` | Zona del negocio, default `America/Bogota`. |

### Frontend (runtime)
La imagen Docker de `admin-web` acepta `API_BASE_URL`, `GOOGLE_AUTH_ENABLED` y
`FIREBASE_WEB_{API_KEY,AUTH_DOMAIN,PROJECT_ID,STORAGE_BUCKET,MESSAGING_SENDER_ID,APP_ID}`. El
entrypoint escribe `config.json` y la app lo carga antes de inicializar Firebase. Si falta algún
valor Firebase, el arranque del frontend falla explícitamente en lugar de usar placeholders.

## Roles y permisos

Claims de Firebase: `app_access: true` y `role: "admin" | "operator"`.

| Sección | admin | operator |
|---|---|---|
| Dashboard | ✓ | ✓ |
| Calendario | ✓ | ✓ |
| Reservas (pagos, consumos, checkout) | ✓ | ✓ |
| Productos (consulta) | ✓ | ✓ |
| Productos/Categorías (edición) | ✓ | — |
| Domos | ✓ | — |
| Usuarios | ✓ | — |
| Reportes | ✓ | — |
| Configuración | ✓ | — |

La autorización **siempre** se valida en el backend (políticas `Admin` y `Operator`). Ocultar
botones en Angular no es suficiente. Endpoints admin requieren `role=admin`.

## Bootstrap del primer administrador

No hay endpoint HTTP de bootstrap. Se usa un comando de consola (requiere `AUTH_MODE=firebase` +
credenciales Admin; es idempotente; solo muestra el UID enmascarado):

```bash
# Local
dotnet run --project backend/src/Allegro.Api -- bootstrap-admin --email usuario@dominio.com
# o por UID
dotnet run --project backend/src/Allegro.Api -- bootstrap-admin --uid <firebase-uid>

# Dentro del contenedor de la API
docker compose exec allegro-api dotnet Allegro.Api.dll bootstrap-admin --email usuario@dominio.com
```
El usuario debe existir en Firebase antes de promoverlo. El comando le asigna `app_access=true` y
`role=admin`.

## Activación posterior de RequireAppAccessClaim

Para no bloquear a los usuarios actuales de Flutter, `Authorization__RequireAppAccessClaim` arranca
en `false`: los endpoints normales solo exigen estar autenticado; los administrativos siempre exigen
`role=admin`. Procedimiento para activarlo sin romper accesos:

1. Asegúrate de que **todos** los usuarios actuales tengan el claim `app_access=true` (créalos/edítalos
   desde la sección Usuarios, o promuévelos con el bootstrap).
2. Verifica que puedan iniciar sesión normalmente.
3. Cambia `Authorization__RequireAppAccessClaim=true` y redepliega el backend.
4. A partir de ahí, un usuario sin `app_access` recibirá 403 en los endpoints normales.

## Definiciones de los reportes

Rango `[from, to)`: **inicio inclusivo, fin exclusivo**, en zona `America/Bogota`. Montos en `decimal`.
Cálculos en el backend (la web no descarga todas las reservas).

- **Cantidad de reservas / Valor reservado / Noches reservadas / Saldo pendiente**: reservas **no
  canceladas** cuya **llegada (CheckIn)** cae en el rango. Cada reserva cuenta en un solo periodo
  (evita el doble conteo entre meses).
- **Cancelaciones**: reservas canceladas con CheckIn en el rango.
- **Noches ocupadas (ocupación)**: suma de **noches de solapamiento** entre cada estadía no cancelada
  y el rango (conteo por noche; una reserva que cruza meses aporta a cada mes solo sus noches reales).
- **Noches disponibles**: `domos activos × noches del rango`, descontando las noches bloqueadas
  por mantenimiento o uso personal.
- **Porcentaje de ocupación**: `noches ocupadas / noches disponibles`.
- **Pagos recibidos**: pagos cuya fecha (Bogotá) cae en el rango, **independiente** del estado de la
  reserva (un pago válido cuenta aunque la reserva se cancele después).
- **Saldo pendiente**: suma de saldos de las reservas no canceladas del periodo.
- **Ventas de productos / más vendidos**: consumos cuya fecha (Bogotá) cae en el rango, agrupados por
  producto y ordenados por valor.

Se distingue siempre: **Valor reservado** (no es ingreso hasta pagarse), **Dinero recibido** (pagos
reales) y **Saldo pendiente**. Exportación a **CSV** disponible. No se implementan PDF, facturación,
impuestos, contabilidad ni utilidad neta en esta fase.

## Endpoints backend añadidos

- `GET/POST/DELETE /api/dome-blocks` — bloqueos de fechas (Operator).
- `GET/POST/PATCH /api/admin/users[...]` — gestión de usuarios Firebase (Admin, con rate limiting):
  list paginado/búsqueda, create, patch (nombre/rol), `activation-link`, `revoke-sessions`, `status`.
- `GET /api/admin/reports/{summary,occupancy,payments,products,export.csv}` — reportería (Admin).
- `GET/POST/PUT /api/admin/product-categories` — administración de categorías (Admin).

Cambio de contrato (aditivo, no rompe Flutter): `AvailabilityDto` incluye `blockedRanges`.

Migraciones nuevas: `AdminAuditLog` (tabla `audit_logs`), `DomeBlocks` (tabla `dome_blocks`).

## Despliegue automático

`deploy-admin.yml` verifica Angular, construye `ghcr.io/juanarias115/allegro-admin:<sha>` y despliega
por SSH cuando cambia `admin-web/**` en `main`. El servidor usa
`deploy/docker-compose.admin.yml` y mantiene el contenedor únicamente en `allegro_ingress`, sin
publicar puertos al host. El proxy compartido expone `admin.allegro.juanariasdev.com` con HTTPS.

Antes del primer despliegue:
1. Registrar `admin.allegro.juanariasdev.com` en DNS y Firebase Authorized domains.
2. Completar las variables `FIREBASE_WEB_*` y `Cors__AllowedOrigins__0` en `/opt/allegro/.env`.
3. Montar el secreto Firebase Admin en la API y ejecutar el bootstrap del primer admin.
4. Instalar el bloque Nginx versionado en `deploy/nginx/allegro-admin.conf` dentro del proxy real.
