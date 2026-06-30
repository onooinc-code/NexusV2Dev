# Requirements Document

## PeopleConnectHub Complete Implementation

## Audit Report

This section documents the current state of the PeopleConnectHub implementation across both
Nexus-Frontend (Next.js/TypeScript) and Nexus-backend (Laravel/PHP), identifying all missing
implementations, discrepancies, and defects that must be resolved before PeopleConnectHub
can be considered complete.

---

## 🛑 Missing Implementations

### Backend — Missing Implementations

**B-M-01** All 13 PeopleConnect-specific database tables are absent. The tables
`peopleconnect_conversations`, `peopleconnect_sessions`, `peopleconnect_messages`,
`peopleconnect_message_analyses`, `peopleconnect_message_tags`,
`peopleconnect_context_snapshots`, `peopleconnect_reply_drafts`,
`peopleconnect_delivery_attempts`, `peopleconnect_sync_runs`,
`peopleconnect_raw_provider_events`, `peopleconnect_processing_logs`,
`peopleconnect_conversation_topics`, and `peopleconnect_reply_mode_overrides`
do not exist. No migrations have been written.

**B-M-02** All 14 recommended PeopleConnect service classes are absent:
`PeopleConnectConversationService`, `PeopleConnectSessionService`,
`PeopleConnectMessageService`, `LiveMsgsSyncService`,
`WahaWebhookIngestionService`, `WahaPollingReconciliationService`,
`WahaMessageDispatcher`, `PeopleConnectContactResolver`,
`PeopleConnectReplyModeService`, `PeopleConnectContextAssembler`,
`PeopleConnectAnalysisService`, `PeopleConnectAgentReplyService`,
`PeopleConnectSearchService`, and `PeopleConnectRealtimeBroadcaster`.

**B-M-03** All 10 recommended queue jobs are absent: `SyncWahaContactsJob`,
`SyncWahaConversationsJob`, `SyncWahaMessagesJob`, `ProcessWahaWebhookJob`,
`AnalyzePeopleConnectMessageJob`, `AssemblePeopleConnectContextJob`,
`GenerateContactReplyDraftJob`, `DispatchWahaMessageJob`,
`ReconcileWahaDeliveryStatusJob`, and `CloseInactivePeopleConnectSessionsJob`.


**B-M-04** No dedicated PeopleConnect controllers exist. There are no controllers for
conversations, sessions, messages, reply mode, rules, notes, search, analytics, or LiveMsgs
under the `/api/v1/peopleconnect/` route prefix.

**B-M-05** No API routes exist under `/api/v1/peopleconnect/`. All 40+ required endpoints
covering conversations, messages, sessions, LiveMsgs, reply mode, rules, notes, search,
and analytics are completely absent.

**B-M-06** No reply mode infrastructure exists anywhere in the stack. There is no global
reply mode setting, no per-contact override, no copilot draft approval flow, and no
autopilot safety enforcement mechanism.

**B-M-07** No outgoing message queue exists. There is no `DispatchWahaMessageJob`, no
delivery status tracking model, no retry mechanism for failed sends, and no pending
outgoing message counter.

**B-M-08** No message deduplication exists. There is no provider message ID uniqueness
check and no provider payload hash check. Duplicate WAHA webhook deliveries will create
duplicate message records.

**B-M-09** No message analysis pipeline exists. There is no topic detection, intent
extraction, tone analysis, sentiment analysis, emotional baseline tracking, or tone
mirroring calculation for any message.

**B-M-10** No session lifecycle management exists. There is no two-hour inactivity
auto-close scheduler, no session open/close event broadcasting, and no session summary
generation.

**B-M-11** No WAHA health status API exists. There is no endpoint returning WAHA
connection state, last webhook received time, last scheduled sync time, or sync health
indicators.

**B-M-12** No scheduled WAHA reconciliation job exists. Missed webhooks are never
recovered. There is no hourly polling job that checks WAHA for contacts, conversations,
and messages not already present in the database.

**B-M-13** No context assembly service exists. There is no
`PeopleConnectContextAssembler` that builds a structured prompt context from contact
profile, rules, notes, memories, session summary, topic history, and recent messages.

**B-M-14** No agent reply drafting pipeline exists. There is no
`GenerateContactReplyDraftJob`, no `peopleconnect_reply_drafts` table, and no API
endpoint for requesting or approving a draft reply.

**B-M-15** No realtime broadcasting infrastructure exists for PeopleConnect. There are
no Reverb channel definitions, no broadcast events for message received, message saved,
message analyzed, draft ready, message sent, message delivered, or WAHA status changes.

**B-M-16** No `PeopleConnectContactResolver` service exists. There is no logic to resolve
a WhatsApp `chatId` or phone number to an existing ContactHub contact, and no logic to
create a new contact when a new WhatsApp sender is encountered.

**B-M-17** No autopilot safety enforcement exists. There is no rule-compliance check,
quiet-hours check, max-replies-per-contact check, confidence threshold check, sensitive
topic block, or emergency global agent pause before an automated send.

**B-M-18** No `CloseInactivePeopleConnectSessionsJob` scheduled command exists. The
two-hour auto-close rule for sessions is never enforced.


### Frontend — Missing Implementations

**F-M-01** No `/people-connect` standalone route or page exists. The hub is incorrectly
placed at `/conversations`, which is the wrong navigation position for a first-class hub.

**F-M-02** No `NxPeopleConnectTopbar` component exists. There is no LiveMsgs button
with WAHA status light, no global reply mode segmented control, no pending outgoing
counter, no incoming save indicator, no sync-now action, and no hub-level stats strip.

**F-M-03** No `NxLiveMsgsModal` component exists. There is no WAHA connection state
display, no sync run history, no manual sync-now trigger, no reconcile-gaps action, no
raw provider event viewer, and no diagnostics panel.

**F-M-04** No proper `NxConversationSidebar` component exists for PeopleConnect. The
current sidebar shows no channel icon, no reply mode indicator, no agent status
indicator, no failed delivery indicator, and no pinned/VIP marker. Sidebar filtering and
sorting are absent.

**F-M-05** No `NxConversationHeader` component exists. There is no display for current
topic, latest intent, emotional baseline, tone mirroring, sentiment, background
processing log ticker, agent reply status, or contact reply mode override.

**F-M-06** No proper `NxMessagePanel` component exists for PeopleConnect. There are no
date separators, no session separators, no sender-type color coding for `contact`,
`agent`, and `system` types, no delivery status per outgoing message, no retry-failed-
message action, and no message toolbar with metadata.

**F-M-07** No `NxComposer` component exists for PeopleConnect. There is no ask-agent-
to-draft action, no send-approved-draft action, no schedule-send option, no template
insertion, no active reply mode display, and no WAHA disconnected warning.

**F-M-08** No contact rules modal (`NxContactRulesModal`) exists. Rules cannot be
viewed, created, edited, or deactivated from within PeopleConnect.

**F-M-09** No contact notes modal (`NxContactNotesModal`) exists. Notes cannot be
viewed, created, pinned, or linked to messages from within PeopleConnect.

**F-M-10** No context modal (`NxContextModal`) exists. The last assembled AI context
cannot be inspected, including profile snapshot, rules, notes, session summary,
memories, token estimate, or exclusion reasons.

**F-M-11** No memories modal (`NxMemoriesModal`) exists. Extracted memories, injected
memories, suggested memories, conflicting memories, and memory approval actions are not
accessible from within PeopleConnect.

**F-M-12** No tasks modal (`NxContactTasksModal`) exists. Tasks linked to the selected
contact and conversation cannot be viewed, created, or managed from within PeopleConnect.

**F-M-13** No realtime subscription exists in the conversations page. There is no
Laravel Echo/Reverb channel subscription for new messages, delivery updates, draft
ready events, or sync status changes. Updates require a full manual refetch.

**F-M-14** No search or filter UI exists in the conversation sidebar or message panel.
Full-text message search, topic search, intent filter, date range filter, sender type
filter, delivery status filter, and sentiment filter are all absent.

**F-M-15** No virtualized message list exists. Long conversations will render all
messages into the DOM simultaneously, causing performance degradation.

**F-M-16** No background processing log ticker exists. Per-conversation background
events such as session opened, intent analyzed, context assembled, and draft ready are
not displayed anywhere in the UI.

---

## ⚠️ Discrepancies

**B-D-01** The `Message` model is missing all WAHA/PeopleConnect-specific columns:
`waha_message_id`, `provider_payload_hash`, `topic_id`, `intent`, `tone`, `sentiment`,
`emotional_baseline_snapshot`, `tone_mirroring_snapshot`, `context_snapshot_id`,
`trace_id`, `delivered_at`, `read_at`, `failed_at`, and `error_message`.

**B-D-02** The `Conversation` model is missing PeopleConnect fields: `channel`,
`provider`, `provider_conversation_id`, `last_message_preview`, `unread_count`,
`reply_mode_effective`, and `agent_status`.

**B-D-03** The `ConversationSession` model is missing `message_count`, `summary`,
`contact_id`, and `closed_reason`.

**B-D-04** `ConversationController::sendMessage()` dispatches `ProcessAiInferenceJob`
instead of `DispatchWahaMessageJob`. Outgoing WhatsApp messages are never actually sent
to WAHA.

**B-D-05** API routes for conversations are registered under `/api/v1/conversations`
instead of `/api/v1/peopleconnect/conversations` as required by the spec.

**B-D-06** No reply mode concept exists anywhere in the generic `Conversation` model,
`ConversationController`, or related services.

**F-D-01** `/conversations/page.tsx` maps `sender === 'user'` to user bubble styling and
all other senders to assistant styling. There is no support for `contact`, `agent`, or
`system` sender types with distinct visual treatment.

**F-D-02** The hub is at `/conversations` instead of `/people-connect`, causing incorrect
placement in the application navigation structure.

**F-D-03** No error boundary wraps the conversation sidebar. A failed API call silently
drops the sidebar, leaving the user with no feedback.

---

## 🐛 Bugs

**B-BUG-01** CRITICAL — `WebhookController::handleWahaWebhook()` requires
`conversation_id` as a mandatory field in the incoming payload. Real WAHA webhooks send
`chatId`, `from`, `message`, and `sessionName` — not a Nexus `conversation_id`. Every
real WAHA webhook event is rejected with a validation error. Zero WAHA events are
ingested.

**B-BUG-02** `WebhookController::handleWahaWebhook()` dispatches
`ProcessAiInferenceJob` (a generic AI model inference job) on every incoming WAHA
message. The contact is never resolved, the session is never assigned, and the message
is never saved, deduplicated, or analyzed for intent, topic, or tone.

**B-BUG-03** `ConversationController::sendMessage()` dispatches `ProcessAiInferenceJob`
instead of `DispatchWahaMessageJob`. The outgoing message body is never forwarded to
WAHA. The contact receives nothing.

**B-BUG-04** No message deduplication guard exists. Re-delivery of the same WAHA
webhook creates a duplicate message record in the database every time.

**F-BUG-01** Messages from `contact`, `agent`, and `system` sender types are all
rendered as assistant-style bubbles, making it impossible to distinguish who sent what.

**F-BUG-02** After sending a message, the page performs a full message refetch via REST.
No Reverb/Echo realtime subscription is used. Incoming messages from the contact side
are never received without a manual page reload.

**F-BUG-03** No error boundary is applied to the conversation sidebar list fetch. A
backend error silently breaks the sidebar with no visible feedback.

**F-BUG-04** The hub is at `/conversations` not `/people-connect`, which conflicts with
the required navigation structure.

---


## Introduction

PeopleConnectHub is the standalone external-contact communication hub for Nexus. It is
the operational center for WhatsApp/WAHA live message synchronization, contact
conversations, manual replies from Hedra, AI-drafted replies, agent-sent replies when
policy allows, message delivery tracking, and conversation analysis including topic,
intent, tone, sentiment, emotional baseline, and tone mirroring.

PeopleConnectHub reads from and writes to the Nexus database as the source of truth.
WAHA is an integration provider, not the UI state source. The frontend consumes
database-backed APIs and receives realtime updates through Laravel Reverb/Echo.

ContactHub owns contact identity and Contact360 profile data. PeopleConnectHub owns
operational conversation state, message delivery workflows, and the AI reply pipeline.
AI replies are routed through AgentsHub and AiModelsHub. Long-running operations run
through Laravel queues. All important operations are logged and broadcast in realtime.

---

## Glossary

- **PeopleConnectHub**: The standalone Nexus hub for managing external contact
  conversations over WhatsApp and other channels.
- **WAHA**: WhatsApp HTTP API — the backend service that bridges Nexus to WhatsApp.
  Sends webhooks to Nexus on new messages, acks, and status changes.
- **LiveMsgs**: The WAHA synchronization and delivery subsystem inside PeopleConnectHub.
  Responsible for contact/conversation/message sync and outgoing delivery tracking.
- **Session**: A time-bounded segment of a contact conversation. Auto-closes after two
  hours of inactivity. New messages after closure open a new session.
- **Session_Lifecycle_Manager**: The service and scheduler responsible for enforcing
  the two-hour inactivity rule and opening new sessions.
- **Reply_Mode**: The behavioral mode controlling how outgoing replies are handled.
  Values: `manual`, `copilot`, `autopilot`.
- **Copilot**: Reply mode where an agent drafts a reply and Hedra approves it before
  sending.
- **Autopilot**: Reply mode where an agent sends replies automatically when all safety
  checks pass.
- **WahaWebhookIngestionService**: The backend service that receives, validates,
  normalizes, and dispatches processing for all incoming WAHA webhook payloads.
- **PeopleConnectContactResolver**: The backend service that resolves a WAHA `chatId`
  or phone number to an existing ContactHub contact, or creates a new contact.
- **PeopleConnectContextAssembler**: The backend service that builds a structured AI
  prompt context from contact profile, rules, notes, memories, session summary, and
  recent messages.
- **PeopleConnectAnalysisService**: The backend service that extracts topic, intent,
  tone, sentiment, emotional baseline, and tone mirroring from messages and sessions.
- **PeopleConnectReplyModeService**: The backend service that resolves the effective
  reply mode for a contact by merging global defaults with contact-level overrides.
- **WahaMessageDispatcher**: The backend service that sends outgoing messages to WAHA
  and records delivery attempts.
- **PeopleConnectRealtimeBroadcaster**: The backend service that broadcasts all
  PeopleConnect events to Reverb channels for frontend consumption.
- **Contact360**: The full contact profile view owned by ContactHub.
- **AgentsHub**: The Nexus hub that defines and executes AI agents.
- **AiModelsHub**: The Nexus hub that manages AI provider/model registry and routes
  all AI generation calls.
- **TasksHub**: The Nexus hub that owns durable tasks.
- **Reverb**: Laravel Reverb — the WebSocket server used for realtime broadcasting.
- **Echo**: Laravel Echo — the frontend WebSocket client library.
- **Sender_Type**: The category of a message sender. Values: `user` (Hedra/manual),
  `contact` (external WhatsApp contact), `agent` (AI agent), `system` (system event).
- **Canonical_Conversation**: The single persistent conversation record associated with
  each contact in PeopleConnectHub.
- **Provider_Message_ID**: The unique identifier assigned to a message by WAHA/WhatsApp,
  stored as `waha_message_id`.
- **Provider_Payload_Hash**: An MD5/SHA-256 hash of the raw WAHA payload used for
  deduplication alongside `waha_message_id`.
- **Delivery_Attempt**: A record of a single outgoing message send attempt including
  status, timestamp, WAHA response, and error details.
- **Processing_Log**: A per-conversation log of background operations including session
  events, analysis results, draft events, and delivery updates.
- **Context_Snapshot**: A frozen copy of the assembled AI context used for a specific
  reply draft or analysis run, stored in `peopleconnect_context_snapshots`.
- **Emotional_Baseline**: A rolling metric representing the contact's prevailing
  emotional state across recent sessions, computed by PeopleConnectAnalysisService.
- **Tone_Mirroring**: A metric indicating how closely the agent or Hedra's reply tone
  matches the contact's tone, computed per session.

---


## Requirements

---

### Requirement 1: PeopleConnect Data Model — 13 Core Tables

**User Story:** As a developer, I want a dedicated PeopleConnect database schema, so
that conversation state, message metadata, delivery tracking, analysis results, and sync
audit data are stored independently from the generic conversation system.

#### Acceptance Criteria

1. THE System SHALL create a `peopleconnect_conversations` table with columns `id`,
   `contact_id`, `channel`, `provider`, `provider_conversation_id`, `status`,
   `last_message_at`, `last_message_preview`, `unread_count`, `reply_mode_effective`,
   and `agent_status`.
2. THE System SHALL create a `peopleconnect_sessions` table with columns `id`,
   `conversation_id`, `contact_id`, `status`, `opened_at`, `closed_at`,
   `closed_reason`, `message_count`, and `summary`.
3. THE System SHALL create a `peopleconnect_messages` table with columns `id`,
   `conversation_id`, `session_id`, `contact_id`, `sender_type`, `sender_id`,
   `direction`, `body`, `body_format`, `status`, `provider`, `waha_message_id`,
   `provider_payload_hash`, `topic_id`, `intent`, `tone`, `sentiment`,
   `emotional_baseline_snapshot`, `tone_mirroring_snapshot`, `context_snapshot_id`,
   `trace_id`, `sent_at`, `delivered_at`, `read_at`, `failed_at`, and `error_message`.
4. THE System SHALL create a `peopleconnect_message_analyses` table with columns `id`,
   `message_id`, `topic`, `intent`, `tone`, `sentiment`, `language`, `urgency`,
   `safety_flags`, `reply_needed`, and `analyzed_at`.
5. THE System SHALL create a `peopleconnect_message_tags` table linking messages to
   string tags with `id`, `message_id`, and `tag`.
6. THE System SHALL create a `peopleconnect_context_snapshots` table with columns `id`,
   `conversation_id`, `session_id`, `payload` (JSON), `token_estimate`,
   `agent_id`, `model_id`, and `created_at`.
7. THE System SHALL create a `peopleconnect_reply_drafts` table with columns `id`,
   `conversation_id`, `message_id`, `agent_id`, `body`, `status`, `context_snapshot_id`,
   `trace_id`, `approved_by`, `approved_at`, `sent_at`, and `rejected_at`.
8. THE System SHALL create a `peopleconnect_delivery_attempts` table with columns `id`,
   `message_id`, `attempt_number`, `status`, `waha_response` (JSON), `attempted_at`,
   and `error_message`.
9. THE System SHALL create a `peopleconnect_sync_runs` table with columns `id`, `type`,
   `status`, `started_at`, `completed_at`, `contacts_found`, `conversations_found`,
   `messages_found`, `errors` (JSON), and `triggered_by`.
10. THE System SHALL create a `peopleconnect_raw_provider_events` table with columns
    `id`, `event_type`, `payload` (JSON), `session_name`, `received_at`,
    `processed_at`, and `processing_status`.
11. THE System SHALL create a `peopleconnect_processing_logs` table with columns `id`,
    `conversation_id`, `event_type`, `description`, `payload` (JSON), and `created_at`.
12. THE System SHALL create a `peopleconnect_conversation_topics` table with columns
    `id`, `conversation_id`, `name`, `first_message_id`, `last_message_id`,
    `message_count`, `first_seen_at`, and `last_seen_at`.
13. THE System SHALL create a `peopleconnect_reply_mode_overrides` table with columns
    `id`, `contact_id`, `reply_mode`, `set_by`, `reason`, and `created_at`.
14. WHEN a `peopleconnect_messages` record is created with a `waha_message_id` that
    already exists for the same conversation, THE System SHALL reject the insert and
    return a duplicate-detected result without creating a second record.

---

### Requirement 2: Fix WAHA Webhook Handler (B-BUG-01, B-BUG-02)

**User Story:** As an operator, I want all real WAHA webhook events to be accepted and
processed, so that incoming WhatsApp messages are reliably ingested into the database.

#### Acceptance Criteria

1. WHEN a POST request arrives at `POST /api/v1/webhooks/waha`, THE
   WahaWebhookIngestionService SHALL accept a payload containing `event`, `session`,
   `payload` (with `chatId`, `from`, `body`, `id`, `timestamp`), and SHALL NOT require
   a `conversation_id` field in the incoming payload.
2. WHEN a WAHA webhook payload is received with a valid `session` and `chatId`, THE
   WahaWebhookIngestionService SHALL store the raw event in
   `peopleconnect_raw_provider_events` before dispatching any job.
3. WHEN a WAHA webhook payload is received, THE WahaWebhookIngestionService SHALL
   dispatch `ProcessWahaWebhookJob` instead of `ProcessAiInferenceJob`.
4. IF a WAHA webhook payload fails signature or shared-secret validation, THEN THE
   WahaWebhookIngestionService SHALL return HTTP 401 and record the failed attempt in
   `peopleconnect_processing_logs`.
5. IF a WAHA webhook payload is missing required fields (`event`, `session`,
   `payload.chatId`), THEN THE WahaWebhookIngestionService SHALL return HTTP 422 with
   a descriptive validation error and SHALL NOT dispatch any job.
6. THE System SHALL deduplicate raw provider events using the combination of
   `session` + `payload.id` before dispatching `ProcessWahaWebhookJob` a second time
   for the same event.

---

### Requirement 3: WAHA Webhook Ingestion Pipeline

**User Story:** As a developer, I want every incoming WAHA webhook event to resolve
contacts, assign sessions, and persist messages, so that the database reflects live
WhatsApp state.

#### Acceptance Criteria

1. WHEN `ProcessWahaWebhookJob` runs for a `message` event, THE
   PeopleConnectContactResolver SHALL search for an existing contact by `chatId` and
   WhatsApp phone number before creating a new contact record.
2. WHEN `ProcessWahaWebhookJob` runs and no matching contact exists for the sender,
   THE PeopleConnectContactResolver SHALL create a new ContactHub contact using the
   WhatsApp display name as the contact name, or the phone number if no display name
   is available.
3. WHEN `ProcessWahaWebhookJob` runs for a contact, THE
   PeopleConnectConversationService SHALL resolve or create exactly one
   `peopleconnect_conversations` record for that contact.
4. WHEN `ProcessWahaWebhookJob` resolves a conversation with no open session, THE
   PeopleConnectSessionService SHALL open a new `peopleconnect_sessions` record for
   that conversation.
5. WHEN `ProcessWahaWebhookJob` resolves a conversation whose last message was received
   more than two hours ago, THE PeopleConnectSessionService SHALL close the existing
   session with `closed_reason = 'inactivity'` and open a new session before inserting
   the message.
6. WHEN `ProcessWahaWebhookJob` inserts a message, THE PeopleConnectMessageService
   SHALL check `waha_message_id` and `provider_payload_hash` for duplicates before
   inserting. IF a duplicate is detected, THEN THE PeopleConnectMessageService SHALL
   skip the insert and log a deduplication event.
7. AFTER a new message is inserted, THE System SHALL dispatch
   `AnalyzePeopleConnectMessageJob` asynchronously without blocking the webhook
   response.
8. AFTER a new message is inserted, THE PeopleConnectRealtimeBroadcaster SHALL
   broadcast a `peopleconnect.message.received` event to the appropriate Reverb channel.
9. WHEN a WAHA `ack` event is received, THE WahaWebhookIngestionService SHALL update
   the matching `peopleconnect_messages` record's `delivered_at` or `read_at` field and
   broadcast a `peopleconnect.message.delivered` or `peopleconnect.message.read` event.

---


### Requirement 4: Scheduled WAHA Reconciliation

**User Story:** As an operator, I want missed webhook messages to be recovered
automatically, so that the database is eventually consistent with WAHA even when
webhooks are dropped or delayed.

#### Acceptance Criteria

1. THE SchedulerHub SHALL execute `SyncWahaContactsJob`, `SyncWahaConversationsJob`,
   and `SyncWahaMessagesJob` on a schedule of once per hour by default.
2. WHEN `SyncWahaMessagesJob` runs, THE LiveMsgsSyncService SHALL call the WAHA API to
   fetch messages not already present in `peopleconnect_messages` and insert the
   missing records.
3. WHEN `SyncWahaContactsJob` runs and finds a WhatsApp contact not present in
   ContactHub, THE LiveMsgsSyncService SHALL create a new contact using the same
   resolver logic as the webhook ingestion pipeline.
4. WHEN a scheduled sync run completes, THE LiveMsgsSyncService SHALL write a
   `peopleconnect_sync_runs` record with `type`, `status`, `started_at`,
   `completed_at`, `contacts_found`, `conversations_found`, `messages_found`, and
   any errors encountered.
5. WHEN `ReconcileWahaDeliveryStatusJob` runs, THE WahaMessageDispatcher SHALL fetch
   delivery acknowledgements from WAHA for all `peopleconnect_messages` records with
   status `sent` but no `delivered_at` older than 24 hours and update their delivery
   status accordingly.
6. IF a scheduled sync run encounters an error querying the WAHA API, THEN THE
   LiveMsgsSyncService SHALL record the error in `peopleconnect_sync_runs.errors` and
   set the sync run status to `degraded` rather than silently failing.

---

### Requirement 5: Session Lifecycle Management

**User Story:** As a user, I want conversations to be automatically segmented into
sessions based on time, so that context is cleanly bounded and summarizable.

#### Acceptance Criteria

1. WHEN a new message arrives and the most recent session for that conversation has
   `closed_at` set, THE PeopleConnectSessionService SHALL create a new open session
   before inserting the message.
2. WHEN a session has been open and no new message has been received for two hours,
   THE CloseInactivePeopleConnectSessionsJob SHALL set the session `status` to
   `closed`, set `closed_at` to the current timestamp, and set `closed_reason` to
   `inactivity`.
3. WHEN a session is closed, THE PeopleConnectRealtimeBroadcaster SHALL broadcast a
   `peopleconnect.session.closed` event to the Reverb channel for that conversation.
4. WHEN a new session is opened, THE PeopleConnectRealtimeBroadcaster SHALL broadcast
   a `peopleconnect.session.opened` event to the Reverb channel for that conversation.
5. THE SchedulerHub SHALL execute `CloseInactivePeopleConnectSessionsJob` at a
   frequency of at least once every 15 minutes to enforce the two-hour inactivity rule
   without excessive delay.
6. WHEN a session is closed, THE System SHALL dispatch an asynchronous job to generate
   a plain-text `summary` for that session using AiModelsHub.

---

### Requirement 6: Message Deduplication

**User Story:** As a developer, I want message deduplication enforced at the service
layer, so that retried or re-delivered WAHA webhooks never create duplicate records.

#### Acceptance Criteria

1. THE PeopleConnectMessageService SHALL check the `waha_message_id` column for
   uniqueness within the same `conversation_id` before inserting any inbound message.
2. THE PeopleConnectMessageService SHALL additionally compute and check a
   `provider_payload_hash` (SHA-256 of the normalized raw provider payload) for
   uniqueness as a second deduplication guard.
3. WHEN a duplicate is detected by either check, THE PeopleConnectMessageService SHALL
   return a `DuplicateMessageException` without modifying any database record.
4. WHEN a duplicate is detected, THE PeopleConnectMessageService SHALL write a
   deduplication log entry in `peopleconnect_processing_logs` with
   `event_type = 'dedup_skipped'`.
5. FOR ALL sequences of ten identical WAHA webhook payloads delivered for the same
   message, THE PeopleConnectMessageService SHALL produce exactly one
   `peopleconnect_messages` record (round-trip dedup property).

---

### Requirement 7: PeopleConnect API Routes

**User Story:** As a frontend developer, I want all PeopleConnect backend data exposed
under `/api/v1/peopleconnect/`, so that the frontend can consume a clearly namespaced
API that is separate from the generic conversation system.

#### Acceptance Criteria

1. THE System SHALL register `GET /api/v1/peopleconnect/conversations` returning a
   paginated list of `peopleconnect_conversations` with contact name, last message
   preview, unread count, reply mode, and agent status.
2. THE System SHALL register `GET /api/v1/peopleconnect/conversations/{id}` returning
   the full conversation record with header analytics fields.
3. THE System SHALL register `GET /api/v1/peopleconnect/conversations/{id}/messages`
   returning paginated messages with sender type, delivery status, analysis fields,
   tags, and topic.
4. THE System SHALL register `POST /api/v1/peopleconnect/conversations/{id}/messages`
   saving an outbound message with status `queued` and dispatching
   `DispatchWahaMessageJob`.
5. THE System SHALL register `POST /api/v1/peopleconnect/messages/{id}/retry`
   re-queuing a failed outbound message by dispatching `DispatchWahaMessageJob`.
6. THE System SHALL register `GET /api/v1/peopleconnect/livemsgs/status` returning
   WAHA connection state, last webhook received timestamp, last sync run timestamp,
   pending outgoing count, and failed send count.
7. THE System SHALL register `POST /api/v1/peopleconnect/livemsgs/sync-now` triggering
   an immediate `SyncWahaMessagesJob` dispatch outside the regular schedule.
8. THE System SHALL register `POST /api/v1/peopleconnect/livemsgs/reconcile` triggering
   an immediate `ReconcileWahaDeliveryStatusJob` dispatch.
9. THE System SHALL register `GET /api/v1/peopleconnect/reply-mode` and
   `PATCH /api/v1/peopleconnect/reply-mode` for reading and updating the global default
   reply mode.
10. THE System SHALL register
    `PATCH /api/v1/peopleconnect/conversations/{id}/reply-mode` for setting a per-
    contact reply mode override stored in `peopleconnect_reply_mode_overrides`.
11. THE System SHALL register `GET /api/v1/peopleconnect/conversations/{id}/sessions`,
    `POST /api/v1/peopleconnect/conversations/{id}/sessions/close`, and
    `POST /api/v1/peopleconnect/conversations/{id}/sessions/reopen`.
12. THE System SHALL register full CRUD routes for rules and notes scoped to a
    conversation: `GET`, `POST` at `.../rules` and `.../notes`, and `PATCH`, `DELETE`
    at `.../rules/{rule}` and `.../notes/{note}`.
13. THE System SHALL register `GET /api/v1/peopleconnect/search` and
    `GET /api/v1/peopleconnect/messages/search` for full-text and metadata-scoped search.
14. THE System SHALL register `GET /api/v1/peopleconnect/stats` returning active
    conversation count, unread count, pending outgoing count, failed send count, WAHA
    connection status, and autopilot-enabled contact count.
15. THE System SHALL register `GET /api/v1/peopleconnect/conversations/{id}/header`
    returning current topic, latest intent, emotional baseline, tone mirroring,
    sentiment, and background processing log entries.
16. WHEN any PeopleConnect API route is accessed by an unauthenticated request, THE
    System SHALL return HTTP 401.

---


### Requirement 8: Global and Per-Contact Reply Mode

**User Story:** As Hedra, I want to control whether replies are sent manually, drafted
by copilot, or sent automatically by autopilot, so that I maintain the right level of
oversight for each contact.

#### Acceptance Criteria

1. THE PeopleConnectReplyModeService SHALL maintain a global default reply mode with
   allowed values `manual`, `copilot`, and `autopilot`, persisted in application
   settings via SettingsHub.
2. THE PeopleConnectReplyModeService SHALL allow a per-contact override stored in
   `peopleconnect_reply_mode_overrides`. WHEN a contact-level override exists, THE
   PeopleConnectReplyModeService SHALL return the override value and ignore the global
   default.
3. WHEN the global reply mode is updated via `PATCH /api/v1/peopleconnect/reply-mode`,
   THE System SHALL broadcast a realtime event so all connected frontend clients update
   their displayed reply mode without reload.
4. WHEN a per-contact override is set or removed, THE PeopleConnectRealtimeBroadcaster
   SHALL broadcast an update event to the conversation's Reverb channel.
5. THE PeopleConnectReplyModeService SHALL expose a single `resolveEffectiveMode(contactId)`
   method that returns the contact override if present, or the global default otherwise.
   FOR ALL combinations of global mode and per-contact override, calling
   `resolveEffectiveMode` SHALL return the contact override when present and the global
   default when no override exists (invariant property).

---

### Requirement 9: Copilot Draft Flow

**User Story:** As Hedra, I want agents to draft replies for my approval when copilot
mode is active, so that I can review and optionally edit AI-drafted messages before
they are sent.

#### Acceptance Criteria

1. WHEN the effective reply mode for a contact is `copilot` and a new inbound message
   arrives, THE System SHALL dispatch `GenerateContactReplyDraftJob` after the message
   analysis completes.
2. WHEN `GenerateContactReplyDraftJob` runs, THE PeopleConnectContextAssembler SHALL
   assemble a context snapshot including contact profile, rules, notes, memories, session
   summary, and recent messages before invoking the agent via AgentsHub.
3. WHEN a draft is generated, THE PeopleConnectAgentReplyService SHALL store the draft
   in `peopleconnect_reply_drafts` with `status = 'pending_approval'` and a reference
   to the `context_snapshot_id`.
4. WHEN a draft is stored with `status = 'pending_approval'`, THE
   PeopleConnectRealtimeBroadcaster SHALL broadcast a `peopleconnect.reply.draft.created`
   event to the conversation's Reverb channel.
5. WHEN Hedra approves a draft via the composer, THE System SHALL update the draft
   `status` to `approved`, set `approved_by` and `approved_at`, and dispatch
   `DispatchWahaMessageJob` for the draft body.
6. WHEN Hedra rejects a draft, THE System SHALL update the draft `status` to `rejected`
   and set `rejected_at` without sending anything to WAHA.
7. IF `GenerateContactReplyDraftJob` fails after three retries, THEN THE System SHALL
   set the draft `status` to `failed` and broadcast an error event to the conversation's
   Reverb channel.

---

### Requirement 10: Autopilot Safety Enforcement

**User Story:** As Hedra, I want autopilot replies to be blocked when safety conditions
are not met, so that no automated message is ever sent in a risky or policy-violating
context.

#### Acceptance Criteria

1. WHEN the effective reply mode for a contact is `autopilot`, THE
   PeopleConnectReplyModeService SHALL evaluate all safety checks before allowing
   `GenerateContactReplyDraftJob` to proceed to a send.
2. THE PeopleConnectReplyModeService SHALL block an autopilot send and set draft status
   to `blocked` WHEN any of the following conditions are true: the active contact rules
   prohibit automated replies; the current time falls within the contact's quiet hours;
   the number of automated replies to this contact within the current day has reached
   the configured maximum; the agent confidence score is below the configured threshold;
   the message contains a topic flagged as sensitive and no explicit approval exists;
   the contact identity confidence is below the minimum threshold; or a global agent
   pause is active.
3. WHEN an autopilot send is blocked, THE PeopleConnectRealtimeBroadcaster SHALL
   broadcast a `peopleconnect.autopilot.blocked` event with the block reason.
4. WHEN an autopilot send is blocked, THE System SHALL write a log entry in
   `peopleconnect_processing_logs` with `event_type = 'autopilot_blocked'` and the
   specific block reason.
5. THE System SHALL expose an emergency global agent pause toggle via SettingsHub that,
   WHEN activated, causes THE PeopleConnectReplyModeService to block all autopilot
   sends regardless of contact settings.
6. FOR ALL autopilot send attempts, THE PeopleConnectReplyModeService SHALL check all
   safety conditions atomically before dispatching `DispatchWahaMessageJob`. A safety
   check added after initial implementation SHALL be enforced on all subsequent send
   attempts without code changes to the dispatcher (open/closed principle invariant).

---

### Requirement 11: Outgoing Message Queue and Delivery Tracking

**User Story:** As Hedra, I want to see the delivery status of every outgoing message
and retry failures easily, so that I know whether my messages reached the contact.

#### Acceptance Criteria

1. WHEN an outbound message is created via `POST .../messages`, THE System SHALL save
   the message to `peopleconnect_messages` with `status = 'queued'` BEFORE dispatching
   `DispatchWahaMessageJob`. The message must be persisted even if the queue is
   temporarily unavailable.
2. WHEN `DispatchWahaMessageJob` sends the message to WAHA, THE WahaMessageDispatcher
   SHALL write a `peopleconnect_delivery_attempts` record for each send attempt with
   the WAHA API response.
3. WHEN WAHA confirms a message send, THE WahaMessageDispatcher SHALL update the
   message `status` to `sent` and set `sent_at`.
4. WHEN a WAHA delivery acknowledgement is received via webhook or reconciliation, THE
   System SHALL set `delivered_at` and update `status` to `delivered`.
5. WHEN a WAHA read receipt is received, THE System SHALL set `read_at` and update
   `status` to `read`.
6. WHEN `DispatchWahaMessageJob` fails, THE WahaMessageDispatcher SHALL update the
   message `status` to `failed`, set `failed_at`, set `error_message`, and increment
   the delivery attempt counter.
7. WHEN message delivery fails, THE PeopleConnectRealtimeBroadcaster SHALL broadcast
   a `peopleconnect.message.failed` event to the conversation's Reverb channel.
8. WHEN Hedra triggers a retry via `POST /api/v1/peopleconnect/messages/{id}/retry`,
   THE System SHALL reset the message `status` to `queued` and dispatch a new
   `DispatchWahaMessageJob`.
9. THE WahaMessageDispatcher SHALL enforce a rate limit of no more than the configured
   maximum outgoing messages per contact per minute to prevent WAHA abuse.

---


### Requirement 12: Message Analysis Pipeline

**User Story:** As Hedra, I want every incoming message to be analyzed for topic,
intent, tone, sentiment, and emotional state, so that the conversation header and AI
reply context are always up to date.

#### Acceptance Criteria

1. WHEN `AnalyzePeopleConnectMessageJob` runs for a message, THE
   PeopleConnectAnalysisService SHALL extract and store `topic`, `intent`, `tone`,
   `sentiment`, `language`, `urgency`, `safety_flags`, and `reply_needed` in
   `peopleconnect_message_analyses`.
2. WHEN analysis completes, THE PeopleConnectAnalysisService SHALL update the message
   record in `peopleconnect_messages` with the analyzed `topic_id`, `intent`, `tone`,
   and `sentiment` fields.
3. WHEN a new topic is detected that does not already exist for the conversation, THE
   PeopleConnectAnalysisService SHALL create a new `peopleconnect_conversation_topics`
   record and set `first_message_id` to the current message.
4. WHEN a message belongs to an existing topic, THE PeopleConnectAnalysisService SHALL
   update `last_message_id` and `last_seen_at` for that topic record.
5. AFTER analysis completes, THE PeopleConnectAnalysisService SHALL recompute the
   conversation-level `emotional_baseline_snapshot` and `tone_mirroring_snapshot` using
   a rolling window of the most recent sessions and store the values on the message.
6. WHEN analysis completes, THE PeopleConnectRealtimeBroadcaster SHALL broadcast a
   `peopleconnect.message.analyzed` event to the conversation's Reverb channel.
7. IF `AnalyzePeopleConnectMessageJob` fails due to an AI provider error, THEN THE
   System SHALL retry up to three times with exponential backoff before marking the
   analysis as `failed` and writing a log entry.

---

### Requirement 13: Context Assembly for AI

**User Story:** As a developer, I want a structured context to be assembled before
every AI reply or analysis, so that agents have accurate and bounded information to
work with.

#### Acceptance Criteria

1. WHEN `GenerateContactReplyDraftJob` is dispatched, THE PeopleConnectContextAssembler
   SHALL assemble a context object containing contact profile snapshot, active contact
   rules, pinned contact notes, relevant memories, last session summary, topic history,
   the most recent messages up to the configured token limit, emotional baseline, and
   tone mirroring.
2. THE PeopleConnectContextAssembler SHALL store the assembled context as a frozen
   `peopleconnect_context_snapshots` record before invoking AgentsHub.
3. THE PeopleConnectContextAssembler SHALL compute a `token_estimate` for the assembled
   context and truncate the oldest messages first if the estimate exceeds the configured
   maximum token budget.
4. THE Context Modal on the frontend SHALL load and display the latest
   `peopleconnect_context_snapshots` record for the selected conversation via
   `GET /api/v1/peopleconnect/conversations/{id}/context/latest`.
5. WHEN a context snapshot is created, THE PeopleConnectContextAssembler SHALL record
   which context items were excluded and the reason for exclusion in the snapshot
   `payload`.
6. FOR ALL context snapshots, the assembled context viewed from the Context Modal SHALL
   exactly match the context sent to AgentsHub for that draft (round-trip property).

---

### Requirement 14: Realtime Broadcasting via Reverb

**User Story:** As a developer, I want all PeopleConnect state changes to be broadcast
over Reverb, so that the frontend updates in realtime without polling.

#### Acceptance Criteria

1. THE PeopleConnectRealtimeBroadcaster SHALL broadcast on a private channel named
   `peopleconnect.conversation.{conversation_id}` for all per-conversation events.
2. THE PeopleConnectRealtimeBroadcaster SHALL broadcast the following events on the
   conversation channel: `peopleconnect.message.received`, `peopleconnect.message.saved`,
   `peopleconnect.message.analyzed`, `peopleconnect.reply.draft.created`,
   `peopleconnect.message.queued`, `peopleconnect.message.sent`,
   `peopleconnect.message.delivered`, `peopleconnect.message.read`,
   `peopleconnect.message.failed`, `peopleconnect.session.opened`,
   `peopleconnect.session.closed`, and `peopleconnect.autopilot.blocked`.
3. THE PeopleConnectRealtimeBroadcaster SHALL broadcast the following events on a
   private hub-level channel `peopleconnect.hub`: `peopleconnect.waha.connected`,
   `peopleconnect.waha.disconnected`, `peopleconnect.livemsgs.sync.started`,
   `peopleconnect.livemsgs.sync.completed`, and pending outgoing count changes.
4. THE Frontend SHALL subscribe to the `peopleconnect.hub` channel on mount of the
   PeopleConnectHub page and update topbar stats in real time without a full page reload.
5. THE Frontend SHALL subscribe to the `peopleconnect.conversation.{id}` channel when
   a conversation is selected and append new messages to the message panel without
   re-fetching the full message list.
6. WHEN a `peopleconnect.message.delivered` or `peopleconnect.message.read` event is
   received on the frontend, THE NxMessagePanel SHALL update the delivery status
   indicator for the matching message in-place.

---

### Requirement 15: Frontend Standalone Hub at `/people-connect`

**User Story:** As Hedra, I want PeopleConnectHub to be accessible at a dedicated
`/people-connect` route with its own navigation item, so that it is a first-class hub
with the correct navigation placement.

#### Acceptance Criteria

1. THE System SHALL create a Next.js page at `app/people-connect/page.tsx` that renders
   the full PeopleConnectHub shell.
2. THE AppLayout navigation SHALL include a PeopleConnectHub navigation item linking
   to `/people-connect`.
3. THE `/conversations` page SHALL be removed or redirected to `/people-connect` to
   avoid duplicate navigation entries.
4. THE PeopleConnectHub page SHALL use the `AppLayout` wrapper consistent with all
   other hub pages in the project.
5. WHEN the PeopleConnectHub page loads, THE System SHALL fetch the initial conversation
   list from `GET /api/v1/peopleconnect/conversations` and display a loading skeleton
   while the request is in flight.
6. IF the initial conversation list fetch fails, THEN THE System SHALL display an error
   boundary with a retry action rather than a blank or silent failure state.

---


### Requirement 16: NxPeopleConnectTopbar Component

**User Story:** As Hedra, I want a topbar with WAHA status, reply mode controls, and
outgoing message counters, so that I can see system health and change reply behavior
at a glance.

#### Acceptance Criteria

1. THE NxPeopleConnectTopbar SHALL render a LiveMsgs button that opens the
   NxLiveMsgsModal on click and displays a colored status light indicating WAHA
   connection state: green for `connected`, amber for `syncing` or `degraded`, and
   red for `disconnected` or `error`.
2. THE NxPeopleConnectTopbar SHALL render a global reply mode segmented control with
   three segments: `Manual`, `Copilot`, and `Autopilot`, reflecting the current global
   default mode from `GET /api/v1/peopleconnect/reply-mode`.
3. WHEN a reply mode segment is selected in the topbar, THE System SHALL call
   `PATCH /api/v1/peopleconnect/reply-mode` and update the selected segment optimistically
   while the request completes.
4. THE NxPeopleConnectTopbar SHALL render a pending outgoing counter button showing
   the count of messages with `status = 'queued'` or `status = 'sending'`. WHEN the
   count is greater than zero, the button color SHALL indicate the most severe state
   across all pending messages.
5. THE NxPeopleConnectTopbar SHALL render an incoming save indicator that shows a
   spinner or pulsing dot WHEN a LiveMsgs sync run is in progress.
6. THE NxPeopleConnectTopbar SHALL display the following hub-level stats from
   `GET /api/v1/peopleconnect/stats`: active conversations, unread conversations,
   pending outgoing messages, failed sends, and WAHA status.

---

### Requirement 17: NxLiveMsgsModal Component

**User Story:** As Hedra, I want a LiveMsgs modal with diagnostics and manual control
actions, so that I can monitor and intervene in the WAHA sync and delivery pipeline.

#### Acceptance Criteria

1. THE NxLiveMsgsModal SHALL display the current WAHA connection state, active WAHA
   session name, last webhook received timestamp, last scheduled sync timestamp, and
   webhook health.
2. THE NxLiveMsgsModal SHALL display counters for: new contacts found in last sync,
   new conversations found, new messages found, pending outgoing count, failed sends,
   and failed imports.
3. THE NxLiveMsgsModal SHALL include a `Sync Now` button that calls
   `POST /api/v1/peopleconnect/livemsgs/sync-now` and displays a loading state while
   the sync job is running.
4. THE NxLiveMsgsModal SHALL include a `Reconcile Gaps` button that calls
   `POST /api/v1/peopleconnect/livemsgs/reconcile`.
5. THE NxLiveMsgsModal SHALL include a `Retry Failed Sends` button that calls
   `POST /api/v1/peopleconnect/livemsgs/retry-failed`.
6. THE NxLiveMsgsModal SHALL show a paginated list of the most recent sync runs from
   `GET /api/v1/peopleconnect/livemsgs/sync-runs` with type, status, timestamp, and
   counts.
7. THE NxLiveMsgsModal SHALL include a diagnostics section showing the last 10 entries
   from `peopleconnect_processing_logs` with event type, description, and timestamp.

---

### Requirement 18: NxConversationSidebar Component

**User Story:** As Hedra, I want a conversation sidebar that shows all relevant
status indicators per conversation, so that I can quickly identify which contacts need
attention.

#### Acceptance Criteria

1. THE NxConversationSidebar SHALL render each conversation item with contact name (or
   phone number fallback), WhatsApp number, last message time, last message preview
   truncated to 60 characters, and an unread message badge when `unread_count > 0`.
2. THE NxConversationSidebar SHALL show a channel icon, a reply mode indicator label,
   an agent status indicator, and a failed delivery warning icon on each conversation
   item where applicable.
3. THE NxConversationSidebar SHALL include a search input that filters conversations
   by contact name, phone number, or last message preview text.
4. THE NxConversationSidebar SHALL include filter controls for: unread only, reply
   mode (`manual`, `copilot`, `autopilot`), and failed sends.
5. WHEN the sidebar list fetch fails, THE NxConversationSidebar SHALL display an error
   state with a retry button rather than silently showing an empty list.
6. WHEN a new `peopleconnect.message.received` or `peopleconnect.message.saved` event
   is received via Reverb, THE NxConversationSidebar SHALL update the matching
   conversation item's last message preview and unread badge without refetching the
   full list.

---

### Requirement 19: NxConversationHeader Component

**User Story:** As Hedra, I want a dynamic conversation header showing analysis data
and quick-action buttons, so that I understand the conversation context without
leaving the message view.

#### Acceptance Criteria

1. THE NxConversationHeader SHALL display the current topic name, latest intent, latest
   emotional baseline, latest tone mirroring score, and latest sentiment value from
   `GET /api/v1/peopleconnect/conversations/{id}/header`.
2. THE NxConversationHeader SHALL display a live background processing log ticker
   showing the last three `peopleconnect_processing_logs` entries for the conversation,
   scrolling automatically as new entries arrive via Reverb.
3. THE NxConversationHeader SHALL display the contact's effective reply mode with a
   visual indicator that distinguishes a contact-level override from the global default.
4. THE NxConversationHeader SHALL include action buttons that open the following modals:
   contact profile (links to ContactHub), rules modal, notes modal, context modal,
   memories modal, and tasks modal.
5. THE NxConversationHeader SHALL include a searchable topic dropdown populated from
   `GET /api/v1/peopleconnect/conversations/{id}/topics`. WHEN a topic is selected,
   THE NxMessagePanel SHALL scroll to the first message belonging to that topic.
6. WHEN a `peopleconnect.message.analyzed` event is received via Reverb for the active
   conversation, THE NxConversationHeader SHALL refresh its displayed analysis fields
   without a full API refetch.

---


### Requirement 20: NxMessagePanel Component

**User Story:** As Hedra, I want a message panel with date separators, session
separators, sender-type color coding, delivery status, and a per-message toolbar, so
that I can read conversations clearly and act on individual messages.

#### Acceptance Criteria

1. THE NxMessagePanel SHALL render messages in chronological ascending order with
   auto-scroll to the latest message on initial load and when a new message event is
   received via Reverb.
2. THE NxMessagePanel SHALL render a date separator before the first message of each
   calendar date in the conversation.
3. THE NxMessagePanel SHALL render a session separator between messages that belong to
   different sessions, showing the session open and close time.
4. THE NxMessagePanel SHALL apply distinct visual styles per sender type: right-aligned
   primary color for `user`, left-aligned secondary color for `contact`, left-aligned
   agent accent color for `agent`, and a centered muted system style for `system`.
5. THE NxMessagePanel SHALL display a delivery status indicator on every outgoing
   message showing one of: `queued`, `sending`, `sent`, `delivered`, `read`, or
   `failed`, with distinct icons for each state.
6. WHEN a message has `status = 'failed'`, THE NxMessagePanel SHALL render a retry
   button that calls `POST /api/v1/peopleconnect/messages/{id}/retry`.
7. THE NxMessagePanel SHALL render a per-message toolbar on hover containing: topic
   label, intent label, tone label, sentiment label, emotional baseline value, tag
   count, copy action, draft reply action, create task action, save note action, and
   a debug link to the raw provider event.
8. THE NxMessagePanel SHALL use a virtualized list (e.g. `react-virtual` or equivalent)
   so that conversations with over 500 messages render without UI lag.
9. WHEN a `peopleconnect.session.opened` or `peopleconnect.session.closed` event is
   received via Reverb, THE NxMessagePanel SHALL insert or update the session separator
   in-place without reloading the full message list.

---

### Requirement 21: NxComposer Component

**User Story:** As Hedra, I want a composer that supports manual send, copilot draft
approval, schedule send, and shows the active reply mode, so that every outgoing
message is handled with the correct intent and safety awareness.

#### Acceptance Criteria

1. THE NxComposer SHALL show the effective reply mode for the selected contact and
   highlight copilot or autopilot mode with a distinct visual treatment.
2. WHEN the effective reply mode is `copilot` and a pending draft exists in
   `peopleconnect_reply_drafts` with `status = 'pending_approval'`, THE NxComposer
   SHALL display the draft body in the compose area with options to approve, edit, or
   reject.
3. WHEN the effective reply mode is `manual`, THE NxComposer SHALL render a standard
   compose area with a send button that calls
   `POST /api/v1/peopleconnect/conversations/{id}/messages`.
4. THE NxComposer SHALL include an `Ask Agent` button that calls
   `POST /api/v1/peopleconnect/messages/{id}/draft-reply` to trigger a copilot draft
   generation on demand, regardless of the active reply mode.
5. WHEN WAHA connection state is `disconnected` or `error`, THE NxComposer SHALL
   display a warning banner and disable the send button.
6. IF a send fails, THEN THE NxComposer SHALL save the composed text as a local draft
   and surface a visible error with a retry option.
7. THE NxComposer SHALL support attaching files for sending via WAHA and SHALL validate
   that attached files do not exceed the maximum WAHA attachment size before attempting
   a send.

---

### Requirement 22: Contact Modals (Rules, Notes, Context, Memories, Tasks)

**User Story:** As Hedra, I want quick-access modals for rules, notes, context,
memories, and tasks for the selected contact, so that I can manage contact intelligence
without leaving the conversation view.

#### Acceptance Criteria

1. THE NxContactRulesModal SHALL load and display active rules for the selected
   conversation's contact from `GET /api/v1/peopleconnect/conversations/{id}/rules`.
   Hedra SHALL be able to add, edit, deactivate, and delete rules from within the modal.
2. THE NxContactRulesModal SHALL show AI-suggested rules with `status = 'pending'`
   and provide approve and reject actions for each.
3. THE NxContactNotesModal SHALL load and display notes from
   `GET /api/v1/peopleconnect/conversations/{id}/notes`. Hedra SHALL be able to add,
   edit, pin, and delete notes. WHEN a note is pinned, THE NxContactNotesModal SHALL
   render it at the top of the list.
4. THE NxContextModal SHALL load and display the latest context snapshot from
   `GET /api/v1/peopleconnect/conversations/{id}/context/latest`, including the contact
   profile section, rules section, notes section, recent messages section, session
   summary, memories section, token estimate, and excluded items with reasons.
5. THE NxMemoriesModal SHALL load recently extracted memories, memories injected into
   the latest prompt, and suggested memories awaiting approval from
   `GET /api/v1/peopleconnect/conversations/{id}/memories/latest`. Hedra SHALL be able
   to approve, reject, or edit each suggested memory.
6. THE NxContactTasksModal SHALL load open tasks, recently completed tasks, and failed
   tasks linked to the selected contact from
   `GET /api/v1/peopleconnect/conversations/{id}/tasks`. Hedra SHALL be able to create
   a new task linked to the current conversation directly from this modal.
7. WHEN any modal fetch fails, THE modal SHALL display an error state with a retry
   button and SHALL NOT render a blank or partially populated view.

---

### Requirement 23: ContactHub Integration

**User Story:** As Hedra, I want PeopleConnectHub to consume ContactHub contact data
and write back message evidence, so that both hubs stay synchronized on contact
identity and intelligence.

#### Acceptance Criteria

1. WHEN `PeopleConnectContactResolver` creates a new contact from a WAHA event, THE
   System SHALL call the ContactHub contact-creation API and store the returned
   canonical `contact_id` on the `peopleconnect_conversations` record.
2. THE NxConversationHeader SHALL provide a link that opens the Contact360 profile in
   ContactHub for the conversation's contact without leaving PeopleConnectHub entirely.
3. WHEN a message is saved and analysis completes, THE PeopleConnectAnalysisService
   SHALL write a message evidence record to ContactHub using the ContactHub message
   evidence API so that ContactHub's analysis pipeline can incorporate the new data.
4. WHEN a contact reply mode override is set in PeopleConnectHub, THE
   PeopleConnectReplyModeService SHALL write the override to
   `peopleconnect_reply_mode_overrides` and also update the contact record in ContactHub
   with the effective reply mode value.
5. WHEN rules or notes are created in PeopleConnectHub for a contact, THE System SHALL
   also create matching records in ContactHub through the ContactHub rules/notes APIs
   so that ContactHub remains the canonical owner of contact intelligence.

---

### Requirement 24: AgentsHub and AiModelsHub Integration

**User Story:** As a developer, I want all AI generation and analysis calls to route
through AgentsHub and AiModelsHub, so that AI usage is tracked, costs are attributed,
and agents can be swapped without changing PeopleConnectHub code.

#### Acceptance Criteria

1. WHEN `GenerateContactReplyDraftJob` invokes AI generation, THE
   PeopleConnectAgentReplyService SHALL call AgentsHub using the configured contact
   reply agent, passing the assembled context snapshot as the prompt context.
2. WHEN `AnalyzePeopleConnectMessageJob` invokes AI analysis, THE
   PeopleConnectAnalysisService SHALL route the call through AiModelsHub using the
   `Intent_Detection` intent and SHALL record the model trace ID on the message
   analysis record.
3. THE PeopleConnectContextAssembler SHALL use the `Contact_Analysis` AiModelsHub
   intent for session summarization and the `Memory_Extraction` intent for memory
   suggestion jobs.
4. WHEN AgentsHub indicates that the configured agent is in quarantine or globally
   paused, THE PeopleConnectAgentReplyService SHALL block the draft generation, set
   draft status to `blocked`, and broadcast a `peopleconnect.autopilot.blocked` event.
5. THE System SHALL record AiModelsHub usage statistics including token counts, model
   used, and cost estimate on every `peopleconnect_context_snapshots` record that
   triggered an AI call.

---


### Requirement 25: Search and Filters

**User Story:** As Hedra, I want full-text and metadata-based search across all
conversations and messages, so that I can find any past message or topic quickly.

#### Acceptance Criteria

1. THE PeopleConnectSearchService SHALL support full-text search over `body` for all
   `peopleconnect_messages` records within a given conversation or globally.
2. THE PeopleConnectSearchService SHALL support filtering messages by: `sender_type`,
   `topic_id`, `intent`, `tone`, `sentiment`, `status` (delivery), `direction`,
   date range, has-tag, has-task, and has-extracted-memory.
3. THE System SHALL respond to `GET /api/v1/peopleconnect/messages/search` with
   paginated results including matched message body snippets, conversation context,
   and analysis fields.
4. THE NxConversationHeader SHALL include a message search input that calls the search
   API and highlights matching messages in the NxMessagePanel.
5. THE NxConversationSidebar SHALL include a global conversation search input that
   filters the sidebar list by contact name, phone number, and last message content
   using the search API.
6. THE NxConversationHeader topic dropdown SHALL be searchable and SHALL show for each
   topic: name, message count, first seen date, and last seen date. WHEN a topic is
   selected, THE NxMessagePanel SHALL scroll to the first message with that `topic_id`.

---

### Requirement 26: Production Hardening and Security

**User Story:** As a developer, I want PeopleConnectHub to be production-safe with
idempotency, rate limiting, PII masking, and SSRF protection, so that it can be
deployed confidently in a live environment.

#### Acceptance Criteria

1. THE WahaWebhookIngestionService SHALL validate incoming webhook requests using a
   shared secret or HMAC signature. IF validation fails, THEN THE System SHALL return
   HTTP 401 and log the attempt without processing the payload.
2. THE System SHALL use idempotency keys for all outgoing WAHA send requests to prevent
   duplicate sends caused by job retries.
3. THE System SHALL mask all phone numbers and message body content in application logs
   by replacing the middle digits of phone numbers with asterisks and truncating message
   bodies to 20 characters maximum in log entries.
4. THE System SHALL NOT log raw WAHA credentials, API tokens, or session secrets at
   any log level.
5. WHEN a WAHA endpoint URL is configured via SettingsHub, THE System SHALL validate
   the URL against an SSRF allowlist and SHALL reject any URL resolving to a private IP
   range (RFC 1918) or loopback address before making any outbound request.
6. THE WahaMessageDispatcher SHALL enforce a per-contact outgoing rate limit. WHEN the
   rate limit is exceeded, THE WahaMessageDispatcher SHALL queue the message with a
   delayed dispatch rather than dropping it.
7. ALL PeopleConnect API routes SHALL be protected by Laravel Sanctum authentication
   and a dedicated `peopleconnect` gate or role check. An authenticated user without
   the required permission SHALL receive HTTP 403.
8. THE System SHALL encrypt the `body` field of `peopleconnect_messages` at rest using
   the application encryption key where the deployment environment requires encryption
   of message content.

---

### Requirement 27: Background Processing Log and Realtime Ticker

**User Story:** As Hedra, I want to see a live log of background operations for the
active conversation, so that I can understand what the system is doing without opening
separate log pages.

#### Acceptance Criteria

1. WHEN any background job writes a `peopleconnect_processing_logs` record for a
   conversation, THE PeopleConnectRealtimeBroadcaster SHALL broadcast a
   `peopleconnect.processing.log.created` event on the conversation's Reverb channel
   with the log entry data.
2. THE NxConversationHeader background log ticker SHALL subscribe to the conversation
   Reverb channel and append new log entries in real time, showing the last five entries
   with auto-scroll.
3. THE NxConversationHeader log ticker SHALL include a `View All` link that opens a
   full log drawer showing all `peopleconnect_processing_logs` entries for the
   conversation, paginated and filterable by `event_type`.
4. THE processing log SHALL capture at minimum the following event types:
   `message_saved`, `session_opened`, `session_closed`, `intent_analyzed`,
   `topic_detected`, `context_assembled`, `agent_drafting`, `draft_ready`,
   `message_queued`, `message_sent`, `delivery_ack_received`, `memory_extracted`,
   `task_created`, `rule_blocked`, `autopilot_blocked`, and `error_retry`.

---

### Requirement 28: SettingsHub Integration

**User Story:** As an operator, I want all WAHA credentials, sync intervals, and
PeopleConnect policy settings stored in SettingsHub, so that configuration changes
do not require code deployment.

#### Acceptance Criteria

1. THE System SHALL read the WAHA base URL and API key from SettingsHub. IF either
   setting is missing or blank, THEN THE LiveMsgsSyncService SHALL set the sync status
   to `not_configured` and return a descriptive error from
   `GET /api/v1/peopleconnect/livemsgs/status`.
2. THE System SHALL read the global default reply mode, sync interval, quiet hours
   definition, max autopilot replies per contact per day, agent confidence threshold,
   and outgoing rate limit from SettingsHub at runtime without requiring a restart.
3. WHEN a SettingsHub value used by PeopleConnectHub is updated, THE System SHALL
   invalidate any in-memory configuration cache for that value within 60 seconds.

---

### Requirement 29: Parsers and Round-Trip Fidelity

**User Story:** As a developer, I want all data transformation layers to be verified
with round-trip tests, so that WAHA payloads, API responses, and context snapshots
do not lose information during serialization and deserialization.

#### Acceptance Criteria

1. THE WahaWebhookIngestionService SHALL parse incoming WAHA JSON payloads into a
   normalized `WahaWebhookPayload` value object. WHEN a valid WAHA payload is provided,
   THE WahaWebhookIngestionService SHALL parse it without error.
2. THE System SHALL include a pretty-printer for `WahaWebhookPayload` objects that
   produces a canonical JSON representation.
3. FOR ALL valid `WahaWebhookPayload` objects, parsing the pretty-printed output
   SHALL produce an equivalent object (round-trip property: parse → print → parse
   equals original).
4. THE PeopleConnectContextAssembler SHALL serialize context snapshots to JSON for
   storage. FOR ALL valid context objects, deserializing a stored snapshot and
   re-serializing it SHALL produce the same JSON output (idempotent serialization
   property).
5. THE API response for `GET .../messages` SHALL deserialize correctly from the backend
   JSON on the frontend. FOR ALL message records with all optional fields populated,
   the TypeScript model deserialized on the frontend SHALL contain all fields present
   in the backend response without data loss.

---


### Requirement 30: Migration and Backward Compatibility

**User Story:** As a developer, I want the PeopleConnect data model to coexist with
the existing generic conversation system, so that existing data and routes are not
broken during the incremental rollout.

#### Acceptance Criteria

1. THE System SHALL create all 13 PeopleConnect tables as new tables prefixed with
   `peopleconnect_` and SHALL NOT modify or drop the existing generic `conversations`,
   `messages`, or `conversation_sessions` tables.
2. THE System SHALL register all new PeopleConnect routes under `/api/v1/peopleconnect/`
   and SHALL NOT remove or modify existing routes under `/api/v1/conversations/` until
   the migration cutover is explicitly scheduled.
3. WHEN the frontend PeopleConnectHub page is loaded, THE System SHALL read exclusively
   from `peopleconnect_*` tables through the new dedicated API. The existing
   `/conversations` page MAY continue to read from the old tables during transition.
4. THE System SHALL provide a one-time data migration command that copies existing
   `conversations`, `messages`, and `conversation_sessions` records into the
   corresponding `peopleconnect_*` tables where a matching `contact_id` can be resolved,
   without deleting any source records.

---

## Acceptance Criteria Summary

PeopleConnectHub is complete when all of the following conditions are verified:

- All 13 `peopleconnect_*` database tables exist with correct columns and migrations.
- The WAHA webhook handler at `POST /api/v1/webhooks/waha` accepts real WAHA payloads
  without requiring a `conversation_id` field and dispatches `ProcessWahaWebhookJob`.
- `ProcessWahaWebhookJob` resolves contacts, opens sessions, deduplicates messages,
  saves messages, dispatches analysis jobs, and broadcasts Reverb events.
- Scheduled hourly reconciliation jobs recover missed contacts, conversations, and
  messages from WAHA without duplication.
- Sessions auto-close after two hours of inactivity via
  `CloseInactivePeopleConnectSessionsJob` and new sessions open on the next message.
- All 40+ API routes are registered under `/api/v1/peopleconnect/` and protected by
  authentication.
- Global and per-contact reply mode is stored, resolved, and enforced by
  `PeopleConnectReplyModeService`.
- Copilot drafts are generated, stored, and require explicit approval before sending.
- Autopilot sends are blocked when any safety condition fails, with block reason logged
  and broadcast.
- Outgoing messages are queued, dispatched by `DispatchWahaMessageJob`, and tracked
  through delivered/read/failed states with retry support.
- Message analysis populates topic, intent, tone, sentiment, emotional baseline, and
  tone mirroring on every inbound message.
- Context snapshots are assembled and stored before every AI generation call.
- All PeopleConnect state changes broadcast through Reverb channels.
- The frontend hub exists at `/people-connect` with the correct navigation item.
- `NxPeopleConnectTopbar`, `NxLiveMsgsModal`, `NxConversationSidebar`,
  `NxConversationHeader`, `NxMessagePanel`, and `NxComposer` are fully implemented.
- Rules, notes, context, memories, and tasks modals work for the selected contact.
- The message panel uses sender-type color coding, date separators, session separators,
  delivery status indicators, and a per-message toolbar.
- Realtime subscriptions via Reverb/Echo keep the frontend up to date without polling.
- ContactHub integration resolves contacts and writes message evidence.
- AgentsHub and AiModelsHub handle all AI generation and analysis calls with tracing.
- All production hardening requirements are met: webhook signature validation,
  deduplication, rate limiting, PII masking, SSRF protection, and encryption where
  required.
- Backend test coverage exists for webhook ingestion, session lifecycle, message
  deduplication, reply mode resolution, outgoing dispatch, and autopilot safety checks.
- Frontend build passes TypeScript compilation with no errors on all new components.
