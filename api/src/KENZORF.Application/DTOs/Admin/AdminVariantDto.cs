namespace KENZORF.Application.DTOs.Admin;

/// <summary>Variante exposée au back-office (inclut l'état actif/inactif).</summary>
public sealed record AdminVariantDto(
    Guid Id,
    string Sku,
    string Size,
    string Color,
    string? ColorHex,
    decimal? Price,
    decimal EffectivePrice,
    int StockQuantity,
    bool IsActive);
