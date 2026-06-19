using KENZORF.Domain.Enums;

namespace KENZORF.Application.DTOs.Admin;

/// <summary>Changement de statut d'une commande (transitions valides uniquement).</summary>
public sealed record UpdateOrderStatusRequest(
    OrderStatus Status);
