---
name: feedback-integration-test-patterns
description: Techniques that made the KENZORF native integration suite reliable on the iOS simulator
metadata:
  type: feedback
---

Patterns that made `marketplace/integration_test/` reliable against a real local
API on an iOS simulator (validated — the suite is green and stable).

**Why:** the app has no test Keys and uses heavy async/network + animations, so
naive `find.text` + `pumpAndSettle` flaked. These techniques fixed each failure.
**How to apply:** reuse the helpers in `integration_test/helpers/` for any new
mobile integration test.

- **Wait for network with a pump loop, not `pumpAndSettle`.** `pumpAndSettle`
  does NOT wait for Dio responses. Use `pumpUntilFound(finder)` (pump in a loop
  until the widget appears) for anything that depends on a network call.
- **`pumpAndSettle` throws on persistent animations** (polling spinner, etc.).
  Wrap it (`pumpUntilSettled`) and fall back to fixed pumps on `FlutterError`.
- **Tap the InkWell ancestor, not the `Text`.** Pills/tiles center a small
  `Text` in a larger tap target; tapping the text hit-test-misses. Use
  `tapInkByText` (taps `find.ancestor(of: text, matching: InkWell)`).
- **`ensureVisible` before tapping buttons in scrollable forms.** Submit buttons
  (Save, Register) sit below the fold; tapping off-screen silently misses.
  `tapPrimaryButton` now calls `ensureVisible` first.
- **Lazy `ListView` items aren't mounted off-screen.** To tap an item far down
  (e.g. the payment method tiles in checkout), `scrollUntilTextVisible` first.
- **SnackBars overlap bottom action bars and steal taps.** The "added to cart"
  snackbar covers the cart's checkout button. Clear it with `clearSnackBars`
  (via `ScaffoldMessengerState.clearSnackBars`) before tapping bottom bars.
- **A text field's value matches `find.textContaining`.** Don't assert a created
  record by its city/name right after saving a form — the form's own
  `EditableText` matches. Wait for the form to pop (e.g. list-only FAB returns),
  then scope the finder to `find.descendant(of: Card, matching: text)`.
- **Tolerate documented app bugs narrowly.** `withKnownBugsTolerated` wraps a
  scenario, swallowing ONLY specific known `FlutterError`s (matched by message +
  stack) and counting them, so unrelated scenarios still pass and the bug is
  asserted (count > 0) where it's expected.
- On timeout, `pumpUntilFound` prints the visible `Text` widgets — invaluable for
  diagnosing which screen is actually showing.
