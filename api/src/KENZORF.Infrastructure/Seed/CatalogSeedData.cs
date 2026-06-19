using KENZORF.Application.Common;
using KENZORF.Domain.Entities;
using KENZORF.Domain.Enums;

namespace KENZORF.Infrastructure.Seed;

/// <summary>Catalogue de démonstration KENZORF : 10 produits, variantes (tailles/couleurs) et images.</summary>
internal static class CatalogSeedData
{
    private static readonly string[] ApparelSizes = { "S", "M", "L", "XL" };

    public static IReadOnlyList<Product> Build(IReadOnlyDictionary<string, Category> categories)
    {
        var homme = categories["homme"];
        var femme = categories["femme"];
        var unisexe = categories["unisexe"];
        var accessoires = categories["accessoires"];

        var products = new List<Product>
        {
            Apparel(
                "T-shirt Signature KENZORF", "tshirt-signature-kenzorf", homme.Id, Gender.Men,
                "T-shirt en coton bio 220g floqué du logo KENZORF. Coupe droite, col rond renforcé.",
                "T-shirt coton bio, coupe droite.", 15000m, null, true,
                "100% coton biologique", "Lavage 30°C, repassage doux",
                new[] { ("Noir", "#111111"), ("Blanc", "#F5F5F5"), ("Sable", "#D8C3A5") },
                "TSHIRT-SIG", new[] { 22, 35, 28, 14 },
                new[]
                {
                    "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800",
                    "https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800",
                }),

            Apparel(
                "Hoodie Oversize KENZORF", "hoodie-oversize-kenzorf", unisexe.Id, Gender.Unisex,
                "Hoodie oversize molletonné 380g, capuche doublée et poche kangourou. Confort absolu.",
                "Hoodie oversize molletonné premium.", 38000m, 45000m, true,
                "80% coton, 20% polyester", "Lavage 30°C sur l'envers",
                new[] { ("Noir", "#0A0A0A"), ("Gris chiné", "#9CA3AF"), ("Bordeaux", "#6B1F2A") },
                "HOODIE-OVS", new[] { 18, 25, 20, 10 },
                new[]
                {
                    "https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=800",
                    "https://images.unsplash.com/photo-1620799140408-edc6dcb6d633?w=800",
                }),

            Apparel(
                "Veste Bomber KENZORF", "veste-bomber-kenzorf", homme.Id, Gender.Men,
                "Bomber matelassé avec broderie dorsale KENZORF. Doublure satinée, zip métal.",
                "Bomber matelassé, broderie dorsale.", 55000m, null, false,
                "Coque polyester, doublure satin", "Nettoyage à sec recommandé",
                new[] { ("Kaki", "#4B5320"), ("Noir", "#101010") },
                "BOMBER-KZF", new[] { 12, 16, 14, 8 },
                new[]
                {
                    "https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=800",
                    "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800",
                }),

            Apparel(
                "Robe Nappe Wax KENZORF", "robe-nappe-wax-kenzorf", femme.Id, Gender.Women,
                "Robe mi-longue en wax premium, taille cintrée et coupe évasée. Pièce signature femme.",
                "Robe wax mi-longue, taille cintrée.", 42000m, 50000m, true,
                "100% coton wax", "Lavage à la main, séchage à l'ombre",
                new[] { ("Indigo", "#3F4C8C"), ("Terracotta", "#C66B3D") },
                "ROBE-WAX", new[] { 9, 14, 11 },
                new[]
                {
                    "https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=800",
                    "https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800",
                }),

            Apparel(
                "Chemise Lin KENZORF", "chemise-lin-kenzorf", homme.Id, Gender.Men,
                "Chemise en lin léger, idéale climat chaud. Col cubain et boutons nacrés.",
                "Chemise lin col cubain.", 28000m, null, false,
                "100% lin", "Lavage 30°C, repassage humide",
                new[] { ("Blanc cassé", "#EFE9DD"), ("Bleu ciel", "#A7C7E7"), ("Olive", "#708238") },
                "CHEMISE-LIN", new[] { 16, 22, 18, 9 },
                new[]
                {
                    "https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800",
                }),

            Apparel(
                "Jogging Tech KENZORF", "jogging-tech-kenzorf", unisexe.Id, Gender.Unisex,
                "Pantalon de jogging tissu technique, taille élastiquée, bandes latérales réfléchissantes.",
                "Jogging technique, coupe ajustée.", 32000m, null, false,
                "88% polyester recyclé, 12% élasthanne", "Lavage 30°C",
                new[] { ("Noir", "#0C0C0C"), ("Anthracite", "#383838") },
                "JOG-TECH", new[] { 20, 28, 22, 12 },
                new[]
                {
                    "https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=800",
                }),

            Apparel(
                "Crop Top KENZORF", "crop-top-kenzorf", femme.Id, Gender.Women,
                "Crop top côtelé stretch, basique incontournable de la garde-robe KENZORF.",
                "Crop top côtelé stretch.", 12000m, null, false,
                "95% coton, 5% élasthanne", "Lavage 30°C",
                new[] { ("Noir", "#111111"), ("Blanc", "#FAFAFA"), ("Rose poudré", "#E8B7C2") },
                "CROP-KZF", new[] { 24, 30, 18 },
                new[]
                {
                    "https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=800",
                }),

            Apparel(
                "Polo Piqué KENZORF", "polo-pique-kenzorf", homme.Id, Gender.Men,
                "Polo en maille piquée, broderie poitrine discrète. Élégance décontractée.",
                "Polo piqué brodé.", 22000m, 26000m, false,
                "100% coton piqué", "Lavage 40°C",
                new[] { ("Marine", "#1F2A44"), ("Blanc", "#F7F7F7"), ("Vert sapin", "#2C5F2D") },
                "POLO-PIQ", new[] { 18, 24, 20, 11 },
                new[]
                {
                    "https://images.unsplash.com/photo-1625910513399-c9fcf8e8b9c3?w=800",
                }),

            Accessory(
                "Casquette Logo KENZORF", "casquette-logo-kenzorf", accessoires.Id,
                "Casquette 6 panneaux, broderie logo 3D, fermeture réglable. Taille unique.",
                "Casquette brodée, taille unique.", 13000m, null, true,
                new[] { ("Noir", "#0A0A0A"), ("Beige", "#D9C7A3"), ("Bleu marine", "#1B2A4A") },
                "CAP-LOGO", new[] { 40, 35, 30 },
                new[]
                {
                    "https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800",
                }),

            Accessory(
                "Bonnet Côtelé KENZORF", "bonnet-cotele-kenzorf", accessoires.Id,
                "Bonnet maille côtelée avec patch KENZORF. Chaud et confortable, taille unique.",
                "Bonnet côtelé avec patch.", 12000m, null, false,
                new[] { ("Noir", "#101010"), ("Gris", "#8A8A8A"), ("Moutarde", "#D4A017") },
                "BONNET-CT", new[] { 28, 22, 18 },
                new[]
                {
                    "https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=800",
                }),
        };

        return products;
    }

    private static Product Apparel(string name, string slug, Guid categoryId, Gender gender, string description,
        string shortDescription, decimal basePrice, decimal? compareAt, bool featured, string material,
        string care, (string Color, string Hex)[] colors, string skuPrefix, int[] stockPerSize, string[] imageUrls)
    {
        var product = NewProduct(name, slug, categoryId, gender, description, shortDescription, basePrice,
            compareAt, featured, material, care, imageUrls);

        foreach (var (color, hex) in colors)
        {
            for (var i = 0; i < ApparelSizes.Length; i++)
            {
                var size = ApparelSizes[i];
                var stock = i < stockPerSize.Length ? stockPerSize[i] : 5;
                product.Variants.Add(new ProductVariant
                {
                    Sku = $"{skuPrefix}-{Initials(color)}-{size}",
                    Size = size,
                    Color = color,
                    ColorHex = hex,
                    StockQuantity = stock,
                    IsActive = true,
                });
            }
        }

        return product;
    }

    private static Product Accessory(string name, string slug, Guid categoryId, string description,
        string shortDescription, decimal basePrice, decimal? compareAt, bool featured,
        (string Color, string Hex)[] colors, string skuPrefix, int[] stockPerColor, string[] imageUrls)
    {
        var product = NewProduct(name, slug, categoryId, Gender.Unisex, description, shortDescription, basePrice,
            compareAt, featured, "Acrylique / coton", "Lavage à la main", imageUrls);

        for (var i = 0; i < colors.Length; i++)
        {
            var (color, hex) = colors[i];
            var stock = i < stockPerColor.Length ? stockPerColor[i] : 10;
            product.Variants.Add(new ProductVariant
            {
                Sku = $"{skuPrefix}-{Initials(color)}-TU",
                Size = "Taille unique",
                Color = color,
                ColorHex = hex,
                StockQuantity = stock,
                IsActive = true,
            });
        }

        return product;
    }

    private static Product NewProduct(string name, string slug, Guid categoryId, Gender gender, string description,
        string shortDescription, decimal basePrice, decimal? compareAt, bool featured, string material, string care,
        string[] imageUrls)
    {
        var product = new Product
        {
            Name = name,
            Slug = slug,
            CategoryId = categoryId,
            Gender = gender,
            Description = description,
            ShortDescription = shortDescription,
            BasePrice = basePrice,
            CompareAtPrice = compareAt,
            Currency = Currency.Xof,
            Material = material,
            CareInstructions = care,
            IsFeatured = featured,
            IsActive = true,
        };

        for (var i = 0; i < imageUrls.Length; i++)
        {
            product.Images.Add(new ProductImage
            {
                Url = imageUrls[i],
                AltText = name,
                IsPrimary = i == 0,
                DisplayOrder = i,
            });
        }

        return product;
    }

    private static string Initials(string color)
    {
        var letters = color
            .Where(char.IsLetter)
            .Take(3)
            .ToArray();
        return new string(letters).ToUpperInvariant();
    }
}
