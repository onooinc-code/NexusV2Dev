# Implementation Plan: PeopleConnectHub Complete

## Overview

This plan implements PeopleConnectHub from scratch across two codebases.
Work is sequenced as: Phase 1 fix broken webhook → Phase 2 data model → Phase 3 ingestion pipeline → Phase 4 scheduled sync + session lifecycle → Phase 5 API routes + controllers → Phase 6 reply mode + outgoing queue → Phase 7 analysis + context + agent reply → Phase 8 realtime → Phase 9 frontend hub + components → Phase 10 modals → Phase 11 property-based tests.

## Tasks

- [ ] 1. Phase 1 — Fix Broken WAHA Webhook Handler
  - [ ] 1.1 Rewrite `WebhookController::handleWahaWebhook()` to accept real WAHA payload
    - Remove the `conversation_id` required validation
    - Accept `event`, `session`, `payload.chatId`, `payload.from`, `payload.body`, `payload.id`, `payload.timestamp`
    - Validate a shared-secret header (read from `SettingsHub` or `.env`)
    - Return HTTP 401 on secret mismatch, 422 on missing required fields
    - Return HTTP 202 immediately; dispatch `ProcessWahaWebhookJob` (to be created)
    - _Requirements: 2.1, 2.4, 2.5_

  - [ ] 1.2 Remove incorrect `ProcessAiInferenceJob` dispatch from webhook handler
    - Delete the `ProcessAiInferenceJob::dispatch()` call inside `handleWahaWebhook()`
    - The webhook handler now only validates, stores the raw event, and dispatches `ProcessWahaWebhookJob`
    - _Requirements: 2.3_

  - [ ]* 1.3 Write `WahaWebhookTest` for the fixed handler
    - Assert real WAHA payload format (chatId/from/session) is accepted with 202
    - Assert old format requiring `conversation_id` is rejected with 422
    - Assert invalid secret returns 401
    - Assert duplicate event (same session+payload.id) is not re-dispatched
    - _Requirements: 2.1, 2.4, 2.6_

- [ ] 2. Phase 2 — Data Model: 13 Migrations + 13 Models
  - [ ] 2.1 Create `peopleconnect_conversations` and `peopleconnect_sessions` migrations and models
    - Migration: `create_peopleconnect_conversations_table` with all columns from design
    - Migration: `create_peopleconnect_sessions_table`
    - Models: `PeopleConnectConversation`, `PeopleConnectSession` with Eloquent relationships
    - Add unique index `(contact_id, channel, provider)` on conversations
    - _Requirements: 1.1, 1.2_

  - [ ] 2.2 Create `peopleconnect_messages` migration and model
    - Migration: `create_peopleconnect_messages_table` with all 30+ columns
    - Add unique index `(conversation_id, waha_message_id)` (partial, where not null)
    - Add index on `provider_payload_hash`
    - Model: `PeopleConnectMessage` with all fillable fields and casts (json columns)
    - _Requirements: 1.3, 6.1_

  - [ ] 2.3 Create remaining 10 migrations and models
    - `peopleconnect_message_analyses`, `peopleconnect_message_tags`
    - `peopleconnect_context_snapshots`, `peopleconnect_reply_drafts`
    - `peopleconnect_delivery_attempts`, `peopleconnect_sync_runs`
    - `peopleconnect_raw_provider_events`, `peopleconnect_processing_logs`
    - `peopleconnect_conversation_topics`, `peopleconnect_reply_mode_overrides`
    - Each migration follows the column schema in the design document
    - _Requirements: 1.4–1.13_

  - [ ]* 2.4 Write model relationship tests
    - Assert `PeopleConnectConversation` → `PeopleConnectSession` → `PeopleConnectMessage` chain works
    - Assert `PeopleConnectMessage` → `PeopleConnectMessageAnalysis` accessible
    - Assert unique constraint on `(conversation_id, waha_message_id)` enforced at DB level
    - _Requirements: 1.14_

- [ ] 3. Checkpoint — Data Model Complete
  - Run `php artisan migrate` and verify all 13 tables are created cleanly.
  - Ask the user if questions arise before proceeding.

- [ ] 4. Phase 3 — Webhook Ingestion Pipeline Services

  - [ ] 4.1 Create `WahaWebhookIngestionService`
    - File: `app/Services/PeopleConnect/WahaWebhookIngestionService.php`
    - `ingest(array $payload): void` — validates secret, stores raw event in `peopleconnect_raw_provider_events`, deduplicates by `session+payload.id`, dispatches `ProcessWahaWebhookJob`
    - Wire this service into `WebhookController::handleWahaWebhook()`
    - _Requirements: 2.2, 2.3, 2.6_

  - [ ] 4.2 Create `PeopleConnectContactResolver`
    - File: `app/Services/PeopleConnect/PeopleConnectContactResolver.php`
    - `resolve(string $chatId, string $phone, string $displayName): Contact`
    - Searches `contact_identifiers` by type `whatsapp` and `phone`
    - Creates new ContactHub contact via `ContactHubService` if not found; uses WhatsApp display name or phone as contact name
    - _Requirements: 3.1, 3.2_

  - [ ] 4.3 Create `PeopleConnectConversationService` and `PeopleConnectSessionService`
    - `PeopleConnectConversationService::resolveOrCreate(int $contactId, string $channel, string $chatId): PeopleConnectConversation`
    - Enforces one canonical conversation per contact per channel/provider
    - `PeopleConnectSessionService::resolveOrOpen(PeopleConnectConversation $conv, Carbon $messageTime): PeopleConnectSession`
    - Closes existing session if last message was 2+ hours ago, opens new session
    - _Requirements: 3.3, 3.4, 3.5_

  - [ ] 4.4 Create `PeopleConnectMessageService` with deduplication
    - File: `app/Services/PeopleConnect/PeopleConnectMessageService.php`
    - `insert(array $data): PeopleConnectMessage`
    - Checks `waha_message_id` uniqueness within conversation
    - Computes and checks `provider_payload_hash` (SHA-256 of normalized raw payload)
    - Throws `DuplicateMessageException` on dedup hit; logs `dedup_skipped` in `peopleconnect_processing_logs`
    - _Requirements: 3.6, 6.1, 6.2, 6.3, 6.4_

  - [ ] 4.5 Create `ProcessWahaWebhookJob`
    - File: `app/Jobs/ProcessWahaWebhookJob.php`
    - Dispatched to `peopleconnect` queue
    - Orchestrates: contact resolve → conversation resolve → session resolve → message insert → dispatch `AnalyzePeopleConnectMessageJob` → broadcast `message.received`
    - Implements `failed(Throwable $e)` to log failure to `peopleconnect_processing_logs`
    - _Requirements: 3.1–3.8_

  - [ ]* 4.6 Write ingestion pipeline feature tests
    - `WahaWebhookIngestionServiceTest`: assert raw event stored; assert dedup on second delivery (Property 17)
    - `PeopleConnectContactResolverTest`: assert new contact created for unknown chatId (Property 5)
    - `PeopleConnectSessionServiceTest`: assert new session opened after 2h gap (Property 3)
    - `PeopleConnectMessageServiceTest`: assert dedup — 10 identical payloads → 1 message (Property 1)
    - `ProcessWahaWebhookJobTest`: assert all 5 pipeline steps execute in correct order
    - _Requirements: 2.6, 3.1–3.8, 6.5_

- [ ] 5. Phase 4 — Scheduled Sync + Session Lifecycle Jobs

  - [ ] 5.1 Create `LiveMsgsSyncService` and sync jobs
    - `LiveMsgsSyncService` at `app/Services/PeopleConnect/LiveMsgsSyncService.php`
    - Methods: `syncContacts()`, `syncConversations()`, `syncMessages()` — call WAHA API, use same resolver/service chain as webhook ingestion, write `peopleconnect_sync_runs` record
    - Create `SyncWahaContactsJob`, `SyncWahaConversationsJob`, `SyncWahaMessagesJob`
    - Register in SchedulerHub / `app/Console/Kernel.php` to run hourly
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [ ] 5.2 Create `CloseInactivePeopleConnectSessionsJob`
    - Queries open sessions where `last_message_at < now()-2h` using the session's latest message
    - Closes each session with `closed_reason = 'inactivity'`, broadcasts `session.closed`
    - Register in SchedulerHub to run every 15 minutes
    - _Requirements: 5.2, 5.3, 5.5_

  - [ ] 5.3 Create `ReconcileWahaDeliveryStatusJob`
    - Fetches WAHA acks for sent messages without `delivered_at` older than 24 hours
    - Updates delivery status accordingly; writes delivery attempts
    - Register in SchedulerHub to run hourly
    - _Requirements: 4.5_

  - [ ]* 5.4 Write scheduled sync tests
    - Assert `SyncWahaMessagesJob` inserts missing messages without creating duplicates (Property 1 — global)
    - Assert sync run record written with correct counts (Req 4.4)
    - Assert `CloseInactivePeopleConnectSessionsJob` closes sessions past 2h threshold (Property 2)
    - Assert `CloseInactivePeopleConnectSessionsJob` does NOT close recently active sessions
    - _Requirements: 4.1–4.6, 5.2, 5.5_

- [ ] 6. Phase 5 — API Routes + Controllers

  - [ ] 6.1 Create PeopleConnect controllers and register all API routes
    - Create controllers in `app/Http/Controllers/PeopleConnect/`:
      - `PeopleConnectConversationController` (list, show, header, sessions, topics, context, memories, tasks, rules, notes)
      - `PeopleConnectMessageController` (list, create, retry, draft-reply, create-task, save-note, trace, raw-event)
      - `PeopleConnectLiveMsgsController` (status, sync-runs, sync-now, reconcile, pending-outgoing, retry-failed)
      - `PeopleConnectReplyModeController` (global get/patch, per-conversation patch)
      - `PeopleConnectSearchController`, `PeopleConnectStatsController`
    - Register all 40+ routes in `routes/api.php` under `/api/v1/peopleconnect/` prefix
    - _Requirements: 7.1–7.16_

  - [ ] 6.2 Implement conversation and message endpoints
    - `GET /conversations` — paginated list with contact name, preview, unread, reply mode, agent status
    - `GET /conversations/{id}` — full conversation with header analytics
    - `GET /conversations/{id}/messages` — paginated with cursor support, all analysis fields
    - `POST /conversations/{id}/messages` — saves with `status = 'queued'`, dispatches `DispatchWahaMessageJob`
    - `POST /messages/{id}/retry` — resets to `queued`, dispatches new `DispatchWahaMessageJob`
    - _Requirements: 7.1–7.5_

  - [ ] 6.3 Implement LiveMsgs and reply-mode endpoints
    - `GET /livemsgs/status` — WAHA connection state, last webhook time, last sync time, pending/failed counts
    - `POST /livemsgs/sync-now` — dispatches `SyncWahaMessagesJob` immediately
    - `POST /livemsgs/reconcile` — dispatches `ReconcileWahaDeliveryStatusJob`
    - `GET/PATCH /reply-mode` — global mode from SettingsHub
    - `PATCH /conversations/{id}/reply-mode` — stores in `peopleconnect_reply_mode_overrides`
    - _Requirements: 7.6–7.10_

  - [ ]* 6.4 Write `PeopleConnectConversationsApiTest` and `PeopleConnectMessagesApiTest`
    - Assert list returns paginated conversations with correct fields
    - Assert POST to messages creates record with `status = 'queued'` and dispatches job (Property 10)
    - Assert retry endpoint re-queues failed message (Property 16)
    - Assert all endpoints return 401 for unauthenticated requests (Req 7.16)
    - _Requirements: 7.1–7.5, 11.1, 11.8_

- [ ] 7. Phase 6 — Reply Mode + Outgoing Queue + Safety

  - [ ] 7.1 Create `PeopleConnectReplyModeService`
    - `resolveEffectiveMode(int $contactId): string` — checks `peopleconnect_reply_mode_overrides`, falls back to global SettingsHub value
    - `checkAutopilotSafety(int $contactId, PeopleConnectMessage $trigger): SafetyResult` — all 7 conditions atomically
    - On block: writes `peopleconnect_processing_logs` with `autopilot_blocked`, broadcasts `autopilot.blocked` event
    - _Requirements: 8.1, 8.2, 8.5, 10.1–10.6_

  - [ ] 7.2 Create `WahaMessageDispatcher` and `DispatchWahaMessageJob`
    - `WahaMessageDispatcher::send(PeopleConnectMessage $message): void` — calls WAHA API, writes delivery attempt, updates message status, enforces per-contact rate limit
    - `DispatchWahaMessageJob`: `tries = 3`, exponential backoff, `failed()` hook marks message `failed` and broadcasts `message.failed`
    - _Requirements: 11.1–11.9_

  - [ ] 7.3 Create `GenerateContactReplyDraftJob`
    - Dispatched when effective mode is `copilot` or triggered manually via `draft-reply` endpoint
    - Calls `PeopleConnectContextAssembler::assemble()` → calls `PeopleConnectAgentReplyService::generateDraft()` → stores in `peopleconnect_reply_drafts` with `status = 'pending_approval'` → broadcasts `reply.draft.created`
    - `failed()` sets draft to `failed` and broadcasts error event
    - _Requirements: 9.1–9.7_

  - [ ]* 7.4 Write reply mode and safety tests
    - `PeopleConnectReplyModeServiceTest`: assert contact override wins over global (Property 6)
    - Assert each of the 7 autopilot safety conditions individually blocks the send (Property 7)
    - Assert `DispatchWahaMessageJob` writes delivery attempt on success and failure (Property 11)
    - Assert outgoing message persisted before job dispatched (Property 10)
    - _Requirements: 8.2, 8.5, 10.1–10.2, 11.1–11.2_

- [ ] 8. Phase 7 — Analysis + Context + Agent Reply + Realtime

  - [ ] 8.1 Create `PeopleConnectAnalysisService` and `AnalyzePeopleConnectMessageJob`
    - `PeopleConnectAnalysisService::analyze(PeopleConnectMessage $message): PeopleConnectMessageAnalysis`
    - Calls AiModelsHub with `Intent_Detection` and `Contact_Analysis` intents
    - Writes `peopleconnect_message_analyses`, updates message fields, creates/updates `peopleconnect_conversation_topics`
    - Recomputes `emotional_baseline_snapshot` from rolling session window
    - `AnalyzePeopleConnectMessageJob`: `tries = 3`, exponential backoff, `failed()` logs failure
    - _Requirements: 12.1–12.7_

  - [ ] 8.2 Create `PeopleConnectContextAssembler`
    - `assemble(PeopleConnectConversation $conv): PeopleConnectContextSnapshot`
    - Collects: contact profile, active rules, pinned notes, relevant memories, last session summary, topic history, recent messages up to token budget
    - Computes `token_estimate`, truncates oldest messages first if over budget
    - Records excluded items + reasons in snapshot payload
    - Stores frozen `peopleconnect_context_snapshots` record before invoking AgentsHub
    - _Requirements: 13.1–13.5_

  - [ ] 8.3 Create `PeopleConnectAgentReplyService` and `PeopleConnectRealtimeBroadcaster`
    - `PeopleConnectAgentReplyService::generateDraft(PeopleConnectContextSnapshot $ctx, int $agentId): string` — calls AgentsHub, returns body + trace_id
    - `PeopleConnectRealtimeBroadcaster` — broadcasts all 18 events to Reverb channels
    - Create Laravel event classes in `app/Events/PeopleConnect/` for all events
    - Define private channels in `routes/channels.php`
    - _Requirements: 14.1–14.3_

  - [ ]* 8.4 Write analysis, context, and realtime tests
    - Assert `AnalyzePeopleConnectMessageJob` creates analysis record and broadcasts `message.analyzed`
    - Assert context snapshot stored matches context sent to AgentsHub (Property 12)
    - Assert `peopleconnect.conversation.{id}` channel receives `message.received` event when message saved
    - Assert 7 conditions in autopilot safety log `autopilot_blocked` event (Req 10.3, 10.4)
    - _Requirements: 12.1–12.7, 13.6, 14.1–14.3_

- [ ] 9. Checkpoint — Backend Complete
  - Run full backend test suite (`php artisan test`). Run `php artisan route:list | grep peopleconnect` to confirm all routes registered.
  - Ask the user if questions arise before proceeding to frontend.

- [ ] 10. Phase 9 — Frontend: Standalone Hub + Core Components

  - [ ] 10.1 Create `/app/people-connect/page.tsx` and add nav item
    - Create `app/people-connect/page.tsx` as the hub shell
    - Remove `app/conversations/page.tsx` or replace it with a redirect to `/people-connect`
    - Add PeopleConnect nav item to `AppLayout` (using `MessageCircle` icon)
    - Page fetches conversation list from `GET /api/v1/peopleconnect/conversations` on mount
    - Shows `NxSkeleton` while loading, error boundary with retry on failure
    - Sets up Laravel Echo subscriptions for `peopleconnect.hub` and active conversation channel
    - _Requirements: 15.1–15.6_

  - [ ] 10.2 Create `NxPeopleConnectTopbar` component
    - WAHA status light (green/amber/red based on connection state)
    - Global reply mode segmented control (Manual / Copilot / Autopilot) wired to `GET/PATCH /reply-mode`
    - Pending outgoing counter with severity color
    - Incoming save indicator (spinner when `isSyncing`)
    - LiveMsgs button opening `NxLiveMsgsModal`
    - Hub stats strip from `GET /api/v1/peopleconnect/stats`
    - _Requirements: 16.1–16.6_

  - [ ] 10.3 Create `NxLiveMsgsModal` component
    - WAHA connection state, session name, last webhook time, last sync time
    - Counters from `GET /livemsgs/status`
    - Sync Now / Reconcile Gaps / Retry Failed Sends buttons
    - Sync run history from `GET /livemsgs/sync-runs`
    - Diagnostics: last 10 processing log entries
    - _Requirements: 17.1–17.7_

  - [ ] 10.4 Create `NxConversationSidebar` component
    - Conversation list items with all required fields (name, phone, preview, unread badge, channel icon, reply mode chip, agent status, failed warning)
    - Search input (client-side filter on loaded list)
    - Filter chips: Unread, Manual/Copilot/Autopilot, Failed
    - Error state with retry button (no silent failure)
    - Realtime update via `message.received` Reverb event: update preview + unread badge in-place
    - _Requirements: 18.1–18.6_

  - [ ] 10.5 Create `NxConversationHeader` component
    - Display topic, intent, emotional baseline, tone mirroring, sentiment from `GET .../header`
    - Background processing log ticker (last 3 entries, auto-scrolls via Reverb `processing_log` events)
    - Reply mode indicator (distinguishes override from global)
    - Quick-action buttons: Rules, Notes, Context, Memories, Tasks, Contact360 link
    - Searchable topic dropdown wired to `GET .../topics`; click triggers scroll in `NxMessagePanel`
    - Refresh analysis fields on `message.analyzed` Reverb event
    - _Requirements: 19.1–19.6_

  - [ ] 10.6 Create `NxMessagePanel` component with virtualization
    - Install `@tanstack/react-virtual` in `Nexus-Frontend/package.json`
    - Virtualized list using `useVirtualizer` for conversations with 500+ messages
    - Date separators, session separators, sender-type color coding
    - Delivery status icons per outgoing message (queued/sending/sent/delivered/read/failed)
    - Retry button on failed messages → `POST /messages/{id}/retry`
    - Per-message toolbar on hover (topic, intent, tone, sentiment, emotional baseline, copy, draft reply, create task, save note, raw event link)
    - Append new messages via Reverb without full refetch; update delivery status in-place
    - Session separators inserted via Reverb `session.opened/closed` events
    - _Requirements: 20.1–20.9_

  - [ ] 10.7 Create `NxComposer` component
    - Manual mode: textarea + Send button → `POST .../messages`
    - Copilot mode with draft: shows draft body with Edit/Approve/Reject actions
    - Approve → `PATCH /reply-drafts/{id}` with status `approved` → dispatches send
    - Ask Agent button → `POST /messages/{id}/draft-reply`
    - WAHA disconnected warning banner (disables send)
    - On send failure: saves draft to local state, shows error + retry
    - File attach with size validation
    - _Requirements: 21.1–21.7_

  - [ ]* 10.8 Write component tests for core frontend components
    - `NxMessagePanel`: assert 4 sender type colors; assert delivery status icons; assert virtualized list renders correctly with 500+ items; assert `message.received` Reverb event appends without refetch (Property 14)
    - `NxComposer`: assert send calls correct API; assert draft displayed in copilot mode; assert WAHA warning disables send
    - `NxPeopleConnectTopbar`: assert WAHA status light colors; assert reply mode control calls PATCH; assert stats displayed (Property 13)
    - `NxConversationSidebar`: assert error state shows retry; assert Reverb update refreshes preview in-place
    - _Requirements: 16.1–16.6, 18.1–18.6, 20.1–20.9, 21.1–21.7_

- [ ] 11. Phase 10 — Frontend: Contact Modals

  - [ ] 11.1 Create `NxContactRulesModal`
    - Loads `GET .../rules` on open
    - CRUD operations: add, edit, deactivate, delete
    - AI-suggested rules with approve/reject actions
    - Error state with retry; no blank view on failure
    - _Requirements: 22.1, 22.2_

  - [ ] 11.2 Create `NxContactNotesModal`
    - Loads `GET .../notes` on open
    - CRUD: add, edit, pin, delete; pinned notes at top
    - _Requirements: 22.3_

  - [ ] 11.3 Create `NxContextModal`
    - Loads `GET .../context/latest` on open
    - Sections: contact profile, rules, notes, messages, session summary, memories, token estimate, excluded items
    - _Requirements: 22.4_

  - [ ] 11.4 Create `NxMemoriesModal`
    - Loads `GET .../memories/latest` on open
    - Recently extracted, injected, and suggested memories
    - Approve/reject/edit per suggested memory
    - _Requirements: 22.5_

  - [ ] 11.5 Create `NxContactTasksModal`
    - Loads `GET .../tasks` on open
    - Open, completed, failed task lists
    - Create task action linked to current conversation
    - _Requirements: 22.6_

  - [ ]* 11.6 Write modal component tests
    - Assert each modal fetches correct endpoint on open
    - Assert each modal shows error state with retry on API failure (Req 22.7)
    - Assert `NxContactRulesModal` approve action calls correct API
    - Assert `NxContextModal` displays all 7 required sections

- [ ] 12. Phase 11 — Property-Based Tests

  - [ ] 12.1 Backend PBT — Dedup and Session Properties (Properties 1–5, 17)
    - **Property 1**: Generate 100+ sequences of N identical WAHA payloads; assert exactly 1 message created
    - **Property 2**: Generate 100+ sessions past 2h threshold; assert all closed by job run
    - **Property 3**: Generate 100+ closed conversations; assert next message always opens new session
    - **Property 4**: Call `resolveOrCreate` 100+ times for same contact; assert always returns same record
    - **Property 5**: Generate 100+ unknown chatIds; assert new contact created each time and resolved on repeat
    - **Property 17**: Generate 100+ duplicate raw event pairs; assert only 1 job dispatched per pair
    - _Requirements: 3.3, 5.1, 5.2, 6.1, 6.5_

  - [ ] 12.2 Backend PBT — Reply Mode and Safety Properties (Properties 6–12)
    - **Property 6**: For 100+ combinations of global mode + contact override, assert effective mode is override when present, global when absent
    - **Property 7**: For each of 7 blocking conditions (100 iterations each), assert autopilot blocked
    - **Property 8**: For 100+ draft generations, assert draft record written before `draft.created` broadcast
    - **Property 9**: For 100+ webhook POSTs, assert HTTP 202 returned before job starts executing
    - **Property 10**: For 100+ outbound messages, assert DB record with `status=queued` before job dispatch
    - **Property 11**: For 100+ `DispatchWahaMessageJob` executions, assert exactly 1 delivery attempt written
    - **Property 12**: For 100+ context snapshots, assert snapshot payload matches context sent to AgentsHub
    - _Requirements: 8.2, 8.5, 9.3, 10.2, 11.1, 11.2, 13.6_

  - [ ] 12.3 Frontend PBT (fast-check) — Realtime and UI Properties (Properties 13–16)
    - Install `fast-check` in `Nexus-Frontend/` if not present
    - **Property 13**: For 100+ Reverb `waha.connected` events, assert topbar WAHA status updates without page reload
    - **Property 14**: For 100+ Reverb `message.received` events, assert message appended without full list refetch
    - **Property 15**: For 100+ Reverb `message.delivered` events with random message IDs, assert only matching message's delivery status updates
    - **Property 16**: For 100+ failed messages triggering retry, assert exactly 1 new `DispatchWahaMessageJob` dispatched each time
    - _Requirements: 11.8, 14.4, 14.5, 14.6_

- [ ] 13. Final Checkpoint — All Tests Pass
  - Run `php artisan test`. Run `npm run test -- --run`. Run `next build` with no TypeScript errors.
  - Ask the user if questions arise.

## Notes

- Tasks marked `*` are optional and can be skipped for faster MVP delivery.
- Phase 1 (fix webhook) must complete before Phase 2. Phase 2 (data model) before Phase 3–5.
- Frontend phases (9–11) can run in parallel with backend Phase 8 once Phase 6 is merged.
- All backend jobs must implement `failed(Throwable $e)`.
- All frontend components use `apiClient` — no raw `fetch()`, no hardcoded hostnames.
- The `react-virtual` install in task 10.6 requires `npm install @tanstack/react-virtual` in `Nexus-Frontend/`.
- Property-based tests use Pest data-driven tests with Faker on the backend; `fast-check` on the frontend.
- Minimum 100 iterations per property test.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3", "2.1", "2.2", "2.3"] },
    { "id": 2, "tasks": ["2.4", "4.1", "4.2", "4.3"] },
    { "id": 3, "tasks": ["4.4", "4.5", "5.1", "5.2"] },
    { "id": 4, "tasks": ["4.6", "5.3", "5.4", "6.1"] },
    { "id": 5, "tasks": ["6.2", "6.3", "7.1"] },
    { "id": 6, "tasks": ["6.4", "7.2", "7.3", "8.1"] },
    { "id": 7, "tasks": ["7.4", "8.2", "8.3"] },
    { "id": 8, "tasks": ["8.4", "10.1"] },
    { "id": 9, "tasks": ["10.2", "10.3", "10.4"] },
    { "id": 10, "tasks": ["10.5", "10.6", "10.7"] },
    { "id": 11, "tasks": ["10.8", "11.1", "11.2", "11.3"] },
    { "id": 12, "tasks": ["11.4", "11.5"] },
    { "id": 13, "tasks": ["11.6", "12.1", "12.2"] },
    { "id": 14, "tasks": ["12.3"] }
  ]
}
```
