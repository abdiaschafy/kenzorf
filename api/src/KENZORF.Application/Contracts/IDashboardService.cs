using KENZORF.Application.DTOs.Admin;

namespace KENZORF.Application.Contracts;

/// <summary>Agrégats du back-office (chiffre d'affaires, commandes, stock bas).</summary>
public interface IDashboardService
{
    Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default);
}
