using KENZORF.Application.DTOs.Auth;

namespace KENZORF.Application.Contracts;

/// <summary>Orchestration de l'authentification : inscription, connexion, rotation, déconnexion, profil.</summary>
public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> RefreshAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default);
    Task LogoutAsync(LogoutRequest request, CancellationToken cancellationToken = default);
    Task<UserDto> GetCurrentUserAsync(CancellationToken cancellationToken = default);
}
