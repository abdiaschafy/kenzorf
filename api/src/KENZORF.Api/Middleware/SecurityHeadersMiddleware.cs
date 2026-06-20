namespace KENZORF.Api.Middleware;

/// <summary>
/// Ajoute des en-têtes de sécurité à chaque réponse : anti-sniffing du type MIME, anti-framing et une CSP
/// basique. S'applique aussi aux fichiers statiques servis (uploads), qui ne doivent jamais être « sniffés ».
/// </summary>
public sealed class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public SecurityHeadersMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var headers = context.Response.Headers;
        headers["X-Content-Type-Options"] = "nosniff";
        headers["X-Frame-Options"] = "DENY";
        headers["Referrer-Policy"] = "strict-origin-when-cross-origin";

        // CSP basique : l'API sert du JSON et des images d'upload ; pas de scripts tiers attendus.
        if (!headers.ContainsKey("Content-Security-Policy"))
        {
            headers["Content-Security-Policy"] =
                "default-src 'self'; img-src 'self' data: https:; object-src 'none'; frame-ancestors 'none'";
        }

        await _next(context);
    }
}
