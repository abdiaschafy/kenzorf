namespace KENZORF.Application.DTOs.Common;

/// <summary>Paramètres de pagination bornés. Page ≥ 1, PageSize entre 1 et 100.</summary>
public sealed record PaginationQuery
{
    private const int DefaultPageSize = 20;
    private const int MaxPageSize = 100;

    private int _page = 1;
    private int _pageSize = DefaultPageSize;

    public int Page
    {
        get => _page;
        init => _page = value < 1 ? 1 : value;
    }

    public int PageSize
    {
        get => _pageSize;
        init => _pageSize = value < 1 ? DefaultPageSize : (value > MaxPageSize ? MaxPageSize : value);
    }

    public int Skip => (Page - 1) * PageSize;
}
