# Milestone 1: Missing Routes — Implementation Plan

## 1. Observation
- Investigated `routes/api.php` and found that the requested routes are **already present** before `Route::apiResource('contacts')` (lines 110-113):
  - `GET /contacts/analytics` → `hubAnalytics()`
  - `GET /contacts/conflicts` → `conflicts()`
  - `GET /contacts/stale-memory` → `staleMemory()`
  - `GET /contacts/{id}/memory-maintenance/runs` → `contactMaintenanceRuns()`
- Investigated `app/Http/Controllers/ContactController.php` and found that the requested methods are **already implemented** (lines 637-692).
- However, `hubAnalytics()` only returns `total_contacts`, `stale_memory_count`, `conflicted_contacts`, and `channel_distribution`. It is **missing**:
  - aggregate contact counts by type
  - reply mode distribution
  - import rates
  - analysis cost totals
- `conflicts()`, `staleMemory()`, and `contactMaintenanceRuns()` are correctly implemented according to the scope.
- Verified models `Contact`, `ContactMessage`, `ContactImportBatch`, `ContactAnalysisRun`, and `ContactMemoryMaintenanceRun`. `ContactMemoryMaintenanceRun` stores `contact_id` inside a JSON column `scope`, which the current implementation handles correctly via `whereJsonContains('scope->contact_id', (int)$id)`.

## 2. Logic Chain
- Since the routes and baseline controller methods already exist, the primary implementation work is strictly focused on **updating `hubAnalytics()`** to fulfill the missing requirements.
- **Aggregate contact counts by type**: Can be fetched by grouping `Contact` records by the `type` column.
- **Reply mode distribution**: Can be fetched by grouping `Contact` records by the `reply_mode_override` column.
- **Import rates**: Can be fetched by grouping `ContactImportBatch` records by `DATE(created_at)` and summing the `imported_records` column.
- **Analysis cost totals**: Can be aggregated from the JSON column `cost_metadata` in the `ContactAnalysisRun` model. Because parsing JSON across many rows can be slow, a `JSON_EXTRACT` or similar DB-level sum (or a simple collection reduction if dataset is small) should be used.
- Other methods (`conflicts()`, `staleMemory()`, `contactMaintenanceRuns()`) already meet all acceptance criteria, thus requiring no changes.

## 3. Caveats
- `ContactAnalysisRun`'s cost is stored inside a JSON column `cost_metadata`. Depending on the exact key used (e.g. `total_cost`), the query must match the JSON structure. If the database is MySQL/PostgreSQL, `DB::raw("sum(JSON_EXTRACT(cost_metadata, '$.total_cost'))")` could be used.
- Import rates are assumed to be daily rates (`imported_records` summed by day), which provides the most useful analytics graph.

## 4. Conclusion
The implementation work is isolated to extending `ContactController::hubAnalytics()`. The plan is:
1. Update `ContactController::hubAnalytics()` array to include:
   ```php
   'contact_types' => \App\Models\Contact::select('type', \DB::raw('count(*) as count'))->groupBy('type')->get(),
   'reply_mode_distribution' => \App\Models\Contact::select('reply_mode_override', \DB::raw('count(*) as count'))->groupBy('reply_mode_override')->get(),
   'import_rates' => \App\Models\ContactImportBatch::select(\DB::raw('DATE(created_at) as date'), \DB::raw('sum(imported_records) as total'))->groupBy('date')->get(),
   'analysis_costs' => \App\Models\ContactAnalysisRun::all()->sum(fn($r) => $r->cost_metadata['total_cost'] ?? 0), // Or optimized DB query
   ```
2. The routes and the other three methods (`conflicts`, `staleMemory`, `contactMaintenanceRuns`) should be left as they are.

## 5. Verification Method
- Execute the tests for `ContactController` or simply hit `GET /api/v1/contacts/analytics` in the local environment and verify the JSON response contains the new keys: `contact_types`, `reply_mode_distribution`, `import_rates`, and `analysis_costs`.
- Inspect the output arrays to ensure counts and cost calculations are mathematically correct based on database seed data.
