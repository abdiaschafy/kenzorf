namespace KENZORF.Application.DTOs.Common;

/// <summary>Enveloppe de pagination standard : { items, page, pageSize, total, totalPages }.</summary>
public sealed record PagedResult<T>(
    IReadOnlyList<T> Items,
    int Page,
    int PageSize,
    int Total)
{
    public int TotalPages => PageSize <= 0 ? 0 : (int)Math.Ceiling(Total / (double)PageSize);

    public static PagedResult<T> Create(IReadOnlyList<T> items, int page, int pageSize, int total)
        => new(items, page, pageSize, total);
}
