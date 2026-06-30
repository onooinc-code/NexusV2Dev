# Requirements Document

## Introduction

The NexusHub Dashboard is the primary landing page of the entire Nexus platform, mounted at
`app/page.tsx`. It serves as Hédra's single cognitive command center: a real-time, unified
view of the system's operational state, active processes, recent activity, and key metrics
spanning all eleven hubs — MemoryHub, ContactsHub, AgentsHub, AiModelsHub, WorkflowsHub,
TasksHub, SettingsHub, LogsHub, SchedulerHub, ConversationHub, and ProactiveAIHub.

The current `app/page.tsx` is a prototype that uses hardcoded mock data, a simulated
log interval, and a Next.js route to a Gemini proxy. It does not connect to the real
backend APIs, does not subscribe to live WebSocket channels, and is missing the majority
of the panels described in this spec. This requirements document drives the full replacement
of that prototype with a production-quality dashboard that integrates `apiClient` from
`@/lib/api/client`, the Laravel backend dashboard aggregation endpoints, and the
`dashboard.{userId}` Reverb WebSocket channel for live cognitive event streaming.

The dashboard must render responsively: a four-column grid on desktop (≥ 1280 px),
a two-column grid on tablet (768 px – 1279 px), and a single-column stack on mobile
(< 768 px). All visual components must follow the Nexus glassmorphism design system and
use only existing `Nx*` design-system components — no raw HTML cards, no Tailwind-only
ad-hoc layouts outside the established patterns.


---

## Glossary

- **NexusHub_Dashboard**: The main landing page of the Nexus platform, mounted at `app/page.tsx`, providing a unified real-time overview of the entire system.
- **Dashboard_Stats_Endpoint**: `GET /api/v1/dashboard/stats` — the backend aggregation endpoint that returns key metrics from all hubs in a single response.
- **Dashboard_Activity_Endpoint**: `GET /api/v1/dashboard/activity-feed` — the paginated endpoint returning a chronological list of recent cognitive events across all hubs.
- **Dashboard_Health_Endpoint**: `GET /api/v1/dashboard/health` — the endpoint returning live health status for each hub's backing service.
- **WebSocket_Dashboard_Channel**: The Reverb channel `dashboard.{userId}` that broadcasts live cognitive events to the frontend in real time.
- **apiClient**: The centralized Axios-based HTTP client at `@/lib/api/client` used for all frontend API calls — raw `fetch` and mock stores are prohibited.
- **Cognitive_Activity_Feed**: The real-time scrolling panel displaying a stream of platform events: memory extractions, contact updates, agent executions, task completions, and conversation processing results.
- **System_Health_Strip**: The horizontal status bar displaying live health indicators for every hub and its backing services (queue workers, Redis, Pinecone, AI providers).
- **Key_Metrics_Cards**: The row of `NxMetricCard` components showing aggregate counts (total contacts, active conversations, memories stored, pending tasks, running agents, queued jobs) with 24-hour trend indicators.
- **AI_Usage_Panel**: The panel showing token consumption, cost estimates, model distribution, and rate-limit status across all AI providers configured in AiModelsHub.
- **Active_Agents_Jobs_Panel**: The panel displaying currently running agents, active Horizon queue jobs with progress, and job failure counts with retry controls.
- **Recent_Contacts_Activity**: The panel listing the 5–10 most recently active contacts with their last interaction snippet, channel badge, time-ago label, and reply-mode indicator.
- **Memory_Health_Summary**: The panel summarising MemoryHub state: total records, confidence distribution chart, last consolidation timestamp, low-confidence count, expired count, and a "Run Maintenance" action.
- **Quick_Actions_Bar**: The toolbar of shortcut `NxActionButton` controls for the most common cross-hub operations.
- **Proactive_AI_Panel**: The panel surfacing current AI-generated suggestions and insights from ProactiveAIHub awaiting Hédra's review.
- **Scheduler_Overview**: The compact panel showing the next three upcoming scheduled jobs or reminders with countdown timers.
- **Trend_Indicator**: The up/down/neutral badge on each metric card comparing the current value to the equivalent value 24 hours prior.
- **Hub_Service**: A named backend service backing a specific hub (e.g., queue worker for AgentsHub, Redis for WorkingMemory, Pinecone for SemanticMemory).
- **Reverb**: Laravel Reverb, the WebSocket server used for real-time event broadcasting.
- **Horizon**: Laravel Horizon, the queue worker dashboard and job management system.
- **NxGlassCard**: The Nexus glassmorphism card component used as the visual container for all dashboard panels.
- **NxMetricCard**: The Nexus metric card component displaying a title, value, icon, and trend indicator.
- **NxActionButton**: The Nexus standard button component used for all interactive controls.
- **NxStatusBadge**: The Nexus badge component used to display status labels (online, degraded, offline, warning).
- **NxQueuePill**: The Nexus component rendering a queue job's name, status, and progress bar.
- **NxModal**: The Nexus overlay modal component used for confirmations and detail views.
- **NxEmptyState**: The Nexus empty-state illustration component shown when a panel has no data.
- **NxSkeleton**: The Nexus skeleton loader component shown while a panel's data is loading.
- **NxToast**: The Nexus toast notification component for transient success and error messages.
- **NxThinkingIndicator**: The Nexus animated indicator shown when an AI operation is in progress.
- **MemoryHub**: The hub managing all memory types (working, episodic, semantic, structured, graph).
- **ContactsHub**: The hub managing contact profiles and interaction history.
- **AgentsHub**: The hub managing AI agent definitions, execution, and orchestration.
- **AiModelsHub**: The hub managing AI provider adapters, model routing, and token accounting.
- **WorkflowsHub**: The hub managing DAG-based workflow definitions and executions.
- **TasksHub**: The hub managing manual, agentic, and system task lifecycles.
- **SettingsHub**: The hub managing platform configuration and feature flags.
- **LogsHub**: The hub providing centralized audit trails and telemetry.
- **SchedulerHub**: The hub managing cron-based scheduled jobs and reminders.
- **ConversationHub**: The hub managing conversation sessions and message pipelines.
- **ProactiveAIHub**: The hub generating AI-driven insights and suggestions for Hédra's review.


---

## Requirements

### Requirement 1: Dashboard Aggregated Stats API Integration

**User Story:** As Hédra, I want the dashboard to load real aggregated platform metrics
from the backend on every page visit, so that all metric cards always reflect the true
current state of the system rather than hardcoded or simulated data.

#### Acceptance Criteria

1. WHEN the NexusHub_Dashboard page mounts, THE Dashboard SHALL call
   `GET /api/v1/dashboard/stats` via `apiClient` and populate the Key_Metrics_Cards
   with the returned values before any user interaction.
2. THE Dashboard_Stats_Endpoint SHALL return a single JSON response containing:
   `total_contacts`, `active_conversations`, `memories_stored`, `pending_tasks`,
   `running_agents`, `queued_jobs`, and for each metric a `trend` object with
   `direction` (`up` | `down` | `neutral`) and `delta` (absolute change vs 24 hours ago).
3. WHEN the stats response is received, THE Dashboard SHALL update each `NxMetricCard`
   with the corresponding `value` and render a `Trend_Indicator` reflecting `direction`
   and `delta`.
4. WHEN the stats fetch is in flight, THE Dashboard SHALL render `NxSkeleton` placeholders
   inside each metric card position.
5. IF the `GET /api/v1/dashboard/stats` call returns a 4xx or 5xx response, THEN
   THE Dashboard SHALL display an inline error banner beneath the metrics row with the
   error message and a "Retry" button that re-triggers the fetch — it SHALL NOT silently
   display zeroed or stale values.
6. WHEN the "Retry" button is clicked after a failed stats fetch, THE Dashboard SHALL
   re-call `GET /api/v1/dashboard/stats` via `apiClient` and clear the error banner
   on success.
7. THE Dashboard SHALL re-fetch stats automatically every 60 seconds via a polling
   interval while the page is visible, updating metric card values and trend indicators
   in place without a full page reload.
8. WHEN the page becomes hidden (browser tab backgrounded), THE Dashboard SHALL pause
   the polling interval and resume it when the page becomes visible again.


---

### Requirement 2: System Health & Status Strip

**User Story:** As Hédra, I want a persistent health strip at the top of the dashboard
that shows the live status of every hub and its backing services, so that I can detect
degraded or failed services at a glance without navigating to a separate monitoring page.

#### Acceptance Criteria

1. WHEN the NexusHub_Dashboard page mounts, THE Dashboard SHALL call
   `GET /api/v1/dashboard/health` via `apiClient` and render one `NxStatusBadge` per
   hub listed in the response within the System_Health_Strip.
2. THE Dashboard_Health_Endpoint SHALL return a `services` array where each entry
   contains `name` (hub or service name), `status` (`online` | `degraded` | `offline`),
   `latency_ms` (nullable integer), and `error_rate` (nullable float 0.0–1.0).
3. WHEN a service `status` is `online`, THE System_Health_Strip SHALL render its badge
   with a green indicator; `degraded` SHALL render amber; `offline` SHALL render red.
4. WHEN a service `latency_ms` exceeds 2000 ms, THE Dashboard SHALL override the badge
   color to amber regardless of the reported `status` field.
5. WHEN a service `error_rate` exceeds 0.05 (5%), THE Dashboard SHALL override the badge
   color to amber regardless of the reported `status` field.
6. WHILE any service reports `status: offline`, THE Dashboard SHALL display a
   full-width dismissible alert banner above the strip stating which service is down.
7. THE System_Health_Strip SHALL refresh its data by re-calling the health endpoint
   every 30 seconds without requiring a page reload.
8. WHEN a user hovers over any health badge, THE Dashboard SHALL display a `NxTooltip`
   showing the service `name`, `latency_ms` in milliseconds, and `error_rate` as a
   percentage.
9. IF `GET /api/v1/dashboard/health` fails, THEN THE System_Health_Strip SHALL render
   all badges with a gray "unknown" state and display a single error label — it SHALL
   NOT leave the strip empty.


---

### Requirement 3: Cognitive Activity Feed — WebSocket Live Stream

**User Story:** As Hédra, I want a real-time feed of cognitive events flowing through
the system — memories extracted, contacts updated, agents running, tasks completed — so
that I always have a live pulse of what Nexus is doing without polling or refreshing.

#### Acceptance Criteria

1. WHEN the NexusHub_Dashboard page mounts and the user is authenticated, THE Dashboard
   SHALL subscribe to the `dashboard.{userId}` Reverb WebSocket channel using the
   established Echo integration and begin receiving live events.
2. WHEN the page first loads, THE Dashboard SHALL call
   `GET /api/v1/dashboard/activity-feed` via `apiClient` to populate the feed with the
   most recent 20 events before any WebSocket events arrive.
3. WHEN a new event arrives on the `dashboard.{userId}` channel, THE Dashboard SHALL
   prepend it to the top of the Cognitive_Activity_Feed list and animate it in with
   a fade-slide transition.
4. THE Cognitive_Activity_Feed SHALL cap its in-memory list at 100 events, discarding
   the oldest entries from the bottom as new events exceed the cap.
5. EACH event entry in the feed SHALL display: an icon representing its hub of origin,
   a short descriptive message, a severity badge (`info` | `warning` | `error`), the
   source hub name, and a relative timestamp (e.g., "2 min ago").
6. WHEN a feed event has severity `error`, THE Dashboard SHALL render its row with a
   red-tinted background and a distinct error icon to make it visually distinct from
   informational events.
7. WHEN a feed event has severity `warning`, THE Dashboard SHALL render its row with an
   amber-tinted background.
8. WHEN the WebSocket connection drops, THE Dashboard SHALL display a "Reconnecting…"
   indicator inside the feed panel and automatically attempt reconnection with exponential
   backoff — it SHALL NOT require a page reload to recover.
9. THE Cognitive_Activity_Feed SHALL include a "Load more" control at the bottom that
   calls `GET /api/v1/dashboard/activity-feed` with the `before` cursor parameter to
   append older events.
10. WHEN the NexusHub_Dashboard page unmounts, THE Dashboard SHALL unsubscribe from
    the `dashboard.{userId}` channel to prevent memory leaks.


---

### Requirement 4: Key Metrics Cards Row

**User Story:** As Hédra, I want a row of summary metric cards at the top of the
dashboard body that each show a key platform count and how it has changed since yesterday,
so that I can assess the system's scale and growth trajectory in seconds.

#### Acceptance Criteria

1. THE Dashboard SHALL render exactly six `NxMetricCard` components in a responsive
   grid row: Total Contacts, Active Conversations, Memories Stored, Pending Tasks,
   Running Agents, and Queued Jobs.
2. EACH card SHALL display a numeric value sourced from the `Dashboard_Stats_Endpoint`
   response, not from any hardcoded constant or mock store.
3. EACH card SHALL display a `Trend_Indicator` using the `trend.direction` and
   `trend.delta` fields from the stats response, formatted as "+ N (X%)" for upward
   trends and "− N (X%)" for downward trends.
4. THE Total Contacts card SHALL use a `Users` icon styled in `--nexus-blue`.
5. THE Active Conversations card SHALL use a `MessageCircle` icon styled in
   `--nexus-teal`.
6. THE Memories Stored card SHALL use a `BrainCircuit` icon styled in amber.
7. THE Pending Tasks card SHALL use a `CheckSquare` icon styled in `--nexus-teal`.
8. THE Running Agents card SHALL use a `Cpu` icon styled in `--hedral-purple`.
9. THE Queued Jobs card SHALL use a `Layers` icon styled in `--success` green.
10. WHEN the stats fetch is loading, THE Dashboard SHALL render `NxSkeleton` components
    inside each card matching the card's height and width.
11. WHEN any metric value changes between poll cycles, THE Dashboard SHALL briefly
    animate the changed value with a flash highlight lasting 600 ms.


---

### Requirement 5: AI Usage & Cost Panel

**User Story:** As Hédra, I want a dedicated panel on the dashboard showing AI token
consumption, cost estimates, and per-provider model distribution, so that I can monitor
spending and rate-limit exposure across all configured AI providers in real time.

#### Acceptance Criteria

1. THE Dashboard SHALL render the AI_Usage_Panel as a `NxGlassCard` sourcing its data
   from the `Dashboard_Stats_Endpoint` response's `ai_usage` object.
2. THE `ai_usage` object SHALL contain: `tokens_today` (integer), `tokens_this_month`
   (integer), `cost_today_usd` (float), `cost_this_month_usd` (float),
   `provider_breakdown` (array of `{ provider, tokens, cost_usd, rate_limit_pct }`),
   and `top_model` (string).
3. THE AI_Usage_Panel SHALL display `cost_today_usd` and `cost_this_month_usd` formatted
   as USD currency values (e.g., "$0.84" and "$12.31") in large, prominent typography.
4. THE AI_Usage_Panel SHALL render a `DashboardChart` (area chart) showing token usage
   over the last 7 days, using data from a `tokens_history` array in the stats response.
5. WHEN a provider's `rate_limit_pct` reaches or exceeds 80%, THE AI_Usage_Panel SHALL
   render that provider's row with an amber `NxStatusBadge` labeled "Near Limit".
6. WHEN a provider's `rate_limit_pct` reaches or exceeds 95%, THE Dashboard SHALL
   render that provider's row with a red `NxStatusBadge` labeled "Rate Limited" and
   include the provider name in the System_Health_Strip with `status: degraded`.
7. THE AI_Usage_Panel SHALL list each provider in `provider_breakdown` as a row showing:
   provider name, token count formatted with thousands separators, cost in USD, and a
   horizontal progress bar representing `rate_limit_pct`.
8. IF `provider_breakdown` is empty or absent, THE AI_Usage_Panel SHALL display an
   `NxEmptyState` with the message "No AI activity recorded yet."


---

### Requirement 6: Active Agents & Jobs Panel

**User Story:** As Hédra, I want a panel showing all currently running agents and active
Horizon queue jobs with their real-time progress, so that I can monitor execution, spot
failures early, and retry failed jobs without leaving the dashboard.

#### Acceptance Criteria

1. THE Dashboard SHALL render the Active_Agents_Jobs_Panel as a `NxGlassCard` sourcing
   its data from the `Dashboard_Stats_Endpoint` response's `agents` and `jobs` arrays.
2. THE `agents` array SHALL contain entries with: `id`, `name`, `role`, `status`
   (`online` | `busy` | `offline`), `token_usage` (integer), and `current_task`
   (nullable string).
3. THE `jobs` array SHALL contain entries with: `id`, `name`, `queue`, `status`
   (`pending` | `running` | `failed` | `completed`), `progress_pct` (0–100 integer),
   `started_at` (ISO timestamp or null), and `failed_count` (integer).
4. THE Active_Agents_Jobs_Panel SHALL render each agent as an `NxAgentCard` component
   showing `name`, `role`, `status` via `NxAgentStatusOrb`, and `token_usage`.
5. EACH job in the `jobs` array SHALL be rendered as an `NxQueuePill` showing the job
   `name`, `queue`, `status` badge, and a progress bar filled to `progress_pct`.
6. WHEN a job has `status: failed`, THE Dashboard SHALL render its `NxQueuePill` with
   a red border and a "Retry" `NxActionButton` that calls
   `POST /api/v1/jobs/{id}/retry` via `apiClient` on click.
7. WHEN a "Retry" call succeeds, THE Dashboard SHALL update that job's `NxQueuePill`
   status to `pending` and display an `NxToast` confirming the retry was queued.
8. IF the `agents` array is empty, THE Active_Agents_Jobs_Panel SHALL display
   `NxEmptyState` with label "No agents currently running."
9. IF the `jobs` array is empty, THE Active_Agents_Jobs_Panel SHALL display
   `NxEmptyState` with label "No queued jobs at this time."
10. WHEN a new job or agent state update arrives via the `dashboard.{userId}` WebSocket
    channel with event type `agent.updated` or `job.updated`, THE Dashboard SHALL update
    the corresponding item in the panel in place without a full data re-fetch.


---

### Requirement 7: Recent Contacts Activity Panel

**User Story:** As Hédra, I want a panel showing the most recently active contacts with
a snippet of their last interaction, so that I can quickly identify who needs follow-up
and jump directly to a contact's profile without searching ContactsHub.

#### Acceptance Criteria

1. THE Dashboard SHALL render the Recent_Contacts_Activity panel as a `NxGlassCard`
   sourcing its data from the `Dashboard_Stats_Endpoint` response's
   `recent_contacts` array.
2. THE `recent_contacts` array SHALL contain 5 to 10 entries, each with: `id`, `name`,
   `avatar_url` (nullable), `last_message_snippet` (string, max 80 characters),
   `channel` (`whatsapp` | `facebook` | `email` | `sms` | `other`),
   `last_interaction_at` (ISO timestamp), and `reply_mode`
   (`autopilot` | `copilot` | `manual`).
3. EACH contact entry SHALL be rendered showing the contact `name`, a relative
   "time ago" label derived from `last_interaction_at`, the `last_message_snippet`
   truncated with an ellipsis if needed, a channel icon badge, and a `reply_mode`
   badge colored green for `autopilot`, amber for `copilot`, and gray for `manual`.
4. WHEN a user clicks on a contact row, THE Dashboard SHALL navigate to
   `/contacts/{id}` using the Next.js router.
5. THE panel header SHALL include a "View all" link navigating to `/contacts`.
6. IF `recent_contacts` is empty, THE Recent_Contacts_Activity panel SHALL display
   `NxEmptyState` with label "No recent contact activity."
7. WHEN a `contact.updated` event arrives on the `dashboard.{userId}` WebSocket channel
   with a contact id matching an entry already in the list, THE Dashboard SHALL update
   that contact's `last_message_snippet`, `last_interaction_at`, and `reply_mode` in
   place.
8. WHEN a `contact.updated` event arrives for a contact not currently in the list,
   THE Dashboard SHALL prepend it as the newest entry and remove the oldest entry if
   the list would exceed 10 items.


---

### Requirement 8: Memory Health Summary Panel

**User Story:** As Hédra, I want a compact memory health summary on the dashboard that
shows the overall state of the MemoryHub — total records, confidence distribution, last
maintenance run, and problematic records — so that I can spot memory degradation and
trigger maintenance directly from the dashboard without opening MemoryHub.

#### Acceptance Criteria

1. THE Dashboard SHALL render the Memory_Health_Summary as a `NxGlassCard` sourcing
   its data from the `Dashboard_Stats_Endpoint` response's `memory_health` object.
2. THE `memory_health` object SHALL contain: `total_records` (integer),
   `low_confidence_count` (integer), `expired_count` (integer),
   `last_consolidation_at` (ISO timestamp or null),
   `confidence_distribution` (object with `high`, `medium`, `low` integer buckets
   representing counts of records at ≥70%, 20–69%, and <20% confidence respectively).
3. THE Memory_Health_Summary SHALL display `total_records`, `low_confidence_count`,
   and `expired_count` as labeled numeric values.
4. THE Memory_Health_Summary SHALL render a small bar or pie chart representing the
   `confidence_distribution` buckets using green for `high`, amber for `medium`, and
   red for `low`.
5. THE Memory_Health_Summary SHALL display the `last_consolidation_at` timestamp
   formatted as a relative label (e.g., "Last run 3 hours ago") — if null, it SHALL
   display "Never run".
6. THE Memory_Health_Summary SHALL include a "Run Maintenance" `NxActionButton` that
   calls `POST /api/v1/memories/maintenance` via `apiClient` on click and displays
   `NxThinkingIndicator` while the 202 response is awaited.
7. WHEN the maintenance dispatch call succeeds (202 Accepted), THE Dashboard SHALL
   show an `NxToast` with message "Maintenance job queued successfully."
8. IF `low_confidence_count` is greater than 100, THE Memory_Health_Summary SHALL
   render the `low_confidence_count` label in amber to signal the memory store needs
   attention.
9. IF `expired_count` is greater than 0, THE Memory_Health_Summary SHALL render the
   `expired_count` label in red.


---

### Requirement 9: Quick Actions Bar

**User Story:** As Hédra, I want a bar of shortcut action buttons at the top of the
dashboard body, so that I can trigger the most common cross-hub operations with a single
click without navigating away to individual hubs.

#### Acceptance Criteria

1. THE Dashboard SHALL render the Quick_Actions_Bar as a horizontal group of
   `NxActionButton` components placed directly below the Key_Metrics_Cards row.
2. THE Quick_Actions_Bar SHALL include exactly the following actions in this order:
   "New Conversation", "Import Contacts", "Run AI Analysis", "Trigger Maintenance",
   and "View Logs".
3. WHEN "New Conversation" is clicked, THE Dashboard SHALL navigate to `/conversations`
   using the Next.js router.
4. WHEN "Import Contacts" is clicked, THE Dashboard SHALL open the `NxImportModal`
   component in-place on the dashboard without full page navigation.
5. WHEN "Run AI Analysis" is clicked, THE Dashboard SHALL open the `NxAiAnalysisModal`
   component in-place on the dashboard.
6. WHEN "Trigger Maintenance" is clicked, THE Dashboard SHALL call
   `POST /api/v1/memories/maintenance` via `apiClient` without a `contact_id` parameter
   (global maintenance) and show `NxThinkingIndicator` on the button until the 202
   response is received.
7. WHEN "View Logs" is clicked, THE Dashboard SHALL navigate to `/logs`.
8. WHEN "Trigger Maintenance" is in flight, THE Dashboard SHALL disable all five
   Quick_Actions_Bar buttons to prevent duplicate submissions.
9. WHEN "Trigger Maintenance" completes successfully, THE Dashboard SHALL show an
   `NxToast` with message "Global maintenance job queued."
10. IF "Trigger Maintenance" fails, THE Dashboard SHALL show an `NxToast` with error
    severity and the returned error message.


---

### Requirement 10: Proactive AI Suggestions Panel

**User Story:** As Hédra, I want a panel on the dashboard showing the current AI-generated
suggestions from ProactiveAIHub that are waiting for my review, so that I never miss an
insight or recommended action surfaced by the system's autonomous reasoning.

#### Acceptance Criteria

1. THE Dashboard SHALL render the Proactive_AI_Panel as a `NxGlassCard` sourcing its
   data from the `Dashboard_Stats_Endpoint` response's `proactive_suggestions` array.
2. THE `proactive_suggestions` array SHALL contain entries with: `id`, `title` (string),
   `body` (string, summary of the suggestion), `category`
   (`contact_insight` | `task_recommendation` | `memory_alert` | `workflow_trigger`),
   `priority` (`high` | `medium` | `low`), and `created_at` (ISO timestamp).
3. THE Proactive_AI_Panel SHALL render each suggestion as a card inside a
   `NxGlassCard` sub-panel showing: a category icon, `title`, a truncated `body`
   (max 120 characters), a priority badge, and a relative timestamp.
4. EACH suggestion card SHALL include an "Approve" and a "Dismiss" `NxActionButton`.
5. WHEN "Approve" is clicked on a suggestion, THE Dashboard SHALL call
   `POST /api/v1/proactive-ai/suggestions/{id}/approve` via `apiClient` and remove
   the card from the panel on success.
6. WHEN "Dismiss" is clicked on a suggestion, THE Dashboard SHALL call
   `POST /api/v1/proactive-ai/suggestions/{id}/dismiss` via `apiClient` and remove
   the card from the panel on success.
7. WHEN a `suggestion.created` event arrives on the `dashboard.{userId}` WebSocket
   channel, THE Dashboard SHALL append the new suggestion to the top of the
   Proactive_AI_Panel list.
8. IF `proactive_suggestions` is empty, THE Proactive_AI_Panel SHALL render
   `NxEmptyState` with the message "No pending suggestions — Nexus is watching."
9. THE panel header SHALL display a count badge showing the total number of pending
   suggestions.
10. THE Proactive_AI_Panel SHALL include a "View all" link navigating to
    `/proactive-ai`.


---

### Requirement 11: Scheduler Overview Panel

**User Story:** As Hédra, I want a compact panel on the dashboard listing the next few
upcoming scheduled jobs and reminders with their countdowns, so that I can anticipate
imminent automated actions and intervene if needed before they fire.

#### Acceptance Criteria

1. THE Dashboard SHALL render the Scheduler_Overview as a `NxGlassCard` sourcing its
   data from the `Dashboard_Stats_Endpoint` response's `upcoming_scheduled` array.
2. THE `upcoming_scheduled` array SHALL contain the next 3 upcoming scheduled jobs
   ordered by `fires_at` ascending, each entry with: `id`, `name`, `fires_at`
   (ISO timestamp), `type` (`job` | `reminder` | `workflow`), and `status`
   (`scheduled` | `paused`).
3. THE Scheduler_Overview SHALL render each entry showing: a type icon, the `name`,
   a live countdown (e.g., "in 14 min") that updates every 60 seconds in the browser,
   and a `NxStatusBadge` for `status`.
4. WHEN a scheduled entry's `fires_at` is within 5 minutes, THE Dashboard SHALL render
   its countdown in amber to signal imminent execution.
5. WHEN a scheduled entry's `fires_at` timestamp passes (countdown reaches zero),
   THE Dashboard SHALL remove the entry from the panel and refresh the
   `upcoming_scheduled` list via a re-fetch of `Dashboard_Stats_Endpoint`.
6. THE Scheduler_Overview SHALL include a "View scheduler" link navigating to
   `/scheduler`.
7. IF `upcoming_scheduled` is empty, THE Scheduler_Overview SHALL render `NxEmptyState`
   with message "No upcoming scheduled jobs."
8. WHEN a `scheduler.job_added` event arrives on the `dashboard.{userId}` WebSocket
   channel, THE Dashboard SHALL insert the new entry into the Scheduler_Overview in
   `fires_at` ascending order and remove the furthest entry if the count would exceed 3.


---

### Requirement 12: Responsive Layout and Grid System

**User Story:** As Hédra, I want the dashboard to adapt gracefully to all screen sizes —
desktop, tablet, and mobile — without losing any information or functionality, so that I
can monitor the platform from any device.

#### Acceptance Criteria

1. THE Dashboard SHALL implement a CSS grid layout with four columns on viewports
   ≥ 1280 px (desktop), two columns on viewports 768 px – 1279 px (tablet), and a
   single column on viewports < 768 px (mobile).
2. ON desktop (≥ 1280 px), THE Dashboard SHALL arrange the panels in the following
   grid layout: Key_Metrics_Cards spanning full width (4 columns), then
   AI_Usage_Panel (2 columns), Active_Agents_Jobs_Panel (2 columns), then
   Cognitive_Activity_Feed (2 columns), Recent_Contacts_Activity (1 column),
   Proactive_AI_Panel (1 column), then Memory_Health_Summary (1 column),
   Scheduler_Overview (1 column), and Quick_Actions_Bar spanning full width.
3. ON tablet (768 px – 1279 px), THE Dashboard SHALL collapse to a two-column grid
   where each panel either spans 1 column or 2 columns (full-width) depending on
   importance, with Key_Metrics_Cards always spanning full width.
4. ON mobile (< 768 px), THE Dashboard SHALL stack all panels into a single column
   in the following priority order: System_Health_Strip, Key_Metrics_Cards,
   Quick_Actions_Bar, Cognitive_Activity_Feed, Active_Agents_Jobs_Panel,
   Recent_Contacts_Activity, Proactive_AI_Panel, AI_Usage_Panel,
   Memory_Health_Summary, Scheduler_Overview.
5. THE System_Health_Strip SHALL remain fixed at the top of the dashboard scroll
   container on all breakpoints, not scrolling out of view.
6. ON mobile, THE Quick_Actions_Bar buttons SHALL wrap to a 2×3 grid rather than
   overflowing horizontally.
7. WHILE on mobile, THE Cognitive_Activity_Feed panel height SHALL be capped at
   300 px with internal scroll to prevent it dominating the single-column layout.
8. ALL `Nx*` component sizes (padding, font sizes, icon sizes) SHALL follow the
   component's built-in responsive props rather than overriding them with arbitrary
   Tailwind classes.


---

### Requirement 13: Dashboard Backend Aggregation Endpoints

**User Story:** As a backend developer, I want three dedicated dashboard API endpoints
that aggregate data from all hubs into lean, purpose-built response shapes, so that the
frontend never has to fan out to multiple hub endpoints from a single page load.

#### Acceptance Criteria

1. THE Backend SHALL expose `GET /api/v1/dashboard/stats` protected by Sanctum
   authentication that returns a single JSON object aggregating data from all hubs
   in a structure defined by Requirements 1, 4, 5, 6, 7, 8, 9, 10, and 11.
2. THE `GET /api/v1/dashboard/stats` endpoint SHALL respond within 800 ms at the
   95th percentile by using a combination of Redis caching (TTL 55 seconds) and
   parallel query execution where hub data can be fetched concurrently.
3. THE Backend SHALL expose `GET /api/v1/dashboard/activity-feed` accepting optional
   query parameters `limit` (default 20, max 100) and `before` (cursor, ISO timestamp)
   that returns a paginated list of recent cognitive events from LogsHub.
4. EACH activity feed entry SHALL contain: `id`, `type` (event type string), `hub`
   (source hub name), `message` (human-readable description), `severity`
   (`info` | `warning` | `error`), and `occurred_at` (ISO timestamp).
5. THE Backend SHALL expose `GET /api/v1/dashboard/health` that performs a live
   health probe of each hub's key services and returns the `services` array described
   in Requirement 2.
6. THE `GET /api/v1/dashboard/health` endpoint SHALL perform service probes with a
   maximum timeout of 3 seconds per probe, returning partial results (with
   `status: unknown` for timed-out probes) rather than failing the entire request.
7. IF a request to any dashboard endpoint is unauthenticated, THE Backend SHALL
   return 401 Unauthorized.
8. THE Backend SHALL expose `GET /api/v1/dashboard/stats` to the standard Nexus
   rate-limiting policy (60 requests per minute per authenticated user) and return
   429 Too Many Requests with a `Retry-After` header when exceeded.


---

### Requirement 14: Dashboard WebSocket Event Broadcasting

**User Story:** As a backend developer, I want the backend to broadcast structured events
on the `dashboard.{userId}` Reverb channel whenever significant platform state changes
occur, so that the frontend Cognitive_Activity_Feed and individual panels can update in
real time without polling.

#### Acceptance Criteria

1. THE Backend SHALL broadcast on channel `dashboard.{userId}` whenever any of the
   following events occur: a new memory is extracted, a contact interaction is recorded,
   an agent changes status, a Horizon job transitions state, a task is completed, a
   ProactiveAI suggestion is created, or a scheduler job fires.
2. EACH broadcast event payload SHALL include: `type` (event type string matching the
   categories in Requirement 3 criteria 5), `hub` (source hub name), `message`
   (human-readable summary ≤ 120 characters), `severity` (`info` | `warning` | `error`),
   `occurred_at` (ISO timestamp), and a `payload` object with event-specific data.
3. WHEN an agent changes status, THE Backend SHALL include `agent_id`, `agent_name`,
   and `new_status` in the broadcast `payload`.
4. WHEN a Horizon job transitions state, THE Backend SHALL include `job_id`, `job_name`,
   `queue`, `new_status`, and `progress_pct` in the broadcast `payload`.
5. WHEN a ProactiveAI suggestion is created, THE Backend SHALL include the full
   suggestion object (id, title, body, category, priority) in the broadcast `payload`.
6. WHEN a scheduler job fires, THE Backend SHALL include `job_id`, `job_name`, and
   `fired_at` in the broadcast `payload`.
7. THE Backend SHALL authorize `dashboard.{userId}` as a private Reverb channel,
   verifying the authenticated user id matches the channel suffix before allowing
   subscription.
8. IF broadcasting fails due to a Reverb connection error, THE Backend SHALL log the
   failure to LogsHub and continue processing without rethrowing the exception to avoid
   breaking the originating operation.


---

### Requirement 15: Error Handling and Loading States

**User Story:** As Hédra, I want every panel on the dashboard to handle loading and
error states gracefully and consistently, so that a failing hub or slow API never leaves
me staring at broken UI or empty panels without explanation.

#### Acceptance Criteria

1. WHEN any dashboard API call is in flight, THE Dashboard SHALL render `NxSkeleton`
   placeholders within the affected panel matching its expected height and layout
   — it SHALL NOT show a blank white area or an invisible panel.
2. WHEN an API call returns a 4xx or 5xx response, THE Dashboard SHALL render an
   inline error state within the affected panel showing the HTTP status, a brief
   error description, and a "Retry" `NxActionButton` that re-triggers the failed
   call — it SHALL NOT crash the entire dashboard page.
3. WHEN an API call returns a 401 Unauthorized response, THE Dashboard SHALL redirect
   to `/login` using the Next.js router rather than showing an error panel.
4. WHEN an API call returns a 429 Too Many Requests response, THE Dashboard SHALL
   wait for the duration specified in the `Retry-After` response header before
   automatically retrying — it SHALL NOT enter an immediate retry loop.
5. WHEN the WebSocket connection is healthy, THE Dashboard SHALL show a green
   connection indicator dot in the Cognitive_Activity_Feed panel header.
6. WHEN the WebSocket connection is disconnected, THE Dashboard SHALL show a red
   disconnection indicator and display the "Reconnecting…" message inside the feed.
7. ALL error banners and retry buttons SHALL be implemented using the existing
   `Nx*` component set — no new ad-hoc error UI components are to be introduced.
8. WHEN a panel's data loads successfully after a previous error state, THE Dashboard
   SHALL clear the error state and render the panel's normal content without requiring
   a full page reload.
9. IF all six `Key_Metrics_Cards` fail to load simultaneously, THE Dashboard SHALL
   display a single consolidated error banner above the metrics row rather than six
   individual panel errors.


---

### Requirement 16: Dashboard Visual Design and Design System Compliance

**User Story:** As Hédra, I want the NexusHub Dashboard to be visually cohesive with the
rest of the Nexus platform — glassmorphic dark theme, correct color tokens, consistent
typography — so that it feels like a unified product and not a collection of mismatched
widgets.

#### Acceptance Criteria

1. ALL panel containers on the dashboard SHALL use `NxGlassCard` as their root element
   — no raw `<div>` cards with ad-hoc Tailwind border and background classes are
   permitted.
2. ALL interactive controls SHALL use `NxActionButton` — no raw `<button>` elements
   styled inline.
3. THE dashboard background SHALL use the `--bg-deep` CSS token (`hsl(224, 71%, 4%)`)
   consistent with the rest of the platform.
4. ALL typography SHALL use the project-standard typefaces: `Inter` for UI labels and
   body text, `Outfit` for metric values and section headings, and `JetBrains Mono`
   for any feed entries, latency values, or log-style content in the
   Cognitive_Activity_Feed.
5. WHEN any dashboard panel is in a loading state, the `NxSkeleton` component's default
   animation SHALL be visible — no custom loading spinners or plain gray boxes.
6. ALL status colors SHALL use the project's semantic CSS tokens: green `--success`
   for healthy/online states, `--amber` for warning/degraded states, `--error` for
   failed/offline states, and `--nexus-blue` for primary interactive elements.
7. THE dashboard SHALL not introduce any new CSS variables, color values, or
   font-family declarations outside of those already defined in `globals.css`.
8. THE dashboard page SHALL pass a basic accessibility check: all icon-only buttons
   SHALL have an `aria-label`, all status badges SHALL have sufficient color contrast,
   and all interactive elements SHALL be keyboard-focusable.
9. WHEN a panel card is hovered on desktop, THE Dashboard SHALL apply the standard
   `transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1)` hover scale defined in the
   platform's micro-transition specification.

