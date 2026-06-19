using KENZORF.Application.Contracts;
using KENZORF.Application.DTOs.Payments;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace KENZORF.Api.Controllers;

/// <summary>Paiement : polling de statut (client) et webhook KPay (public, signature vérifiée).</summary>
[ApiController]
[Route("api/payments")]
public sealed class PaymentsController : ControllerBase
{
    private const string SignatureHeader = "X-KPay-Signature";

    private readonly IPaymentService _payments;

    public PaymentsController(IPaymentService payments)
    {
        _payments = payments;
    }

    [HttpGet("{reference}/status")]
    [Authorize]
    [ProducesResponseType(typeof(PaymentStatusDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PaymentStatusDto>> GetStatus(string reference, CancellationToken cancellationToken)
        => Ok(await _payments.GetStatusAsync(reference, cancellationToken));

    [HttpPost("webhook")]
    [AllowAnonymous]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Webhook(CancellationToken cancellationToken)
    {
        Request.EnableBuffering();
        using var reader = new StreamReader(Request.Body, leaveOpen: true);
        var rawBody = await reader.ReadToEndAsync(cancellationToken);
        Request.Body.Position = 0;

        var signature = Request.Headers.TryGetValue(SignatureHeader, out var value)
            ? value.ToString()
            : null;

        await _payments.HandleWebhookAsync(new PaymentWebhookRequest(rawBody, signature), cancellationToken);
        return Ok();
    }
}
