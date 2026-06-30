# Design Document — NexusHub Dashboard

## Overview

This document describes the technical design for replacing `app/page.tsx` with a
production-quality dashboard. The implementation covers all twelve requirements: real-time
metrics via polling, live events via Reverb WebSocket, nine distinct panels, and a
responsive four/two/one-column grid system — all using `apiClient` and the existing
`Nx*` design-system components.

---

## Architecture

### High-Level Component Tree

```
app/page.tsx  (DashboardPage — "use client")
├── AppLayout
│   ├── NxNavRail
│   ├── NxTopBar / MobileHeader
│   └── NxStatusBar
├── SystemHealthStrip          ← Req 2
├── [error banner]             ← Req 1.5 / 2.9
├── KeyMetricsRow              ← Req 4
├── QuickActionsBar            ← Req 9
└── DashboardGrid              ← Req 12
    ├── AiUsagePanel           ← Req 5
    ├── ActiveAgentsJobsPanel  ← Req 6
    ├── CognitiveActivityFeed  ← Req 3
    ├── RecentContactsPanel    ← Req 7
    ├── ProactiveAiPanel       ← Req 10
    ├── MemoryHealthPanel      ← Req 8
    └── SchedulerOverviewPanel ← Req 11
```

---

## File Structure

```
app/
  page.tsx                          ← DashboardPage (replaces prototype)

components/dashboard/
  SystemHealthStrip.tsx             ← Req 2
  KeyMetricsRow.tsx                 ← Req 4
  QuickActionsBar.tsx               ← Req 9
  DashboardGrid.tsx                 ← Req 12 layout wrapper
  AiUsagePanel.tsx                  ← Req 5
  ActiveAgentsJobsPanel.tsx         ← Req 6
  CognitiveActivityFeed.tsx         ← Req 3
  RecentContactsPanel.tsx           ← Req 7
  ProactiveAiPanel.tsx              ← Req 10
  MemoryHealthPanel.tsx             ← Req 8
  SchedulerOverviewPanel.tsx        ← Req 11
  index.ts

hooks/
  useDashboardStats.ts              ← polling + visibility-aware (Req 1, 7)
  useDashboardHealth.ts             ← polling 30s (Req 2)
  useDashboardWebSocket.ts          ← Reverb subscription + reconnect (Req 3)
  useActivityFeed.ts                ← initial fetch + WS prepend + Load More (Req 3)
  useSchedulerCountdowns.ts         ← live countdown ticks (Req 11)
  useJobRetry.ts                    ← POST /api/v1/jobs/{id}/retry (Req 6.6)
  useMaintenanceAction.ts           ← POST /api/v1/memories/maintenance (Req 8.6, 9.6)

lib/api/dashboard.ts               ← typed API calls for dashboard endpoints

types/dashboard.ts                 ← all shared TypeScript interfaces
```

---

## Data Models

### TypeScript Interfaces (`types/dashboard.ts`)

```typescript
// --- Stats ---
export interface TrendIndicator {
  direction: 'up' | 'down' | 'neutral';
  delta: number;
}

export interface AiProviderRow {
  provider: string;
  tokens: number;
  cost_usd: number;
  rate_limit_pct: number;
}

export interface AiUsage {
  tokens_today: number;
  tokens_this_month: number;
  cost_today_usd: number;
  cost_this_month_usd: number;
  provider_breakdown: AiProviderRow[];
  top_model: string;
  tokens_history: { name: string; value: number }[];
}

export interface AgentEntry {
  id: string;
  name: string;
  role: string;
  status: 'online' | 'busy' | 'offline';
  token_usage: number;
  current_task: string | null;
}

export interface JobEntry {
  id: string;
  name: string;
  queue: string;
  status: 'pending' | 'running' | 'failed' | 'completed';
  progress_pct: number;
  started_at: string | null;
  failed_count: number;
}

export interface RecentContact {
  id: string;
  name: string;
  avatar_url: string | null;
  last_message_snippet: string;
  channel: 'whatsapp' | 'facebook' | 'email' | 'sms' | 'other';
  last_interaction_at: string;
  reply_mode: 'autopilot' | 'copilot' | 'manual';
}
```

```typescript
export interface MemoryHealth {
  total_records: number;
  low_confidence_count: number;
  expired_count: number;
  last_consolidation_at: string | null;
  confidence_distribution: { high: number; medium: number; low: number };
}

export interface ProactiveSuggestion {
  id: string;
  title: string;
  body: string;
  category: 'contact_insight' | 'task_recommendation' | 'memory_alert' | 'workflow_trigger';
  priority: 'high' | 'medium' | 'low';
  created_at: string;
}

export interface ScheduledEntry {
  id: string;
  name: string;
  fires_at: string;
  type: 'job' | 'reminder' | 'workflow';
  status: 'scheduled' | 'paused';
}

export interface DashboardStats {
  total_contacts: number;
  active_conversations: number;
  memories_stored: number;
  pending_tasks: number;
  running_agents: number;
  queued_jobs: number;
  trends: Record<string, TrendIndicator>;
  ai_usage: AiUsage;
  agents: AgentEntry[];
  jobs: JobEntry[];
  recent_contacts: RecentContact[];
  memory_health: MemoryHealth;
  proactive_suggestions: ProactiveSuggestion[];
  upcoming_scheduled: ScheduledEntry[];
}

// --- Health ---
export interface ServiceHealth {
  name: string;
  status: 'online' | 'degraded' | 'offline';
  latency_ms: number | null;
  error_rate: number | null;
}

export interface DashboardHealth {
  services: ServiceHealth[];
}

// --- Activity Feed ---
export interface ActivityEvent {
  id: string;
  hub: string;
  message: string;
  severity: 'info' | 'warning' | 'error';
  created_at: string;
}

export interface ActivityFeedResponse {
  data: ActivityEvent[];
  next_cursor: string | null;
}
```

---

## API Layer (`lib/api/dashboard.ts`)

```typescript
import apiClient from '@/lib/api/client';
import type {
  DashboardStats,
  DashboardHealth,
  ActivityFeedResponse,
} from '@/types/dashboard';

export const fetchDashboardStats = (): Promise<DashboardStats> =>
  apiClient.get('/v1/dashboard/stats').then(r => r.data);

export const fetchDashboardHealth = (): Promise<DashboardHealth> =>
  apiClient.get('/v1/dashboard/health').then(r => r.data);

export const fetchActivityFeed = (params?: { before?: string; limit?: number }): Promise<ActivityFeedResponse> =>
  apiClient.get('/v1/dashboard/activity-feed', { params }).then(r => r.data);

export const retryJob = (id: string): Promise<void> =>
  apiClient.post(`/v1/jobs/${id}/retry`).then(() => undefined);

export const triggerMaintenance = (contactId?: string): Promise<void> =>
  apiClient.post('/v1/memories/maintenance', contactId ? { contact_id: contactId } : {}).then(() => undefined);

export const approveSuggestion = (id: string): Promise<void> =>
  apiClient.post(`/v1/proactive-ai/suggestions/${id}/approve`).then(() => undefined);

export const dismissSuggestion = (id: string): Promise<void> =>
  apiClient.post(`/v1/proactive-ai/suggestions/${id}/dismiss`).then(() => undefined);
```

---

## Custom Hooks

### `useDashboardStats` (Req 1)

```typescript
// hooks/useDashboardStats.ts
// - Fetches GET /api/v1/dashboard/stats on mount
// - Polls every 60 000 ms using setInterval
// - Uses document.addEventListener('visibilitychange') to pause/resume interval
// - Returns: { stats, loading, error, refetch }
// - On error: stores error message, exposes refetch() for Retry button
// - On value change between cycles: emits changedKeys set for flash animation
```

State shape:
```typescript
{
  stats: DashboardStats | null;
  loading: boolean;
  error: string | null;
  changedKeys: Set<string>;   // keys whose value changed vs previous cycle
  refetch: () => void;
}
```

### `useDashboardHealth` (Req 2)

```typescript
// hooks/useDashboardHealth.ts
// - Fetches GET /api/v1/dashboard/health on mount
// - Polls every 30 000 ms
// - Computes effective badge color:
//     'offline'              → red
//     latency_ms > 2000      → amber (overrides reported status)
//     error_rate > 0.05      → amber (overrides reported status)
//     'degraded'             → amber
//     'online'               → green
//     fetch failed           → gray 'unknown'
// - Returns: { services, offlineServices, loading, error }
```

### `useDashboardWebSocket` (Req 3)

```typescript
// hooks/useDashboardWebSocket.ts
// - Subscribes to Echo.private(`dashboard.${userId}`) on mount
// - Unsubscribes on unmount
// - Reconnect strategy: uses Echo's built-in Pusher reconnection with
//   exponential backoff; exposes wsStatus: 'connected'|'reconnecting'|'disconnected'
// - Dispatches events to per-panel handlers via callback map:
//     'agent.updated'        → updateAgent(payload)
//     'job.updated'          → updateJob(payload)
//     'contact.updated'      → updateContact(payload)
//     'suggestion.created'   → prependSuggestion(payload)
//     'scheduler.job_added'  → insertScheduledEntry(payload)
//     'CognitiveEvent'       → prependFeedEvent(payload)
```

### `useActivityFeed` (Req 3)

```typescript
// hooks/useActivityFeed.ts
// - Calls fetchActivityFeed({ limit: 20 }) on mount
// - Accepts prependEvent(event) called by useDashboardWebSocket
// - Maintains events: ActivityEvent[] capped at 100 (splice oldest)
// - loadMore(): calls fetchActivityFeed({ before: cursor }) and appends
// - Returns: { events, wsStatus, loadMore, hasMore, loadingMore }
```

### `useSchedulerCountdowns` (Req 11)

```typescript
// hooks/useSchedulerCountdowns.ts
// - Accepts entries: ScheduledEntry[]
// - Maintains a setInterval tick every 60 000 ms
// - Computes countdown label: 'in X min' / 'in X hr' / 'Imminent'
// - Returns isImminent(entry): boolean  (fires_at within 5 min)
// - When any entry's fires_at passes, calls onExpired(id) callback
//   so DashboardPage can trigger a stats refetch
```

---

## Page Orchestration (`app/page.tsx`)

`DashboardPage` is a single `"use client"` component. It owns no panel-level state
directly — each panel component receives its slice of data as props, together with
mutation callbacks. This keeps the page as a thin orchestrator.

```
DashboardPage
  ├── useDashboardStats()          → stats, statsLoading, statsError, refetch, changedKeys
  ├── useDashboardHealth()         → services, offlineServices, healthLoading
  ├── useActivityFeed()            → events, wsStatus, loadMore, hasMore
  ├── useDashboardWebSocket()      → wires WS callbacks into the feed + local state mergers
  ├── local useState: suggestions  ← merged from stats + WS suggestion.created
  ├── local useState: contacts     ← merged from stats + WS contact.updated
  ├── local useState: agents       ← merged from stats + WS agent.updated
  ├── local useState: jobs         ← merged from stats + WS job.updated
  ├── local useState: scheduled    ← merged from stats + WS scheduler.job_added
  ├── useMaintenanceAction()       → triggerMaintenance, maintenancePending
  └── useToast()                   → toast helper
```

### Merge Strategy for WebSocket Updates

When a `job.updated` WebSocket event arrives:
1. `setJobs(prev => prev.map(j => j.id === payload.id ? { ...j, ...payload } : j))`
2. No API refetch is triggered — the in-place merge is sufficient.

The same pattern applies for `agent.updated` and `contact.updated`. New
`contact.updated` events for unknown contacts prepend and cap the list at 10.

---

## Components and Interfaces

### `SystemHealthStrip` (Req 2)

```
┌─ full-width strip ──────────────────────────────────────────────────────┐
│ [offline banner — dismissible]                                           │
│ MemoryHub ● ContactsHub ● AgentsHub ● AiModels ● Redis ● Pinecone ...  │
└─────────────────────────────────────────────────────────────────────────┘
```

Props: `services: ServiceHealth[]`, `loading: boolean`, `error: boolean`

- Maps each service → `NxStatusBadge` with computed effective color
- Wraps each badge in `NxTooltip` showing name, latency_ms, error_rate %
- Renders gray "unknown" badges when `error === true`
- Offline banner: `dismissible` state via local `useState<string[]>`
  tracking dismissed service names

### `KeyMetricsRow` (Req 4)

Props: `stats: DashboardStats | null`, `loading: boolean`, `changedKeys: Set<string>`

Six `NxMetricCard` instances in a `grid grid-cols-2 md:grid-cols-3 xl:grid-cols-6`.

Flash animation: a CSS class `animate-value-flash` (keyframes: background
flash from `rgba(var(--nexus-blue-rgb), 0.2)` to transparent over 600 ms)
is conditionally applied when the metric key is in `changedKeys`. The class
is removed after 600 ms via a `useEffect` timeout.

| Card              | Icon        | Color CSS var        |
|-------------------|-------------|----------------------|
| Total Contacts    | Users       | `--nexus-blue`       |
| Active Conversations | MessageCircle | `--nexus-teal`   |
| Memories Stored   | BrainCircuit | amber (`#F59E0B`)   |
| Pending Tasks     | CheckSquare | `--nexus-teal`       |
| Running Agents    | Cpu         | `--hedral-purple`    |
| Queued Jobs       | Layers      | `--success` green    |

### `QuickActionsBar` (Req 9)

Props: `maintenancePending: boolean`, `onTriggerMaintenance: () => void`,
`modalState: { importOpen; aiAnalysisOpen }`, `setModalState`

Five `NxActionButton` components in a `flex flex-wrap gap-3`.
All buttons are `disabled={maintenancePending}` while maintenance is in-flight.
"Trigger Maintenance" shows `NxThinkingIndicator` as its `leftIcon` during flight.

Two modal components rendered conditionally at page level:
- `NxImportModal` — controlled by `importOpen`
- `NxAiAnalysisModal` — controlled by `aiAnalysisOpen`

### `CognitiveActivityFeed` (Req 3)

Props: `events: ActivityEvent[]`, `wsStatus`, `loadMore`, `hasMore`, `loadingMore`

```
┌─ NxGlassCard ─────────────────────────────────────┐
│ Live Feed  ● connected / ↺ Reconnecting…           │
│ ┌─ event row (fade-slide in) ─────────────────────┐│
│ │ [hub icon] [message]  [severity badge] [time]   ││
│ └─────────────────────────────────────────────────┘│
│ ...                                                │
│ [Load more ↓]                                      │
└────────────────────────────────────────────────────┘
```

- Severity row background: `bg-red-500/10` (error), `bg-amber-500/10` (warning), transparent (info)
- Fade-slide animation: new items get class `animate-in fade-in slide-in-from-top-2 duration-300`
- Each event is `React.memo`-ized with stable `key={event.id}`
- "Reconnecting…" shown when `wsStatus === 'reconnecting'`

### `AiUsagePanel` (Req 5)

Props: `aiUsage: AiUsage | null`, `loading: boolean`

Layout: two-column sub-grid inside `NxGlassCard`
- Left: cost headline (`cost_today_usd`, `cost_this_month_usd`), top model label
- Right: `DashboardChart` (area chart) with `tokens_history` data, `dataKey="value"`

Provider table rows: name / token count (`.toLocaleString()`) / cost / progress bar
- Progress bar: `<div style={{ width: `${rate_limit_pct}%` }}` with `bg-nexus-blue` fill
- Badge: `NxStatusBadge` label "Near Limit" (amber ≥80%) or "Rate Limited" (red ≥95%)

### `ActiveAgentsJobsPanel` (Req 6)

Props: `agents: AgentEntry[]`, `jobs: JobEntry[]`, `loading: boolean`,
`onRetryJob: (id: string) => void`

Two sections inside `NxGlassCard`:
1. Agent sub-section: maps `agents` → `NxAgentCard` (existing component, already in index)
2. Jobs sub-section: maps `jobs` → `NxQueuePill` (existing component, already in index)
   - Failed jobs get `className="border-red-500"` and a "Retry" `NxActionButton`

`NxAgentCard` and `NxQueuePill` are already exported from `@/components` — use as-is.

### `RecentContactsPanel` (Req 7)

Props: `contacts: RecentContact[]`, `loading: boolean`

Each row rendered as a `button` (for keyboard navigation) that calls
`router.push('/contacts/' + id)`.

Channel icon map:
```typescript
const CHANNEL_ICONS = {
  whatsapp:  <MessageCircle className="text-green-400" />,
  facebook:  <Facebook className="text-blue-500" />,
  email:     <Mail className="text-nexus-blue" />,
  sms:       <Phone className="text-amber-400" />,
  other:     <Globe className="text-gray-400" />,
};
```

Reply-mode badge colors: `autopilot` → green, `copilot` → amber, `manual` → gray.

Relative timestamps via `formatDistanceToNow` from `date-fns` (already used in the
codebase pattern; if not installed, use a local `timeAgo(isoString)` utility).

### `MemoryHealthPanel` (Req 8)

Props: `memoryHealth: MemoryHealth | null`, `loading: boolean`,
`onRunMaintenance: () => void`, `maintenancePending: boolean`

Confidence distribution rendered as a horizontal stacked bar:
```
[■■■■■■■■ high (green)] [■■■ medium (amber)] [■ low (red)]
```
Each segment width proportional to its count relative to `total_records`.

`last_consolidation_at` formatted with `formatDistanceToNow` + "ago" suffix, or "Never run".

### `ProactiveAiPanel` (Req 10)

Props: `suggestions: ProactiveSuggestion[]`, `loading: boolean`,
`onApprove: (id) => void`, `onDismiss: (id) => void`

Category icon map:
```typescript
const CATEGORY_ICONS = {
  contact_insight:      <Users />,
  task_recommendation:  <CheckSquare />,
  memory_alert:         <BrainCircuit />,
  workflow_trigger:     <GitMerge />,
};
```

Priority badge: `high` → red `NxStatusBadge`, `medium` → amber, `low` → gray.

Header count badge: `<span className="ml-2 px-2 py-0.5 rounded-full bg-white/10 text-xs">{suggestions.length}</span>`

### `SchedulerOverviewPanel` (Req 11)

Props: `entries: ScheduledEntry[]`, `loading: boolean`,
`countdowns: Record<string, string>`, `isImminent: (id: string) => boolean`

Type icon map:
```typescript
const TYPE_ICONS = { job: <Layers />, reminder: <Bell />, workflow: <GitMerge /> };
```

Countdown label in amber when `isImminent(entry.id)` is true.

---

## Responsive Grid Layout (Req 12)

Implemented via a single Tailwind CSS grid in `DashboardGrid.tsx`:

```tsx
<div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
  {/* Key Metrics — full width all breakpoints */}
  <div className="col-span-1 md:col-span-2 xl:col-span-4">
    <KeyMetricsRow ... />
  </div>

  {/* Quick Actions — full width all breakpoints */}
  <div className="col-span-1 md:col-span-2 xl:col-span-4">
    <QuickActionsBar ... />
  </div>

  {/* AI Usage Panel — 2 cols on xl */}
  <div className="col-span-1 md:col-span-1 xl:col-span-2">
    <AiUsagePanel ... />
  </div>

  {/* Active Agents & Jobs — 2 cols on xl */}
  <div className="col-span-1 md:col-span-1 xl:col-span-2">
    <ActiveAgentsJobsPanel ... />
  </div>

  {/* Activity Feed — 2 cols on xl */}
  <div className="col-span-1 md:col-span-2 xl:col-span-2">
    <CognitiveActivityFeed ... />
  </div>

  {/* Recent Contacts — 1 col on xl */}
  <div className="col-span-1 md:col-span-1 xl:col-span-1">
    <RecentContactsPanel ... />
  </div>

  {/* Proactive AI — 1 col on xl */}
  <div className="col-span-1 md:col-span-1 xl:col-span-1">
    <ProactiveAiPanel ... />
  </div>

  {/* Memory Health — 1 col on xl */}
  <div className="col-span-1 md:col-span-1 xl:col-span-1">
    <MemoryHealthPanel ... />
  </div>

  {/* Scheduler — 1 col on xl */}
  <div className="col-span-1 md:col-span-1 xl:col-span-1">
    <SchedulerOverviewPanel ... />
  </div>
</div>
```

Breakpoint thresholds match requirements (768 px → `md:`, 1280 px → `xl:`).
The `SystemHealthStrip` is rendered outside and above the grid, spanning full width.

---

## Data Flow Diagram

```
Browser mount
  │
  ├─► useDashboardStats ──► GET /v1/dashboard/stats
  │       │  ↺ 60s poll (paused when tab hidden)
  │       └─► stats → KeyMetricsRow, AiUsagePanel, ActiveAgentsJobsPanel,
  │                    RecentContactsPanel, MemoryHealthPanel,
  │                    ProactiveAiPanel, SchedulerOverviewPanel
  │
  ├─► useDashboardHealth ─► GET /v1/dashboard/health
  │       │  ↺ 30s poll
  │       └─► services → SystemHealthStrip
  │
  ├─► useActivityFeed ────► GET /v1/dashboard/activity-feed (20 items)
  │       └─► events → CognitiveActivityFeed
  │
  └─► useDashboardWebSocket ─► Echo.private('dashboard.{userId}')
          │
          ├─ CognitiveEvent     → prepend to events (useActivityFeed)
          ├─ agent.updated      → merge into local agents state
          ├─ job.updated        → merge into local jobs state
          ├─ contact.updated    → merge/prepend into local contacts state
          ├─ suggestion.created → prepend into local suggestions state
          └─ scheduler.job_added → insert into local scheduled state
```

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| Stats fetch fails | Inline error banner with "Retry" button below metrics row; no zeroed values |
| Health fetch fails | All badges rendered gray with "unknown" label |
| Activity feed fails | `NxEmptyState` with error message in feed panel |
| WebSocket drops | "Reconnecting…" overlay in feed panel; Echo reconnects with exponential backoff |
| Job retry fails | `NxToast` with error severity + returned message |
| Maintenance 4xx/5xx | `NxToast` with error severity (Req 9.10, 8.7 path) |
| Suggestion approve/dismiss fails | `NxToast` with error; card stays visible |

All API calls through `apiClient` — error messages extracted from `ApiError.message`
(already set by the Axios interceptor in `lib/api/client.ts`).

---

## Performance Considerations

- All panel components are `React.memo`-ized to prevent re-renders when unrelated
  state slices change.
- `useMemo` applied to derived values: effective badge color computation in
  `SystemHealthStrip`, stacked bar widths in `MemoryHealthPanel`.
- Activity feed rows are individually `React.memo`-ized with `key={event.id}`.
- No virtual scrolling needed — feed is capped at 100 items, well within DOM limits.
- Polling intervals are cleared on unmount via `useEffect` cleanup returns.
- WebSocket subscription is established once; only the callback map is updated via
  `useRef` to avoid re-subscribing on every render.

---

## Correctness Properties

These properties can be validated with a PBT framework (e.g., `fast-check`):

### Property 1: Stats Polling Respects Visibility

*For any* sequence of `visibilitychange` events, the polling interval is active if
and only if `document.visibilityState === 'visible'`. No fetch to `/v1/dashboard/stats`
is issued while the tab is hidden.

**Validates: Requirements 1.7, 1.8**

---

### Property 2: Activity Feed Cap Invariant

*For any* sequence of prepend operations via WebSocket or `fetchActivityFeed`,
`events.length ≤ 100` always holds after each operation. The oldest entries are
discarded when the cap is exceeded.

**Validates: Requirements 3.4**

---

### Property 3: Health Badge Color Dominance

*For any* `ServiceHealth` entry, if `status === 'offline'` then `effectiveColor === 'red'`.
If `latency_ms > 2000` or `error_rate > 0.05` then `effectiveColor !== 'green'`,
regardless of the `status` field value.

**Validates: Requirements 2.3, 2.4, 2.5**

---

### Property 4: Scheduler Countdown Ordering

*For any* tick and *for any* `scheduler.job_added` WebSocket event, the rendered
`ScheduledEntry` list is always sorted ascending by `fires_at` and `count ≤ 3`.

**Validates: Requirements 11.2, 11.8**

---

### Property 5: Contact List Cap After WebSocket Updates

*For any* sequence of `contact.updated` WebSocket events, `contacts.length ≤ 10`
always holds. When a new unknown contact arrives that would push the count to 11,
the oldest entry is removed.

**Validates: Requirements 7.8**

---

### Property 6: Quick Actions Lockout During Maintenance

*For any* state where `maintenancePending === true`, all five `NxActionButton`
elements in the Quick Actions Bar have `disabled === true`. No action can be
triggered concurrently with an in-flight maintenance call.

**Validates: Requirements 9.8**

---

### Property 7: Suggestion Removal After Action

*For any* successful `approve` or `dismiss` call for suggestion with id `X`,
`X` does not appear in the rendered suggestion list immediately after the API
response resolves — with no page reload required.

**Validates: Requirements 10.5, 10.6**

---

### Property 8: Metric Flash Is Transient

*For any* metric key that enters `changedKeys`, the flash CSS class is absent
from the DOM element after 600 ms, regardless of subsequent re-renders.

**Validates: Requirements 4.11**

## Testing Strategy

### Unit Tests (Jest + React Testing Library)

- `useDashboardStats`: mock `apiClient`, assert polling interval starts/stops
  on visibility events, assert error state is set on HTTP error.
- `useDashboardHealth`: assert effective badge color derivation logic for all
  combinations of `status`, `latency_ms`, and `error_rate`.
- `useActivityFeed`: assert 100-event cap, prepend ordering, Load More cursor.
- `useSchedulerCountdowns`: assert countdown labels, imminent detection, and
  expiry callback fires.

### Integration Tests

- `SystemHealthStrip`: renders gray badges when health fetch errors.
- `CognitiveActivityFeed`: new WS event appears at top with correct severity
  background.
- `ActiveAgentsJobsPanel`: "Retry" button calls `POST /v1/jobs/{id}/retry` and
  updates job status to `pending` on success.
- `QuickActionsBar`: all buttons disabled while maintenance is in-flight.

### Property-Based Tests (fast-check)

See Correctness Properties section. Each property is an `fc.property` test
run with 100+ random inputs covering edge cases for state mutation logic.

---

## Accessibility

- `SystemHealthStrip` badges include `aria-label="{name}: {effectiveStatus}"`.
- `CognitiveActivityFeed` uses `aria-live="polite"` on the list container so screen
  readers announce new events.
- All `NxActionButton` elements have descriptive labels; the "Trigger Maintenance"
  button uses `aria-busy={maintenancePending}`.
- Contact rows rendered as `<button>` ensure keyboard navigation and focus management.
- Color is never the sole differentiator — severity rows also use distinct icons.

---

## Animation Additions to `globals.css`

```css
@keyframes value-flash {
  0%   { background-color: rgba(0, 122, 255, 0.2); }
  100% { background-color: transparent; }
}

.animate-value-flash {
  animation: value-flash 600ms ease-out forwards;
}
```

This is the only addition needed beyond the existing Nexus glassmorphism stylesheet.
The `animate-in`, `fade-in`, `slide-in-from-top-2` classes used by the activity feed
are already provided by `tailwindcss-animate` (referenced in `tailwind.config`).
