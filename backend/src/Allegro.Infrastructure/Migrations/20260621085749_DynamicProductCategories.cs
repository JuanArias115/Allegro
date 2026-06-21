using System;
using System.Linq;
using Allegro.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Allegro.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DynamicProductCategories : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1) Tabla de categorías.
            migrationBuilder.CreateTable(
                name: "product_categories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    DisplayOrder = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_product_categories", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_product_categories_DisplayOrder",
                table: "product_categories",
                column: "DisplayOrder");

            // 2) Insertar las cuatro categorías iniciales (UUIDs conocidos).
            var initial = ProductCategorySeedData.Initial;
            var rows = new object[initial.Count, 4];
            for (var i = 0; i < initial.Count; i++)
            {
                rows[i, 0] = initial[i].Id;
                rows[i, 1] = initial[i].Name;
                rows[i, 2] = initial[i].Order;
                rows[i, 3] = true;
            }
            migrationBuilder.InsertData(
                table: "product_categories",
                columns: new[] { "Id", "Name", "DisplayOrder", "IsActive" },
                values: rows);

            // 3) Columna nueva, temporalmente NULLABLE para poder migrar datos.
            migrationBuilder.AddColumn<Guid>(
                name: "ProductCategoryId",
                table: "products",
                type: "uuid",
                nullable: true);

            // 4) Migrar los productos existentes según el antiguo enum y su nombre.
            //    0 -> Bebidas, 2 -> Servicios; nombres de la lista -> Snacks; resto -> Menú.
            var snackList = string.Join(", ",
                ProductCategorySeedData.SnackNames.Select(s => "'" + s.Trim().ToLowerInvariant().Replace("'", "''") + "'"));
            migrationBuilder.Sql($@"
UPDATE products SET ""ProductCategoryId"" = (CASE
    WHEN ""Category"" = 0 THEN '{ProductCategorySeedData.Bebidas}'
    WHEN ""Category"" = 2 THEN '{ProductCategorySeedData.Servicios}'
    WHEN LOWER(TRIM(""Name"")) IN ({snackList}) THEN '{ProductCategorySeedData.Snacks}'
    ELSE '{ProductCategorySeedData.Menu}'
END)::uuid;");

            // 5) Ya migrados los datos, la columna pasa a ser OBLIGATORIA.
            migrationBuilder.AlterColumn<Guid>(
                name: "ProductCategoryId",
                table: "products",
                type: "uuid",
                nullable: false,
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            // 6) Índice + clave foránea.
            migrationBuilder.CreateIndex(
                name: "IX_products_ProductCategoryId",
                table: "products",
                column: "ProductCategoryId");

            migrationBuilder.AddForeignKey(
                name: "FK_products_product_categories_ProductCategoryId",
                table: "products",
                column: "ProductCategoryId",
                principalTable: "product_categories",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            // 7) Solo ahora, eliminar la columna del enum anterior.
            migrationBuilder.DropIndex(
                name: "IX_products_Category",
                table: "products");

            migrationBuilder.DropColumn(
                name: "Category",
                table: "products");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Restaurar la columna enum (temporalmente nullable) y mapear de vuelta.
            migrationBuilder.AddColumn<int>(
                name: "Category",
                table: "products",
                type: "integer",
                nullable: true);

            migrationBuilder.Sql($@"
UPDATE products SET ""Category"" = CASE
    WHEN ""ProductCategoryId"" = '{ProductCategorySeedData.Bebidas}'::uuid THEN 0
    WHEN ""ProductCategoryId"" = '{ProductCategorySeedData.Servicios}'::uuid THEN 2
    ELSE 1
END;");

            migrationBuilder.AlterColumn<int>(
                name: "Category",
                table: "products",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_products_Category",
                table: "products",
                column: "Category");

            migrationBuilder.DropForeignKey(
                name: "FK_products_product_categories_ProductCategoryId",
                table: "products");

            migrationBuilder.DropIndex(
                name: "IX_products_ProductCategoryId",
                table: "products");

            migrationBuilder.DropColumn(
                name: "ProductCategoryId",
                table: "products");

            migrationBuilder.DropTable(
                name: "product_categories");
        }
    }
}
