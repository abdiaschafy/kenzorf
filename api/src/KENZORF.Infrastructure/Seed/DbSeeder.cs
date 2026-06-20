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
/// Amorçage idempotent de KENZORF : rôles, admin, client démo, catégories et un catalogue de produits
/// (vêtements de la marque) avec variantes, stock et images placeholder. FCFA (XOF), montants entiers.
/// </summary>
public static class DbSeeder
{
    private const string DefaultPassword = "Password123!";
    private const string AdminEmail = "admin@kenzorf.com";
    private const string CustomerEmail = "client@kenzorf.com";

    public static async Task SeedAsync(IServiceProvider services, CancellationToken cancellationToken = default)
    {
        using var scope = services.CreateScope();
        var provider = scope.ServiceProvider;

        var db = provider.GetRequiredService<AppDbContext>();
        var roleManager = provider.GetRequiredService<RoleManager<ApplicationRole>>();
        var userManager = provider.GetRequiredService<UserManager<ApplicationUser>>();
        var logger = provider.GetRequiredService<ILoggerFactory>().CreateLogger("DbSeeder");

        await SeedRolesAsync(roleManager, db);
        await SeedAdminAsync(db, userManager);
        await SeedDemoCustomerAsync(db, userManager);
        await SeedCatalogAsync(db, logger, cancellationToken);
    }

    private static async Task SeedRolesAsync(RoleManager<ApplicationRole> roleManager, AppDbContext db)
    {
        // Auto-réparation : une tentative de déploiement antérieure (ancien comportement ValueGeneratedNever
        // sur Identity) a pu insérer un rôle corrompu (Id = Guid.Empty) avant de planter. On purge ce rôle
        // et ses éventuelles assignations pour repartir d'une base saine, avant de (re)créer les rôles.
        var brokenLinks = await db.UserRoles.Where(ur => ur.RoleId == Guid.Empty).ToListAsync();
        if (brokenLinks.Count > 0)
        {
            db.UserRoles.RemoveRange(brokenLinks);
            await db.SaveChangesAsync();
        }

        var brokenRoles = await db.Roles.Where(r => r.Id == Guid.Empty).ToListAsync();
        if (brokenRoles.Count > 0)
        {
            db.Roles.RemoveRange(brokenRoles);
            await db.SaveChangesAsync();
        }

        foreach (var role in AppRoles.All)
        {
            if (!await roleManager.RoleExistsAsync(role))
            {
                await roleManager.CreateAsync(new ApplicationRole(role));
            }
        }
    }

    private static async Task SeedAdminAsync(AppDbContext db, UserManager<ApplicationUser> userManager)
    {
        var user = await userManager.FindByEmailAsync(AdminEmail);
        if (user is null)
        {
            var customer = await EnsureCustomerProfileAsync(db, AdminEmail, "Admin", "KENZORF", "+2250700000000");
            user = new ApplicationUser
            {
                UserName = AdminEmail,
                Email = AdminEmail,
                EmailConfirmed = true,
                CustomerId = customer.Id,
            };

            var result = await userManager.CreateAsync(user, DefaultPassword);
            if (!result.Succeeded)
            {
                return;
            }
        }

        // Assignation idempotente (répare aussi un compte créé sans rôle lors d'un seed partiel).
        await EnsureRolesAsync(userManager, user, AppRoles.Admin, AppRoles.Customer);
    }

    private static async Task SeedDemoCustomerAsync(AppDbContext db, UserManager<ApplicationUser> userManager)
    {
        var user = await userManager.FindByEmailAsync(CustomerEmail);
        if (user is null)
        {
            var customer = await EnsureCustomerProfileAsync(db, CustomerEmail, "Awa", "Koné", "+2250500000000");
            user = new ApplicationUser
            {
                UserName = CustomerEmail,
                Email = CustomerEmail,
                EmailConfirmed = true,
                CustomerId = customer.Id,
            };

            var result = await userManager.CreateAsync(user, DefaultPassword);
            if (!result.Succeeded)
            {
                return;
            }
        }

        await EnsureRolesAsync(userManager, user, AppRoles.Customer);
    }

    /// <summary>Assigne à un utilisateur les rôles qui lui manquent (idempotent).</summary>
    private static async Task EnsureRolesAsync(UserManager<ApplicationUser> userManager,
        ApplicationUser user, params string[] roles)
    {
        foreach (var role in roles)
        {
            if (!await userManager.IsInRoleAsync(user, role))
            {
                await userManager.AddToRoleAsync(user, role);
            }
        }
    }

    private static async Task<Customer> EnsureCustomerProfileAsync(AppDbContext db, string email,
        string firstName, string lastName, string phone)
    {
        var existing = await db.Customers.FirstOrDefaultAsync(c => c.Email == email);
        if (existing is not null)
        {
            return existing;
        }

        var customer = new Customer
        {
            Email = email,
            FirstName = firstName,
            LastName = lastName,
            PhoneNumber = phone,
        };
        db.Customers.Add(customer);
        await db.SaveChangesAsync();
        return customer;
    }

    private static async Task SeedCatalogAsync(AppDbContext db, ILogger logger, CancellationToken cancellationToken)
    {
        if (await db.Products.AnyAsync(cancellationToken))
        {
            return;
        }

        var categories = await SeedCategoriesAsync(db, cancellationToken);
        var products = CatalogSeedData.Build(categories);

        db.Products.AddRange(products);
        await db.SaveChangesAsync(cancellationToken);

        logger.LogInformation("Seeded {CategoryCount} categories and {ProductCount} products.",
            categories.Count, products.Count);
    }

    private static async Task<IReadOnlyDictionary<string, Category>> SeedCategoriesAsync(AppDbContext db,
        CancellationToken cancellationToken)
    {
        var existing = await db.Categories.ToListAsync(cancellationToken);
        var bySlug = existing.ToDictionary(c => c.Slug, c => c);

        var seeds = new (string Name, string Slug, string Description, int Order)[]
        {
            ("Homme", "homme", "Vêtements KENZORF pour homme", 1),
            ("Femme", "femme", "Vêtements KENZORF pour femme", 2),
            ("Unisexe", "unisexe", "Pièces unisexes KENZORF", 3),
            ("Accessoires", "accessoires", "Casquettes, bonnets et accessoires KENZORF", 4),
        };

        foreach (var seed in seeds)
        {
            if (bySlug.ContainsKey(seed.Slug))
            {
                continue;
            }

            var category = new Category
            {
                Name = seed.Name,
                Slug = seed.Slug,
                Description = seed.Description,
                DisplayOrder = seed.Order,
                IsActive = true,
            };
            db.Categories.Add(category);
            bySlug[seed.Slug] = category;
        }

        await db.SaveChangesAsync(cancellationToken);
        return bySlug;
    }
}
