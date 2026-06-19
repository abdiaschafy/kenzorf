using KENZORF.Application.DTOs.Addresses;

namespace KENZORF.Application.DTOs.Orders;

/// <summary>
/// Création d'une commande à partir du panier courant.
/// <c>paymentMethod</c> : "orange_money" | "mtn" | "wave" | "moov" | "card".
/// </summary>
public sealed record CreateOrderRequest(
    AddressRequest ShippingAddress,
    string? CustomerNote,
    string? PaymentMethod);
