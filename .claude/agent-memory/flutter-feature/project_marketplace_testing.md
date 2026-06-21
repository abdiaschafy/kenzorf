---
name: project-marketplace-testing
description: How to run/write Flutter tests for KENZORF marketplace — pub cache quirk, default locale, no test keys, local API isolation
metadata:
  type: project
---

Running marketplace Flutter tooling on this machine.

**Why:** symlinks in the default pub cache are broken on this host, so every
flutter/dart invocation must use a project-local cache or it fails.
**How to apply:** always prefix flutter/dart commands with
`PUB_CACHE=/Users/abdiaschafanglontchi/kenzorf/.pub-cache-local`.

Key facts for writing tests:
- **Default UI locale is French** (`Locale('fr')`). `AppLocalizations.t(key)`
  falls back to `kStringsFr`. So integration/widget tests that match on visible
  text must use the French strings in `lib/core/l10n/app_strings.dart`
  (e.g. login button = "Se connecter", add to cart = "Ajouter au panier").
- **No `Key`/test keys exist anywhere** in the widget tree. Drive tests via
  localized text, widget types (`AppTextField`, `PrimaryButton`,
  `ProductCard`, `QuantityStepper`), `Icons`, and `Semantics` labels.
  `PrimaryButton` is a `GestureDetector` (not a Material button) wrapping a
  `Semantics(button:true,label:...)` — tap by finding its `label` text.
- `AppTextField` wraps a `TextFormField` and shows the label in UPPERCASE as a
  separate `Text` above the field; the editable field has no `labelText`.
  Enter text by locating the `TextFormField`/`EditableText` in order.
- Live/network tests use `@Tags(['live'])` and are skipped by default via
  `dart_test.yaml`. There is a working network probe pattern in
  `test/cart_live_probe_test.dart` (login → get JWT → hit repos with Dio).
- Local API isolation for e2e: run a dedicated API on a non-default port
  (8080 is taken by the docker dev API) against a throwaway DB created on the
  `kenzorf-pg` Postgres container (host port **5433**, kenzorf/kenzorf/kenzorf).
  Override the app base URL with `--dart-define=API_BASE_URL=...`.
- iOS Info.plist already allows insecure HTTP to `localhost` (ATS exception),
  so `http://localhost:<port>/api` works from the iOS simulator.

Seed accounts (password `Password123!`): `admin@kenzorf.com` (Admin),
`client@kenzorf.com` (Customer), plus demo customers. Catalog + variants +
stock are seeded at boot in Development.
