namespace KENZORF.Application.Contracts;

/// <summary>
/// Transaction de base de données abstraite (sans dépendre de l'implémentation EF). Tant que
/// <see cref="CommitAsync"/> n'a pas été appelé, la libération (<c>DisposeAsync</c>) annule les changements.
/// </summary>
public interface IAppTransaction : IAsyncDisposable
{
    /// <summary>Valide la transaction.</summary>
    Task CommitAsync(CancellationToken cancellationToken = default);
}
