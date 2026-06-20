/**
 * Clés de persistance liées à l'authentification.
 *
 * Durcissement sécurité (audit E2) :
 * - L'access token n'est JAMAIS persisté : il reste en mémoire (signal) côté
 *   AuthService et disparaît au rechargement de l'onglet (restauré via silent-refresh).
 * - Le refresh token + métadonnées de session sont stockés en `sessionStorage`
 *   (et non plus `localStorage`) : ils sont effacés à la fermeture de l'onglet,
 *   ce qui réduit la fenêtre d'exposition.
 *
 * Durcissement futur recommandé (NE PAS implémenter ici) : déplacer le refresh
 * token dans un cookie HttpOnly/Secure/SameSite=Strict, inaccessible au JS.
 * Nécessite un support API dédié ; le client mobile consomme le refresh par body,
 * donc ce changement ne doit pas casser le contrat API partagé.
 */
export const AUTH_STORAGE = {
  /** Refresh token — sessionStorage uniquement. */
  RefreshToken: 'kenzorf.admin.refreshToken',
  /** Expiration de l'access token (ISO) — sessionStorage. */
  ExpiresAt: 'kenzorf.admin.expiresAt',
  /** Profil utilisateur courant (JSON) — sessionStorage. */
  User: 'kenzorf.admin.user',
} as const;
