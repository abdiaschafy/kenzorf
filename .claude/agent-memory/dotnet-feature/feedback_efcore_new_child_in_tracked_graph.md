---
name: efcore-new-child-in-tracked-graph
description: KENZORF gotcha — adding a NEW child entity only to a tracked parent's navigation collection makes EF emit UPDATE (0 rows) instead of INSERT; add via the DbSet explicitly
metadata:
  type: feedback
---

**Root cause now fixed at the model level (security-hardening pass):** `AppDbContext.OnModelCreating` forces **`ValueGeneratedNever`** on every single-column `Guid` `Id` PK (loop over `Model.GetEntityTypes()`; Identity's `int` claim-table keys are left untouched). Because `BaseEntity` assigns `Id = Guid.NewGuid()` at construction, the key is always app-supplied, so adding a new child to a tracked parent now produces an `INSERT` even via `parent.Items.Add(child)` alone. There is no DDL impact in Postgres (Guid PKs were never serial), so the change rode in an additive migration.

**Still do this defensively:** when adding a **new** child to an already-tracked aggregate, prefer adding it through its DbSet (`_db.CartItems.Add(child)`) as well — it's explicit and unambiguous. `CartService.AddItemAsync` keeps this pattern.

**Why it used to break (pre-fix history):** Guid keys were `ValueGeneratedOnAdd`. A new child with a non-default key discovered by `DetectChanges` inside a tracked graph was read as "row already exists" -> `Modified` -> `UPDATE ... WHERE Id=@p` (0 rows) -> `DbUpdateConcurrencyException` (HTTP 500). This was the `POST /api/cart/items` 500 bug. `ValueGeneratedNever` removes that ambiguity.

**How to apply:** Applies to any Application-layer service attaching entities to a loaded/tracked parent (cart items, order items, addresses, etc.). Existing-row mutations are unaffected. Go through `IAppDbContext` (DbSets + `SaveChangesAsync` + now `BeginTransactionAsync` returning `IAppTransaction`), never the concrete `AppDbContext`. See [[efcore-iappdbcontext-abstraction]].
