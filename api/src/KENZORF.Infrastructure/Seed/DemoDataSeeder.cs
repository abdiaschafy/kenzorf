using KENZORF.Application.Common;
using KENZORF.Domain.Entities;
using KENZORF.Domain.Enums;
using KENZORF.Infrastructure.Identity;
using KENZORF.Infrastructure.Persistence;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace KENZORF.Infrastructure.Seed;

/// <summary>
/// Amorçage de démonstration KENZORF : ~8 clients, ~30 commandes réparties sur les 7 derniers jours
/// (statuts pondérés), un paiement par commande cohérent avec le statut, et décrément du stock des
/// variantes vendues. Idempotent : ne fait rien si des commandes existent déjà. Doit être invoqué
/// APRÈS <see cref="DbSeeder"/> (s'appuie sur la marque, les catégories et le catalogue de base).
/// </summary>
public static class DemoDataSeeder
{
    /// <summary>Seed fixe pour des tirages reproductibles d'un run à l'autre.</summary>
    private const int RandomSeed = 73519;

    /// <summary>Email du client de base (créé par <see cref="DbSeeder"/>) réutilisé pour quelques commandes.</summary>
    private const string ExistingCustomerEmail = "client@kenzorf.com";

    /// <summary>Statuts dont le paiement est confirmé : seuls ceux-ci décrémentent le stock.</summary>
    private static readonly OrderStatus[] StockConsumingStatuses =
    {
        OrderStatus.Paid, OrderStatus.Processing, OrderStatus.Shipped, OrderStatus.Delivered,
    };

    public static async Task SeedAsync(IServiceProvider services, CancellationToken cancellationToken = default)
    {
        using var scope = services.CreateScope();
        var provider = scope.ServiceProvider;

        var db = provider.GetRequiredService<AppDbContext>();
        var userManager = provider.GetRequiredService<UserManager<ApplicationUser>>();
        var logger = provider.GetRequiredService<ILoggerFactory>().CreateLogger("DemoDataSeeder");

        // Idempotence : si des commandes existent déjà, on considère la démo en place et on ne touche à rien
        // (évite tout double décrément de stock au redémarrage).
        if (await db.Orders.AnyAsync(cancellationToken))
        {
            logger.LogInformation("Demo seed skipped: orders already present.");
            return;
        }

        // Catalogue requis (variantes actives en stock). Si vide, le seed de base n'a pas tourné : on s'abstient.
        var variants = await db.ProductVariants
            .Include(v => v.Product)
            .Where(v => v.IsActive && v.Product.IsActive && v.StockQuantity > 0)
            .ToListAsync(cancellationToken);

        if (variants.Count == 0)
        {
            logger.LogWarning("Demo seed skipped: no active product variants in stock.");
            return;
        }

        var random = new Random(RandomSeed);

        // Pool aléatoire = uniquement les nouveaux clients démo. Le client de base reçoit un nombre
        // restreint de commandes via le chemin réservé (2–3), il ne fait pas partie du tirage aléatoire.
        var customers = await EnsureDemoCustomersAsync(db, userManager, cancellationToken);
        var existingCustomer = await db.Customers
            .FirstOrDefaultAsync(c => c.Email == ExistingCustomerEmail, cancellationToken);

        var (orders, payments) = BuildOrders(customers, existingCustomer, variants, random);

        db.Orders.AddRange(orders);
        db.Payments.AddRange(payments);

        ApplyStockDecrements(orders);

        await db.SaveChangesAsync(cancellationToken);

        LogSummary(logger, orders);
    }

    /// <summary>Crée les ~8 comptes clients démo (ApplicationUser + Customer + adresses) si absents.</summary>
    private static async Task<List<Customer>> EnsureDemoCustomersAsync(
        AppDbContext db, UserManager<ApplicationUser> userManager, CancellationToken cancellationToken)
    {
        var created = new List<Customer>();

        foreach (var seed in DemoSeedData.Customers)
        {
            var existing = await userManager.FindByEmailAsync(seed.Email);
            if (existing is not null)
            {
                var profile = await db.Customers.FirstOrDefaultAsync(c => c.Email == seed.Email, cancellationToken);
                if (profile is not null)
                {
                    created.Add(profile);
                }

                continue;
            }

            var customer = new Customer
            {
                FirstName = seed.FirstName,
                LastName = seed.LastName,
                Email = seed.Email,
                PhoneNumber = seed.PhoneNumber,
            };

            for (var i = 0; i < seed.Addresses.Count; i++)
            {
                var address = seed.Addresses[i];
                customer.Addresses.Add(new Address
                {
                    Label = address.Label,
                    FullName = customer.FullName,
                    PhoneNumber = seed.PhoneNumber,
                    Line1 = address.Line1,
                    City = address.City,
                    Region = address.City,
                    Country = "Côte d'Ivoire",
                    Landmark = address.Landmark,
                    IsDefault = i == 0,
                });
            }

            db.Customers.Add(customer);
            await db.SaveChangesAsync(cancellationToken);

            var user = new ApplicationUser
            {
                UserName = seed.Email,
                Email = seed.Email,
                PhoneNumber = seed.PhoneNumber,
                EmailConfirmed = true,
                CustomerId = customer.Id,
            };

            var result = await userManager.CreateAsync(user, DemoSeedData.Password);
            if (result.Succeeded)
            {
                await userManager.AddToRoleAsync(user, AppRoles.Customer);
            }

            created.Add(customer);
        }

        return created;
    }

    /// <summary>Construit le graphe complet (commandes + lignes + paiements) à partir du plan pondéré.</summary>
    private static (List<Order> Orders, List<Payment> Payments) BuildOrders(
        IReadOnlyList<Customer> customers,
        Customer? existingCustomer,
        IReadOnlyList<ProductVariant> variants,
        Random random)
    {
        var orders = new List<Order>();
        var payments = new List<Payment>();

        var sequence = 0;
        var existingCustomerOrders = 0;
        var failedPaymentEmitted = false;

        foreach (var template in DemoSeedData.OrderPlan)
        {
            sequence++;

            // Réserve 3 commandes au client de base existant (réparties sur des statuts variés).
            Customer customer;
            if (existingCustomer is not null && existingCustomerOrders < 3 && sequence % 9 == 0)
            {
                customer = existingCustomer;
                existingCustomerOrders++;
            }
            else
            {
                customer = customers[random.Next(customers.Count)];
            }

            var address = customer.Addresses.FirstOrDefault();
            var placedAt = ResolvePlacedAt(template);

            var order = new Order
            {
                OrderNumber = $"KZF-2026-{sequence:D4}",
                CustomerId = customer.Id,
                Status = template.Status,
                Currency = Currency.Xof,
                ShippingFullName = customer.FullName,
                ShippingPhone = customer.PhoneNumber ?? "+2250700000000",
                ShippingLine1 = address?.Line1 ?? "Cocody, Abidjan",
                ShippingCity = address?.City ?? "Abidjan",
                ShippingRegion = address?.Region ?? "Abidjan",
                ShippingCountry = "Côte d'Ivoire",
                ShippingLandmark = address?.Landmark,
                CreatedAt = placedAt,
            };

            AddOrderItems(order, variants, template.LineCount, random);

            order.ShippingFee = ShippingPolicy.ComputeFee(order.Items.Sum(i => i.LineTotal));
            order.Discount = 0m;
            order.Recalculate();

            ApplyStatusTimestamps(order, placedAt);

            var payment = BuildPayment(order, placedAt, random, ref failedPaymentEmitted);
            payments.Add(payment);

            orders.Add(order);
        }

        return (orders, payments);
    }

    /// <summary>Ajoute 1–3 lignes issues de vraies variantes (snapshots figés), variantes distinctes.</summary>
    private static void AddOrderItems(Order order, IReadOnlyList<ProductVariant> variants, int lineCount, Random random)
    {
        var count = Math.Clamp(lineCount, 1, 3);
        var picked = new HashSet<Guid>();

        while (order.Items.Count < count && picked.Count < variants.Count)
        {
            var variant = variants[random.Next(variants.Count)];
            if (!picked.Add(variant.Id))
            {
                continue;
            }

            var product = variant.Product;
            var unitPrice = variant.Price ?? product.BasePrice;
            var quantity = random.Next(1, 4); // 1..3

            order.Items.Add(new OrderItem
            {
                ProductVariantId = variant.Id,
                ProductVariant = variant, // instance suivie (déjà chargée) : sert au décrément de stock
                ProductName = product.Name,
                VariantLabel = variant.Label,
                Sku = variant.Sku,
                ImageUrl = product.Images
                    .OrderByDescending(img => img.IsPrimary)
                    .ThenBy(img => img.DisplayOrder)
                    .Select(img => img.Url)
                    .FirstOrDefault(),
                UnitPrice = unitPrice,
                Quantity = quantity,
            });
        }
    }

    /// <summary>Crée un paiement cohérent avec le statut de la commande (un Failed à titre d'exemple).</summary>
    private static Payment BuildPayment(Order order, DateTimeOffset placedAt, Random random, ref bool failedPaymentEmitted)
    {
        var method = DemoSeedData.PaymentMethods[random.Next(DemoSeedData.PaymentMethods.Count)];

        var payment = new Payment
        {
            OrderId = order.Id,
            Order = order,
            Provider = "KPay",
            Amount = order.Total,
            Currency = order.Currency,
            PaymentMethod = method,
            Reference = $"KPY-DEMO-{order.OrderNumber["KZF-2026-".Length..]}",
            CreatedAt = placedAt,
        };

        switch (order.Status)
        {
            case OrderStatus.Paid:
            case OrderStatus.Processing:
            case OrderStatus.Shipped:
            case OrderStatus.Delivered:
                payment.Status = PaymentStatus.Succeeded;
                payment.ProviderTransactionId = $"KPAY-TX-{random.Next(100000, 999999)}";
                payment.CompletedAt = order.PaidAt ?? placedAt.AddMinutes(4);
                payment.UpdatedAt = payment.CompletedAt;
                break;

            case OrderStatus.Refunded:
                payment.Status = PaymentStatus.Refunded;
                payment.ProviderTransactionId = $"KPAY-TX-{random.Next(100000, 999999)}";
                payment.CompletedAt = placedAt.AddMinutes(5);
                payment.UpdatedAt = placedAt.AddDays(1);
                break;

            case OrderStatus.Cancelled:
                payment.Status = PaymentStatus.Cancelled;
                payment.UpdatedAt = order.CancelledAt ?? placedAt.AddMinutes(20);
                break;

            case OrderStatus.Pending:
            default:
                // Un seul exemple d'échec de paiement, le reste reste en attente client (Pending/Initiated).
                if (!failedPaymentEmitted)
                {
                    payment.Status = PaymentStatus.Failed;
                    payment.FailureReason = "payments.declinedByProvider";
                    payment.UpdatedAt = placedAt.AddMinutes(2);
                    failedPaymentEmitted = true;
                }
                else if (random.Next(2) == 0)
                {
                    payment.Status = PaymentStatus.Initiated;
                    payment.ProviderTransactionId = $"KPAY-TX-{random.Next(100000, 999999)}";
                    payment.CheckoutUrl = $"https://kpay.site/checkout/{payment.Reference}";
                    payment.UpdatedAt = placedAt.AddSeconds(30);
                }
                else
                {
                    payment.Status = PaymentStatus.Pending;
                }

                break;
        }

        return payment;
    }

    /// <summary>Renseigne PaidAt/ShippedAt/DeliveredAt/CancelledAt de façon chronologiquement plausible.</summary>
    private static void ApplyStatusTimestamps(Order order, DateTimeOffset placedAt)
    {
        switch (order.Status)
        {
            case OrderStatus.Paid:
                order.PaidAt = placedAt.AddMinutes(4);
                order.UpdatedAt = order.PaidAt;
                break;

            case OrderStatus.Processing:
                order.PaidAt = placedAt.AddMinutes(4);
                order.UpdatedAt = placedAt.AddHours(2);
                break;

            case OrderStatus.Shipped:
                order.PaidAt = placedAt.AddMinutes(4);
                order.ShippedAt = placedAt.AddHours(6);
                order.UpdatedAt = order.ShippedAt;
                break;

            case OrderStatus.Delivered:
                order.PaidAt = placedAt.AddMinutes(4);
                order.ShippedAt = placedAt.AddHours(6);
                order.DeliveredAt = placedAt.AddDays(1).AddHours(3);
                order.UpdatedAt = order.DeliveredAt;
                break;

            case OrderStatus.Refunded:
                order.PaidAt = placedAt.AddMinutes(4);
                order.UpdatedAt = placedAt.AddDays(1);
                break;

            case OrderStatus.Cancelled:
                order.CancelledAt = placedAt.AddMinutes(20);
                order.UpdatedAt = order.CancelledAt;
                break;

            case OrderStatus.Pending:
            default:
                break;
        }
    }

    /// <summary>Décrémente le stock des variantes vendues par les commandes au paiement confirmé.</summary>
    private static void ApplyStockDecrements(IReadOnlyList<Order> orders)
    {
        foreach (var order in orders.Where(o => StockConsumingStatuses.Contains(o.Status)))
        {
            foreach (var item in order.Items.Where(i => i.ProductVariant is not null))
            {
                var variant = item.ProductVariant!;
                variant.StockQuantity = Math.Max(0, variant.StockQuantity - item.Quantity);
                variant.UpdatedAt = DateTimeOffset.UtcNow;
            }
        }
    }

    private static DateTimeOffset ResolvePlacedAt(DemoOrderTemplate template)
    {
        var day = DateTimeOffset.UtcNow.Date.AddDays(-template.DaysAgo);
        return new DateTimeOffset(day.Year, day.Month, day.Day, template.Hour, template.Minute, 0, TimeSpan.Zero);
    }

    private static void LogSummary(ILogger logger, IReadOnlyList<Order> orders)
    {
        var byStatus = orders
            .GroupBy(o => o.Status)
            .OrderBy(g => g.Key)
            .Select(g => $"{g.Key}={g.Count()}");

        logger.LogInformation(
            "Demo seed completed: {OrderCount} orders ({StatusBreakdown}).",
            orders.Count,
            string.Join(", ", byStatus));
    }
}
