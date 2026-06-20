---
name: project-backoffice-auth
description: KENZORF back-office (Angular 22) auth/session security model after the 2026-06 hardening audit — token storage, silent-refresh, logout, nginx headers
metadata:
  type: project
---

KENZORF back-office (`/Users/abdiaschafanglontchi/kenzorf/back-office/`) auth/session security model, set during the 2026-06 front-end hardening audit.

**Why:** an audit flagged token storage (E2) and logout revocation (M5). Mono-tenant, roles Customer/Admin; the back-office is Admin-only.

**How to apply** when touching `AuthService`, `tokenInterceptor`, guards, or `nginx.conf`:
- Access token lives **in memory only** (the `_session` signal) — never written to any storage. `AuthSession.accessToken` is `string | null` (null right after restore, before silent-refresh).
- Refresh token + `expiresAt` + `user` are persisted in **`sessionStorage`** (not localStorage), keys in `core/constants/storage.constants.ts` (no `AccessToken` key).
- **Silent-refresh** runs at startup via `provideAppInitializer(() => inject(AuthService).silentRefresh())` in `app.config.ts`, BEFORE router guards activate. It POSTs `/auth/refresh` with the stored refresh token to restore the in-memory access token; on failure it purges and forces re-login.
- **Logout (M5):** `AuthService.logout()` awaits `/auth/logout` (server revocation) with a short timeout (`LOGOUT_TIMEOUT_MS = 3000`, `catchError`→fail-safe) and purges the local session in a trailing `tap` — i.e. AFTER the response, so the refresh token is still present when the request is built. `/auth/logout` is in `isAuthEndpoint`, so the interceptor does not retry it.
- Future hardening (intentionally NOT implemented): refresh token in an HttpOnly/Secure/SameSite cookie. Blocked on API support; the **mobile client consumes refresh by request body**, so the shared API contract must not change.
- `nginx.conf` carries security headers (`X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy`, a CSP with `script-src 'self'` / `style-src 'self' 'unsafe-inline'` for Angular's inline component styles). nginx does not inherit server-level `add_header` into a `location` that declares its own — the fingerprinted-asset block re-emits the security headers.
- Tests: **Vitest** (`npm test`). i18n parity enforced by `core/services/i18n/i18n-parity.spec.ts` (fr/en must match). Node ≥ 22 required: prefix npm with `export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"`.
