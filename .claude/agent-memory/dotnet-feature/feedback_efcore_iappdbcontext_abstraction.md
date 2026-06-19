---
name: efcore-iappdbcontext-abstraction
description: KENZORF data-access abstraction — Application services depend on IAppDbContext (DbSets + SaveChangesAsync); IUnitOfWork also exists; AppDbContext is IdentityDbContext implementing both
metadata:
  type: feedback
---

Application-layer services access data through `Application/Contracts/IAppDbContext` (exposes every `DbSet<>` plus `Task<int> SaveChangesAsync(...)`). There is also an `IUnitOfWork` contract. The concrete `Infrastructure/Persistence/AppDbContext` is an `IdentityDbContext<ApplicationUser, ApplicationRole, Guid>` and implements both `IAppDbContext` and `IUnitOfWork`.

**Why:** Keeps Clean Architecture intact — the Application layer writes LINQ against the abstraction and never references EF Identity or the concrete context.

**How to apply:** When a service needs to persist/query, inject `IAppDbContext` and use its DbSets + `SaveChangesAsync`. Do not inject the concrete `AppDbContext` into Application. EF Core configurations live in `Infrastructure/Persistence/Configurations/*` (one `IEntityTypeConfiguration<T>` per entity, applied via `ApplyConfigurationsFromAssembly`). Related: [[efcore-new-child-in-tracked-graph]].
