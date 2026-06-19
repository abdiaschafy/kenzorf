using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Models;

/// <summary>
/// Formulaire multipart d'ajout d'image produit : soit un fichier (<see cref="File"/>), soit une URL distante.
/// </summary>
public sealed class AdminImageUploadForm
{
    [FromForm(Name = "file")]
    public IFormFile? File { get; set; }

    [FromForm(Name = "url")]
    public string? Url { get; set; }

    [FromForm(Name = "altText")]
    public string? AltText { get; set; }

    [FromForm(Name = "isPrimary")]
    public bool IsPrimary { get; set; }
}
