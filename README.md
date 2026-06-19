<div align="center">

# KENZORF

**Plateforme e-commerce mono-marque de vêtements — Afrique francophone (FCFA / XOF)**

API .NET 9 · Back-office Angular 22 · Marketplace mobile Flutter

</div>

---

## 1. Vue d'ensemble

KENZORF est une boutique de vêtements en ligne **mono-marque** (la marque vendue *est* KENZORF). Trois applications dans un mono-repo :

| Application | Rôle | Techno | Port (dev) |
|---|---|---|---|
| **`api/`** | API REST (catalogue, panier, commandes, paiement, auth) | .NET 9 · ASP.NET Core · Clean Architecture · EF Core · PostgreSQL | `8080` |
| **`back-office/`** | Administration (produits, stock, commandes, clients) | Angular 22 · signals · Tailwind | `4200` |
| **`marketplace/`** | App **mobile** client (vitrine → checkout KPay → suivi) | Flutter · Riverpod · go_router | (émulateur) |

> **Mono-tenant** : pas de multi-boutique. Deux rôles : `Customer` (app mobile) et `Admin` (back-office).
> **Devise** : FCFA (XOF), montants entiers. **Paiement** : KPay (mobile money / carte) derrière une abstraction `IPaymentGateway`.

## 2. Architecture

```
kenzorf/
├── api/                              # API .NET 9 — KENZORF.sln (Clean Architecture)
│   ├── src/KENZORF.Domain/           #   entités, enums, règles métier pures
│   ├── src/KENZORF.Application/       #   DTOs, contrats, services, validators
│   ├── src/KENZORF.Infrastructure/   #   EF Core, Identity, JWT, KPay, seed
│   ├── src/KENZORF.Api/              #   controllers, middleware, Swagger, Program.cs
│   └── Dockerfile
├── back-office/                      # Angular 22 (standalone, signals, OnPush, Tailwind)
│   ├── src/app/{core,features,layouts,shared}
│   ├── Dockerfile · nginx.conf       #   build + service statique + proxy /api
├── marketplace/                      # Flutter (lib/{core,features})
├── .claude/                          # agents, commandes, hooks, specs (voir §8)
├── docker-compose.yml · .env.example
└── CLAUDE.md                         # guide de référence pour les agents
```

**Dépendances** (Clean Architecture, vers l'intérieur) : `Api → Application → Domain` ; `Infrastructure` implémente les abstractions de `Application`. Aucune logique métier dans les controllers, aucun EF Core dans le Domain.

## 3. Prérequis

- **Docker** + Docker Compose (voie recommandée pour tout lancer)
- Pour le dev local : **.NET SDK 9**, **Node ≥ 22** (Angular 22), **Flutter 3.41+ / Dart 3.11+**

## 4. Démarrage rapide (Docker)

```bash
cp .env.example .env          # puis adapter les secrets (Jwt__Key, mots de passe…)
docker compose up --build
```

- API : <http://localhost:8080>  ·  Swagger : <http://localhost:8080/swagger>
- Back-office : <http://localhost:4200>
- PostgreSQL : `localhost:5432`

Au démarrage, l'API applique les migrations EF et **seed** la base (marque, catégories, produits, comptes de test).

> **Ports déjà occupés ?** Les ports hôte sont configurables dans `.env` : `POSTGRES_PORT`, `API_PORT`, `BACKOFFICE_PORT` (utile pour cohabiter avec un autre projet).

## 5. Développement local (app par app)

### API .NET (`api/`)
```bash
# Postgres requis (ex. : docker run -d --name kenzorf-pg -e POSTGRES_DB=kenzorf \
#   -e POSTGRES_USER=kenzorf -e POSTGRES_PASSWORD=kenzorf -p 5432:5432 postgres:16-alpine)
cd api
dotnet run --project src/KENZORF.Api          # http://localhost:8080  ·  Swagger /swagger
# Migrations (jamais à la main — via l'outil EF) :
dotnet ef migrations add <Nom> --project src/KENZORF.Infrastructure --startup-project src/KENZORF.Api
```

### Back-office Angular (`back-office/`) — **Node ≥ 22 requis**
```bash
export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"   # ou `nvm use 22`
cd back-office
npm install
npm start        # http://localhost:4200  (appelle l'API sur http://localhost:8080/api)
npm test         # Vitest
npm run build    # build prod (sortie dist/back-office/browser)
```

### Marketplace Flutter (`marketplace/`)
```bash
cd marketplace
flutter pub get
flutter run      # émulateur Android → http://10.0.2.2:8080/api
# iOS : flutter run --dart-define=API_BASE_URL=http://localhost:8080/api
flutter test
flutter analyze
```

> **Note environnement** : si `~/.pub-cache` est un symlink cassé (volume externe non monté), exporter
> `PUB_CACHE=$(pwd)/../.pub-cache-local` avant les commandes `flutter`.

## 6. Comptes de test (seed)

| Rôle | Email | Mot de passe |
|---|---|---|
| **Admin** (back-office) | `admin@kenzorf.com` | `Password123!` |
| **Client** (marketplace) | `client@kenzorf.com` | `Password123!` |

Le seed crée 4 catégories (Homme, Femme, Unisexe, Accessoires) et 10 produits KENZORF avec variantes (tailles/couleurs), stock et images.

## 7. Paiement KPay

Le paiement passe par une abstraction `IPaymentGateway` :
- **Développement** : `FakePaymentGateway` (renvoie un `checkoutUrl` local, permet de simuler le webhook).
- **Production** : `KPayPaymentGateway`. Renseigner dans `.env` :
  `KPay__BaseUrl`, `KPay__ApiKey`, `KPay__Secret`, `KPay__WebhookSecret`.

**Sécurité** (non négociable) :
- **Fail-closed** : en production sans clés valides, l'initiation de paiement échoue proprement — jamais de faux succès.
- Le statut commande passe à `Paid` **uniquement** via le webhook serveur vérifié (`POST /api/payments/webhook`), **jamais** sur le retour navigateur.
- Idempotence : référence de paiement unique (index unique) ; rejouer le webhook ne double rien.

> ⚠️ L'adaptateur `KPayPaymentGateway` suit le pattern agrégateur mobile-money standard. **Avant la mise en production réelle**, aligner le chemin d'API, le schéma du webhook et l'algorithme de signature sur la documentation officielle de `kpay.site` (voir `KPayPaymentGateway.cs`).

## 8. Workflow agents (`.claude/`)

Le projet est outillé pour un développement piloté par agents spécialisés (repris et adaptés depuis un projet de même stack) :

| Agent | Rôle |
|---|---|
| `pm-po` | Cadrage produit → specs dev-ready (`.claude/specs/`) |
| `fullstack-architect` | Cadrage technique (placement, interfaces, patterns) — ne code pas |
| `dotnet-feature` | Implémentation API .NET |
| `angular-feature` | Implémentation back-office Angular |
| `flutter-feature` | Implémentation app mobile Flutter |
| `test-runner` | Exécution des tests |
| `code-reviewer` | Audit qualité / sécurité / paiements / auth |

Commandes (slash) encapsulant le pipeline : `/feature`, `/spec`, `/boucle`, `/livraison`, `/revue`.
Contrat d'API de référence : **`.claude/specs/kenzorf-mvp.md`**. Guide complet : **`CLAUDE.md`**.

**Garde-fous (hooks)** : git en écriture bloqué (livraison dans le working tree), création manuelle de migration EF bloquée, auto-format best-effort après édition.

## 9. Déploiement production (VPS / Docker)

1. Provisionner un VPS avec Docker, pointer un domaine, terminer le TLS sur un reverse proxy en amont (Caddy/Traefik/Nginx) ou ajouter le certificat au service `back-office`.
2. `.env` de production : secrets forts (`Jwt__Key` aléatoire ≥ 32 caractères, mot de passe Postgres), `ASPNETCORE_ENVIRONMENT=Production`, clés `KPay__*`.
3. `docker compose up -d --build`. Le SPA appelle l'API en relatif `/api` (proxifié par Nginx vers le service `api`).
4. Sauvegarder le volume `kenzorf-pgdata` (base) et `kenzorf-uploads` (images produit).
5. App mobile : `flutter build apk --release` / `flutter build ipa` avec `--dart-define=API_BASE_URL=https://votre-domaine/api`.

## 10. Dépannage

| Symptôme | Cause / solution |
|---|---|
| `ng`/build Angular échoue | Node < 22. `export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"` |
| Port 4200/5432/8080 déjà pris | Ajuster `POSTGRES_PORT` / `API_PORT` / `BACKOFFICE_PORT` dans `.env` |
| `flutter` échoue (pub cache) | `~/.pub-cache` symlink cassé → `export PUB_CACHE=…/.pub-cache-local` |
| API : `relation does not exist` | Migration non appliquée → vérifier la connexion Postgres ; l'API migre au boot |
| Paiement refusé en prod | Clés `KPay__*` absentes (fail-closed) → les renseigner |

---

<div align="center"><sub>KENZORF · Clean Architecture · Signals · Flutter · FCFA</sub></div>
