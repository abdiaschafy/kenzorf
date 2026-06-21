---
name: project-mobile-architecture
description: Durable structural facts about the KENZORF Flutter marketplace that shape changes — state mgmt, routing, auth, payment flow
metadata:
  type: project
---

Structural facts that are stable and shape most changes (verify specifics in
code before relying on a name).

- **State:** Riverpod (`Notifier`/`AsyncNotifier`/`FutureProvider`). Controllers
  live under `lib/features/<domain>/application/`, repositories under `data/`,
  screens under `presentation/`. Models in `lib/core/models/`, aligned 1:1 with
  the API DTOs in `.claude/specs/kenzorf-mvp.md` §5.
- **HTTP:** single Dio via `dioProvider` with `AuthInterceptor` (Bearer +
  `Accept-Language` + auto-refresh on 401 using a separate refreshDio).
  Tokens persisted in `flutter_secure_storage` via `TokenStore`.
- **Routing:** go_router with a `StatefulShellRoute` (tabs: home/catalog/cart/
  orders/profile) + detail routes above the shell. `guardRedirect` sends
  unauthenticated users to `/login` for protected prefixes
  (cart, orders, profile, checkout, payment, addresses).
- **Cart invariant:** cart mutations NEVER surface an `AsyncError` (would blank
  the screen/badge). On failure they keep the current cart and rethrow a
  localizable `ApiException` for the caller to toast.
- **Payment flow (spec §7):** `POST /orders` creates a `Pending` order AND
  initiates payment, returning `payment.checkoutUrl`. App opens it in a WebView
  (`PaymentWebViewScreen`) and polls `GET /payments/{reference}/status`. Order
  becomes `Paid` ONLY via the server webhook, never the browser return.
- **Errors are translated client-side:** API returns `{code, messageKey,
  params, status}`; `ApiException.fromDio` maps to i18n keys; UI shows
  `l10n.describeError(e)` — never raw server text.
