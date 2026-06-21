---
name: project-known-bugs
description: Status of the two KENZORF Flutter bugs the integration suite pinned (checkout WebView relative-url, MainShell setState) — both FIXED 2026-06-21
metadata:
  type: project
---

Two bugs the native integration suite (`marketplace/integration_test/`) once
pinned as "known issues" are now **FIXED** (2026-06-21). The suite was updated to
assert the corrected behavior instead of tolerating the defects.

**Why:** found running the customer journey e2e against a local API on an iOS
simulator; they blocked the real payment flow and spammed errors.
**How to apply:** these are resolved — do NOT reintroduce `withKnownBugsTolerated`
or expect non-zero bug counts. The suite now uses `guardAgainstRegressions(...)`
+ `expectNoKnownBugs()` (in `integration_test/helpers/test_harness.dart`) which
make both signatures FATAL and assert zero occurrences.

1. **Checkout WebView relative `checkoutUrl` crash — FIXED.**
   - API side (already corrected): `FakePaymentGateway` now returns an ABSOLUTE
     url (`{request.Scheme}://{request.Host}/dev/checkout.html?...`), integer
     FCFA amount (no culture comma).
   - App side (defensive, durable): `AppConfig.resolveCheckoutUrl(String?)`
     resolves a relative url against `AppConfig.apiOrigin` (scheme+host+port,
     `/api` stripped) and returns absolute-or-null; `PaymentWebViewScreen` parses
     only that resolved url, never raw `Uri.parse(checkoutUrl)`. Unit-tested in
     `test/core_logic_test.dart` (group "AppConfig.resolveCheckoutUrl (P1)").

2. **`MainShell` "setState during build" — FIXED.**
   Root cause: `cartCountProvider` was a plain `Provider` watching the whole
   `AsyncValue<Cart>`; `cartControllerProvider.build()` watches auth, so a
   login/add-to-cart transition (loading→data) notified `MainShell` DURING its
   build phase. Fix = derive with `.select`: `cartCountProvider` now does
   `ref.watch(cartControllerProvider.select((c)=>count))` and `MainShell` reads
   `authControllerProvider.select((s)=>s.isAuthenticated)`. `select` filters to a
   stable `int`/`bool` and lets Riverpod schedule the dependent rebuild after the
   frame instead of re-entering the current build.

**e2e DB precondition the suite needs (not produced by the demo seeder):** the
"variante en rupture" test expects T-shirt (`tshirt-signature-kenzorf`) variant
**M/Sable stock = 0** while M/Noir stays in stock. The standard Development demo
seed leaves M/Sable in stock, so before running integration tests against a fresh
DB you must zero it: `UPDATE product_variants SET "StockQuantity"=0 ...` joined to
`products."Slug"='tshirt-signature-kenzorf'` where Size='M' AND Color='Sable'.

**Note for the P2 non-regression test:** it uses the seeded `client@kenzorf.com`
whose cart is CUMULATIVE across runs, so it asserts the cart `Badge` exists with a
count `> 0` (the only Material `Badge` in the app is the cart nav item, rendered
only when count>0) — never an exact value, which flaked.
