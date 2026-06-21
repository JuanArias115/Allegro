using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Allegro.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class DomeBlocks : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "dome_blocks",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DomeId = table.Column<Guid>(type: "uuid", nullable: false),
                    StartDate = table.Column<DateOnly>(type: "date", nullable: false),
                    EndDate = table.Column<DateOnly>(type: "date", nullable: false),
                    Reason = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_dome_blocks", x => x.Id);
                    table.ForeignKey(
                        name: "FK_dome_blocks_domes_DomeId",
                        column: x => x.DomeId,
                        principalTable: "domes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_dome_blocks_DomeId_StartDate_EndDate",
                table: "dome_blocks",
                columns: new[] { "DomeId", "StartDate", "EndDate" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "dome_blocks");
        }
    }
}
