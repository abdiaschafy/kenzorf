namespace KENZORF.Infrastructure.Auth;

/// <summary>Configuration JWT (section "Jwt"). Le secret HMAC doit faire au moins 32 caractères.</summary>
public sealed class JwtOptions
{
    public const string SectionName = "Jwt";

    public string Issuer { get; set; } = "kenzorf";
    public string Audience { get; set; } = "kenzorf";
    public string Key { get; set; } = string.Empty;
    public int AccessMinutes { get; set; } = 15;
    public int RefreshDays { get; set; } = 14;
}
