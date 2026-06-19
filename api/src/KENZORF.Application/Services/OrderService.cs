using FluentValidation;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Orders;
using KENZORF.Application.Mapping;
using KENZORF.Domain.Entities;
using KENZORF.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>Création de commande (+ initiation paiement), consultation et annulation côté client.</summary>
public sealed class OrderService : IOrderService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IPaymentGateway _gateway;
    private readonly IValidator<CreateOrderRequest> _createValidator;

    public OrderService(
        IAppDbContext db,
        ICurrentUser currentUser,
        IPaymentGateway gateway,
        IValidator<CreateOrderRequest> createValidator)
    {
        _db = db;
        _currentUser = currentUser;
        _gateway = gateway;
        _createValidator = createValidator;
    }

    public async Task<OrderDto> CreateOrderAsync(CreateOrderRequest request, CancellationToken cancellationToken = default)
    {
        await ValidationGuard.EnsureValidAsync(_createValidator, request, cancellationToken);

        var customerId = RequireCustomerId();

        var cart = await _db.Carts
            .Include(c => c.Items)
                .ThenInclude(i => i.ProductVariant)
                    .ThenInclude(v => v.Product)
                        .ThenInclude(p => p.Images)
            .FirstOrDefaultAsync(c => c.CustomerId == customerId, cancellationToken);

        if (cart is null || cart.Items.Count == 0)
        {
            throw new ConflictException(ErrorCodes.CartEmpty);
        }

        // Vérifie le stock disponible avant de figer la commande (fail-closed).
        foreach (var item in cart.Items)
        {
            var variant = item.ProductVariant;
            if (variant is null || !variant.IsActive || variant.Product is null || !variant.Product.IsActive)
            {
                throw new ConflictException(ErrorCodes.ProductVariantNotFound);
            }

            if (item.Quantity > variant.StockQuantity)
            {
                throw new ConflictException(ErrorCodes.OrderInsufficientStock,
                    new Dictionary<string, object?>
                    {
                        ["productVariantId"] = variant.Id,
                        ["available"] = variant.StockQuantity,
                    });
            }
        }

        var address = request.ShippingAddress;
        var order = new Order
        {
            OrderNumber = ReferenceGenerator.OrderNumber(),
            CustomerId = customerId,
            Status = OrderStatus.Pending,
            Currency = Currency.Xof,
            ShippingFullName = address.FullName.Trim(),
            ShippingPhone = address.PhoneNumber.Trim(),
            ShippingLine1 = address.Line1.Trim(),
            ShippingLine2 = address.Line2?.Trim(),
            ShippingCity = address.City.Trim(),
            ShippingRegion = address.Region?.Trim(),
            ShippingCountry = string.IsNullOrWhiteSpace(address.Country) ? "Côte d'Ivoire" : address.Country.Trim(),
            ShippingLandmark = address.Landmark?.Trim(),
            CustomerNote = string.IsNullOrWhiteSpace(request.CustomerNote) ? null : request.CustomerNote.Trim(),
        };

        foreach (var item in cart.Items)
        {
            var variant = item.ProductVariant;
            var product = variant.Product;
            order.Items.Add(new OrderItem
            {
                ProductVariantId = variant.Id,
                ProductName = product.Name,
                VariantLabel = variant.Label,
                Sku = variant.Sku,
                ImageUrl = CatalogMapper.SelectPrimaryImageUrl(product),
                UnitPrice = item.UnitPrice,
                Quantity = item.Quantity,
            });
        }

        order.ShippingFee = ShippingPolicy.ComputeFee(order.Items.Sum(i => i.LineTotal));
        order.Discount = 0m;
        order.Recalculate();

        var payment = new Payment
        {
            OrderId = order.Id,
            Order = order,
            Provider = _gateway.Provider,
            Amount = order.Total,
            Currency = order.Currency,
            Status = PaymentStatus.Pending,
            Reference = ReferenceGenerator.PaymentReference(),
            PaymentMethod = request.PaymentMethod,
        };
        order.Payments.Add(payment);

        _db.Orders.Add(order);
        await _db.SaveChangesAsync(cancellationToken);

        // Initiation paiement (fail-closed : lève PaymentException si la passerelle n'est pas configurée).
        var result = await _gateway.InitiatePaymentAsync(order, payment, request.PaymentMethod, cancellationToken);

        payment.ProviderTransactionId = result.ProviderTransactionId;
        payment.CheckoutUrl = result.CheckoutUrl;
        payment.Status = result.Status;
        payment.UpdatedAt = DateTimeOffset.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        var created = await LoadOrderAsync(order.Id, customerId, cancellationToken);
        return OrderMapper.ToDto(created);
    }

    public async Task<IReadOnlyList<OrderSummaryDto>> GetMyOrdersAsync(CancellationToken cancellationToken = default)
    {
        var customerId = RequireCustomerId();

        var orders = await _db.Orders
            .AsNoTracking()
            .Where(o => o.CustomerId == customerId)
            .Include(o => o.Items)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync(cancellationToken);

        return orders.Select(OrderMapper.ToSummary).ToList();
    }

    public async Task<OrderDto> GetMyOrderAsync(Guid orderId, CancellationToken cancellationToken = default)
    {
        var customerId = RequireCustomerId();
        var order = await LoadOrderAsync(orderId, customerId, cancellationToken);
        return OrderMapper.ToDto(order);
    }

    public async Task<OrderDto> CancelMyOrderAsync(Guid orderId, CancellationToken cancellationToken = default)
    {
        var customerId = RequireCustomerId();

        var order = await _db.Orders
            .Include(o => o.Items)
            .Include(o => o.Payments)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.CustomerId == customerId, cancellationToken);

        if (order is null)
        {
            throw new NotFoundException(ErrorCodes.OrderNotFound);
        }

        if (order.Status != OrderStatus.Pending)
        {
            throw new ConflictException(ErrorCodes.OrderNotCancelable);
        }

        order.Status = OrderStatus.Cancelled;
        order.CancelledAt = DateTimeOffset.UtcNow;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        foreach (var payment in order.Payments.Where(p =>
                     p.Status is PaymentStatus.Pending or PaymentStatus.Initiated))
        {
            payment.Status = PaymentStatus.Cancelled;
            payment.UpdatedAt = DateTimeOffset.UtcNow;
        }

        await _db.SaveChangesAsync(cancellationToken);

        var reloaded = await LoadOrderAsync(orderId, customerId, cancellationToken);
        return OrderMapper.ToDto(reloaded);
    }

    private Guid RequireCustomerId()
    {
        if (_currentUser.CustomerId is null)
        {
            throw new UnauthorizedException(ErrorCodes.Unauthorized);
        }

        return _currentUser.CustomerId.Value;
    }

    private async Task<Order> LoadOrderAsync(Guid orderId, Guid customerId, CancellationToken cancellationToken)
    {
        var order = await _db.Orders
            .AsNoTracking()
            .Include(o => o.Items)
            .Include(o => o.Payments)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.CustomerId == customerId, cancellationToken);

        if (order is null)
        {
            throw new NotFoundException(ErrorCodes.OrderNotFound);
        }

        return order;
    }
}
