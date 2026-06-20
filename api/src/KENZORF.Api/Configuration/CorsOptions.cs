namespace KENZORF.Api.Configuration;

/// <summary>Configuration CORS (section "Cors"). Les origines autorisées sont pilotées par configuration.</summary>
public sealed class CorsOptions
{
    public const string SectionName = "Cors";

    /// <summary>
    /// Origines autorisées (ex. <c>https://admin.kenzorf.com</c>). Par défaut le back-office Angular local.
    /// Jamais d'origine <c>*</c> conjointement aux credentials.
    /// </summary>
    public string[] AllowedOrigins { get; set; } = { "http://localhost:4200" };
}
