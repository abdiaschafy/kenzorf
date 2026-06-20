---
name: project-kenzorf-marketplace
description: KENZORF Flutter marketplace app — stack, architecture, and non-negotiable invariants
metadata:
  type: project
---

KENZORF marketplace = customer-facing Flutter app for a **mono-brand, mono-tenant** clothing shop. Market: francophone Africa, currency **FCFA (XOF)**, default lang **fr** (i18n ready for `en`). Single customer role (`Customer`). Payment via **KPay** WebView. NOT multi-tenant — ignore any tenant/RBAC/agency guidance.

**Why:** Consumes a hardened .NET 9 API (Clean Architecture). Swagger/OpenAPI is the contract source of truth. Spec lives at `/Users/abdiaschafanglontchi/kenzorf/.claude/specs/kenzorf-mvp.md`; root guide at `/Users/abdiaschafanglontchi/kenzorf/CLAUDE.md`.

**How to apply:**
- State: **Riverpod 3** (`AsyncNotifier`/`Notifier` + providers). HTTP: **Dio** with a JWT+refresh interceptor (`core/api/auth_interceptor.dart`, queued, auto-refresh on 401). Routing: **go_router** with auth-guard redirect. Tokens in **flutter_secure_storage** via `TokenStore`.
- Structure: `lib/core/` (models, api, auth, router, theme, l10n, widgets, utils) + `lib/features/<domain>/{data,application,presentation}`. No network logic in widgets — go through repositories.
- i18n: **zero hardcoded UI text**. All strings via `context.l10n.t('key')` against the dual maps in `core/l10n/app_strings.dart` (`kStringsFr`/`kStringsEn`, parity required). API returns stable `messageKey`s the app translates — see [[reference-api-error-contract]].
- Money: integer FCFA (no cents), formatted via `PriceFormatter`. Models parse with tolerant `core/models/json_utils.dart` (`asInt` rounds doubles).
- Tooling quirk: `~/.pub-cache` is a broken symlink — prefix flutter/dart with `PUB_CACHE=/Users/abdiaschafanglontchi/kenzorf/.pub-cache-local`. Flutter 3.41 / Dart 3.11.
- Local API for manual testing: run from `/Users/abdiaschafanglontchi/kenzorf/api` against Postgres on `localhost:5433` (kenzorf/kenzorf/kenzorf), seeded demo customers `prenom@kenzorf.com` / `Password123!`. `flutter analyze` must be 0 errors before delivering. Never commit.
