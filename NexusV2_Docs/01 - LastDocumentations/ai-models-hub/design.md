# Design Document

## AI Models Hub

## Overview

AIModelsHub (`/ai-models`) is a fully client-rendered Next.js page that wraps all AI infrastructure management behind a single tabbed interface. The page is built with the existing `AppLayout` shell, relies on the shared `NxTabs` component for navigation, and delegates each domain area to a dedicated sub-component file under `app/ai-models/components/`. All API communication runs through the existing `lib/api/ai-models.ts` client. No new backend routes or API client changes are required.

---

## Architecture

#### Page Structure

```
app/ai-models/
├── page.tsx                  ← orchestrator: tab state, header actions, toast wiring
└── components/
    ├── ProvidersTab.tsx       ← Requirement 1, 2, 3 (providers, sync, ping)
    ├── IntentRoutingTab.tsx   ← Requirement 4
    ├── HealthTab.tsx          ← Requirement 5
    ├── AnalyticsTab.tsx       ← Requirement 6
    └── AuditTrailTab.tsx      ← Requirement 7
```

The current `app/ai-models/page.tsx` is a monolithic ~1 400-line file. The refactor extracts each functional area into its own component while keeping the data-fetching hooks and local state co-located with each tab so no global state management is introduced.

#### Shared Utilities (page-level, not exported)

| Utility | Purpose |
|---|---|
| `useToast()` | Local hook — manages a `ToastMessage[]` array, auto-dismisses after 4 s, exposes `addToast(type, msg)` and `dismiss(id)` |
| `ToastContainer` | Fixed-position `bottom-6 right-6` stack of `NxToast` components |
| `ProviderWithState` | Extends `AiProvider` with `testState`, `syncState`, `latency`, and `syncedModels` runtime fields |

---

## Components and Interfaces

### Component Design

#### `page.tsx` — Page Orchestrator

Responsibilities:
- Owns `activeTab: Tab` state (`'providers' | 'routing' | 'health' | 'analytics' | 'audit'`).
- Owns the `useToast()` instance and passes `addToast` down as a prop to each tab.
- Renders `AppLayout` with the title "AI Model Gateway".
- Renders the `NxTabs` component in `pills` variant (nexus-blue active highlight per R8.4).
- Conditionally renders "Verify All" and "Add Provider" buttons in the header when `activeTab === 'providers'` (R8.3).
- Renders `<ToastContainer>` fixed to `bottom-6 right-6` (R8.5).
- Passes a `onVerifyAll` callback down to `ProvidersTab` so the header button can trigger the bulk ping.

```tsx
// Tab definition (R8.2)
const TABS: NxTabItem[] = [
  { id: 'providers', label: 'Providers & Models', icon: <Server /> },
  { id: 'routing',   label: 'Intent Routing',     icon: <ChevronRight /> },
  { id: 'health',    label: 'Health',              icon: <Activity /> },
  { id: 'analytics', label: 'Analytics',           icon: <DollarSign /> },
  { id: 'audit',     label: 'Audit Trail',         icon: <ClipboardList /> },
];
```

---

#### `ProvidersTab.tsx`

Covers: Provider Management (R1), Model Sync (R2), Provider Health Testing (R3).

**Local state:**

```ts
providers: ProviderWithState[]      // merged AiProvider + runtime fields
loading: boolean                    // initial page load skeleton
showAddModal: boolean
editTarget: AiProvider | null
deleteTarget: AiProvider | null
```

**Data flow:**

1. On mount → `aiProvidersApi.list()` → map into `ProviderWithState[]`, seeding `syncedModels` from `provider.models ?? []`.
2. "Add Provider" → open `ProviderFormModal` in `add` mode → on save, prepend new record to `providers`.
3. "Edit" icon → open `ProviderFormModal` in `edit` mode → on save, splice updated record.
4. "Delete" icon → open `DeleteConfirmModal` → on confirm, filter from list.
5. "Toggle active" → optimistic update, call `aiProvidersApi.toggleActive()`, roll back on error.
6. "Ping" → set `testState = 'testing'`, call `aiProvidersApi.test(id)` → set `success`/`failed` + latency.
7. "Verify All" (exposed via `verifyAllRef` callback) → call Ping for all providers simultaneously.
8. "Sync Models" → set `syncState = 'syncing'`, call `aiProvidersApi.syncModels(id)` → update `syncedModels` in place.

**Child components:**

| Component | Purpose |
|---|---|
| `ProviderCard` | Renders a single `ProviderWithState` card (R1.4, R2.5–7, R3.3–4) |
| `ProviderFormModal` | Add/Edit form modal (R1.5–6) |
| `DeleteConfirmModal` | Confirmation modal (R1.8) |
| `GridCardSkeleton` (shared) | Skeleton placeholders while loading (R1.2) |
| `NxEmptyState` (shared) | Empty state with "Add First Provider" CTA (R1.3) |

**`ProviderCard` design:**

```
┌────────────────────────────────────────────────────────────┐
│ [base_url monospace]           [ACTIVE badge] [toggle] [✎] [🗑] │
│ Provider Name     [payload badge]                          │
│ ─────────────────────────────────────────────────────────  │
│ Models Endpoint   Generate Endpoint                        │
│ Auth Format       Latency                                  │
│ ─────────────────────────────────────────────────────────  │
│ 🗄 N models synced                  Last sync: dd/mm/yyyy  │
│ [chip] [chip] [chip] ... +N more ▾                        │
│ ─────────────────────────────────────────────────────────  │
│ [status icon] status text   [Sync Models] [Ping]           │
└────────────────────────────────────────────────────────────┘
```

Model chips limited to 6 by default; "show more / show less" toggle controlled by local `modelsExpanded` boolean (R2.5–6).

**State machine for `testState`:**

```
idle → testing → success
              ↘ failed
(resets to idle on list refresh)
```

**State machine for `syncState`:**

```
idle → syncing → done
              ↘ error
```

---

#### `IntentRoutingTab.tsx`

Covers: Intent Routing (R4).

**Local state:**

```ts
intents: { id: string; name: string }[]
providers: { id: string; name: string; models: { id: string; name: string }[] }[]
routes: IntentRoute[]
draftRoutes: Record<string, { provider: string; model: string }>  // intent → selection
saving: Record<string, boolean>
loading: boolean
```

**Data flow:**

1. On mount → `intentRoutingApi.getMatrix()` → populate all three slices.
2. Initialise `draftRoutes` from existing `routes` (pre-select current values).
3. Provider dropdown change → update `draftRoutes[intent].provider`, clear model selection.
4. Model dropdown is filtered: only models whose `provider_id` matches selected provider.
5. "Save" per intent → validate provider selected (R4.8 toast if not) → `intentRoutingApi.updateRoute()`.

**Layout:**

Responsive grid of intent cards (1-col mobile, 2-col md, 3-col lg). Each card:

```
┌─────────────────────────────────┐
│ Intent Name    [Configured ✓]   │
│ Provider ▾  [provider dropdown] │
│ Model ▾     [model dropdown]    │
│                         [Save]  │
└─────────────────────────────────┘
```

"Configured" badge rendered when `routes` contains a record for the intent (R4.6).

---

#### `HealthTab.tsx`

Covers: Provider Health Monitoring (R5).

**Local state:**

```ts
scorecard: Record<string, ProviderHealthRecord> | null
loading: boolean
error: boolean
```

**Data flow:** Single `useEffect` → `aiHealthApi.getScorecard()` → populate. No auto-refresh on the frontend; backend scheduler handles 5-min updates (R5.6).

**Render states:**
- Loading → centered spinner + "Loading health data..." (R5.2)
- API error → `NxEmptyState` with "scheduler must be running" message (R5.3)
- Empty object → `NxEmptyState` noting first polling cycle (R5.4)
- Data → responsive grid of health cards (1-col → 2-col → 3-col)

**Health card:**

```
┌──────────────────────┐
│ [provider_id[:8]…]   │
│ [HEALTHY/DEGRADED/…] │
│ 142 ms avg           │
└──────────────────────┘
```

Status badge colours: `healthy` → green, `degraded` → yellow, `offline` → red (R5.5).

---

#### `AnalyticsTab.tsx`

Covers: Cost Analytics (R6).

**Local state:**

```ts
forecast: CostForecast | null
loading: boolean
budgetInput: string
saving: boolean
```

**Data flow:**

1. On mount and after budget save → `aiCostApi.getForecast()`.
2. "Save Budget" → parse float, validate > 0 → `aiCostApi.setBudget(val)` → re-fetch forecast.

**Layout:**

```
[Status Banner]
────────────────────────────────────────
[Current Spend] [Monthly Limit] [Remaining] [Forecasted Total]
────────────────────────────────────────
[Budget usage progress bar — colour coded]
────────────────────────────────────────
Budget limit input: [_____] [Save Budget]
```

Progress bar colour rules (R6.4):
- ≤ 70% → `bg-green-500`
- 70–90% → `bg-yellow-500`
- > 90% → `bg-red-500`

Banner messages (R6.5):
- `healthy` → "Budget on track"
- `over_budget_predicted` → "On track to exceed budget this month"
- `budget_exceeded` → "Budget Exceeded — requests may be blocked"

Metric cards use `NxGlassCard` with a 2×2 grid (sm) / 4-col row (md+).

---

#### `AuditTrailTab.tsx`

Covers: Audit Trail (R7).

**Local state:**

```ts
entries: AiAuditEntry[]
loading: boolean
filter: 'all' | 'success' | 'failed' | 'fallback'
```

**Data flow:** On mount → `aiAuditApi.list({ limit: 100 })`. Filter is applied client-side.

**Filter logic:**

```ts
const filtered = entries.filter(e => {
  if (filter === 'all')      return true;
  if (filter === 'fallback') return e.fallback_triggered;
  return e.status === filter;
});
```

**Audit entry row:**

```
[intent or —]   [timestamp]   [● SUCCESS]   [142ms]   [FALLBACK?]   [error_type?]
```

Status dot colours: `success` → green, `failed` → red, other → yellow (R7.5).

Rendered as a scrollable `NxTable` (existing shared component). Fallback badge is a small pill only visible when `fallback_triggered === true`.

---

## Data Models

### Data Types

All types are already defined in `lib/api/ai-models.ts` and consumed as-is. No new type definitions are needed.

Key types used per component:

| Component | Types |
|---|---|
| ProvidersTab | `AiProvider`, `AiModel`, `ProviderWithState` (local extension) |
| IntentRoutingTab | `IntentRoute` |
| HealthTab | `ProviderHealthRecord` |
| AnalyticsTab | `CostForecast` |
| AuditTrailTab | `AiAuditEntry` |

---

### API Mapping

| Action | API Call |
|---|---|
| Load providers | `GET /ai/providers` via `aiProvidersApi.list()` |
| Create provider | `POST /ai/providers` via `aiProvidersApi.create()` |
| Update provider | `PUT /ai/providers/{id}` via `aiProvidersApi.update()` |
| Delete provider | `DELETE /ai/providers/{id}` via `aiProvidersApi.delete()` |
| Toggle active | `PATCH /ai/providers/{id}/toggle-active` via `aiProvidersApi.toggleActive()` |
| Ping provider | `POST /ai/providers/{id}/test` via `aiProvidersApi.test()` |
| Sync models | `POST /ai/providers/{id}/sync-models` via `aiProvidersApi.syncModels()` |
| Load routing matrix | `GET /ai/intents/routing` via `intentRoutingApi.getMatrix()` |
| Save intent route | `PUT /ai/intents/routing` via `intentRoutingApi.updateRoute()` |
| Load health scorecard | `GET /ai/providers/health` via `aiHealthApi.getScorecard()` |
| Load cost forecast | `GET /ai/cost/forecast` via `aiCostApi.getForecast()` |
| Set monthly budget | `POST /ai/cost/budget` via `aiCostApi.setBudget()` |
| Load audit trail | `GET /ai/audit-trail?limit=100` via `aiAuditApi.list()` |

---

## Error Handling

### Error Handling Strategy

All API calls follow this pattern:

```ts
try {
  const res = await api.call();
  // update local state
  addToast('success', 'Descriptive success message');
} catch (err) {
  addToast('error', err?.message ?? 'Fallback error message');
}
```

Toast auto-dismiss is 4 seconds (R8.5). Toasts are rendered via `ToastContainer` fixed to `bottom-6 right-6`.

Optimistic updates (toggle active only) roll back on failure.

---

### Shared Component Usage

| Shared Component | Used In |
|---|---|
| `AppLayout` | `page.tsx` |
| `NxTabs` (pills variant) | `page.tsx` |
| `NxGlassCard` | All tab components |
| `NxActionButton` | `page.tsx` header, `ProvidersTab` card footer |
| `NxEmptyState` | `ProvidersTab`, `HealthTab`, `IntentRoutingTab` |
| `NxStatusBadge` | `ProvidersTab` ProviderCard |
| `NxToast` | `ToastContainer` (local) |
| `NxTable` | `AuditTrailTab` |
| `NxSelect` | `IntentRoutingTab` dropdowns |
| `GridCardSkeleton` | `ProvidersTab` loading state |

---

## Correctness Properties

The following properties define the observable invariants the implementation must satisfy. They are suitable for property-based testing.

### Property 1: Provider list consistency

After any CRUD operation (create, update, delete), the in-memory `providers` array must reflect the change. After create, `providers.length` increases by 1. After delete, it decreases by 1. After update, the record with the matching `id` has the new field values.

**Validates: Requirements 1.7, 1.8**

### Property 2: Sync state exclusivity

For any provider, only one of `{ idle, syncing, done, error }` can be active at a time. `syncState` never transitions from `done` or `error` back to `syncing` without first returning to `idle`.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

### Property 3: Test state exclusivity

Same as Property 2 for `testState` values `{ idle, testing, success, failed }`.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

### Property 4: Model chip count invariant

When a provider has `N` synced models, the card shows exactly `min(N, 6)` chips by default. When expanded, it shows exactly `N` chips.

**Validates: Requirements 2.5, 2.6**

### Property 5: Intent route filter

The routing matrix never shows model options from a provider other than the one currently selected in the provider dropdown for that intent.

**Validates: Requirements 4.4, 4.5**

### Property 6: Audit filter correctness

When `filter === 'success'`, every visible entry has `status === 'success'`. When `filter === 'fallback'`, every visible entry has `fallback_triggered === true`. When `filter === 'all'`, visible count equals total loaded count.

**Validates: Requirements 7.4, 7.5**

### Property 7: Budget progress bar bounds

The computed `pct` value is always clamped to `[0, 100]`. The bar colour is always one of green/yellow/red with no overlap in thresholds.

**Validates: Requirements 6.4, 6.5**

### Property 8: Toast auto-dismiss

Every toast added via `addToast()` is removed from the list exactly 4 000 ms after insertion, regardless of how many other toasts are added concurrently.

**Validates: Requirements 8.5**

### Property 9: Optimistic toggle rollback

If `aiProvidersApi.toggleActive()` rejects, the provider's `is_active` value in `providers` returns to its pre-toggle value.

**Validates: Requirements 1.9, 1.10**

### Property 10: Verify All coverage

When "Verify All" is triggered, `aiProvidersApi.test()` is called exactly once for every provider currently in the `providers` array, with no duplicate calls and no providers skipped.

**Validates: Requirements 3.5**


---

## Testing Strategy

Property-based tests (PBT) will be written using **Vitest** + **fast-check**, co-located in `app/ai-models/__tests__/`. Each correctness property maps directly to a test:

| Property | Test approach |
|---|---|
| P1 — Provider list consistency | Generate arbitrary provider arrays; simulate create/update/delete operations; assert array length and record fields after each mutation |
| P2 — Sync state exclusivity | Use a state machine model; generate random event sequences; assert only one state is active at any point |
| P3 — Test state exclusivity | Same approach as P2 |
| P4 — Model chip count invariant | Generate providers with 0–50 models; assert `min(N, 6)` chips shown by default and `N` when expanded |
| P5 — Intent route filter | Generate routing matrix data; assert model options in dropdown are always a subset of the selected provider's models |
| P6 — Audit filter correctness | Generate audit entry arrays with random statuses; apply each filter; assert all resulting entries satisfy the filter predicate |
| P7 — Budget progress bar bounds | Generate arbitrary `current_spend` / `monthly_limit` pairs including edge cases (0, negative, equal, very large); assert `pct ∈ [0,100]` and correct colour bucket |
| P8 — Toast auto-dismiss | Mock timers; add N toasts; advance clock by 4 000 ms; assert all are removed |
| P9 — Optimistic toggle rollback | Stub `toggleActive` to reject; fire toggle; assert `is_active` returns to original value |
| P10 — Verify All coverage | Generate provider arrays of length 1–20; call verifyAll; assert `test()` stub called once per provider with no duplicates |

Unit tests for pure helper functions (filter logic, progress-bar colour selection, timestamp formatting) will be written as standard deterministic tests alongside the property tests.
