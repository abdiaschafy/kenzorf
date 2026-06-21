# KENZORF — Suite E2E Playwright

Tests end-to-end couvrant **le back-office Angular (UI)** et **l'API .NET (request context)**,
exécutés contre une **stack locale isolée** (jamais la prod, jamais la DB de démo).

## Architecture de la stack de test (isolée)

| Composant      | Port  | Détail                                                                 |
| -------------- | ----- | --------------------------------------------------------------------- |
| PostgreSQL     | 5433  | conteneur `kenzorf-pg`, base **dédiée `kenzorf_e2e`** (créée fraîche)  |
| API .NET       | 8090  | `Development` (seed base + démo, `FakePaymentGateway`), CORS pour 4400 |
| Back-office    | 4400  | `ng serve --configuration e2e` → `apiUrl = http://localhost:8090/api`  |

> ⚠️ Le port **8080** et la base `kenzorf` sont occupés par la stack de démonstration
> (`docker compose`). La suite E2E ne les touche pas : elle tourne sur 8090 / `kenzorf_e2e` / 4400.

Le port API/UI est surchargeable par variables d'environnement (`E2E_API_URL`, `E2E_BASE_URL`).

## Prérequis

- Node ≥ 22 : `export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"`
- .NET 9 SDK + `dotnet-ef` (l'API auto-migre au boot)
- Conteneur Postgres `kenzorf-pg` en écoute sur `localhost:5433` (kenzorf/kenzorf)

## 1. Démarrer la stack locale

```bash
# a) Base fraîche (autocommit, hors transaction)
docker exec kenzorf-pg psql -U kenzorf -d kenzorf -c "DROP DATABASE IF EXISTS kenzorf_e2e WITH (FORCE);"
docker exec kenzorf-pg psql -U kenzorf -d kenzorf -c "CREATE DATABASE kenzorf_e2e OWNER kenzorf;"

# b) API E2E sur 8090 (seed base+démo, FakePaymentGateway, CORS pour 4400)
cd api
ConnectionStrings__Default="Host=localhost;Port=5433;Database=kenzorf_e2e;Username=kenzorf;Password=kenzorf" \
ASPNETCORE_ENVIRONMENT=Development ASPNETCORE_URLS="http://localhost:8090" Seed__Demo=true \
Cors__AllowedOrigins__0="http://localhost:4400" Cors__AllowedOrigins__1="http://127.0.0.1:4400" \
Cors__AllowedOrigins__2="http://localhost:4200" \
nohup dotnet run --project src/KENZORF.Api --no-launch-profile >/tmp/e2e-api.log 2>&1 &
# attendre : curl http://localhost:8090/api/categories  → 200

# c) Back-office sur 4400 (env e2e → API 8090)
cd back-office && npm install
nohup npx ng serve --configuration e2e --port 4400 --host 127.0.0.1 >/tmp/e2e-front.log 2>&1 &
# attendre : http://localhost:4400  → 200
```

## 2. Installer et lancer les tests

```bash
cd e2e
npm install
npx playwright install chromium

npm test            # toute la suite (api + ui)
npm run test:api    # uniquement l'API (rapide, sans navigateur)
npm run test:ui     # uniquement le back-office
npm run report      # rapport HTML
```

## 3. Nettoyage

```bash
# arrêter l'API E2E (8090) et le ng serve (4400) lancés ci-dessus
lsof -ti tcp:8090 | xargs kill 2>/dev/null
lsof -ti tcp:4400 | xargs kill 2>/dev/null
# supprimer la base de test (ne touche pas `kenzorf`)
docker exec kenzorf-pg psql -U kenzorf -d kenzorf -c "DROP DATABASE IF EXISTS kenzorf_e2e WITH (FORCE);"
```

## Organisation

```
e2e/
├── playwright.config.ts        # 2 projets : "api" (request context) + "ui" (Desktop Chrome)
├── support/
│   ├── constants.ts            # comptes seedés, URLs, clés sessionStorage
│   ├── api.ts                  # helpers API typés (login, register, panier, commande)
│   └── ui-fixtures.ts          # fixture `adminPage` (session admin) + login UI
└── tests/
    ├── api/                    # auth, catalog, cart, orders-payments, addresses, rbac, idor
    └── ui/                     # auth (+guards), dashboard-nav, products, categories, orders (+clients)
```

### Isolation des données

Les tests qui écrivent (panier, commandes, IDOR) utilisent un **client fraîchement inscrit
par test** (`registerFreshCustomer`) pour éviter toute course d'écriture en parallèle sur un
panier partagé. Les assertions UI sur des données seedées restent **structurelles** (présence
d'en-têtes/lignes) plutôt que de dépendre d'un enregistrement précis, car les tests d'écriture
polluent la base partagée (newest-first → pagination).

## Bugs détectés (tests rouges volontaires)

Trois tests sont **rouges à dessein** : ils documentent de vrais bugs (à ne pas supprimer).

1. **Format d'erreur non conforme sur champs manquants** — `tests/api/auth.spec.ts`
   `POST /api/auth/register` avec des champs requis **absents** renvoie le `ProblemDetails`
   par défaut d'ASP.NET (`{ type, title, status:400, errors, traceId }`) au lieu du format
   contrat `{ code, messageKey, params, status }` (spec §3), et **fuite un `traceId`**.
   Quand les champs sont présents-mais-invalides, FluentValidation renvoie bien `422` au format
   standard. Concerne tous les endpoints `[FromBody]`. Sévérité : **moyenne**.

2. **Recherche clients inopérante** — `tests/ui/orders.spec.ts` (describe « Clients »)
   `GET /api/admin/customers` ignore le paramètre `?search` (il ne bind que `page`/`pageSize`),
   alors que la page Clients du back-office expose un champ de recherche câblé dessus.
   Sévérité : **moyenne** (fonction UI cassée).

3. **Recherche produits (back-office) inopérante** — `tests/ui/products.spec.ts`
   `GET /api/admin/products` ignore aussi `?search`. Le catalogue **public**
   `GET /api/products?search=…` fonctionne, lui, correctement. Sévérité : **moyenne**.

Voir le rapport de livraison pour le détail (endpoint, attendu vs obtenu, sévérité).
