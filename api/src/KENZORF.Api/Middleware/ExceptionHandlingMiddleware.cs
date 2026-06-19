using System.Text.Json;
using KENZORF.Api.Errors;
using KENZORF.Application.Common;

namespace KENZORF.Api.Middleware;

/// <summary>
/// Middleware d'exception global : traduit les exceptions applicatives (<see cref="AppException"/>) et
/// toute erreur inattendue vers le format d'erreur du contrat. Aucune stack trace n'est renvoyée.
/// </summary>
public sealed class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException ex)
        {
            await WriteAsync(context, new ApiError
            {
                Code = ex.Code,
                MessageKey = ex.Code,
                Params = ex.Params,
                Status = ex.Status,
                Errors = ex.Errors.Count > 0 ? ex.Errors : null,
            });
        }
        catch (AppException ex)
        {
            await WriteAsync(context, new ApiError
            {
                Code = ex.Code,
                MessageKey = ex.Code,
                Params = ex.Params,
                Status = ex.Status,
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception processing {Method} {Path}.",
                context.Request.Method, context.Request.Path);

            await WriteAsync(context, new ApiError
            {
                Code = ErrorCodes.InternalError,
                MessageKey = ErrorCodes.InternalError,
                Status = StatusCodes.Status500InternalServerError,
            });
        }
    }

    private static async Task WriteAsync(HttpContext context, ApiError error)
    {
        if (context.Response.HasStarted)
        {
            return;
        }

        context.Response.Clear();
        context.Response.StatusCode = error.Status;
        context.Response.ContentType = "application/json";

        var options = new JsonSerializerOptions(JsonSerializerDefaults.Web);
        await context.Response.WriteAsync(JsonSerializer.Serialize(error, options));
    }
}
