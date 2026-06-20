using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace KENZORF.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddOrderAdminNoteAndStockCheck : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "AdminNote",
                table: "orders",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_product_variants_StockQuantity",
                table: "product_variants",
                sql: "\"StockQuantity\" >= 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_product_variants_StockQuantity",
                table: "product_variants");

            migrationBuilder.DropColumn(
                name: "AdminNote",
                table: "orders");
        }
    }
}
