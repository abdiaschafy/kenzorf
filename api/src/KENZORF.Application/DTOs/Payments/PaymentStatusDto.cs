using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Payments;

/// <summary>Résultat du polling de statut d'un paiement.</summary>
public sealed record PaymentStatusDto(
    PaymentStatus Status,
    Guid OrderId,
    OrderStatus OrderStatus);
