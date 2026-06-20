---
name: seed-pipeline
description: KENZORF seeding — DbSeeder (base) then DemoDataSeeder (demo activity) run at boot in Program.cs; demo gated by Seed:Demo config, idempotent via "orders already present"
metadata:
  type: project
---

Two seeders run at boot in `KENZORF.Api/Program.cs` (after `db.Database.MigrateAsync()`), both static `SeedAsync(IServiceProvider)` taking a fresh scope internally:

1. `DbSeeder.SeedAsync` — base data: roles, `admin@kenzorf.com` + `client@kenzorf.com`, brand categories, 10-product catalog (`CatalogSeedData`). Idempotent per-entity.
2. `DemoDataSeeder.SeedAsync` — "one week of activity" demo: ~8 customers (`prenom@kenzorf.com`), ~30 orders over last 7 days with weighted statuses, one Payment per order, stock decrement for paid-class orders. Idempotent by an all-or-nothing gate: `if (await db.Orders.AnyAsync()) return;` (prevents double stock-decrement on restart). Gated by config `Seed:Demo` (env `Seed__Demo`): key absent => default `IsDevelopment()`; explicit true/false wins. Set to `false` in appsettings.json, `true` in appsettings.Development.json.

**Why:** Demo data must be reproducible for dashboard/Playwright demos without corrupting the base seed or double-applying stock decrements.

**How to apply:** New seed phases follow the same shape — static seeder in `Infrastructure/Seed`, own scope, idempotent guard, wired in `Program.cs` after migrate. Config-bound flags use an Options class with `SectionName` (see `SeedOptions`), but read a single nullable flag with `Configuration.GetValue<bool?>("Seed:Demo")` when you need "absent vs explicit-false". Note: `dotnet run` picks the URL from `launchSettings.json` (it overrides `ASPNETCORE_URLS`); grep the boot log for "Now listening on" to find the actual port. Builds whole graphs detached and `db.Orders.AddRange(...)` for cascade insert; to also decrement stock, set `OrderItem.ProductVariant` to the already-tracked variant instance loaded with tracking (related: [[efcore-new-child-in-tracked-graph]]).
