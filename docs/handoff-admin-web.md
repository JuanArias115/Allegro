# Handoff — App web administrativa (Angular) + extensiones backend

> Documento vivo para retomar entre sesiones. Rama: **`feature/admin-web`** (NO mergear, NO desplegar, NO push a main sin autorización).
> Inicio: 2026-06-21.

## Objetivo

Nueva app web administrativa (`admin-web/`, Angular) + ampliar el backend .NET para:
reservas, calendario/ocupación, productos y categorías, usuarios de Firebase, reportería.
Flutter sigue siendo la herramienta operativa móvil. La web es administración/análisis.

## Decisiones tomadas con el usuario (2026-06-21)

1. **Precio base por domo:** NO se agrega. Domos solo administra nombre, capacidad y estado activo.
   `LodgingPrice` se sigue fijando por reserva. (Tarifas/temporadas se diseñarán más adelante.)
2. **DomeBlock (bloqueo de fechas):** INCLUIDO en este trabajo (entidad + migración + integración con disponibilidad).
3. Trabajar en rama nueva `feature/admin-web`, plan aprobado, implementar por bloques, probar tras cada bloque, commits separados.

## Plan por bloques (commits)

1. ✅ **Backend seguridad + roles + auditoría** (commit `3e69469`).
2. ✅ **DomeBlock** (bloqueo de fechas) (commit `dee96f8`).
3. ✅ **Usuarios Firebase** (Firebase Admin SDK, abstracción, endpoints, bootstrap CLI) (commit `5918112`).
4. ✅ **Reportes** (/api/admin/reports/* + CSV) + **categorías admin** — ver estado abajo.
5. ⬜ **Angular base** (proyecto admin-web, tema, auth Firebase, guards, interceptor, shell).
6. ⬜ **Módulos admin** (dashboard, calendario, reservas, domos, productos+categorías, usuarios, reportes, configuración).
7. ⬜ **Pruebas + docs + Docker/CI web**.

## Estado del backend tras Bloque 1 y 2

### Bloque 1 — Seguridad/roles/auditoría (commit `3e69469`)
- `Allegro.Api/Auth/AuthPolicies.cs`: constantes `Roles` (admin/operator), `Policies` (AppAccess/Admin/Operator), `AppClaims` (role/app_access).
- `Allegro.Api/Auth/AppAccessRequirement.cs`: requisito + handler. Si `Authorization:RequireAppAccessClaim=true` exige claim `app_access=true`; si false (default) basta autenticación. **No bloquea a los usuarios actuales de Flutter.**
- `AuthSetup.cs`: JwtBearer con `MapInboundClaims=false` (conserva user_id/sub/role/app_access). Políticas registradas. DefaultPolicy = AppAccess (lo usan los `[Authorize]` existentes). Admin = role admin. Operator = role operator|admin. Registra `IHttpContextAccessor` + `ICurrentUser`.
- `Allegro.Api/Auth/CurrentUser.cs`: implementa `ICurrentUser` (Application/Abstractions/ICurrentUser.cs) leyendo claims.
- `LocalDevAuthHandler`: ahora emite `role` (env `LOCAL_DEV_ROLE`, default admin) + `app_access=true` + user_id/name. Para probar admin/operator en dev sin Firebase.
- `Program.cs`: CORS por `Cors:AllowedOrigins` (abierto solo en Development sin orígenes). Rate limiting nativo .NET 8: política `admin-sensitive` (20/min por usuario) — aplicar con `[EnableRateLimiting("admin-sensitive")]` en endpoints sensibles.
- Entidad `AuditLog` (Domain/AuditLog.cs) + `AuditActions` constantes. Tabla `audit_logs`. `IAuditLogService`/`AuditLogService` (Application/Services). Migración **`20260621102955_AdminAuditLog`**.
- `appsettings.json`: añadidas `LOCAL_DEV_ROLE`, `Authorization:RequireAppAccessClaim=false`, `Cors:AllowedOrigins=[]`.

### Bloque 2 — DomeBlock
- `Allegro.Domain/DomeBlock.cs`: Id, DomeId, StartDate (incl), EndDate (excl), Reason, CreatedAt + `OverlapsWith`.
- DbContext config (tabla `dome_blocks`, índice DomeId+fechas, FK Restrict) + DbSet + `IAppDbContext.DomeBlocks`.
- DTOs `DomeBlockDto` / `CreateDomeBlockDto`; validador `CreateDomeBlockValidator`.
- `IDomeBlockService`/`DomeBlockService`: List(domeId?, from?, to?), Create (valida cruce con reservas activas y con otros bloqueos), Delete.
- Integración en `ReservationService`: Create/Update rechazan fechas bloqueadas (`EnsureNoBlockOverlapAsync`); `CheckAvailabilityAsync` ahora también considera bloqueos.
- **Contrato (aditivo, documentar):** `AvailabilityDto` ahora incluye `BlockedRanges: DomeBlockDto[]` además de `Conflicts`. Flutter ignora el campo extra (parseo por claves).
- Endpoint nuevo: `GET/POST /api/dome-blocks`, `DELETE /api/dome-blocks/{id}` (`DomeBlocksController`, política Operator). Migración **`DomeBlocks`**.
- Tests `DomeBlockTests.cs`.

## Arquitectura backend (recordatorio)
.NET 8 Clean Architecture: Domain / Application / Infrastructure / Api. EF Core 8 + Npgsql, PostgreSQL 16, FluentValidation, xUnit + FluentAssertions (SQLite in-memory, `TestHelpers.cs` con `TestHarness` y `FakeClock`).
- Build/test SOLO dentro de docker: `docker run --rm -v "$PWD/backend":/src -w /src mcr.microsoft.com/dotnet/sdk:8.0 dotnet test Allegro.sln` (el SDK local es 3.1).
- Migraciones: hay design-time factory en `Allegro.Infrastructure/Persistence/AllegroDbContextFactory.cs`, así que `--startup-project src/Allegro.Infrastructure`. Instalar `dotnet-ef --version 8.0.8` en el contenedor.
- `IClock` (SystemClock) usa `BUSINESS_TIMEZONE` default `America/Bogota`. Montos `decimal`. Fechas reserva `DateOnly` (date); timestamps UTC.
- Servicios existentes a REUTILIZAR: `ReservationService` (completo), `DomeService` (GetAll/GetById/Update), `ProductService` (CRUD+activar), `ProductCategoryService` (solo GetActive — falta escritura admin para la web).

### Bloque 3 — Usuarios Firebase
- Paquete `FirebaseAdmin` 3.1.0 en Allegro.Infrastructure.csproj.
- Abstracción `IFirebaseUserManagementService` (Application/Abstractions) + DTOs `UserDtos.cs` (AdminUserDto, UserPageDto, CreateUserDto, CreateUserResultDto, UpdateUserDto, ChangeUserStatusDto, ActivationLinkDto).
- Impl real `Infrastructure/Firebase/FirebaseUserManagementService.cs` (List con búsqueda+paginación en memoria, cap 1000; mapea UserRecord→DTO; sanea errores del SDK como DomainException; `GeneratePasswordResetLinkAsync(email)` SIN ct — el SDK no tiene ese overload).
- Stub `UnavailableFirebaseUserManagementService` para AUTH_MODE!=firebase (List vacío, escrituras lanzan DomainException claro).
- `FirebaseAppInitializer.EnsureInitialized` (ADC / GOOGLE_APPLICATION_CREDENTIALS). DI en Infrastructure elige impl según AUTH_MODE.
- `AdminUserService` (Application) con reglas: validar rol, rechazar email duplicado, **proteger último admin activo** (no degradar ni bloquear), auditar todo, nunca auditar el enlace. `Roles` interno (admin/operator).
- `AdminUsersController` (`/api/admin/users`, `[Authorize(Policy=Admin)]`, `[EnableRateLimiting("admin-sensitive")]`): GET list (query/pageToken/pageSize), GET {uid}, POST, PATCH {uid} (name/role), POST {uid}/activation-link, POST {uid}/revoke-sessions, PATCH {uid}/status.
- CLI `bootstrap-admin` en `Allegro.Api/Bootstrap/BootstrapAdminCommand.cs`, conectado en Program antes de migraciones/Run. Uso: `dotnet run --project src/Allegro.Api -- bootstrap-admin --email x@y.com` (o `--uid`). Idempotente, requiere AUTH_MODE=firebase + creds, solo imprime UID enmascarado.
- Tests `AdminUserTests.cs` con fakes en `tests/.../Fakes/` (FakeFirebaseUserManagementService, FakeAuditLogService, FakeCurrentUser). NO tocan Firebase real.

### Bloque 4 — Reportes + categorías admin
- `IClock.ToBusinessDate(DateTime utc)` agregado (SystemClock convierte con la tz; FakeClock usa UTC-5).
- DTOs `ReportDtos.cs` (ReportSummaryDto, OccupancyReportDto/OccupancyByDomeDto, PaymentsReportDto/PaymentBucketDto, ProductsReportDto/ProductSalesDto) con definiciones documentadas en XML doc.
- `ReportService` (Application): GetSummary/GetOccupancy/GetPayments/GetProducts. Rango [from,to). Ocupación por noches de solapamiento (sin doble conteo de meses); reservas atribuidas por CheckIn; canceladas fuera de ocupación/valor pero pagos reales sí cuentan; montos decimal; pagos/consumos agrupados por fecha Bogota.
- `ReportCsv.Build(...)` helper en Application (testeable sin AspNetCore). `AdminReportsController` (`/api/admin/reports/*`, Admin) usa el servicio + helper; export.csv con BOM UTF-8.
- **Categorías admin (aditivo, no rompe Flutter):** `ProductCategoryService` ahora tiene GetAllAsync/CreateAsync/UpdateAsync (valida nombre único, no desactivar con productos activos). `AdminProductCategoriesController` (`/api/admin/product-categories`, Admin): GET all, POST, PUT. El GET público `/api/product-categories` (activas) NO cambió.
- Validador `UpsertProductCategoryValidator`. DTO `UpsertProductCategoryDto`.
- Tests `ReportTests.cs` (8) y `CategoryAdminTests.cs` (5).

## Pendiente inmediato (donde retomar)
- Faltan pruebas de **autorización** a nivel Api (admin/operator/sin claims) — requieren WebApplicationFactory (Program es partial public) + Microsoft.AspNetCore.Mvc.Testing en el test csproj. Pendiente para fase de pruebas (Bloque 7).
- **Bloques 5-7 (Angular)**: proyecto `admin-web/` completo. Es el grueso restante; planear sesión dedicada. Ver sección TECNOLOGÍA/DISEÑO del prompt original.
- **Resumen de endpoints nuevos backend** (todos bajo /api): `GET/POST/DELETE /dome-blocks` (Operator); `GET/POST/PATCH /admin/users[...]` (Admin, rate-limited); `GET /admin/reports/{summary,occupancy,payments,products,export.csv}` (Admin); `GET/POST/PUT /admin/product-categories` (Admin). Sin cambios de contrato salvo `AvailabilityDto.BlockedRanges` (aditivo).
- **Variables de entorno nuevas**: `Authorization__RequireAppAccessClaim` (default false), `Cors__AllowedOrigins__0..n`, `LOCAL_DEV_ROLE` (dev), `GOOGLE_APPLICATION_CREDENTIALS` (prod, montar secreto), `FIREBASE_PROJECT_ID` (ya existía).

## Restricciones (recordatorio)
No TRA. No secretos en git. No cambiar credenciales. No desplegar. No push a main. No romper Flutter. Documentar cambios de contrato. No datos demo en prod. Nada contable avanzado. No borrar históricos.
