---
name: reference-api-error-contract
description: Exact shape of KENZORF .NET API error responses and how the Flutter client must translate them
metadata:
  type: reference
---

The .NET API error JSON has **two shapes**, both must be handled by `core/api/api_exception.dart`:

1. Domain/business errors: `{ "code", "messageKey", "params": {}, "status" }` — translate `messageKey` via i18n.
2. FluentValidation 422: `{ "code": "common.validationFailed", "messageKey": "common.validationFailed", "params": {}, "status": 422, "errors": { "<field>": ["<i18n.key>"] } }`. **The useful key is inside `errors`, not `params`.** E.g. adding over-stock returns `errors.quantity = ["cart.quantity.max"]`. ASP.NET model-binding 400s use a different RFC9110 ProblemDetails shape (`errors` map of human strings, no `code`).

**Why:** A naive client that only reads top-level `messageKey` shows a vague generic message on the most common cart failure (quantity > stock). Field-level keys like `cart.quantity.max`, `cart.productVariantId.required` carry the real meaning and must be surfaced + present in the i18n dict.

**How to apply:** `ApiException.fromDio` extracts the first `errors[field][0]` value as the messageKey when present. Keep these keys translated in `core/l10n/app_strings.dart`: `common.validationFailed`, `cart.quantity.max`, `cart.quantity.min`, `cart.productVariantId.required`, `variant.outOfStock`.

**FCFA float gotcha:** decimals serialize as floats (`12000.0`, not `12000`). Model parsing uses `asInt` (rounds `num`) so it's safe — do NOT switch to `as int` casts on price/subtotal/lineTotal/stockQuantity fields or parsing throws.
