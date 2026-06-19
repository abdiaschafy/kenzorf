# KENZORF — guide agent

**KENZORF** est une **boutique de vêtements en ligne mono-marque** (la marque vendue est KENZORF elle-même). Marché : **Afrique francophone**, devise **FCFA (XOF)**, langue **français** (i18n prête pour `en`). Paiement via **KPay** (`kpay.site`, mobile money + carte) derrière une abstraction.

> ⚠️ **KENZORF n'est PAS multi-tenant.** Contrairement au projet djara-connect dont sont issus les agents, il n'y a **ni TenantId, ni RBAC d'agence, ni bookings/trips**. Deux rôles seulement : **`Customer`** (client de la marketplace) et **`Admin`** (back-office). Ignore toute consigne « multi-tenant / tenant scoping / agence » héritée des agents : elle ne s'applique pas ici.

Monorepo, 3 applications :
- **API** .NET 9 (Clean Architecture) — catalogue, panier, commandes, paiement, auth.
- **Back-office** Angular 22 — administration (produits, stock, commandes, clients).
- **Marketplace** Flutter — app mobile client (vitrine, panier, checkout KPay, suivi commande).

---

## Règle d'or — pipeline agents (ne jamais court-circuiter)

Le travail passe **toujours** par les agents de `.claude/agents/`, en parallèle quand les tâches sont indépendantes :

1. **`pm-po`** — cadre le besoin, écrit les specs dev-ready dans `.claude/specs/`.
2. **`fullstack-architect`** — cadre la technique (placement fichiers, interfaces, patterns, risques). Ne code pas.
3. **`dotnet-feature`** + **`angular-feature`** + **`flutter-feature`** — implémentent **en parallèle**.
4. **`test-runner`** — lance les tests.
5. **`code-reviewer`** — audite (sécurité, auth, paiements, régressions).
6. On reboucle sur 3 jusqu'à ce que tout soit vert.

Commandes encapsulant ce pipeline : `.claude/commands/` (`/feature`, `/spec`, `/boucle`, `/livraison`, `/revue`).

## Garde-fous automatiques (hooks)

- **Git** : `commit` / `add` / `push` / branche / PR **bloqués** — on livre dans le working tree, le commit est géré à la main. (Contournement : `DJARA_ALLOW_GIT=1`.)
- **Migrations EF** : **toujours** `dotnet ef migrations add` ; créer un fichier de migration à la main est bloqué.
- **Auto-format** best-effort après édition (Prettier front si installé localement, csharpier .NET si installé).

---

## Stack

| Couche | Techno |
|---|---|
| **API** | .NET 9 ASP.NET Core, **Clean Architecture** (Domain · Application · Infrastructure · Api) |
| Data | EF Core 9 + Npgsql, **PostgreSQL** ; FluentValidation ; Swashbuckle/OpenAPI |
| Auth | **JWT Bearer HMAC-SHA256 + refresh token rotatif hashé** ; rôles `Customer` / `Admin` |
| Paiement | **KPay** (`IPaymentGateway` + adapter), mobile money/carte, **FCFA (XOF)**, idempotent, **fail-closed sans clés** |
| **Back-office** | Angular 22 (standalone, **signals**, **OnPush par défaut**, router fonctionnel), Tailwind, **Signal Forms**, RxJS 7 (`takeUntilDestroyed`) ; **Node ≥ 22 · TS 6** ; builder esbuild (`@angular/build`) |
| **Marketplace** | **Flutter** (Dart 3.11+), Material 3, Riverpod (state), Dio (HTTP), go_router, flutter_secure_storage, intl (i18n fr/en) |
| Tests | Back : xUnit + FluentAssertions ; Front : **Vitest** ; Mobile : `flutter test` |

### ⚠️ Node ≥ 22 obligatoire pour le back-office Angular 22
Le shell par défaut est en **Node 20**. Avant tout `ng`/`npm`/build/test du back-office, préfixer :
```bash
export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"
```

## Structure

```text
kenzorf/
├── CLAUDE.md · README.md · docker-compose.yml · .env.example
├── api/                         # API .NET 9 — KENZORF.sln
│   └── src/{KENZORF.Domain, KENZORF.Application, KENZORF.Infrastructure, KENZORF.Api}
├── back-office/                 # Angular 22 — admin   (src/app/{core,features,layouts,shared})
└── marketplace/                 # Flutter — app cliente (lib/{core,features,...})
```

## Commandes essentielles

```bash
# API .NET  (depuis api/)
dotnet build KENZORF.sln
dotnet run --project src/KENZORF.Api          # http://localhost:8080  ·  Swagger /swagger
dotnet ef migrations add <Nom> --project src/KENZORF.Infrastructure --startup-project src/KENZORF.Api
dotnet ef database update   --project src/KENZORF.Infrastructure --startup-project src/KENZORF.Api

# Back-office Angular  (depuis back-office/)  — Node ≥ 22 requis
export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"
npm start            # dev server :4200
npm test             # Vitest
npm run build

# Marketplace Flutter  (depuis marketplace/)
flutter pub get
flutter run          # appareil/émulateur
flutter test
flutter build apk --release

# Docker (depuis la racine)
cp .env.example .env && docker compose up --build   # API :8080 · back-office :4200 · PG :5432
```

## Conventions & invariants non négociables

- **Clean Architecture** : dépendances vers l'intérieur (Api → Application → Domain ; Infrastructure implémente les abstractions). Pas de logique métier dans les controllers, pas d'EF Core dans le Domain.
- **Rôles** : `Customer` (marketplace) et `Admin` (back-office). Endpoints admin protégés `[Authorize(Roles="Admin")]`. Un client ne voit **que ses propres** commandes/panier/adresses (fail-closed).
- **Argent en FCFA (XOF)** : montants **entiers** (pas de centimes). Stockés `decimal`, formatés `1 500 FCFA`.
- **Paiement KPay** : idempotence obligatoire (référence unique + index unique), webhook vérifié (signature/secret), **fail-closed sans clés** (refuser, ne jamais « laisser passer »). Le statut commande ne passe `Paid` que sur confirmation serveur (webhook/poll), **jamais** sur simple retour navigateur.
- **Contrats HTTP** : Swagger/OpenAPI = source de vérité. JSON **camelCase**, **enums sérialisés en string**, codes HTTP corrects, erreurs standardisées `{ code, messageKey, params }` (jamais de stack trace exposée).
- **Tests verts avant livraison** ; ne jamais masquer un souci d'environnement en échec de test.
- **Jamais de commit/push** : livraison dans le working tree.

## Placement du code — strict (jamais de déclaration inline)

**Ne jamais** déclarer types/interfaces/enums/gros `const`/DTOs **dans** un composant ou un controller. Toujours un fichier dédié, bien nommé.

**Back .NET** :

| Artefact | Emplacement |
|---|---|
| Enums | `Domain/Enums/` |
| Entités · Value Objects | `Domain/Entities/` · `Domain/ValueObjects/` |
| Constantes | `Domain/Common/` ou `Application/Common/` |
| DTOs / records de transport | `Application/DTOs/` |
| Contrats / interfaces · Validators | `Application/Contracts/` · `Application/Validators/` |

**Front Angular** — dans `core/`, jamais inline dans `features/**/*.component.ts` :

| Artefact | Emplacement | Nommage |
|---|---|---|
| Interfaces / types / models | `core/interfaces/` | `<domaine>.interfaces.ts` |
| Constantes, énumérations | `core/constants/` | `<domaine>.constants.ts` |

> Le front **n'utilise pas `enum` TS** : modéliser en `const { … } as const` + union type. Importer via l'alias `@app/core/...`.

**Marketplace Flutter** : `lib/core/` (models, services, theme, router, l10n), `lib/features/<domaine>/` (data/domain/presentation). Pas de logique réseau dans les widgets ; passer par les repositories/services.

## i18n — traduction systématique et proactive

Dès qu'un fichier contient du texte affiché à l'utilisateur, l'externaliser en i18n — **même si non demandé**. Aucun texte UI en dur.
- **Back** : l'API renvoie un **code/clé stable** (`orders.notFound`), jamais une phrase en dur ; le front/mobile traduit.
- **Front Angular** : système i18n maison (`fr` + `en`, parité obligatoire).
- **Mobile Flutter** : `intl` / ARB (`fr` + `en`).

## Comptes de test (seed)

Mot de passe par défaut **`Password123!`**. Admin : `admin@kenzorf.com`. Client démo : `client@kenzorf.com`. Le seed crée la marque KENZORF, des catégories (Homme, Femme, Accessoires…), des produits avec variantes (tailles/couleurs) et stock. Détail : **README §Seed**.

## Où trouver quoi

- **`README.md`** — doc projet de référence (démarrage, Docker, seed, déploiement).
- **`.claude/specs/`** — specs produit & contrat d'API dev-ready (`kenzorf-mvp.md`).
- **`.claude/agents/`** — les 7 agents · **`.claude/agent-memory/`** — mémoire par agent.
