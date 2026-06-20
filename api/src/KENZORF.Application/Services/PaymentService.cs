using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Payments;
using KENZORF.Domain.Entities;
using KENZORF.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace KENZORF.Application.Services;

/// <summary>Polling de statut et traitement idempotent du webhook KPay.</summary>
public sealed class PaymentService : IPaymentService
{
    private static readonly PaymentStatus[] FinalStatuses =
    {
        PaymentStatus.Succeeded, PaymentStatus.Failed, PaymentStatus.Refunded,
    };

    private readonly IAppDbContext _db;
    private readonly ICurrentUser _currentUser;
    private readonly IPaymentGateway _gateway;
    private readonly ILogger<PaymentService> _logger;

    public PaymentService(IAppDbContext db, ICurrentUser currentUser, IPaymentGateway gateway,
        ILogger<PaymentService> logger)
    {
        _db = db;
        _currentUser = currentUser;
        _gateway = gateway;
        _logger = logger;
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

        // Tout le traitement (transition d'état + effets) est atomique : sur des callbacks concurrents,
        // un seul réussit la transition non-final -> final et applique les effets exactement une fois.
        await using var transaction = await _db.BeginTransactionAsync(cancellationToken);

        // Transition d'état conditionnelle au niveau base : la ligne paiement ne bascule que si elle n'est
        // pas déjà dans un état final. ExecuteUpdateAsync renvoie le nombre de lignes affectées : 1 = c'est
        // CE callback qui a effectué la transition (on applique les effets) ; 0 = déjà traité ou inconnu.
        var affected = await _db.Payments
            .Where(p => p.Reference == result.Reference && !FinalStatuses.Contains(p.Status))
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(p => p.Status, result.Status)
                .SetProperty(p => p.ProviderTransactionId,
                    p => p.ProviderTransactionId ?? result.ProviderTransactionId)
                .SetProperty(p => p.RawPayload, result.RawPayload)
                .SetProperty(p => p.FailureReason,
                    p => result.Status == PaymentStatus.Failed ? result.FailureReason : p.FailureReason)
                .SetProperty(p => p.CompletedAt,
                    p => result.Status == PaymentStatus.Succeeded ? DateTimeOffset.UtcNow : p.CompletedAt)
                .SetProperty(p => p.UpdatedAt, DateTimeOffset.UtcNow),
                cancellationToken);

        if (affected == 0)
        {
            // Référence inconnue OU paiement déjà finalisé par un autre callback : rien à faire (idempotent).
            await transaction.CommitAsync(cancellationToken);
            return;
        }

        if (result.Status == PaymentStatus.Succeeded)
        {
            await ApplySuccessAsync(result.Reference, cancellationToken);
        }

        await _db.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    /// <summary>
    /// Effets d'un paiement réussi (dans la transaction du webhook) : passage de la commande à Paid,
    /// décrément atomique conditionnel du stock, vidage du panier. Idempotent côté commande (n'agit que
    /// depuis Pending) et sûr face aux ruptures (le décrément ne descend jamais sous zéro).
    /// </summary>
    private async Task ApplySuccessAsync(string reference, CancellationToken cancellationToken)
    {
        var order = await _db.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Payments.Any(p => p.Reference == reference), cancellationToken);

        if (order is null)
        {
            return;
        }

        // N'avancer la commande que depuis Pending (idempotent côté commande également).
        if (order.Status != OrderStatus.Pending)
        {
            return;
        }

        order.Status = OrderStatus.Paid;
        order.PaidAt = DateTimeOffset.UtcNow;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        // Décrément atomique conditionnel du stock, ligne par ligne : UPDATE ... WHERE StockQuantity >= q.
        // Si 0 ligne affectée -> stock insuffisant (rupture). On NE clampe PAS silencieusement : la
        // commande est marquée pour traitement manuel et l'événement est journalisé.
        var shortages = new List<Guid>();

        foreach (var item in order.Items.Where(i => i.ProductVariantId.HasValue))
        {
            var variantId = item.ProductVariantId!.Value;
            var quantity = item.Quantity;

            var decremented = await _db.ProductVariants
                .Where(v => v.Id == variantId && v.StockQuantity >= quantity)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(v => v.StockQuantity, v => v.StockQuantity - quantity)
                    .SetProperty(v => v.UpdatedAt, DateTimeOffset.UtcNow),
                    cancellationToken);

            if (decremented == 0)
            {
                shortages.Add(variantId);
            }
        }

        if (shortages.Count > 0)
        {
            var note = $"[{DateTimeOffset.UtcNow:O}] Stock insuffisant au paiement pour les variantes : " +
                       $"{string.Join(", ", shortages)}. Traitement manuel requis.";
            order.AdminNote = string.IsNullOrWhiteSpace(order.AdminNote)
                ? note
                : $"{order.AdminNote}\n{note}";

            _logger.LogWarning(
                "Paiement {Reference} : rupture de stock sur la commande {OrderNumber} pour {Count} variante(s) " +
                "({VariantIds}). Commande marquée pour traitement manuel.",
                reference, order.OrderNumber, shortages.Count, string.Join(", ", shortages));
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
