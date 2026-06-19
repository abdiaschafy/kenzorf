using KENZORF.Application.DTOs.Orders;

namespace KENZORF.Application.Contracts;

/// <summary>Cycle de vie des commandes côté client (création + paiement, consultation, annulation).</summary>
public interface IOrderService
{
    /// <summary>
    /// Crée la commande à partir du panier, initie le paiement KPay et renvoie la commande
    /// (avec <c>payment.checkoutUrl</c>).
    /// </summary>
    Task<OrderDto> CreateOrderAsync(CreateOrderRequest request, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<OrderSummaryDto>> GetMyOrdersAsync(CancellationToken cancellationToken = default);

    Task<OrderDto> GetMyOrderAsync(Guid orderId, CancellationToken cancellationToken = default);

    Task<OrderDto> CancelMyOrderAsync(Guid orderId, CancellationToken cancellationToken = default);
}
