# Implementation Plan: AI Models Hub

## Overview

Refactor `app/ai-models/page.tsx` from a monolithic file into a tabbed orchestrator with five dedicated tab components. All API communication uses the existing `lib/api/ai-models.ts` client. No backend changes are required.

## Tasks

- [x] 1. Scaffold component directory and refactor page.tsx into tab orchestrator
  - Create `app/ai-models/components/` with empty stub files: `ProvidersTab.tsx`, `IntentRoutingTab.tsx`, `HealthTab.tsx`, `AnalyticsTab.tsx`, `AuditTrailTab.tsx`
  - Refactor `page.tsx` to own `activeTab` state, render `AppLayout` with title "AI Model Gateway", render pill-style `NxTabs` with five tabs and icons, render conditional "Verify All" and "Add Provider" header buttons when `activeTab === 'providers'`, and mount `<ToastContainer>` fixed to `bottom-6 right-6`
  - Extract `useToast()` hook (manages `ToastMessage[]`, auto-dismisses after 4 s) and wire `addToast` as a prop to each tab
  - **Requirements:** 8.1, 8.2, 8.3, 8.4, 8.5, 8.6

- [x] 2. Implement ProvidersTab — provider list, skeleton, and empty states
  - On mount, call `aiProvidersApi.list()` and map into `ProviderWithState[]` seeding `syncedModels`, `testState: 'idle'`, `syncState: 'idle'`
  - While loading, render a grid of `<GridCardSkeleton>` placeholder cards
  - When providers array is empty after load, render `<NxEmptyState>` with "Add First Provider" CTA opening the add modal
  - Render provider grid (1-col mobile / 2-col md / 3-col lg) using `<ProviderCard>` for each provider
  - **Requirements:** 1.1, 1.2, 1.3

- [x] 3. Build ProviderCard component
  - Display all required fields: provider name, base URL (monospace), payload format badge, `NxStatusBadge` active/inactive, models endpoint, generate endpoint, auth header format, latency when `testState === 'success'`, synced model count
  - Render model chips from `syncedModels` limited to 6 by default with "show more / show less" toggle via local `modelsExpanded` boolean
  - Show `last_synced_at` timestamp when present
  - Render footer with `testState`/`syncState` status icon + text, "Sync Models" button, and "Ping" button
  - Render Edit and Delete icon buttons in the header row, and active/inactive toggle button
  - **Requirements:** 1.4, 2.5, 2.6, 2.7, 3.3, 3.4

- [x] 4. Build ProviderFormModal (add and edit modes)
  - Accept `mode: 'add' | 'edit'` and optional `initial: AiProvider`; render all fields (Provider Name required, Base URL required, Models Endpoint, Generate Endpoint, Test/Ping Endpoint, Auth Header Format, Payload Format dropdown, API Key password input)
  - In edit mode, pre-populate from `initial` and show "Leave blank to keep existing key." hint on the API key field
  - On submit call `aiProvidersApi.create()` or `aiProvidersApi.update()`; call `onSaved(provider)` on success; show inline error on failure
  - **Requirements:** 1.5, 1.6, 1.7

- [x] 5. Build DeleteConfirmModal
  - Show provider name and warning that all associated models and API keys will be removed
  - On confirm call `aiProvidersApi.delete(id)`; call `onDeleted(id)` on success; show inline error on failure
  - **Requirements:** 1.8

- [x] 6. Wire provider CRUD actions and toast feedback in ProvidersTab
  - "Add Provider" button → open add modal → on save prepend new `ProviderWithState` to list, fire success toast
  - Edit icon → open edit modal → on save splice updated record, fire success toast
  - Delete icon → open delete modal → on confirm filter from list, fire success toast
  - Toggle button → optimistically flip `is_active`, call `aiProvidersApi.toggleActive()`, roll back on rejection, fire success or error toast
  - **Requirements:** 1.7, 1.8, 1.9, 1.10, 1.11

- [x] 7. Implement Model Sync in ProvidersTab
  - On "Sync Models" click, set `syncState = 'syncing'`; call `aiProvidersApi.syncModels(id)`
  - On success, update `syncedModels` and `last_synced_at` in-place, set `syncState = 'done'`, fire success toast with synced count
  - On failure, set `syncState = 'error'`, fire error toast with the API failure message
  - **Requirements:** 2.1, 2.2, 2.3, 2.4, 2.7

- [x] 8. Implement Provider Health Testing (Ping) in ProvidersTab
  - On "Ping" click, set `testState = 'testing'`; call `aiProvidersApi.test(id)`
  - On success, set `testState = 'success'` and capture latency; card shows green checkmark, "Connected", and latency ms
  - On failure, set `testState = 'failed'`; card shows red X and "Unreachable"
  - Expose a `verifyAll` callback from `ProvidersTab`; when triggered from the page header button, call the Ping handler for all providers simultaneously
  - Reset `testState` to `'idle'` on list refresh
  - **Requirements:** 3.1, 3.2, 3.3, 3.4, 3.5, 3.6

- [x] 9. Implement IntentRoutingTab
  - On mount, call `intentRoutingApi.getMatrix()`; initialise `draftRoutes` from existing route assignments; render loading spinner; render `<NxEmptyState>` when intents array is empty
  - Render each intent as a card: intent name, "Configured" green badge if a route exists, provider dropdown, model dropdown filtered to the selected provider's models, and "Save" button
  - On provider dropdown change, update `draftRoutes[intent].provider` and clear model selection
  - On "Save", validate provider is selected (toast error "Select a provider before saving." if not); call `intentRoutingApi.updateRoute()`; fire success toast with intent name
  - **Requirements:** 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9

- [x] 10. Implement HealthTab
  - On mount call `aiHealthApi.getScorecard()`; handle loading (spinner + "Loading health data..."), API error (empty state with scheduler message), and empty-object (empty state with first-cycle message) states
  - Render health cards in a responsive grid; each card shows truncated provider ID, colour-coded status badge (healthy=green, degraded=yellow, offline=red), and average latency ms
  - **Requirements:** 5.1, 5.2, 5.3, 5.4, 5.5

- [x] 11. Implement AnalyticsTab
  - On mount call `aiCostApi.getForecast()`; render loading spinner while fetching
  - Render four metric cards: Current Spend, Monthly Limit, Remaining Budget, Forecasted Total (all in USD)
  - Render budget status banner with correct message per status (healthy / over_budget_predicted / budget_exceeded)
  - Render budget usage progress bar clamped to [0, 100]%; colour-code: ≤70% green, 70–90% yellow, >90% red
  - Render number input + "Save Budget" button; on click call `aiCostApi.setBudget(val)`, re-fetch forecast on success, fire success or error toast
  - **Requirements:** 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7

- [x] 12. Implement AuditTrailTab
  - On mount call `aiAuditApi.list({ limit: 100 })`; render loading spinner; render `<NxEmptyState>` when entries array is empty
  - Render filter buttons (All / Success / Failed / Fallback) and apply client-side filter logic
  - Render filtered entries in a scrollable table; each row: intent (or "—"), timestamp, colour-coded status dot, latency ms, "FALLBACK" pill when `fallback_triggered`, error type when present
  - **Requirements:** 7.1, 7.2, 7.3, 7.4, 7.5

- [x] 13. Write property-based and unit tests
  - Set up Vitest + fast-check if not present; create `app/ai-models/__tests__/` directory
  - PBT for Property 1 (provider list consistency): generate arbitrary arrays, simulate CRUD, assert length and field values
  - PBT for Property 4 (model chip count): generate providers with 0–50 models, assert `min(N, 6)` default and `N` expanded
  - PBT for Property 6 (audit filter correctness): generate entry arrays with random statuses, assert each filter predicate
  - PBT for Property 7 (budget progress bar bounds): generate arbitrary spend/limit pairs, assert pct ∈ [0,100] and correct colour
  - Unit tests for Properties 2, 3 (state machine transitions), 5 (intent route filter), 8 (toast auto-dismiss with fake timers), 9 (optimistic toggle rollback), 10 (Verify All coverage)
  - **Requirements:** All (correctness validation)

## Task Dependency Graph

```json
{
  "waves": [
    { "wave": 1, "tasks": [1] },
    { "wave": 2, "tasks": [2, 9, 10, 11, 12] },
    { "wave": 3, "tasks": [3, 4, 5] },
    { "wave": 4, "tasks": [6, 7, 8] },
    { "wave": 5, "tasks": [13] }
  ]
}
```

## Notes

- The existing `app/ai-models/page.tsx` already contains working implementations of most components. Tasks 2–12 are primarily about extracting that code into the new component files rather than writing from scratch, while ensuring each component strictly satisfies its requirements.
- The `ProviderWithState` type extension (adds `testState`, `syncState`, `latency`, `syncedModels` to `AiProvider`) lives in `ProvidersTab.tsx` or a collocated types file — it is not exported to the API layer.
- No changes to `lib/api/ai-models.ts` are required. All API types and client functions are already in place.
- Toast auto-dismiss duration is 4 000 ms (R8.5). Use the existing `NxToast` component from the shared library.
