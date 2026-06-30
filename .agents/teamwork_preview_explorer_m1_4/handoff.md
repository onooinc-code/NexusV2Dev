# Handoff Report

## 1. Observation
- `ContactController::hubAnalytics()` currently uses potentially dangerous methods for summing analysis costs: `ContactAnalysisRun::whereNotNull('cost_metadata')->get()->sum(...)`, which fetches all records into memory (OOM risk).
- The `staleContacts` query does not match the actual logic from `staleMemory()` (it ignores the config fallback and `orWhereNull`).
- The `conflictedContacts` query does not match the logic from `conflicts()` (it omits the check for aliases confidence).
- `importRates` uses `DATE(created_at)` and `GROUP BY date`, causing an SQL dialect error in certain drivers.
- `ContactImportBatch` model defines the attributes `total_records`, `imported_records`, and `failed_records`.

## 2. Logic Chain
- To fix the OOM issue, we replace `get()` with `cursor()` which iterates over a `LazyCollection`, retrieving models iteratively without loading everything into memory.
- To fix the logical inconsistencies, we sync `$staleContacts` with `staleMemory()` by using `config('contacts.memory_staleness_days', 30)` and `->orWhereNull('memory_freshness')`.
- We sync `$conflictedContacts` with `conflicts()` by appending `->orWhereHas('aliases', fn($q) => $q->where('confidence', '<', 0.7))`.
- To fix the SQL dialect error, we simplify `importRates` to fetch the sum of `total_records`, `imported_records`, and `failed_records` without grouping.

## 3. Caveats
- `ContactAnalysisRun::cursor()` is memory-safe but will still issue a query that retrieves columns one-by-one. In a very large table, performing a direct SQL aggregate on the JSON field might be marginally faster, but `cursor()` maintains strict DB-agnostic behavior, which fulfills the user's requirement cleanly.

## 4. Conclusion
The implementation of `hubAnalytics()` has been rewritten to fix the OOM vulnerability, align the statistical counts with the respective dedicated endpoints, and prevent SQL dialect issues.

## 5. Verification Method
- Code Review: Confirm `cursor()` is used for `ContactAnalysisRun`.
- Code Review: Confirm `$staleContacts` and `$conflictedContacts` have the correct `orWhere...` clauses.
- Code Review: Confirm `$importRates` computes simple sums.
- Run tests: `./vendor/bin/phpunit --filter ContactControllerTest` (or equivalent) to ensure the API endpoint still functions without exceptions.

---

### Implementation Plan & Code Block

**Target File**: `Nexus-backend/app/Http/Controllers/ContactController.php`

**Implementation:**
```php
    public function hubAnalytics(Request $request)
    {
        $this->authorize('viewAny', Contact::class);
        $totalContacts = Contact::count();
        
        $staleContacts = Contact::where('memory_freshness', '<', now()->subDays(config('contacts.memory_staleness_days', 30)))
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

        $importRates = [
            'total_records' => (int) \App\Models\ContactImportBatch::sum('total_records'),
            'imported_records' => (int) \App\Models\ContactImportBatch::sum('imported_records'),
            'failed_records' => (int) \App\Models\ContactImportBatch::sum('failed_records'),
        ];

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
