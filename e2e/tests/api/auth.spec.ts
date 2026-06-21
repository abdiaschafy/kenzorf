import { test, expect } from '@playwright/test';
import { ACCOUNTS } from '../../support/constants';
import { login, loginAdmin, registerFreshCustomer } from '../../support/api';

test.describe('API · Auth', () => {
  test('register crée un client (role Customer) et renvoie un couple de jetons', async ({ request }) => {
    const { auth } = await registerFreshCustomer(request);
    expect(auth.accessToken).toBeTruthy();
    expect(auth.refreshToken).toBeTruthy();
    expect(auth.expiresAt).toBeTruthy();
    expect(auth.user.role).toBe('Customer');
  });

  test('login admin renvoie role Admin', async ({ request }) => {
    const auth = await loginAdmin(request);
    expect(auth.user.email).toBe(ACCOUNTS.admin.email);
    expect(auth.user.role).toBe('Admin');
  });

  test('login client renvoie role Customer', async ({ request }) => {
    const auth = await login(request, ACCOUNTS.customer.email, ACCOUNTS.customer.password);
    expect(auth.user.role).toBe('Customer');
  });

  test('mauvais mot de passe → 401', async ({ request }) => {
    const res = await request.post('/api/auth/login', {
      data: { email: ACCOUNTS.admin.email, password: 'WrongPassword!' },
    });
    expect(res.status()).toBe(401);
  });

  test('GET /me sans token → 401', async ({ request }) => {
    const res = await request.get('/api/auth/me');
    expect(res.status()).toBe(401);
  });

  test('GET /me avec token → profil courant', async ({ request }) => {
    const auth = await loginAdmin(request);
    const res = await request.get('/api/auth/me', {
      headers: { Authorization: `Bearer ${auth.accessToken}` },
    });
    expect(res.status()).toBe(200);
    const me = await res.json();
    expect(me.email).toBe(ACCOUNTS.admin.email);
    expect(me.role).toBe('Admin');
  });

  test('refresh effectue une rotation : nouveau couple valide, ancien refresh révoqué', async ({ request }) => {
    const { auth } = await registerFreshCustomer(request);

    const refreshRes = await request.post('/api/auth/refresh', {
      data: { refreshToken: auth.refreshToken },
    });
    expect(refreshRes.status()).toBe(200);
    const rotated = await refreshRes.json();
    expect(rotated.accessToken).toBeTruthy();
    expect(rotated.refreshToken).toBeTruthy();
    // Le nouveau refresh token doit différer de l'ancien (rotation).
    expect(rotated.refreshToken).not.toBe(auth.refreshToken);

    // Le NOUVEAU refresh token est valide (on le vérifie AVANT tout rejeu de l'ancien).
    const again = await request.post('/api/auth/refresh', {
      data: { refreshToken: rotated.refreshToken },
    });
    expect(again.status(), 'le nouveau refresh token doit fonctionner').toBe(200);

    // Rejouer l'ANCIEN refresh token (déjà tourné) doit échouer.
    const reuse = await request.post('/api/auth/refresh', {
      data: { refreshToken: auth.refreshToken },
    });
    expect(reuse.status(), 'ancien refresh token rejoué doit être refusé').toBe(401);
  });

  test('reuse-detection : rejouer un refresh token déjà tourné révoque toute la chaîne', async ({ request }) => {
    const { auth } = await registerFreshCustomer(request);

    // Rotation : old → rotated.
    const rotated = await (
      await request.post('/api/auth/refresh', { data: { refreshToken: auth.refreshToken } })
    ).json();

    // Rejeu de l'ANCIEN (token volé) → 401.
    const reuse = await request.post('/api/auth/refresh', {
      data: { refreshToken: auth.refreshToken },
    });
    expect(reuse.status()).toBe(401);

    // Défense OAuth : la détection de rejeu invalide aussi le token descendant légitime.
    const descendant = await request.post('/api/auth/refresh', {
      data: { refreshToken: rotated.refreshToken },
    });
    expect(
      descendant.status(),
      'après détection de rejeu, le token descendant est aussi révoqué',
    ).toBe(401);
  });

  test('logout révoque le refresh token', async ({ request }) => {
    const { auth } = await registerFreshCustomer(request);

    const logoutRes = await request.post('/api/auth/logout', {
      data: { refreshToken: auth.refreshToken },
    });
    expect(logoutRes.status()).toBe(204);

    const afterLogout = await request.post('/api/auth/refresh', {
      data: { refreshToken: auth.refreshToken },
    });
    expect(afterLogout.status(), 'refresh après logout doit être refusé').toBe(401);
  });

  test('register avec valeurs invalides (champs présents) → 422 au format contrat', async ({ request }) => {
    // Tous les champs requis présents mais invalides → passe par FluentValidation.
    const res = await request.post('/api/auth/register', {
      data: { email: 'not-an-email', password: 'x', firstName: 'A', lastName: 'B' },
    });
    expect(res.status()).toBe(422);
    const body = await res.json();
    // Contrat §3 respecté ici.
    expect(body, JSON.stringify(body)).toHaveProperty('code');
    expect(body).toHaveProperty('messageKey');
    expect(body).not.toHaveProperty('traceId');
  });

  /**
   * BUG (rouge volontaire) — voir rapport « Format d'erreur non conforme sur champs manquants ».
   * Quand des champs REQUIS du modèle sont absents, la validation automatique d'ASP.NET
   * ([ApiController]) renvoie le ProblemDetails par défaut { type, title, status:400, errors, traceId },
   * ce qui viole le contrat §3 ({ code, messageKey, params, status }) et fuite un traceId.
   * Attendu : 422 au format standard, comme pour les valeurs présentes-mais-invalides.
   */
  test('register avec champs requis manquants → DEVRAIT renvoyer le format d\'erreur contrat', async ({
    request,
  }) => {
    const res = await request.post('/api/auth/register', {
      data: { email: 'x@y.z', password: 'Password123!' }, // firstName/lastName manquants
    });
    const body = await res.json();
    expect(res.status(), `corps: ${JSON.stringify(body)}`).toBe(422);
    expect(body, 'format contrat { code, messageKey, params, status }').toHaveProperty('code');
    expect(body).toHaveProperty('messageKey');
    expect(body, 'ne doit pas fuiter de traceId interne').not.toHaveProperty('traceId');
  });
});
