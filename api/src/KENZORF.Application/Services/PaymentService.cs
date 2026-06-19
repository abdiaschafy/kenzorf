using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Payments;
using KENZORF.Domain.Entities;
using KENZORF.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace KENZORF.Application.Services;

/// <summary>Polling de statut et traitement idempotent du webhook KPay.</summary>
public sealed class PaymentService : IPaymentService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IPaymentGateway _gateway;

    public PaymentService(IAppDbContext db, ICurrentUser currentUser, IPaymentGateway gateway)
    {
        _db = db;
        _currentUser = currentUser;
        _gateway = gateway;
    }

    public async Task<PaymentStatusDto> GetStatusAsync(string reference, CancellationToken cancellationToken = default)
    {
        if (_currentUser.CustomerId is null)
        {
            throw new UnauthorizedException(ErrorCodes.Unauthorized);
        }

        var normalized = (reference ?? string.Empty).Trim();

        var payment = await _db.Payments
            .AsNoTracking()
            .Include(p => p.Order)
            .FirstOrDefaultAsync(p => p.Reference == normalized, cancellationToken);

        if (payment is null || payment.Order is null)
        {
            throw new NotFoundException(ErrorCodes.PaymentNotFound);
        }

        // Un client ne consulte que ses propres paiements (fail-closed).
        if (payment.Order.CustomerId != _currentUser.CustomerId.Value)
        {
            throw new NotFoundException(ErrorCodes.PaymentNotFound);
        }

        return new PaymentStatusDto(payment.Status, payment.OrderId, payment.Order.Status);
    }

    public async Task HandleWebhookAsync(PaymentWebhookRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _gateway.HandleWebhookAsync(request, cancellationToken);
        if (result is null)
        {
            throw new PaymentException(ErrorCodes.PaymentInvalidSignature);
        }

        var payment = await _db.Payments
            .Include(p => p.Order)
                .ThenInclude(o => o.Items)
            .FirstOrDefaultAsync(p => p.Reference == result.Reference, cancellationToken);

        if (payment is null || payment.Order is null)
        {
            // Référence inconnue : on acquitte sans rien faire (évite les rejeux infinis du PSP).
            return;
        }

        // Idempotence : si le paiement est déjà dans un état final, ne rien refaire.
        if (payment.Status is PaymentStatus.Succeeded or PaymentStatus.Failed or PaymentStatus.Refunded)
        {
            return;
        }

        payment.ProviderTransactionId ??= result.ProviderTransactionId;
        payment.RawPayload = result.RawPayload;
        payment.Status = result.Status;
        payment.UpdatedAt = DateTimeOffset.UtcNow;

        if (result.Status == PaymentStatus.Succeeded)
        {
            payment.CompletedAt = DateTimeOffset.UtcNow;
            await ApplySuccessAsync(payment.Order, cancellationToken);
        }
        else if (result.Status == PaymentStatus.Failed)
        {
            payment.FailureReason = result.FailureReason;
        }

        await _db.SaveChangesAsync(cancellationToken);
    }

    private async Task ApplySuccessAsync(Order order, CancellationToken cancellationToken)
    {
        // N'avancer la commande que depuis Pending (idempotent côté commande également).
        if (order.Status != OrderStatus.Pending)
        {
            return;
        }

        order.Status = OrderStatus.Paid;
        order.PaidAt = DateTimeOffset.UtcNow;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        // Décrément du stock des variantes commandées.
        var variantIds = order.Items
            .Where(i => i.ProductVariantId.HasValue)
            .Select(i => i.ProductVariantId!.Value)
            .Distinct()
            .ToList();

        if (variantIds.Count > 0)
        {
            var variants = await _db.ProductVariants
                .Where(v => variantIds.Contains(v.Id))
                .ToListAsync(cancellationToken);

            foreach (var item in order.Items.Where(i => i.ProductVariantId.HasValue))
            {
                var variant = variants.FirstOrDefault(v => v.Id == item.ProductVariantId!.Value);
                if (variant is null)
                {
                    continue;
                }

                variant.StockQuantity = Math.Max(0, variant.StockQuantity - item.Quantity);
                variant.UpdatedAt = DateTimeOffset.UtcNow;
            }
        }

        // Vidage du panier du client.
        var cart = await _db.Carts
            .Include(c => c.Items)
            .FirstOrDefaultAsync(c => c.CustomerId == order.CustomerId, cancellationToken);

        if (cart is not null && cart.Items.Count > 0)
        {
            _db.CartItems.RemoveRange(cart.Items);
            cart.UpdatedAt = DateTimeOffset.UtcNow;
        }
    }
}
