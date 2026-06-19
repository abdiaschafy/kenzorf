using KENZORF.Application.DTOs.Payments;
using KENZORF.Domain.Entities;

namespace KENZORF.Application.Mapping;

/// <summary>Projections Domain → DTO pour les paiements.</summary>
public static class PaymentMapper
{
    public static PaymentDto ToDto(Payment payment)
        => new(
            payment.Reference,
            payment.Provider,
            payment.Status,
            payment.Amount,
            payment.Currency,
            payment.PaymentMethod,
            payment.CheckoutUrl);
}
