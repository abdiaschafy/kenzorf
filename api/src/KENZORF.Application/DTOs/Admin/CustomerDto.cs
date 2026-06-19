namespace KENZORF.Application.DTOs.Admin;

/// <summary>Client exposé au back-office (liste clients).</summary>
public sealed record CustomerDto(
    Guid Id,
    string FirstName,
    string LastName,
    string Email,
    string? PhoneNumber,
    int OrderCount,
    decimal TotalSpent,
    string Currency,
    DateTimeOffset CreatedAt);
