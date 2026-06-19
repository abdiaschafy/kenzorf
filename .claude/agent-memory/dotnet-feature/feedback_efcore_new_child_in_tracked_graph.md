---
name: efcore-new-child-in-tracked-graph
description: KENZORF gotcha — adding a NEW child entity only to a tracked parent's navigation collection makes EF emit UPDATE (0 rows) instead of INSERT; add via the DbSet explicitly
metadata:
  type: feedback
---

When adding a **new** child entity to an aggregate whose root is already tracked, do NOT rely solely on `parent.Items.Add(child)`. Add it explicitly through its DbSet too (e.g. `_db.CartItems.Add(child)`), then optionally mirror it into the navigation collection for in-memory consistency.

**Why:** Every KENZORF entity derives from `Domain/Common/BaseEntity` which initializes `Id = Guid.NewGuid()` at construction. All Guid keys are mapped `ValueGeneratedOnAdd` (Npgsql/EF convention — see the model snapshot). When a new child with a *non-default* key is discovered by `DetectChanges` inside an already-tracked graph, EF interprets the non-sentinel store-generated key as "this row already exists" and marks it `Modified` -> emits `UPDATE ... WHERE Id=@p` affecting 0 rows -> `DbUpdateConcurrencyException` (HTTP 500). This was the root cause of the `POST /api/cart/items` 500 bug. Calling `.Add()` on the DbSet forces state `Added` -> `INSERT`.

**How to apply:** Applies to any Application-layer service that builds an entity and attaches it to a loaded/tracked parent (cart items, order items, addresses on a tracked customer, etc.). Existing-row mutations (update/remove) are unaffected because those entities are already tracked as `Unchanged`/`Modified`. The Application layer goes through `IAppDbContext` (which exposes every `DbSet<>` + `SaveChangesAsync`) — use that abstraction, do not reach into the concrete `AppDbContext`. See [[efcore-iappdbcontext-abstraction]].
