# Workflows Hub — Design Document

## Overview

WorkflowsHub is a real-time workflow orchestration canvas built as a Next.js Client Component at `app/workflows/page.tsx`. It provides three integrated experiences in a single page:

1. **Browse** — a sidebar list of all workflow pipelines fetched from the backend.
2. **Visualize** — a horizontal node-graph canvas showing each pipeline's steps as typed, status-aware nodes connected by lines.
3. **Operate** — trigger executions, watch them stream live via Laravel Reverb/Echo WebSocket, handle human approval gates, and read a full execution trace log.

The page deliberately keeps all state local to the route component (no Zustand store for page-level concerns), relying on `useWebSocket()` for the Echo instance and `apiClient` for all HTTP calls. The `useWorkflowsStore` Zustand store exists but is not currently wired into this page; the design keeps the local state approach to minimize coupling.

---

## Architecture

### Component Tree

```
app/workflows/page.tsx  (WorkflowsPage — all local state lives here)
│
├── AppLayout                      # nav rail, top bar, status bar, notification drawer
│   └── <page content>
│       ├── PageHeader             # inline — title, WS badge, Refresh / New Workflow / Execute buttons
│       └── Three-Panel Grid
│           ├── WorkflowSidebar    # inline — NxGlassCard wrapping workflow buttons + NxEmptyState
│           ├── WorkflowCanvas     # inline — node row with NxWorkflowNode instances + connectors
│           └── ExecutionTracer    # inline — NxGlassCard with realtime logs, step logs, approval CTA
│
├── NxModal (Create Workflow)      # controlled by isModalOpen
│   └── form: NxInput + NxSelect + NxActionButton
│
└── NxApprovalGateModal            # controlled by showApprovalModal + execution != null
```

### Data Flow

```
mount
  └─► fetchWorkflows() → GET /workflows?limit=50
        └─► setWorkflows(list), auto-select first

select workflow
  └─► fetchProgress(id) → GET /workflows/{id}/progress
        └─► setExecution(latest_execution)
              └─► if paused+approval → setShowApprovalModal(true)

execute workflow
  └─► POST /workflows/{id}/execute
        └─► setExecution(response)
        └─► fetchProgress(id)

WebSocket connected
  └─► echo.private('workflow.{id}')
        ├─► .workflow.started        → append log line, fetchProgress
        ├─► .workflow.step_completed → append log line, optimistic step patch
        │     └─► if status=paused  → fetchProgress, setShowApprovalModal(true)
        ├─► .workflow.completed      → append log, patch execution.status
        └─► .workflow.failed         → append log, patch execution.status

WebSocket disconnected (fallback)
  └─► setInterval(fetchProgress, 2500ms)
        └─► stops when execution is terminal

approval gate
  └─► NxApprovalGateModal
        ├─► approve → POST /executions/{id}/resume { decision: 'approve' }
        └─► deny    → POST /executions/{id}/resume { decision: 'deny' }
              └─► setExecution(response), setShowApprovalModal(false)
```

---

## Components and Interfaces

### WorkflowsPage (page.tsx)

The single route component. Owns all local state and orchestrates child regions.

**Local state**

| Variable | Type | Purpose |
|---|---|---|
| `workflows` | `WorkflowItem[]` | All workflows fetched from the API |
| `selectedId` | `string\|number\|null` | Currently selected workflow ID |
| `execution` | `WorkflowExecution\|null` | Latest execution for the selected workflow |
| `isLoading` | `boolean` | Workflow list loading indicator |
| `isRunning` | `boolean` | Execute button spinner |
| `isModalOpen` | `boolean` | Create-workflow modal visibility |
| `showApprovalModal` | `boolean` | Approval gate modal visibility |
| `newName` | `string` | Create-modal name field |
| `newTrigger` | `string` | Create-modal trigger-type field |
| `realtimeLogs` | `string[]` | WebSocket-sourced log lines (newest first) |
| `wsConnected` | `boolean` | Tracks active WS subscription state |

**Derived (useMemo)**

| Variable | Derived from | Purpose |
|---|---|---|
| `selectedWorkflow` | `workflows + selectedId` | The currently active `WorkflowItem` |
| `nodes` | `selectedWorkflow + execution` | Steps with live `status` applied via `mapNodeStatus` |

---

### WorkflowSidebar (inline region)

Rendered inside the first grid column. Wraps in `NxGlassCard`.

**Responsibilities**
- Renders one `<button>` per workflow with name and `trigger_type / status`.
- Applies `border-nexus-blue/60 bg-nexus-blue/10` to the selected item.
- Renders `NxEmptyState` ("No Workflows") when list is empty and not loading.
- On click: `setSelectedId`, clear `execution`, clear `realtimeLogs`.

---

### WorkflowCanvas (inline region)

Rendered inside the middle grid column. A `div` with `bg-grid`, `overflow-x-auto`, min-height 520px.

**Responsibilities**
- Renders a horizontal `flex gap-16` row of `NxWorkflowNode` components from `nodes`.
- Passes `selected={node.status === 'running'}` to highlight the active step.
- Renders a type label `<div>` above each node (monospace, uppercase) showing the raw `step.type`.
- Renders a horizontal connector `div` (absolute positioned, `bg-nexus-blue/40`, 1px height) between consecutive nodes — hidden on small screens (`hidden md:block`).
- Renders `NxEmptyState` ("Canvas is Empty") when `nodes.length === 0`.
- The outer container uses `overflow-x-auto` so long pipelines scroll horizontally.

**Note on NxWorkflowCanvas:** The `NxWorkflowCanvas` component (ReactFlow-based) exists in the codebase but is not used on this page. The current implementation renders nodes directly as a flex row, which is intentional — it avoids the ReactFlow overhead for the list-display use case and keeps the canvas stateless with respect to drag interactions.

---

### ExecutionTracer (inline region)

Rendered inside the third grid column. Wraps in `NxGlassCard`.

**Responsibilities**
- Header: "Execution Tracer" label + status icon (CheckCircle2 / XCircle / PauseCircle).
- Realtime log section: maps `realtimeLogs[]` to color-coded `<div>` lines.
  - Lines starting with `❌` or `✗` → `text-red-400`
  - Lines starting with `✅` or `✓` → `text-emerald-400`
  - Lines starting with `▶` → `text-blue-400`
  - All others → `text-gray-400`
- Divider: `── API step logs ──` separator between realtime and persisted logs.
- Persisted logs: maps `execution.step_logs[]`, each entry showing name, status (color-coded), duration, and error.
- Execution metadata: `execution.id` and `execution.status` (color-coded per status).
- Empty state: "No active execution." when `execution === null`.
- Approval CTA: "Review Approval Gate" button when `execution.status === 'paused' && waiting_for.type === 'approval'`.
- Scrollable: `max-h-[300px] overflow-y-auto`.

---

### NxWorkflowNode

External component. Props: `{ title, type, status, selected, className }`.

- `type` drives the icon and color scheme (trigger=amber/Play, action=blue/Webhook, condition=purple/Waypoints, agent=emerald/Bot).
- `status` drives the status indicator (running → animated blue dots, success → CheckCircle2, error → AlertCircle, pending → nothing).
- `selected=true` adds `ring-2 ring-nexus-blue/20 border-nexus-blue`.

---

### NxApprovalGateModal

External component. Props: `{ executionId, stepId, contextData, onApprove, onReject, onClose }`.

- Self-contained: makes the `/resume` API call internally via `apiClient`.
- Calls `onApprove()` or `onReject()` then `onClose()` after a successful decision.
- Exposes an error state for API failures.

The page's `resumeExecution` handler (`onApprove`/`onReject` callbacks) additionally calls `POST /executions/{id}/resume` to keep `execution` state in sync — the page-level handler is wired through the callbacks, which the modal fires after its own internal call completes. In practice the modal makes the call and the callbacks update page state accordingly.

---

### NxModal (Create Workflow)

Standard modal. Controlled by `isModalOpen`. On close (Cancel or `onClose`): resets `newName` to `''` and `newTrigger` to `'manual'`.

---

## Data Models

### WorkflowItem

```typescript
interface WorkflowItem {
  id: string | number;
  name: string;
  key: string;
  description?: string;
  status: string;           // 'draft' | 'active' | 'running' | 'paused' | ...
  trigger_type: string;     // 'manual' | 'scheduled' | 'event' | 'webhook'
  steps: WorkflowStep[];
  version: number;
  is_system: boolean;
}
```

### WorkflowStep

```typescript
interface WorkflowStep {
  id: string;
  name: string;
  type: string;   // raw backend type — mapped to NodeType before rendering
  status?: NodeStatus;
}
```

### WorkflowExecution

```typescript
interface WorkflowExecution {
  id: string;
  status: string;   // 'running' | 'completed' | 'failed' | 'paused' | 'cancelled'
  step_logs?: StepLog[];
  runtime_state?: {
    waiting_for?: { type?: string; step_id?: string };
    variables?: Record<string, unknown>;
  };
}

interface StepLog {
  step_id: string;
  status: string;
  step_name: string;
  duration_ms?: number;
  error?: string;
}
```

### ReverbStepEvent

```typescript
interface ReverbStepEvent {
  execution_id?: string;
  step_id?: string;
  step_name?: string;
  status?: string;
  output?: Record<string, unknown>;
  duration_ms?: number;
  error?: string;
}
```

### NodeType / NodeStatus

```typescript
type NodeType   = 'trigger' | 'action' | 'condition' | 'agent';
type NodeStatus = 'pending'  | 'running' | 'success'  | 'error';
```

---

## Node Type and Status Mapping

### `mapNodeType(type: string): NodeType`

Pure function. Applied to each `step.type` before passing to `NxWorkflowNode`.

| Input `type` | Output `NodeType` |
|---|---|
| `'trigger'` `'webhook'` `'scheduled'` | `'trigger'` |
| `'agent'` `'task'` | `'agent'` |
| `'decision'` `'condition'` | `'condition'` |
| anything else (incl. `'action'` `'wait'` `'log'`) | `'action'` |

```typescript
const mapNodeType = (type: string): NodeType => {
  if (type === 'agent' || type === 'task') return 'agent';
  if (type === 'decision' || type === 'condition') return 'condition';
  if (type === 'trigger' || type === 'webhook' || type === 'scheduled') return 'trigger';
  return 'action';
};
```

### `mapNodeStatus(step: WorkflowStep, execution?: WorkflowExecution): NodeStatus`

Pure function. Looks up the step in the execution's `step_logs` by `step_id`.

| Condition | Output `NodeStatus` |
|---|---|
| No matching log entry | `'pending'` |
| `log.status === 'running'` or `'paused'` | `'running'` |
| `log.status === 'failed'` | `'error'` |
| Any other status (`'completed'`, etc.) | `'success'` |

```typescript
const mapNodeStatus = (step: WorkflowStep, execution?: WorkflowExecution): NodeStatus => {
  const log = execution?.step_logs?.find((l) => l.step_id === step.id);
  if (!log) return 'pending';
  if (log.status === 'running' || log.status === 'paused') return 'running';
  if (log.status === 'failed') return 'error';
  return 'success';
};
```

---

## State Management

### Local React State (page.tsx)

All page-level state is managed with `useState` inside `WorkflowsPage`. This keeps the component self-contained and avoids leaking ephemeral execution state into global stores.

**Why not Zustand?** The `useWorkflowsStore` store is available and provides `fetchWorkflows` / `fetchWorkflowDefinition`, but its data model uses a different `Workflow` interface (no `steps[]`, no `status`, no `trigger_type`) and fetches from an unversioned `/api/v1/workflows` path. The page uses its own `apiClient` calls with the correct API shape. The two can be unified in a future refactor once the store types are aligned.

### State Initialization Sequence

```
WorkflowsPage mounts
  └─► useEffect [fetchWorkflows] (deferred via setTimeout 0)
        └─► GET /workflows?limit=50
              └─► setWorkflows(list)
              └─► setSelectedId(list[0].id) if no prior selection

  └─► useEffect [selectedWorkflow] (deferred via setTimeout 0)
        └─► GET /workflows/{id}/progress
              └─► setExecution(latest_execution)
```

### Selection Side Effects

When the user selects a different workflow from the sidebar:
- `setSelectedId(id)` triggers `selectedWorkflow` to recalculate (via `useMemo`).
- `setExecution(null)` clears any previous execution state.
- `setRealtimeLogs([])` clears the log panel.
- The `useEffect` watching `selectedWorkflow` fires `fetchProgress` for the new ID.
- The WebSocket `useEffect` re-runs: it leaves the old channel and subscribes to the new one.

### Execution State Mutations

Execution state is mutated from three sources, applied in order of freshness:

1. **API response** (`fetchProgress`, `executeWorkflow`, `resumeExecution`) — full object replacement.
2. **WebSocket events** — optimistic partial patch via functional `setExecution` updater.
3. **Terminal status patch** — `.workflow.completed` / `.workflow.failed` events patch only `status` without a full re-fetch.

The optimistic patch for `step_logs` either replaces an existing entry (matched by `step_id`) or appends a new one, ensuring the array remains consistent.

---

## API Integration

### Endpoints

| Method | Path | Purpose | Called from |
|---|---|---|---|
| `GET` | `/workflows?limit=50` | Fetch all workflows | `fetchWorkflows()` |
| `POST` | `/workflows` | Create a new workflow | `createWorkflow()` |
| `POST` | `/workflows/{id}/execute` | Start async execution | `executeWorkflow()` |
| `GET` | `/workflows/{id}/progress` | Poll/fetch latest execution | `fetchProgress()` |
| `POST` | `/workflows/executions/{executionId}/resume` | Approve or deny gate | `resumeExecution()` / `NxApprovalGateModal` |

### Request / Response Shapes

**GET /workflows?limit=50**
```
Response: { data: WorkflowItem[] }
```

**POST /workflows**
```json
{
  "name": "string",
  "key": "slug-timestamp",
  "description": "Custom orchestration workflow",
  "trigger_type": "manual | scheduled | event | webhook",
  "status": "draft",
  "steps": [
    { "id": "manual_trigger",  "name": "Manual Launch",         "type": "trigger" },
    { "id": "collect_context", "name": "Collect Context",       "type": "action"  },
    { "id": "approval_gate",   "name": "Human Approval",        "type": "wait"    },
    { "id": "final_log",       "name": "Write Execution Log",   "type": "log"     }
  ],
  "settings": { "max_execution_depth": 1000 }
}
Response: { data: WorkflowItem }
```

**POST /workflows/{id}/execute**
```json
{
  "run_mode": "async",
  "input_payload": { "launched_from": "WorkflowsHub" }
}
Response: { data: WorkflowExecution }
```

**GET /workflows/{id}/progress**
```
Response: { data: { latest_execution: WorkflowExecution } }
```

**POST /workflows/executions/{executionId}/resume**
```json
{
  "decision": "approve | deny",
  "input_payload": { "approval_decision": "approve | deny" }
}
Response: { data: WorkflowExecution }
```

### Key Generation

```typescript
const key =
  name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '')
  || `workflow-${Date.now()}`;
// submitted key = `${key}-${Date.now()}`
```

The timestamp suffix (`-${Date.now()}`) is appended unconditionally, guaranteeing uniqueness across concurrent creations.

---

## WebSocket Integration

### Setup

`useWebSocket()` creates a single `Echo` instance connected to Laravel Reverb (Pusher protocol). It authenticates private channels via a real Axios POST to `/broadcasting/auth` with the Bearer token.

Connection status flows through Pusher connection events into `connectionStatus: string` (`'disconnected'` | `'connecting'` | `'connected'` | `'unavailable'`).

### Channel Subscription

Subscribed inside `useEffect` watching `[echo, connectionStatus, selectedWorkflow]`.

```
Condition to subscribe: echo !== null && connectionStatus === 'connected' && selectedWorkflow !== null
Channel: workflow.{selectedWorkflow.id}  (private)
```

On cleanup (workflow deselected, component unmounts, WS reconnects): `echo.leave(channelName)`, `setWsConnected(false)`.

### Event Handling

| Event | Action |
|---|---|
| `.workflow.started` | Append `▶ Workflow started — execution: {id}` to `realtimeLogs`; call `fetchProgress` |
| `.workflow.step_completed` | Append icon + step name + status + duration/error line; optimistic `setExecution` patch |
| `.workflow.step_completed` (status=paused) | Additionally call `fetchProgress`; `setShowApprovalModal(true)` |
| `.workflow.completed` | Append `✅ Workflow completed successfully`; patch `execution.status = 'completed'` |
| `.workflow.failed` | Append `❌ Workflow failed: {error}`; patch `execution.status = 'failed'` |

### Optimistic Step Patch

When `.workflow.step_completed` arrives, `setExecution` applies a functional update:

```typescript
setExecution((prev) => {
  if (!prev) return prev;
  const logs = prev.step_logs ?? [];
  const exists = logs.find((l) => l.step_id === event.step_id);
  const newLog = { step_id, step_name, status, duration_ms, error };
  return {
    ...prev,
    step_logs: exists
      ? logs.map((l) => l.step_id === event.step_id ? newLog : l)
      : [...logs, newLog],
  };
});
```

This ensures the canvas node status updates immediately without waiting for a full `fetchProgress` round-trip.

### Polling Fallback

Active when `wsConnected === false` AND `execution` is non-null AND not in a terminal state.

```typescript
const TERMINAL = ['completed', 'failed', 'cancelled'];
// Poll every 2500ms via setInterval
// Stops when execution.status ∈ TERMINAL
```

Terminal states for the polling guard: `completed`, `failed`, `cancelled`. The interval is cleared when the WebSocket reconnects (`wsConnected` flips to `true`) or the component unmounts.

---

## Approval Gate Flow

```
Trigger condition
  ├─► WebSocket: .workflow.step_completed { status: 'paused' }
  │     └─► fetchProgress() → execution.status=paused, waiting_for.type=approval
  │           └─► setShowApprovalModal(true)
  │
  └─► Polling fallback: fetchProgress() → same condition
        └─► setShowApprovalModal(true)

NxApprovalGateModal renders with:
  executionId  = execution.id
  stepId       = execution.runtime_state.waiting_for.step_id
  contextData  = execution.runtime_state   (full runtime state as ApprovalContext)

User clicks Approve:
  └─► Modal internally: POST /executions/{id}/resume { decision: 'approve' }
        └─► onApprove() callback → page's resumeExecution('approve')
              └─► POST /executions/{id}/resume (page-level, updates execution state)
              └─► setExecution(response.data)
              └─► setShowApprovalModal(false)

User clicks Deny:
  └─► Same flow with decision='deny' / onReject()

User closes modal (X button):
  └─► onClose() → setShowApprovalModal(false)  (no API call)
```

**Tracer CTA:** A "Review Approval Gate" button appears at the bottom of the ExecutionTracer when the paused+approval condition is true, allowing re-opening the modal without triggering a new execution.

---

## Workflow Creation Flow

```
User clicks "New Workflow"
  └─► setIsModalOpen(true)

Modal renders:
  ├─► NxInput (controlled by newName)
  └─► NxSelect (controlled by newTrigger, options: manual/scheduled/event/webhook)

User submits form:
  └─► validateName (trim — if empty, do nothing)
  └─► generate key: slugify(name) + '-' + Date.now()
  └─► POST /workflows { name, key, description, trigger_type, status:'draft', steps: starterSteps, settings }
        ├─► success:
        │     setWorkflows([workflow, ...current])  // prepend → appears at top
        │     setSelectedId(workflow.id)            // auto-select
        │     setNewName(''), setNewTrigger('manual')
        │     setIsModalOpen(false)
        └─► failure:
              setRealtimeLogs([`❌ Failed to create workflow: ${error.message}`])
              // modal remains open

User cancels / closes modal:
  └─► setIsModalOpen(false), setNewName(''), setNewTrigger('manual')
```

**Starter steps** injected on every creation:

| id | name | type |
|---|---|---|
| `manual_trigger` | Manual Launch | trigger |
| `collect_context` | Collect Context | action |
| `approval_gate` | Human Approval | wait |
| `final_log` | Write Execution Log | log |

---

## Layout and Responsive Behavior

### Grid Structure

```
xl:grid-cols-[280px_1fr_320px]   ← three-panel (large screens)
grid-cols-1                      ← stacked (mobile)
gap-4
min-h-[520px]  (grid row constraint)
```

```
AppLayout
  └─► <div class="p-6 h-full flex flex-col gap-6 w-full max-w-7xl mx-auto overflow-y-auto">
        ├─► PageHeader (flex-col md:flex-row, border-b)
        └─► Three-Panel Grid
              ├─► [0] Sidebar   280px fixed — NxGlassCard, overflow-y-auto, max-h-[500px]
              ├─► [1] Canvas    flexible  — bg-grid, overflow-x-auto, overflow-y-hidden, p-6
              └─► [2] Tracer    320px fixed — NxGlassCard, flex-col
```

### Canvas Scrolling

The canvas outer div has `overflow-x-auto overflow-y-hidden`. Inside, a `div.w-max.min-w-full` expands to fit all nodes. This means:
- Short pipelines (few nodes): fills the full canvas width.
- Long pipelines: the canvas scrolls horizontally while keeping its fixed height.

### Connector Lines

Connector lines between nodes are `hidden md:block` — they only render on medium-and-larger breakpoints where horizontal layout makes sense.

### Mobile Collapse

On `< xl` screens the grid falls to `grid-cols-1`, stacking sidebar → canvas → tracer vertically. `AppLayout` itself handles the mobile nav via `MobileHeader` + overlay sidebar.

### Background

Canvas uses `bg-grid` CSS class, which should be defined in `globals.css` as a repeating grid pattern — typically `background-image: linear-gradient(...)` or `radial-gradient(...)` giving the dot-grid aesthetic.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

**Property Reflection**

Before writing properties, redundant candidates from the prework are consolidated:

- **4.4 / 3.5** — "display execution ID and status" is fully subsumed by the broader property that any execution is rendered with its id and status (Property 5 below). 4.4 is dropped.
- **6.4 / 6.3** — the timestamp uniqueness requirement is an invariant of the key-generation function. It is covered within Property 9 (key-generation property). 6.4 is not a separate property.
- **4.5 / 4.6** — status color mapping and status icon selection are both pure functions of `execution.status`. They can be combined into one property about status presentation (Property 6).
- **2.6** is an invariant that follows directly from `mapNodeStatus` (Property 3) and the canvas render rule (Property 4). It is expressed as a corollary of Property 4 rather than a separate property.
- **1.3 and 2.1** both test "any list of N items renders N visual elements." They are parallel but distinct (workflow buttons vs. canvas nodes) so they remain separate (Properties 1 and 4).

---

### Property 1: Sidebar renders one button per workflow

*For any* non-empty array of `WorkflowItem` objects, the sidebar renders exactly one selectable button per workflow, and each button contains the workflow's `name` and its `trigger_type / status` text.

**Validates: Requirements 1.3**

---

### Property 2: Auto-selection of first workflow

*For any* non-empty list of workflows fetched when no prior selection exists, the resulting `selectedId` equals the `id` of the first item in the list.

**Validates: Requirements 1.6**

---

### Property 3: `mapNodeType` is a total function with correct outputs

*For any* step type string drawn from the known input set (`'trigger'`, `'webhook'`, `'scheduled'`, `'agent'`, `'task'`, `'decision'`, `'condition'`, and any arbitrary other string), `mapNodeType` returns the correct canonical `NodeType` per the mapping table, and never returns `undefined` or throws.

**Validates: Requirements 2.4**

---

### Property 4: Canvas renders one node per step, running node is highlighted

*For any* `WorkflowItem` with N steps, the canvas renders exactly N `NxWorkflowNode` components. Furthermore, for any step whose derived `NodeStatus` is `'running'`, the corresponding `NxWorkflowNode` receives `selected={true}`; for all others, `selected` is falsy.

**Validates: Requirements 2.1, 2.6**

---

### Property 5: `mapNodeStatus` pure mapping invariant

*For any* `WorkflowStep` and any `WorkflowExecution`, `mapNodeStatus(step, execution)` satisfies:
- If no `step_log` entry matches `step.id` → returns `'pending'`
- If the matching log has `status ∈ { 'running', 'paused' }` → returns `'running'`
- If the matching log has `status === 'failed'` → returns `'error'`
- Otherwise → returns `'success'`

And never returns `undefined` or throws for any valid input combination.

**Validates: Requirements 2.5**

---

### Property 6: Execution status presentation is correct for all statuses

*For any* `WorkflowExecution`, the Execution Tracer applies the correct color class and icon:
- `'completed'` → emerald color class, `CheckCircle2` icon
- `'failed'` → red color class, `XCircle` icon
- `'paused'` → amber color class, `PauseCircle` icon
- `'running'` → blue color class, no icon
- Any other status → gray color class, no icon

**Validates: Requirements 4.5, 4.6**

---

### Property 7: Execute button disabled iff no selection or status is running

*For any* application state, the Execute button is disabled if and only if `selectedWorkflow === null` OR `selectedWorkflow.status === 'running'`. For any other non-null selected workflow with a status other than `'running'`, the button is enabled.

**Validates: Requirements 3.3**

---

### Property 8: Optimistic step log patch is correct for any event

*For any* `WorkflowExecution` state and any `ReverbStepEvent`, the optimistic patch function produces a new execution where:
- If `step_id` already exists in `step_logs` → that entry is replaced with the event's data.
- If `step_id` is new → the entry is appended to `step_logs`.
- All other `step_logs` entries are unchanged.
- The `status` and other top-level fields of the execution are unmodified by this patch.

**Validates: Requirements 3.8**

---

### Property 9: Workflow key generation produces valid slugs with timestamp suffix

*For any* non-empty workflow name string, the generated key:
- Is lowercase alphanumeric with hyphens only (matches `/^[a-z0-9][a-z0-9-]*[a-z0-9]$/` or a single alphanumeric character).
- Has no leading or trailing hyphens.
- Ends with a numeric timestamp suffix (`-{digits}`).
- Is non-empty even for edge-case names containing only special characters (falls back to `workflow-{timestamp}`).

**Validates: Requirements 6.3, 6.4**

---

### Property 10: Newly created workflow is prepended and auto-selected

*For any* current `workflows` array of any length, after a successful `createWorkflow` call, the returned workflow is at `workflows[0]` and `selectedId === newWorkflow.id`.

**Validates: Requirements 6.5**

---

### Property 11: Modal reset on close

*For any* values of `newName` and `newTrigger` at the time the Create Workflow modal is closed (via Cancel, backdrop click, or successful submission), both fields are reset to their defaults: `newName === ''` and `newTrigger === 'manual'`.

**Validates: Requirements 6.7**

---

### Property 12: Approval gate button visibility is exclusive

*For any* `WorkflowExecution`, the "Review Approval Gate" button in the Execution Tracer is visible if and only if `execution.status === 'paused'` AND `execution.runtime_state?.waiting_for?.type === 'approval'`. For all other execution states (including `null`), the button is not rendered.

**Validates: Requirements 5.1**

---

### Property 13: Log line color classification is a total pure function

*For any* log line string, the color-class selector function returns exactly one of the four defined classes based solely on the string's first character/emoji:
- Starts with `❌` or `✗` → `text-red-400`
- Starts with `✅` or `✓` → `text-emerald-400`
- Starts with `▶` → `text-blue-400`
- Anything else → `text-gray-400`

And never returns `undefined` or throws.

**Validates: Requirements 4.2**

---

## Error Handling

### API Errors

All `apiClient` calls are wrapped in `try/catch`. The `apiClient` interceptor normalizes errors into `ApiError` with a human-readable `message` and HTTP `status`.

| Operation | On failure |
|---|---|
| `fetchWorkflows` | `setIsLoading(false)`, list remains empty (or stale) |
| `fetchProgress` | Silently ignored (polling will retry on next tick) |
| `executeWorkflow` | `setRealtimeLogs([❌ Failed to launch execution: {msg}])`, `setExecution(status='failed')` |
| `createWorkflow` | `setRealtimeLogs([❌ Failed to create workflow: {msg}])`, modal stays open |
| `resumeExecution` | Error logged to console; `NxApprovalGateModal` shows inline error via its own `error` state |

### WebSocket Errors

`useWebSocket` suppresses repeated errors (after 3 consecutive failures, further logs are suppressed). The hook sets `connectionStatus = 'disconnected'` on any connection error, which deactivates the WS subscription and activates the polling fallback automatically.

### Loading States

- `isLoading` guards the initial fetch. The sidebar renders existing (or empty) state without crashing during load.
- `isRunning` disables the Execute button and shows a spinner to prevent double-submission.
- The Approval modal has its own `loading` and `error` state, isolated from page state.

---

## Testing Strategy

### Approach

This feature uses a **dual testing approach**: property-based tests for universal invariants and pure functions, plus example-based unit tests for specific interactions and integration checks.

### Property-Based Tests

Use **fast-check** (TypeScript PBT library) configured for minimum 100 runs per property.

Each property test references its design property via a comment tag:
`// Feature: workflows-hub, Property {N}: {property_title}`

Properties suitable for PBT:

| Design Property | Test Target | fast-check Arbitraries |
|---|---|---|
| Property 3 | `mapNodeType` pure function | `fc.constantFrom(...knownTypes)`, `fc.string()` |
| Property 5 | `mapNodeStatus` pure function | `fc.record(WorkflowStep)`, `fc.option(fc.record(WorkflowExecution))` |
| Property 8 | Optimistic step patch function | `fc.record(WorkflowExecution)`, `fc.record(ReverbStepEvent)` |
| Property 9 | Key generation function | `fc.string({ minLength: 1 })`, unicode strings, special-char-only strings |
| Property 13 | Log line color classifier | `fc.string()`, prefixed strings with emoji |

Pure functions (`mapNodeType`, `mapNodeStatus`, the optimistic patch, key generation, color classification) are extracted and tested independently of the React component. They contain no I/O and are trivially testable with generated inputs.

### Example-Based Unit Tests

Use **Jest + React Testing Library**.

| Requirement | Test |
|---|---|
| 1.1 — fetch on mount | Mock `apiClient.get`, mount component, assert `GET /workflows?limit=50` called once |
| 1.4 — selected highlight | Render with `selectedId=X`, assert button X has nexus-blue classes |
| 1.5 — empty state | Render with `workflows=[]`, assert "No Workflows" text |
| 2.7 — canvas empty state | Render with `steps=[]`, assert "Canvas is Empty" |
| 3.1 — execute call body | Click Execute, assert `POST /workflows/{id}/execute` called with correct body |
| 3.4 — logs cleared on execute | Pre-fill logs, click Execute, assert `realtimeLogs = []` |
| 3.10 — WS badge | Render with `connectionStatus='connected'`, assert "Live" badge |
| 5.3 — approval modal auto-open | Mock `fetchProgress` returning paused+approval, assert `NxApprovalGateModal` visible |
| 5.5 — approve call | Click Approve in modal, assert `POST /resume` with `decision:'approve'` |
| 5.6 — deny call | Click Deny in modal, assert `POST /resume` with `decision:'deny'` |
| 6.1 — modal opens | Click "New Workflow", assert `NxModal` visible |
| 6.6 — creation error | Mock `POST /workflows` to reject, assert realtime log starts with `❌` |

### Integration Tests (Example-based, 1–2 executions)

- WebSocket channel subscription: mock `Echo`, verify `echo.private('workflow.X')` called on connect.
- Polling fallback: mock `setInterval`, assert polling starts when `wsConnected=false` and execution is non-terminal; stops when terminal.
- Approval gate WS trigger: fire `.workflow.step_completed` with `status='paused'`, assert `fetchProgress` called and `showApprovalModal=true`.

### Smoke Tests

- Loading state does not crash: render with `isLoading=true`, assert no error boundary thrown.
- Canvas has horizontal scroll: assert `overflow-x-auto` on canvas container.
- Tracer has max height: assert `max-h-[300px] overflow-y-auto` on log area.
