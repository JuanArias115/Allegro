# Handoff — Categorías de productos dinámicas (enum → PostgreSQL)

> Documento de contexto para retomar el trabajo en otra sesión.
> **Estado: COMPLETADO y desplegado en producción.** Commit `4a3f47d` en `main` (ya pusheado).
> Fecha: 2026-06-21.

## 1. Qué se pidió

Reemplazar el **enum fijo** de categorías de productos por categorías **almacenadas en PostgreSQL**,
que Flutter obtiene dinámicamente desde el backend. Sin pantalla de administración de categorías
(se administran directo en la base por ahora). Sin pérdida de datos existentes.

Categorías iniciales: **Bebidas, Menú, Snacks, Servicios**.

Restricciones respetadas: no admin de categorías en Flutter; no app web todavía; no añadir productos
al repo/seeder; no tocar Firebase Auth; nada de TRA; no borrar datos; no tocar Docker/Nginx/dominio/
despliegue (más allá del flujo normal); no guardar secretos; mantener PostgreSQL 16; seguir arquitectura
y convenciones existentes.

## 2. Modelo de datos

Entidad **`ProductCategory`**: `Id` (UUID), `Name` (req, max 80), `DisplayOrder` (int), `IsActive` (bool).
Sin colores/iconos/imágenes/subcategorías/auditoría.

UUIDs fijos de las 4 categorías (en `ProductCategorySeedData`):
- Bebidas   `c0000000-0000-0000-0000-000000000001`
- Menú      `c0000000-0000-0000-0000-000000000002`
- Snacks    `c0000000-0000-0000-0000-000000000003`
- Servicios `c0000000-0000-0000-0000-000000000004`

`Product` ahora tiene `ProductCategoryId` (FK obligatoria, `OnDelete: Restrict`) + nav `Category`.
El enum `ProductCategory` fue **eliminado** del dominio.

## 3. Migración de datos (segura, ya aplicada en prod)

Migración EF: `backend/src/Allegro.Infrastructure/Migrations/20260621085749_DynamicProductCategories.cs`
(editada a mano para preservar datos). Orden en `Up()`:

1. Crea tabla `product_categories` + índice por `DisplayOrder`.
2. `InsertData` de las 4 categorías con UUIDs fijos.
3. `AddColumn ProductCategoryId` **nullable**.
4. `UPDATE` mapeando el viejo enum `Category` (int): `0→Bebidas`, `2→Servicios`,
   nombres de la lista de snacks → **Snacks**, **todo lo demás (incl. el viejo 1 y valores raros) → Menú**.
   El CASE va envuelto en `(CASE ... END)::uuid`.
5. `AlterColumn` → **NOT NULL** (solo posible si todos quedaron mapeados ⇒ garantiza que ningún producto queda sin categoría).
6. Crea índice + FK (`Restrict`).
7. **Recién entonces** elimina el índice viejo y la columna `Category`.

Lista de snacks (`ProductCategorySeedData.SnackNames`): Galletas Tosh, Chocolatina Jumbo Maní,
Mix de arándanos, Chocolatina Gol, Todo Rico Original, Maíz tostado, Gomitas Trolli.

**Verificada contra PostgreSQL 16 real** con datos legacy: 5/5 productos preservados, mapeo correcto,
columna `Category` eliminada, 4 categorías creadas.

## 4. Cambios de contrato de API (BREAKING)

- **Nuevo endpoint**: `GET /api/product-categories` (protegido, solo activas, orden `DisplayOrder` luego `Name`).
  Sin endpoints de escritura de categorías.
- **Producto (respuesta)**: antes `category` (string del enum, p.ej. `"Beverages"`). Ahora **`categoryId`** (UUID)
  + **`categoryName`** (string).
- **Crear/editar producto**: se envía **`categoryId`** (obligatorio; debe existir y estar activa).
  Ya **no** se aceptan nombres de categoría como texto ni el enum anterior.

## 5. Archivos clave

### Backend (.NET 8 / EF Core 8 / Npgsql / PostgreSQL 16)
- `Allegro.Domain/ProductCategory.cs` (entidad), `Allegro.Domain/Product.cs` (FK), `Allegro.Domain/Enums.cs` (enum removido).
- `Allegro.Infrastructure/Persistence/ProductCategorySeedData.cs` (UUIDs, lista snacks, `ResolveLegacyCategory`).
- `Allegro.Infrastructure/Persistence/AllegroDbContext.cs` (DbSet + config EF), `DataSeeder.cs` (seed idempotente).
- `Allegro.Application/Dtos/ProductDtos.cs` (`ProductCategoryDto`, `ProductDto`, `UpsertProductDto`).
- `Allegro.Application/Services/ProductCategoryService.cs` (nuevo), `ProductService.cs` (valida categoría existe+activa).
- `Allegro.Application/Validation/Validators.cs` (`CategoryId` NotEmpty).
- `Allegro.Api/Controllers/ProductCategoriesController.cs` (nuevo: `GET /api/product-categories`).
- Migración: `Allegro.Infrastructure/Migrations/20260621085749_DynamicProductCategories.cs`.

### Flutter (Riverpod / go_router)
- `mobile/lib/src/models/product_category.dart` (nuevo), `models/product.dart` (categoryId/categoryName).
- `mobile/lib/src/data/product_repository.dart` (`getCategories()`).
- `mobile/lib/src/providers.dart` (`productCategoriesProvider`).
- `mobile/lib/src/features/products/product_grouping.dart` (nuevo: agrupa, ordena por DisplayOrder, oculta vacías, no pierde productos).
- `mobile/lib/src/features/products/products_screen.dart` (catálogo agrupado dinámico).
- `mobile/lib/src/features/products/product_form_sheet.dart` (selector dinámico; conserva categoría inactiva al editar).

## 6. Pruebas (todas en verde)

- **Backend** `dotnet test Allegro.sln`: **24/24**. Incluye `ProductCategoryTests.cs`: lectura activas/ordenadas,
  crear/editar con categoría válida, rechazo de inexistente (`*no existe*`), rechazo de inactiva (`*no está activa*`),
  y `[Theory]` del mapeo legacy.
- **Flutter** `flutter analyze` limpio · `flutter test`: **9/9** (`products_test.dart` + `widget_test.dart`).
- Backend se compila/prueba dentro de `mcr.microsoft.com/dotnet/sdk:8.0` (el SDK local es 3.1).

## 7. Despliegue y entrega

- Push a `main` (commit `4a3f47d`) disparó `.github/workflows/deploy.yml` → **deploy exitoso** (run 27900455257).
  El workflow construye imagen GHCR, hace SSH al servidor, corre migraciones al iniciar y espera healthcheck.
- Producción: `https://allegro.juanariasdev.com` → `/health/ready` = **Healthy**; `GET /api/product-categories` = 401 sin token (existe).
- **APK release** (apunta a prod + Firebase): se compila con
  `flutter build apk --release --dart-define-from-file=config/production.json`
  (`config/production.json` = `AUTH_MODE: firebase`, `API_BASE_URL: https://allegro.juanariasdev.com`).
  Se instaló en el Xiaomi `23028RA60L` y se dejó copia en el Escritorio (`Allegro-4a3f47d.apk`) para el cliente.

## 8. Cómo retomar / comandos útiles

```bash
# Backend (dentro de docker, SDK local es 3.1)
docker run --rm -v "$PWD":/src -w /src/backend mcr.microsoft.com/dotnet/sdk:8.0 dotnet test Allegro.sln

# Flutter
cd mobile && flutter analyze && flutter test

# Recompilar APK release para el cliente
cd mobile && flutter build apk --release --dart-define-from-file=config/production.json
cp build/app/outputs/flutter-apk/app-release.apk "$HOME/Desktop/Allegro-$(git rev-parse --short HEAD).apk"

# Instalar en teléfono físico (Xiaomi requiere "Instalar vía USB" en Opciones de desarrollo)
adb devices -l
adb -s <serial> install -r build/app/outputs/flutter-apk/app-release.apk
```

## 9. Posibles próximos pasos (no solicitados aún)

- Administración de categorías (CRUD) — explícitamente **fuera de alcance** por ahora.
- App web — pendiente, no implementar todavía.
- Si el cliente necesita logs en vivo desde el teléfono: compilar versión **debug** / `flutter run`.
