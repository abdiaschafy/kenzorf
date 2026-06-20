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
docker compose up --build     # ou simplement :  make up      (make down pour arrêter)
```

- API : <http://localhost:8080>  ·  Swagger : <http://localhost:8080/swagger>
- Back-office : <http://localhost:4200>
- PostgreSQL : `localhost:5432`

Au démarrage, l'API applique les migrations EF et **seed** la base (marque, catégories, produits, comptes de test).

> **Ports déjà occupés (multi-projets) ?** `make up` / `make api` / `make front` **libèrent automatiquement** leurs ports avant de démarrer — ils stoppent le conteneur Docker ou le process qui squatte `8080` / `4200` / `5432` (ex. un autre projet). Cible dédiée : `make free-ports`. Pour cohabiter *sans* rien stopper, change plutôt les ports dans `.env` (`POSTGRES_PORT`, `API_PORT`, `BACKOFFICE_PORT`).

## 5. Développement local (app par app)

> 💡 **Raccourcis `Makefile`** (depuis la racine ; `make help` liste toutes les cibles) :
>
> | Action | Cible `make` | Équivaut à |
> |---|---|---|
> | Lancer l'API | `make api` | `dotnet run --project src/KENZORF.Api` |
> | Migrer la base | `make migrate` | `dotnet ef database update …` |
> | Lancer le back-office | `make front` | `npm start` (Node 22) |
> | Build back-office | `make front-build` | `npm run build` |
> | Stack Docker complète | `make up` / `make down` | `docker compose up --build` |
> | Build + install iOS | `make build-ios` → `make install-ios DEVICE=<UDID>` | cf. *iPhone* ci-dessous |
> | Tests | `make test-front` · `make test-flutter` | Vitest · `flutter test` |

### API .NET (`api/`)
```bash
# Postgres requis (ex. : docker run -d --name kenzorf-pg -e POSTGRES_DB=kenzorf \
#   -e POSTGRES_USER=kenzorf -e POSTGRES_PASSWORD=kenzorf -p 5432:5432 postgres:16-alpine)
cd api
dotnet run --project src/KENZORF.Api          # raccourci : make api  ·  http://localhost:8080 (Swagger /swagger)
# Migrations (jamais à la main — via l'outil EF) :
dotnet ef migrations add <Nom> --project src/KENZORF.Infrastructure --startup-project src/KENZORF.Api
```

### Back-office Angular (`back-office/`) — **Node ≥ 22 requis**
```bash
export PATH="$HOME/.nvm/versions/node/v22.22.3/bin:$PATH"   # ou `nvm use 22`
cd back-office
npm install
npm start        # raccourci : make front       · http://localhost:4200 (API → http://localhost:8080/api)
npm test         # raccourci : make test-front   · Vitest
npm run build    # raccourci : make front-build  · sortie dist/back-office/browser
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

#### 📱 Lancer sur un iPhone physique (connecté au Mac en USB)

Prérequis : **Xcode** installé, un **Apple ID** (compte gratuit suffit pour le dev), iPhone branché en USB.

1. **Préparer l'iPhone** : branche-le, déverrouille-le, accepte « Faire confiance à cet ordinateur ». Sur **iOS 16+**, active le **Mode développeur** : Réglages → Confidentialité et sécurité → Mode développeur → activer, puis redémarrer.
2. **Signature Xcode** : `open marketplace/ios/Runner.xcworkspace`
   Onglet *Signing & Capabilities* → coche *Automatically manage signing* → choisis ton *Team* (ton Apple ID). Si besoin, mets un *Bundle Identifier* unique (ex. `com.kenzorf.marketplace`).
3. **Vérifier la détection** : `flutter devices` → ton iPhone doit apparaître.
4. **Adresse de l'API = IP LAN du Mac** (sur un vrai téléphone, `localhost`/`10.0.2.2` ne pointent PAS vers le Mac). Récupère l'IP Wi-Fi du Mac :
   ```bash
   ipconfig getifaddr en0        # ex. 192.168.1.42
   ```
   iPhone et Mac sur le **même Wi-Fi**. L'API écoute déjà sur toutes les interfaces (`http://+:8080`) ; autorise le port 8080 si le pare-feu macOS le demande.
5. **Lancer l'app vers l'API du Mac** :
   ```bash
   cd marketplace
   flutter run -d <id_iphone> --dart-define=API_BASE_URL=http://192.168.1.42:8080/api
   ```
   (remplace par ton IP). Ajoute `--release` pour une build optimisée.

⚠️ **HTTP en clair sur iOS (App Transport Security)** : iOS bloque par défaut le HTTP non chiffré vers une IP LAN. Pour le dev, au choix :
- **Tunnel HTTPS (recommandé, zéro config iOS)** : `ngrok http 8080` puis `--dart-define=API_BASE_URL=https://xxxx.ngrok.app/api`. Aucun souci ATS.
- **Exception ATS dev** : ajouter l'IP du Mac aux `NSExceptionDomains` (clé `NSAppTransportSecurity`) dans `marketplace/ios/Runner/Info.plist` — **à retirer en prod**.

**Raccourcis `Makefile`** (à la racine, façon `make build-ios` + `xcrun devicectl`) :
```bash
make devices                                                  # liste les iPhone + leur UDID
make build-ios   API_BASE_URL=http://192.168.1.42:8080/api    # flutter build ios --release (signé)
make install-ios DEVICE=CF5DDF0C-C8C6-5C08-872D-C6EBE34D9BA5  # xcrun devicectl device install app
make deploy-ios  DEVICE=CF5DDF0C-C8C6-5C08-872D-C6EBE34D9BA5 API_BASE_URL=http://192.168.1.42:8080/api   # build + install (⚠️ SANS chevrons < >, et remplace l'IP par la tienne : make ip)
```
Équivaut à :
```bash
cd marketplace && flutter build ios --release --dart-define=API_BASE_URL=http://<IP_Mac>:8080/api
xcrun devicectl device install app --device <UDID> marketplace/build/ios/iphoneos/Runner.app
```
> Prérequis : signature Xcode configurée (Team/Apple ID) — sinon `flutter build ios` échoue. Sur iPhone physique en HTTP LAN, voir l'avertissement ATS ci-dessus (tunnel `ngrok` HTTPS le plus simple).

> **Production** : `flutter build ipa --dart-define=API_BASE_URL=https://api.ton-domaine/api` (HTTPS, pas d'ATS à toucher).

## 6. Comptes de connexion (après seed)

**Tous les comptes ont le mot de passe `Password123!`.**

| Rôle | Email | Se connecter sur |
|---|---|---|
| **Admin** | `admin@kenzorf.com` | Back-office → http://localhost:4200 |
| **Client** (avec historique de commandes) | `client@kenzorf.com` | App mobile marketplace |

**Seed de base** : marque KENZORF, 4 catégories (Homme, Femme, Unisexe, Accessoires), 10 produits avec variantes (tailles/couleurs), stock et images.

**Seed démo** (`Seed:Demo=true`, activé par défaut en développement — désactiver en prod via `Seed__Demo=false`) : ajoute **~8 clients démo** (`prénom@kenzorf.com`, même mot de passe) et **~30 commandes réparties sur les 7 derniers jours** avec statuts variés (livrée, expédiée, en préparation, payée, en attente, annulée, remboursée) + paiements et stock décrémenté. Résultat : **dashboard back-office peuplé** (CA, commandes par statut, stock bas) et **historique de commandes** visible côté mobile.

> 📋 **Liste exacte des clients démo** : voir la section ci-dessous (renseignée à partir de la sortie du seed).
>
> 📱 Sur **iPhone**, connecte-toi avec `client@kenzorf.com` / `Password123!` pour voir un historique réaliste.

<!-- DEMO_ACCOUNTS_START -->
**8 clients démo** (mot de passe `Password123!`) — ils se partagent avec `client@kenzorf.com` les 30 commandes de démonstration :

| Client | Email | Ville |
|---|---|---|
| Aboubacar Traoré | `aboubacar@kenzorf.com` | Abidjan — Cocody |
| Fatoumata Bamba | `fatoumata@kenzorf.com` | Abidjan — Yopougon |
| Ismaël Koffi | `ismael@kenzorf.com` | Abidjan — Marcory |
| Mariam Ouattara | `mariam@kenzorf.com` | Abidjan — Plateau |
| Yao Kouassi | `yao@kenzorf.com` | Abidjan — Abobo |
| Aïcha Diabaté | `aicha@kenzorf.com` | Abidjan — Cocody |
| Seydou Cissé | `seydou@kenzorf.com` | Bouaké |
| Rokia Sanogo | `rokia@kenzorf.com` | Abidjan — Treichville |

> 30 commandes réparties : Livrée 8 · Expédiée 5 · En préparation 4 · Payée 4 · En attente 5 · Annulée 3 · Remboursée 1. Dashboard back-office : **CA 2 376 000 FCFA**.
<!-- DEMO_ACCOUNTS_END -->

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
