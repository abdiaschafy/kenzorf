using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Models;

/// <summary>Formulaire multipart d'upload d'image générique (back-office).</summary>
public sealed class UploadForm
{
    [FromForm(Name = "file")]
    public IFormFile? File { get; set; }
}
