using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Payments;

/// <summary>Transaction de paiement exposée au client (référence, statut, lien de checkout).</summary>
public sealed record PaymentDto(
    string Reference,
    string Provider,
    PaymentStatus Status,
    decimal Amount,
    string Currency,
    string? PaymentMethod,
    string? CheckoutUrl);
