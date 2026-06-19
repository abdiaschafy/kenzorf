using KENZORF.Api.Models;
using KENZORF.Application.Common;
using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Admin;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers.Admin;

/// <summary>Back-office : upload d'images génériques.</summary>
[ApiController]
[Route("api/admin/uploads")]
[Authorize(Roles = AppRoles.Admin)]
public sealed class AdminUploadsController : ControllerBase
{
    private readonly IImageUploadService _uploads;

    public AdminUploadsController(IImageUploadService uploads)
    {
        _uploads = uploads;
    }

    [HttpPost]
    [ProducesResponseType(typeof(UploadResultDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status422UnprocessableEntity)]
    [RequestSizeLimit(10 * 1024 * 1024)]
    public async Task<ActionResult<UploadResultDto>> Upload([FromForm] UploadForm form,
        CancellationToken cancellationToken)
    {
        if (form.File is null || form.File.Length == 0)
        {
            throw new ValidationException(ErrorCodes.UploadInvalidFile);
        }

        await using var stream = form.File.OpenReadStream();
        var result = await _uploads.UploadAsync(stream, form.File.FileName, form.File.ContentType, cancellationToken);
        return Ok(result);
    }
}
