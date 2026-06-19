namespace KENZORF.Application.DTOs.Admin;

/// <summary>Variante en stock bas, remontée sur le dashboard.</summary>
public sealed record LowStockVariantDto(
    Guid VariantId,
    Guid ProductId,
    string ProductName,
    string Sku,
    string VariantLabel,
    int StockQuantity);
