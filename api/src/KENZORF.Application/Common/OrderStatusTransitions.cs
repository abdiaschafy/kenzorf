using KENZORF.Domain.Enums;

namespace KENZORF.Application.Common;

/// <summary>Transitions de statut de commande autorisées (back-office).</summary>
public static class OrderStatusTransitions
{
    private static readonly IReadOnlyDictionary<OrderStatus, OrderStatus[]> Allowed =
        new Dictionary<OrderStatus, OrderStatus[]>
        {
            [OrderStatus.Pending] = new[] { OrderStatus.Paid, OrderStatus.Cancelled },
            [OrderStatus.Paid] = new[] { OrderStatus.Processing, OrderStatus.Cancelled, OrderStatus.Refunded },
            [OrderStatus.Processing] = new[] { OrderStatus.Shipped, OrderStatus.Cancelled, OrderStatus.Refunded },
            [OrderStatus.Shipped] = new[] { OrderStatus.Delivered, OrderStatus.Refunded },
            [OrderStatus.Delivered] = new[] { OrderStatus.Refunded },
            [OrderStatus.Cancelled] = Array.Empty<OrderStatus>(),
            [OrderStatus.Refunded] = Array.Empty<OrderStatus>(),
        };

    public static bool CanTransition(OrderStatus from, OrderStatus to)
        => from == to || (Allowed.TryGetValue(from, out var targets) && targets.Contains(to));
}
