# KENZORF — Spec MVP & contrat d'API (source de vérité)

> Document de cadrage dev-ready consommé **en parallèle** par `dotnet-feature`, `angular-feature`, `flutter-feature`.
> KENZORF = boutique **mono-marque, mono-tenant**. Rôles : `Customer`, `Admin`. Devise **FCFA (XOF)**, montants **entiers**. Paiement **KPay**.

## 1. Périmètre MVP

**Marketplace (Flutter, client)** : inscription/connexion, vitrine + mise en avant, catalogue filtrable (catégorie, genre, recherche), fiche produit avec sélection variante (taille/couleur) + stock, panier, checkout (adresse + paiement KPay), confirmation + suivi des commandes, profil + adresses.

**Back-office (Angular, admin)** : connexion admin, dashboard (CA, commandes, stock bas), CRUD produits + variantes + images + stock, CRUD catégories, liste/détail commandes + changement de statut, liste clients.

**API (.NET)** : expose tout le contrat ci-dessous, JWT + refresh, seed KENZORF, paiement KPay (abstraction + webhook).

## 2. Domaine (déjà créé dans `api/src/KENZORF.Domain`)

`Category`, `Product`, `ProductImage`, `ProductVariant`, `Customer`, `Address`, `Cart`, `CartItem`, `Order`, `OrderItem`, `Payment`.
Enums : `OrderStatus { Pending, Paid, Processing, Shipped, Delivered, Cancelled, Refunded }`, `PaymentStatus { Pending, Initiated, Succeeded, Failed, Cancelled, Refunded }`, `Gender { Men, Women, Unisex, Kids }`.
> Le **Domain est figé** : les agents s'appuient dessus, ne le refactorent pas sans raison. `ApplicationUser : IdentityUser` (Infrastructure) porte un `CustomerId` (FK vers `Customer`).

## 3. Conventions de contrat

- Base URL : `/api`. JSON **camelCase**. **Enums en string** (`"Paid"`).
- Auth : `Authorization: Bearer <accessToken>`. En-tête `Accept-Language: fr|en`.
- Pagination : `?page=1&pageSize=20` → `{ items, page, pageSize, total, totalPages }`.
- Erreurs (toujours ce format) : `{ "code": "orders.notFound", "messageKey": "orders.notFound", "params": {}, "status": 404 }`. Jamais de stack trace.
- Dates : ISO 8601 UTC.

## 4. Endpoints

### Auth — `/api/auth` (public sauf `me`)
| Méthode | Route | Body | Réponse |
|---|---|---|---|
| POST | `/register` | `RegisterRequest` | `AuthResponse` |
| POST | `/login` | `LoginRequest` | `AuthResponse` |
| POST | `/refresh` | `{ refreshToken }` | `AuthResponse` |
| POST | `/logout` | `{ refreshToken }` | 204 |
| GET | `/me` | — (Auth) | `UserDto` |

### Catalogue — public
| GET | `/api/categories` | → `CategoryDto[]` |
| GET | `/api/products` | query `categorySlug,gender,search,minPrice,maxPrice,sort(newest|price_asc|price_desc),page,pageSize` → `Paged<ProductListItemDto>` |
| GET | `/api/products/featured` | → `ProductListItemDto[]` |
| GET | `/api/products/{slug}` | → `ProductDetailDto` |

### Panier — `/api/cart` (Auth, Customer)
| GET | `/api/cart` | → `CartDto` |
| POST | `/api/cart/items` | `{ productVariantId, quantity }` → `CartDto` |
| PUT | `/api/cart/items/{itemId}` | `{ quantity }` → `CartDto` |
| DELETE | `/api/cart/items/{itemId}` | → `CartDto` |
| DELETE | `/api/cart` | → 204 |

### Commandes — `/api/orders` (Auth, Customer)
| POST | `/api/orders` | `CreateOrderRequest` → `OrderDto` (crée la commande `Pending` à partir du panier **et** initie le paiement KPay ; renvoie `payment.checkoutUrl`) |
| GET | `/api/orders` | → `OrderSummaryDto[]` (les miennes) |
| GET | `/api/orders/{id}` | → `OrderDto` (la mienne) |
| POST | `/api/orders/{id}/cancel` | → `OrderDto` (si `Pending`) |

### Paiement — `/api/payments`
| GET | `/api/payments/{reference}/status` | (Auth) → `{ status, orderId, orderStatus }` (polling) |
| POST | `/api/payments/webhook` | **public**, signature KPay vérifiée → 200. Met à jour `Payment` + `Order` (→ `Paid`). Idempotent. |

### Adresses — `/api/addresses` (Auth, Customer)
| GET | `/api/addresses` | → `AddressDto[]` |
| POST/PUT/DELETE | `/api/addresses(/{id})` | `AddressRequest` → `AddressDto` |

### Admin — `/api/admin` (Auth, **Admin**)
| GET | `/dashboard` | → `DashboardDto` (CA total/mois, nb commandes par statut, commandes récentes, variantes en stock bas) |
| GET/POST/PUT/DELETE | `/products(/{id})` | `AdminProductRequest` → `AdminProductDto` |
| POST/PUT/DELETE | `/products/{id}/variants(/{variantId})` | `VariantRequest` |
| POST | `/products/{id}/images` | multipart → `{ url }` (ou URL distante) |
| GET/POST/PUT/DELETE | `/categories(/{id})` | `CategoryRequest` |
| GET | `/orders` | query `status,search,page,pageSize` → `Paged<AdminOrderSummaryDto>` |
| GET | `/orders/{id}` | → `AdminOrderDto` |
| PUT | `/orders/{id}/status` | `{ status }` → `AdminOrderDto` (transitions valides only) |
| GET | `/customers` | → `Paged<CustomerDto>` |
| POST | `/uploads` | multipart image → `{ url }` |

## 5. DTOs (camelCase ; les agents s'alignent à l'identique back/front/mobile)

```
RegisterRequest    { email, password, firstName, lastName, phoneNumber? }
LoginRequest       { email, password }
AuthResponse       { accessToken, refreshToken, expiresAt, user: UserDto }
UserDto            { id, email, firstName, lastName, phoneNumber?, role }   // role: "Customer"|"Admin"

CategoryDto        { id, name, slug, description?, imageUrl?, productCount }
ProductListItemDto { id, name, slug, basePrice, compareAtPrice?, currency, primaryImageUrl?, gender, inStock, isFeatured }
ProductDetailDto   { id, name, slug, description, shortDescription?, basePrice, compareAtPrice?, currency,
                     gender, material?, careInstructions?, category: CategoryRefDto,
                     images: ImageDto[], variants: VariantDto[] }
ImageDto           { id, url, altText?, isPrimary, displayOrder }
VariantDto         { id, sku, size, color, colorHex?, price, stockQuantity, inStock }

CartDto            { id, items: CartItemDto[], subtotal, totalQuantity, currency }
CartItemDto        { id, productVariantId, productId, productName, productSlug, size, color, colorHex?,
                     imageUrl?, unitPrice, quantity, lineTotal, stockQuantity }

CreateOrderRequest { shippingAddress: AddressRequest, customerNote?, paymentMethod? }   // paymentMethod: "orange_money"|"mtn"|"wave"|"moov"|"card"
AddressRequest     { label?, fullName, phoneNumber, line1, line2?, city, region?, country, landmark? }
AddressDto         { id, label, fullName, phoneNumber, line1, line2?, city, region?, country, landmark?, isDefault }

OrderDto           { id, orderNumber, status, subtotal, shippingFee, discount, total, currency,
                     items: OrderItemDto[], shippingAddress: {...}, customerNote?, payment: PaymentDto?,
                     placedAt, paidAt? }
OrderItemDto       { id, productName, variantLabel, sku, imageUrl?, unitPrice, quantity, lineTotal }
OrderSummaryDto    { id, orderNumber, status, total, currency, itemCount, placedAt }
PaymentDto         { reference, provider, status, amount, currency, paymentMethod?, checkoutUrl? }

DashboardDto       { revenueTotal, revenueThisMonth, currency, ordersByStatus: {status:count},
                     recentOrders: AdminOrderSummaryDto[], lowStockVariants: {...}[] }
AdminProductRequest{ name, slug?, description, shortDescription?, categoryId, basePrice, compareAtPrice?,
                     gender, material?, careInstructions?, isFeatured, isActive,
                     images: {url,altText?,isPrimary,displayOrder}[], variants: VariantRequest[] }
VariantRequest     { id?, sku, size, color, colorHex?, price?, stockQuantity, isActive }
```

## 6. Auth — flux

JWT **HMAC-SHA256** (access ~15 min) + **refresh token rotatif** (opaque, **hashé en base**, ~14 j). À chaque `/refresh` : valider, révoquer l'ancien, émettre un nouveau couple. `/logout` révoque. Claims : `sub`(userId), `email`, `role`. Mot de passe via ASP.NET Core Identity (hash). `register` crée `ApplicationUser` (role `Customer`) **+** `Customer`. Le seed crée un `Admin`.

## 7. Paiement KPay — flux (`IPaymentGateway`)

> ⚠️ L'API publique exacte de `kpay.site` n'est pas documentée ici. Modéliser une **abstraction** `IPaymentGateway` (Application/Contracts) et un adapter `KPayPaymentGateway` (Infrastructure) suivant le pattern agrégateur mobile-money classique. Config par variables d'env (`KPay:BaseUrl`, `KPay:ApiKey`, `KPay:Secret`, `KPay:WebhookSecret`). **Fail-closed** : sans clés valides, refuser le paiement (ne pas simuler en prod). Prévoir un `FakePaymentGateway` activable en `Development` pour les tests/local.

1. `POST /api/orders` → crée `Order(Pending)` + `Payment(Pending, reference unique)` → appelle `gateway.InitiatePaymentAsync(order)` → reçoit `checkoutUrl` + `providerTransactionId` → `Payment(Initiated)` → renvoie `checkoutUrl`.
2. Client paie sur la page KPay (redirection / WebView Flutter).
3. KPay appelle `POST /api/payments/webhook` → vérifier signature → maj `Payment(Succeeded|Failed)` ; si succès → `Order(Paid)`, `paidAt`, décrément stock, vider panier. **Idempotent** (rejouer le webhook ne double rien).
4. Le client poll `GET /api/payments/{reference}/status` jusqu'à statut final. Le passage `Paid` ne vient **que** du webhook (jamais du retour navigateur).

## 8. Découpage par agent (parallélisable)

### `dotnet-feature` — API (chemin critique, démarre en premier)
- **Application** : DTOs (`Application/DTOs`), contrats (`Application/Contracts` : `IProductService`, `ICatalogService`, `ICartService`, `IOrderService`, `IPaymentGateway`, `ITokenService`, `IAuthService`, `IUnitOfWork`, `ICurrentUser`, `IDashboardService`, `IImageStorage`), validators FluentValidation, services applicatifs, mapping, exceptions applicatives, `DependencyInjection.AddApplication()`.
- **Infrastructure** : `AppDbContext` + configurations EF (Fluent API, index, `Reference` unique paiement), `ApplicationUser`+Identity, repositories/UoW, `TokenService` (JWT+refresh hashé), `KPayPaymentGateway` + `FakePaymentGateway`, `ImageStorage` (disque/wwwroot), `Seeder` (admin + marque + catégories + produits/variantes), `AddInfrastructure(config)`. Migration via `dotnet ef migrations add InitialCreate` (installer `dotnet-ef` 9.x avant).
- **Api** : `Program.cs` (Serilog, CORS pour `:4200` + app mobile, JWT, Swagger, ProblemDetails/exception middleware, auto-migrate+seed au boot, `ASPNETCORE_URLS=http://+:8080`), controllers (Auth, Categories, Products, Cart, Orders, Payments, Addresses, Admin*), `appsettings.json` (+ `appsettings.Development.json`), `Dockerfile` multi-stage.
- Pas de logique métier dans les controllers. Enums string (JsonStringEnumConverter). Erreurs au format §3.

### `angular-feature` — back-office (Angular 22, Node ≥ 22)
- Scaffold dans `back-office/` (déjà créé par l'orchestrateur). Tailwind, env API `http://localhost:8080/api`.
- `core/` : `interfaces` (alignés DTOs §5), `services` (Api typés, AuthService signaux, TokenInterceptor, ErrorInterceptor), `guards` (authGuard, adminGuard), `constants` (statuts, libellés), i18n (`fr`/`en`).
- `features/` : `auth/login`, `dashboard`, `products` (liste + form variantes/images/stock), `categories`, `orders` (liste + détail + changement statut), `customers`. `layouts/` shell admin (sidebar). Signals + OnPush + Signal Forms. i18n proactif.

### `flutter-feature` — marketplace (Flutter)
- Scaffold dans `marketplace/` (déjà créé par l'orchestrateur). Riverpod, Dio (intercepteur JWT+refresh), go_router, flutter_secure_storage, intl (fr/en), thème Material 3 KENZORF, format FCFA.
- `lib/core/` : models (alignés DTOs §5), `api` (Dio + endpoints), `auth` (controller + secure storage), router, theme, l10n, widgets communs.
- `lib/features/` : `auth` (login/register), `home` (vitrine + featured), `catalog` (liste + filtres), `product` (détail + sélection variante), `cart`, `checkout` (adresse + KPay WebView + statut), `orders` (liste + détail), `profile`/`addresses`. État via Riverpod, navigation go_router, secure storage pour tokens.

## 9. Definition of Done
Back compile + migration applique + seed OK + Swagger expose tout le contrat. Front compile + lint + écrans câblés sur l'API. Mobile `flutter analyze` OK + écrans câblés. `docker compose up` démarre les 3. README à jour.
