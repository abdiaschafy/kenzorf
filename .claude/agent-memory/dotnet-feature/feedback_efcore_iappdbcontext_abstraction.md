---
name: efcore-iappdbcontext-abstraction
description: KENZORF data-access abstraction — Application services depend on IAppDbContext (DbSets + SaveChangesAsync); IUnitOfWork also exists; AppDbContext is IdentityDbContext implementing both
metadata:
  type: feedback
---

Application-layer services access data through `Application/Contracts/IAppDbContext` (exposes every `DbSet<>`, `Task<int> SaveChangesAsync(...)`, and `Task<IAppTransaction> BeginTransactionAsync(...)`). There is also an `IUnitOfWork` contract. The concrete `Infrastructure/Persistence/AppDbContext` is an `IdentityDbContext<ApplicationUser, ApplicationRole, Guid>` and implements both `IAppDbContext` and `IUnitOfWork`.

**Transactions / atomic conditional writes:** for "exactly once" effects (e.g. the payment webhook), open `await using var tx = await _db.BeginTransactionAsync(ct)` then `await tx.CommitAsync(ct)`. `IAppTransaction` (`Application/Contracts`) is an EF-free wrapper over `IDbContextTransaction`; dispose-without-commit rolls back. For DB-level conditional updates that return affected-row counts, use EF Core 9 `ExecuteUpdateAsync` on a filtered `DbSet` query (e.g. `Payments.Where(p => p.Reference==r && !final.Contains(p.Status)).ExecuteUpdateAsync(...)`, `ProductVariants.Where(v => v.Id==id && v.StockQuantity>=q).ExecuteUpdateAsync(...)`) — translates to `UPDATE ... WHERE ...`, no read-modify-write race. Enum columns mapped `HasConversion<string>()` translate correctly inside these predicates/setters.

**Why:** Keeps Clean Architecture intact — the Application layer writes LINQ against the abstraction and never references EF Identity or the concrete context.

**How to apply:** When a service needs to persist/query, inject `IAppDbContext` and use its DbSets + `SaveChangesAsync` (+ `BeginTransactionAsync` for atomic blocks). Do not inject the concrete `AppDbContext` into Application. EF Core configurations live in `Infrastructure/Persistence/Configurations/*` (one `IEntityTypeConfiguration<T>` per entity, applied via `ApplyConfigurationsFromAssembly`). Related: [[efcore-new-child-in-tracked-graph]].
