# Handoff Report

## Observation
1. The previous `hubAnalytics` implementation caused OOM by loading all `ContactAnalysisRun` models into memory to sum their costs.
2. The `staleContacts` query did not check for NULL `memory_freshness` or use the `config('contacts.memory_staleness_days', 30)` threshold, which is required to match `staleMemory()`.
3. The `conflictedContacts` query did not check for aliases with confidence < 0.7, which is required to match `conflicts()`.
4. The `importRates` query attempted to group by `DATE(created_at)`, which led to an SQL dialect error, and should instead just calculate the totals.

## Logic Chain
1. To address the OOM issue, `ContactAnalysisRun::whereNotNull('cost_metadata')->cursor()->sum(...)` iterates over rows memory-efficiently instead of loading a huge collection.
2. We must update the `$staleContacts` query to `Contact::where('memory_freshness', '<', now()->subDays(config('contacts.memory_staleness_days', 30)))->orWhereNull('memory_freshness')->count()`.
3. We must update the `$conflictedContacts` query to `Contact::whereHas('identifiers', fn($q) => $q->where('conflict_detected', true))->orWhereHas('aliases', fn($q) => $q->where('confidence', '<', 0.7))->count()`.
4. We must simplify `$importRates` to a single raw select that sums `total_records`, `imported_records`, and `failed_records` without a group by date.

## Caveats
No caveats.

## Conclusion
The `hubAnalytics()` implementation has been restructured to prevent OOM errors by using Eloquent's `cursor()`, correct the logical inconsistencies in identifying stale and conflicted contacts, and prevent SQL dialect errors by avoiding improper grouping functions on `ContactImportBatch`.

## Verification Method
1. Verify the code executes without memory exhaustion when there are large numbers of `ContactAnalysisRun` records.
2. Verify that `hubAnalytics` endpoint correctly aggregates contacts, reporting accurate counts for stale and conflicted.
3. Verify that the SQL query for `importRates` works uniformly across databases by not using `DATE()`.
4. Run `php artisan test` on the relevant API tests.

## Implementation Plan

### `ContactController::hubAnalytics()` Replacement

File: `Nexus-backend/app/Http/Controllers/ContactController.php`

```php
    public function hubAnalytics(Request $request)
    {
        $this->authorize('viewAny', Contact::class);
        $totalContacts = Contact::count();
        
        $staleThreshold = config('contacts.memory_staleness_days', 30);
        $staleContacts = Contact::where('memory_freshness', '<', now()->subDays($staleThreshold))
            ->orWhereNull('memory_freshness')
            ->count();
            
        $conflictedContacts = Contact::whereHas('identifiers', fn($q) => $q->where('conflict_detected', true))
            ->orWhereHas('aliases', fn($q) => $q->where('confidence', '<', 0.7))
            ->count();

        $contactsByType = Contact::select('type', \DB::raw('count(*) as count'))
            ->groupBy('type')
            ->get();

        $replyModeDistribution = Contact::select('reply_mode_override', \DB::raw('count(*) as count'))
            ->groupBy('reply_mode_override')
            ->get();

        $importRates = \App\Models\ContactImportBatch::selectRaw('SUM(total_records) as total_records, SUM(imported_records) as imported_records, SUM(failed_records) as failed_records')
            ->first();

        $totalAnalysisCost = ContactAnalysisRun::whereNotNull('cost_metadata')->cursor()->sum(function ($run) {
            return $run->cost_metadata['total_cost'] ?? 0;
        });

        return response()->json([
            'data' => [
                'total_contacts' => $totalContacts,
                'stale_memory_count' => $staleContacts,
                'conflicted_contacts' => $conflictedContacts,
                'channel_distribution' => \DB::table('contact_messages')
                    ->select('channel', \DB::raw('count(*) as count'))
                    ->groupBy('channel')
                    ->get(),
                'contacts_by_type' => $contactsByType,
                'reply_mode_distribution' => $replyModeDistribution,
                'import_rates' => $importRates,
                'total_analysis_cost' => $totalAnalysisCost,
            ]
        ]);
    }
```
