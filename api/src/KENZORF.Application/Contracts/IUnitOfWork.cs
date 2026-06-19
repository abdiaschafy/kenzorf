namespace KENZORF.Application.Contracts;

/// <summary>Validation transactionnelle des changements (abstraction du DbContext).</summary>
public interface IUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
