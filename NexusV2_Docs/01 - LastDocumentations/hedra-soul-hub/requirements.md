# HedraSoulHub Complete Implementation

## Audit Report

This section documents the current state of HedraSoulHub implementation across both
Nexus-Frontend (Next.js/TypeScript) and Nexus-backend (Laravel/PHP), identifying all
missing implementations, discrepancies, and defects that must be resolved before
HedraSoulHub can be considered complete.

---

## 🛑 Missing Implementations

### Backend — Missing Implementations

**B-M-01** All 14 HedraSoulHub-specific database tables are absent. The tables
`hedrasoul_sessions`, `hedrasoul_messages`, `hedrasoul_message_mentions`,
`hedrasoul_context_snapshots`, `souly_instruction_versions`, `souly_runtime_profiles`,
`souly_action_policies`, `hedra_clone_sources`, `hedra_profile_facts`,
`hedra_memory_suggestions`, `hedra_memory_versions`, `hedrasoul_approval_requests`,
`hedrasoul_notifications`, and `souly_action_traces` do not exist.

**B-M-02** All 14 recommended HedraSoulHub service classes are absent:
`HedraSoulSessionService`, `HedraSoulMessageService`, `SoulyCommandRouter`,
`SoulyContextAssembler`, `SoulyPromptBuilder`, `SoulyInstructionVersionService`,
`SoulyModelControlService`, `HedraCloneProfileService`, `HedraMemoryService`,
`HedraMemoryMaintenanceService`, `ApprovalInboxService`, `SoulyActionPolicyService`,
`SoulyTraceService`, and `HedraSoulNotificationService`.

**B-M-03** All 7 recommended queue jobs are absent: `ProcessHedraSoulMessageJob`,
`AnalyzeHedraSoulMessageJob`, `ExecuteSoulyCommandJob`,
`CreateHedraMemorySuggestionJob`, `RebuildHedraCloneProfileJob`,
`RecomputeHedraMemoryEmbeddingsJob`, and `DispatchApprovalReminderJob`.

**B-M-04** No dedicated HedraSoulHub controllers exist. There are no controllers for
sessions, messages, Souly control, system instructions, Hedra profile, clone sources,
memories, approvals, notifications, mentions, context preview, search, or analytics
under the `/api/v1/hedrasoul` prefix.

**B-M-05** No API routes exist under `/api/v1/hedrasoul`. All 50+ required endpoints
covering sessions, messages, Souly controls, instructions, Hedra profile, clone sources,
memories, approvals, notifications, mentions, context preview, and analytics are absent.

**B-M-06** No Souly instruction versioning system exists. There is no versioned
instruction table, no draft/active/archived lifecycle, no diff viewer data, no rollback
endpoint, and no test sandbox.

**B-M-07** No approval gate system exists. There is no `hedrasoul_approval_requests`
table, no approval inbox API, no approve/reject/defer endpoints, and no
`DispatchApprovalReminderJob` for overdue approvals.

**B-M-08** No HedraSoulHub notification infrastructure exists. There is no
`hedrasoul_notifications` table, no priority/severity system, no snooze/dismiss/convert
endpoints, and no realtime notification broadcast for HedraSoulHub events.

**B-M-09** No HedraSoulHub mention system exists. There is no mention resolution
service, no `GET /api/v1/hedrasoul/mentions/search` endpoint, no resolved mention
storage in message metadata, and no audit trail for sensitive object injection.

**B-M-10** No Hedra clone source management exists. There is no `hedra_clone_sources`
table, no source type/sensitivity/scope classification, no conflict detection, and no
version history for clone sources.

**B-M-11** No Hedra profile facts management exists. There is no `hedra_profile_facts`
table, no memory type classification (working, episodic, semantic, structured, graph,
preference, tone/style, decision, boundary, correction), and no memory suggestion and
approval workflow.

**B-M-12** No `SoulyContextAssembler` service exists. There is no context assembly
from Souly instruction version, active persona, session summary, mentions, injected
memories, Hedra profile facts, rules, tool permissions, and token estimation.

**B-M-13** No `souly_action_traces` table or `SoulyTraceService` exists. Souly actions
are not traced with trace ID, parsed intent, selected action, model, agent, instruction
version, context snapshot ID, tools invoked, tasks created, approval decision, cost,
duration, or errors.

**B-M-14** No autonomy mode system exists. There is no `souly_action_policies` table,
no `SoulyActionPolicyService`, and no enforcement of the five autonomy modes:
`chat_only`, `copilot`, `operator`, `autopilot_limited`, `emergency_paused`.

**B-M-15** No `SoulyCommandRouter` exists. Messages are never parsed for command intent
to distinguish between questions, draft requests, task creation, workflow execution,
memory updates, contact actions, system control requests, and approval triggers.

**B-M-16** No realtime broadcasting events for HedraSoulHub exist in `EventServiceProvider`.
The 13 recommended events (`hedrasoul.message.created`, `hedrasoul.command.executed`,
`hedrasoul.approval.requested`, etc.) are not defined or wired.

**B-M-17** No `souly_runtime_profiles` table exists. Souly's active model instance,
routing profile, persona, and tool permission state have no dedicated storage and
cannot be persisted between sessions.

**B-M-18** No `HedraSoulSessionService` exists. Private sessions between Hedra and
Souly have no lifecycle management: no auto-close on 2-hour inactivity, no session
naming, no archive/restore, and no session summaries.

### Frontend — Missing Implementations

**F-M-01** No `/hedra-soul` standalone route or page exists. HedraSoulHub as a first-
class hub is completely absent from the application. The closest existing page is
`/proactive-ai` which only covers ECA rules — a small fraction of HedraSoulHub.

**F-M-02** No `NxHedraTopbar` component exists with Souly status indicator, active
model display, autonomy mode segmented control, system instruction version selector,
notification bell, approval inbox count, running tasks count, and emergency pause.

**F-M-03** No private Hedra ↔ Souly conversation UI exists. There is no session panel,
no multi-session management, no streaming response display, no mention autocomplete
in the composer, and no slash command support.

**F-M-04** No `NxSoulyControlPanel` component exists for changing autonomy mode,
active model, active instruction version, persona, tool permissions, memory access
toggles, external messaging toggles, Souly quarantine, and context reset.

**F-M-05** No `NxInstructionEditor` component exists for viewing, creating, diffing,
and rolling back versioned Souly system instructions, with a test prompt sandbox.

**F-M-06** No `NxApprovalInbox` component exists. Hedra cannot approve, reject, defer,
or edit actions from agent tasks, workflows, or Souly commands from within HedraSoulHub.

**F-M-07** No `NxHedraCloneManager` component exists for managing clone sources, facts,
writing samples, values, preferences, and boundaries that shape Souly's behavior.

**F-M-08** No `NxHedraMemoryManager` component exists for reviewing, approving, editing,
versioning, searching, and pruning Hedra's memory facts and suggestions.

**F-M-09** No `NxHedraSoulNotifications` component exists. System notifications,
escalations, provider outages, WAHA disconnections, memory conflicts, and autopilot
safety blocks are not surfaced in a dedicated notification center.

**F-M-10** No `NxSoulyContextPreview` component exists. Hedra cannot inspect the
assembled context before a command executes — no system instruction version, active
persona, injected memories, mentioned objects, token estimate, or risk classification.

**F-M-11** No `NxSoulyTraceViewer` component exists. Souly actions cannot be audited
per message for trace ID, parsed intent, model used, tools invoked, tasks created,
approval decision, cost, or duration.

**F-M-12** No `NxSessionList` component exists. Hedra cannot create, name, search,
archive, or switch between multiple private Souly sessions.

**F-M-13** No `NxMentionAutocomplete` component exists in the composer. Contacts,
tasks, workflows, agents, memories, providers, conversations, settings, and schedules
cannot be mentioned and resolved from within a HedraSoul message.

**F-M-14** No `NxTaskMonitor` side panel exists in HedraSoulHub. Hedra cannot see
live task state, task logs, agent traces, and retry/cancel actions from within the hub.

**F-M-15** No `NxWorkflowApprovalModal` exists in HedraSoulHub. Workflows that pause
for human decision cannot be reviewed and acted upon from within the hub.

**F-M-16** No HedraSoulHub analytics page exists showing session counts, task commands,
approval request stats, Souly response latency, model usage costs, memory update
acceptance rates, and autonomy mode change history.

---

## ⚠️ Discrepancies

**B-D-01** The existing `ProactiveAIController` and `proactive-ai` page cover ECA rules,
triggers, and logs. These belong to the ProactiveAI engine, which is a related but
separate concern from HedraSoulHub. The `/proactive-ai` route must coexist but must
not be confused with or merged into HedraSoulHub. The spec clearly states HedraSoulHub
is the private Hedra ↔ Souly interface, not a rule management page.

**B-D-02** The existing `ConversationSession` model (`conversation_id`, `name`,
`status`, `source`, `metadata`, `started_at`, `ended_at`) is a generic model. It lacks
HedraSoulHub-specific fields such as `topic`, `task_count`, `approval_count`,
`instruction_version_id`, `persona_id`, and `last_autonomy_mode`. Using the generic
model for HedraSoulHub sessions would cause structural conflicts.

**B-D-03** The existing `EventServiceProvider` only registers task-related events. None
of the 13 recommended HedraSoulHub broadcast events are wired. Realtime updates for
HedraSoulHub will silently fail even when event classes are created.

**F-D-01** The `/proactive-ai` page references "Souly" in its description but manages
ECA rules, not private Souly conversations or command execution. This creates a UX
confusion between HedraSoulHub (private chat + command center) and ProactiveAI (rule
engine). The two must be clearly separated in navigation.

---

## 🐛 Bugs

**B-BUG-01** The `EventServiceProvider` registers an Eloquent model observer directly
inside `boot()` using `\App\Models\AgentTask::updated(...)`. Eloquent observers
registered via closures inside service providers are not queued and run synchronously
within the HTTP request, which can cause timeouts for any workflow that fires many
rapid status changes.

**F-BUG-01** The `proactive-ai` page's `deleteRule` function catches errors with
`catch { /* silent */ }` — this silently swallows all delete errors with no user
feedback, no notification, and no log. The UI still removes the rule from local state
even when the API call fails, causing a stale state divergence.

**F-BUG-02** The `proactive-ai` page's `toggleRule` function also uses
`catch { /* silent */ }`. A failed toggle silently shows the wrong state to Hedra.
The rule appears toggled in the UI but remains in its original state on the backend.

**F-BUG-03** There is no `app/hedra-soul/page.tsx` — HedraSoulHub does not exist as a
navigation destination. The `/proactive-ai` page is not an adequate substitute for a
private AI command cockpit.

---

## Introduction

HedraSoulHub is the private communication, command, oversight, and personality-management
hub between Hedra and Souly. It is a standalone first-class hub with its own navigation
entry, its own API namespace, its own database tables, and its own frontend layout.

HedraSoulHub is not a dashboard widget and not a sub-area of any other hub. Its
primary job is to give Hedra a dedicated private cockpit for: talking with Souly,
executing commands through safe action routing, approving or rejecting risky work,
monitoring task/agent/workflow activity, editing Souly's instructions and configuration,
and managing Hedra's own profile and memory.

All AI actions route through AgentsHub and AiModelsHub. No external memory services are
allowed. Long-running actions are queued, logged, and observable. Risky and irreversible
actions require explicit human approval.

---

## Glossary

- **HedraSoulHub**: The standalone private hub for Hedra ↔ Souly communication and command.
- **Souly**: The private AI companion/operator representing Hedra inside Nexus.
- **HedraSoul Session**: A private time-bounded conversation segment between Hedra and Souly.
- **Command**: An instruction from Hedra that may produce an answer, draft, task, workflow execution, memory update, or approval request.
- **Mention**: A structured `@object` reference inside a HedraSoul message that resolves to a Nexus object (contact, task, workflow, agent, memory, provider, setting, schedule).
- **Approval Gate**: A human-in-the-loop checkpoint requiring Hedra's decision (approve/reject/defer/edit) before a risky action proceeds.
- **Hedra Clone Profile**: The structured set of sources, facts, memories, writing samples, values, and style rules used to shape Souly's behavior.
- **Souly System Instruction**: The versioned instruction set controlling Souly's identity, values, tone, boundaries, tool usage, and autonomy policy.
- **Autonomy Mode**: One of `chat_only`, `copilot`, `operator`, `autopilot_limited`, `emergency_paused` — controls how autonomously Souly can act.
- **SoulyCommandRouter**: The backend service that parses a message to determine its command intent and routes it to the correct action handler.
- **SoulyContextAssembler**: The backend service that builds a structured prompt context from instruction version, persona, session summary, mentions, memories, and profile facts.
- **SoulyTraceService**: The backend service that writes a `souly_action_traces` record for every meaningful Souly action.
- **ApprovalInboxService**: The backend service that creates, queries, and resolves `hedrasoul_approval_requests` records.
- **Risk Level**: Classification of an action's danger: `read`, `draft`, `write_low`, `write_medium`, `external_send`, `danger`.
- **Reverb**: Laravel Reverb — the WebSocket server used for realtime broadcasting.
- **Echo**: Laravel Echo — the frontend WebSocket client library.
- **apiClient**: The centralized Axios HTTP client at `@/lib/api/client` — all frontend components MUST use this exclusively.

---

## Requirements

---

### Requirement 1: HedraSoulHub Data Model — 14 Core Tables

**User Story:** As a developer, I want a dedicated HedraSoulHub database schema so that
private sessions, messages, mentions, instructions, approval requests, notifications, and
Hedra profile data are stored independently from all other hubs.

#### Acceptance Criteria

1. THE System SHALL create a `hedrasoul_sessions` table with columns: `id`, `title`,
   `status` (`active`, `archived`), `topic`, `task_count`, `approval_count`,
   `instruction_version_id`, `last_autonomy_mode`, `opened_at`, `closed_at`, `summary`,
   and timestamps.
2. THE System SHALL create a `hedrasoul_messages` table with columns: `id`, `session_id`,
   `sender_type` (`user`, `agent`, `system`), `sender_id`, `body`, `body_format`,
   `status`, `intent`, `topic`, `tone`, `sentiment`, `risk_level`, `context_snapshot_id`,
   `trace_id`, `model_instance_id`, `token_count`, `cost_usd`, `is_streaming`, and timestamps.
3. THE System SHALL create a `hedrasoul_message_mentions` table with columns: `id`,
   `message_id`, `mention_type`, `object_id`, `object_type`, `display_name`, `sensitivity`,
   and `resolved_at`.
4. THE System SHALL create a `hedrasoul_context_snapshots` table with columns: `id`,
   `session_id`, `message_id`, `instruction_version_id`, `persona_id`, `model_instance_id`,
   `payload` (JSON), `token_estimate`, `risk_classification`, `excluded_items` (JSON),
   and `created_at`.
5. THE System SHALL create a `souly_instruction_versions` table with columns: `id`,
   `version_number`, `status` (`draft`, `active`, `archived`), `content` (text/JSON),
   `change_reason`, `activated_at`, `activated_by`, and timestamps.
6. THE System SHALL create a `souly_runtime_profiles` table with columns: `id`,
   `autonomy_mode`, `active_model_instance_id`, `active_instruction_version_id`,
   `active_persona_id`, `tool_permissions` (JSON), `memory_access`, `contact_access`,
   `task_execution_access`, `workflow_execution_access`, `external_messaging_access`,
   `is_quarantined`, and timestamps.
7. THE System SHALL create a `souly_action_policies` table with columns: `id`,
   `policy_type`, `rule_key`, `rule_value`, `applies_to_mode`, and timestamps.
8. THE System SHALL create a `hedra_clone_sources` table with columns: `id`,
   `source_type`, `content` (text), `confidence`, `sensitivity`, `freshness_score`,
   `visibility_scope`, `validation_status`, `provenance`, `is_archived`, and timestamps.
9. THE System SHALL create a `hedra_profile_facts` table with columns: `id`,
   `memory_type`, `content`, `confidence`, `evidence` (JSON), `sensitivity`,
   `visibility_scope`, `is_approved`, `approved_at`, `version`, and timestamps.
10. THE System SHALL create a `hedra_memory_suggestions` table with columns: `id`,
    `source_message_id`, `content`, `memory_type`, `confidence`, `status`
    (`pending`, `approved`, `rejected`), `reviewed_at`, and timestamps.
11. THE System SHALL create a `hedra_memory_versions` table with columns: `id`,
    `fact_id`, `content`, `version_number`, `changed_by`, `change_reason`, and timestamps.
12. THE System SHALL create a `hedrasoul_approval_requests` table with columns: `id`,
    `source_type` (task/workflow/command/agent), `source_id`, `action_description`,
    `inputs` (JSON), `expected_side_effects`, `risk_level`, `cost_estimate`,
    `context_snapshot_id`, `agent_reasoning`, `status`, `decided_by`,
    `decided_at`, `decision_notes`, and timestamps.
13. THE System SHALL create a `hedrasoul_notifications` table with columns: `id`,
    `notification_type`, `priority`, `title`, `body`, `related_type`, `related_id`,
    `action_buttons` (JSON), `is_read`, `snoozed_until`, `is_dismissed`, and timestamps.
14. THE System SHALL create a `souly_action_traces` table with columns: `id`,
    `message_id`, `trace_id`, `parsed_intent`, `selected_action`, `model_instance_id`,
    `agent_id`, `instruction_version_id`, `context_snapshot_id`, `tools_invoked` (JSON),
    `tasks_created` (JSON), `workflows_triggered` (JSON), `approval_decision`,
    `final_output`, `cost_usd`, `duration_ms`, `errors` (JSON), and timestamps.

---

### Requirement 2: Fix Proactive AI Silent Error Bugs (F-BUG-01, F-BUG-02)

**User Story:** As Hedra, I want rule toggle and delete operations to show visible
feedback when they fail, so that I always know the true state of my rules.

#### Acceptance Criteria

1. WHEN `deleteRule` is called in the proactive-ai page and the API returns an error,
   THE `ProactiveAIPage` SHALL display an error notification and SHALL NOT remove the
   rule from local state.
2. WHEN `toggleRule` is called and the API returns an error, THE `ProactiveAIPage`
   SHALL display an error notification and SHALL revert the optimistic UI toggle to the
   original state.
3. IF an API call fails, THEN THE frontend component SHALL call `addNotification` (or
   equivalent) with the error message before discarding the error.

---

### Requirement 3: HedraSoulHub API Routes

**User Story:** As a frontend developer, I want all HedraSoulHub data exposed under
`/api/v1/hedrasoul/`, so that the hub can be built on a dedicated API namespace.

#### Acceptance Criteria

1. THE System SHALL register the following session routes: `GET /hedrasoul/sessions`,
   `POST /hedrasoul/sessions`, `GET /hedrasoul/sessions/{id}`,
   `PATCH /hedrasoul/sessions/{id}`, `POST /hedrasoul/sessions/{id}/archive`,
   `GET /hedrasoul/sessions/{id}/messages`, `POST /hedrasoul/sessions/{id}/messages`.
2. THE System SHALL register message action routes: `POST /hedrasoul/messages/{id}/regenerate`,
   `GET /hedrasoul/messages/{id}/trace`, `GET /hedrasoul/messages/{id}/context`.
3. THE System SHALL register Souly control routes: `GET /hedrasoul/souly/status`,
   `PATCH /hedrasoul/souly/autonomy`, `PATCH /hedrasoul/souly/model`,
   `POST /hedrasoul/souly/quarantine`, `POST /hedrasoul/souly/resume`,
   `POST /hedrasoul/souly/simulate`.
4. THE System SHALL register instruction routes: `GET /hedrasoul/instructions`,
   `POST /hedrasoul/instructions`, `GET /hedrasoul/instructions/{id}`,
   `PATCH /hedrasoul/instructions/{id}`, `POST /hedrasoul/instructions/{id}/activate`,
   `POST /hedrasoul/instructions/{id}/rollback`, `POST /hedrasoul/instructions/{id}/test`.
5. THE System SHALL register Hedra profile and clone source routes:
   `GET /hedrasoul/profile`, `PATCH /hedrasoul/profile`, `GET /hedrasoul/clone-sources`,
   `POST /hedrasoul/clone-sources`, `PATCH /hedrasoul/clone-sources/{id}`,
   `DELETE /hedrasoul/clone-sources/{id}`.
6. THE System SHALL register memory routes: `GET /hedrasoul/memories`,
   `POST /hedrasoul/memories`, `PATCH /hedrasoul/memories/{id}`,
   `POST /hedrasoul/memories/{id}/approve`, `POST /hedrasoul/memories/{id}/reject`,
   `POST /hedrasoul/memory-maintenance`.
7. THE System SHALL register approval routes: `GET /hedrasoul/approvals`,
   `GET /hedrasoul/approvals/{id}`, `POST /hedrasoul/approvals/{id}/approve`,
   `POST /hedrasoul/approvals/{id}/reject`, `POST /hedrasoul/approvals/{id}/defer`.
8. THE System SHALL register notification routes: `GET /hedrasoul/notifications`,
   `POST /hedrasoul/notifications/{id}/read`, `POST /hedrasoul/notifications/{id}/snooze`.
9. THE System SHALL register search and context routes: `GET /hedrasoul/mentions/search`,
   `POST /hedrasoul/context/preview`, `GET /hedrasoul/search`.
10. THE System SHALL register analytics routes: `GET /hedrasoul/analytics`,
    `GET /hedrasoul/usage`.
11. WHEN any HedraSoulHub route is accessed without authentication, THE System SHALL
    return HTTP 401.

---

### Requirement 4: HedraSoul Session Lifecycle

**User Story:** As Hedra, I want private sessions with Souly to be automatically
bounded by inactivity, so that context is cleanly segmented and each session can be
summarized independently.

#### Acceptance Criteria

1. WHEN Hedra sends the first message to a new HedraSoulHub visit, THE
   `HedraSoulSessionService` SHALL create a new `hedrasoul_sessions` record with
   `status = 'active'` and `opened_at = now()`.
2. WHEN a session has been active and no new message arrives for two hours, THE
   `CloseInactiveHedraSoulSessionsJob` SHALL set `status = 'closed'` and
   `closed_at = now()` on that session.
3. WHEN a new message arrives after a session is closed, THE
   `HedraSoulSessionService` SHALL open a new session rather than appending to the
   closed one.
4. WHEN a session is closed, THE System SHALL dispatch a job to generate a plain-text
   `summary` for that session using AiModelsHub.
5. THE System SHALL allow Hedra to manually archive and restore sessions via
   `POST /hedrasoul/sessions/{id}/archive`.
6. WHEN a session is closed or archived, THE `HedraSoulRealtimeBroadcaster` SHALL
   broadcast a `hedrasoul.session.closed` event to the hub's Reverb channel.

---

### Requirement 5: Souly Command Processing Pipeline

**User Story:** As Hedra, I want Souly to understand whether my message is a question,
a command, a task request, a workflow trigger, or a memory update, so that each intent
is routed to the correct action with appropriate safety checks.

#### Acceptance Criteria

1. WHEN a message is submitted to `POST /hedrasoul/sessions/{id}/messages`, THE
   `HedraSoulMessageService` SHALL save the message and dispatch
   `ProcessHedraSoulMessageJob` asynchronously, returning a `202 Accepted` response.
2. WHEN `ProcessHedraSoulMessageJob` runs, THE `SoulyCommandRouter` SHALL classify
   the message intent as one of: `answer`, `draft`, `create_task`, `execute_agent`,
   `start_workflow`, `schedule_work`, `open_approval`, `update_profile`,
   `suggest_memory`, `suggest_setting`, or `notify`.
3. WHEN the classified intent has `risk_level = 'read'` or `risk_level = 'draft'`,
   THE `SoulyCommandRouter` SHALL allow execution without an approval gate.
4. WHEN the classified intent has `risk_level = 'write_medium'`, `'external_send'`,
   or `'danger'`, THE `SoulyCommandRouter` SHALL create an `hedrasoul_approval_requests`
   record with `status = 'pending'` and SHALL NOT execute the action until approved.
5. WHEN the active autonomy mode is `chat_only`, THE `SoulyCommandRouter` SHALL
   restrict all responses to answers and drafts and SHALL NOT create tasks, execute
   agents, or start workflows.
6. WHEN the active autonomy mode is `emergency_paused`, THE `SoulyCommandRouter`
   SHALL block all commands except `answer` and SHALL broadcast a
   `hedrasoul.autonomy.paused_block` event.
7. AFTER a message is processed, THE `SoulyTraceService` SHALL write a
   `souly_action_traces` record with all required trace fields.
8. AFTER a message is processed, THE `AnalyzeHedraSoulMessageJob` SHALL extract and
   store `intent`, `topic`, `tone`, and `sentiment` on the message record.

---

### Requirement 6: Souly System Instruction Versioning

**User Story:** As Hedra, I want to version Souly's system instructions so that I can
safely test, activate, and roll back instruction changes without losing history.

#### Acceptance Criteria

1. WHEN Hedra creates a new instruction via `POST /hedrasoul/instructions`, THE System
   SHALL create a `souly_instruction_versions` record with `status = 'draft'` and
   the next sequential `version_number`.
2. WHEN Hedra calls `POST /hedrasoul/instructions/{id}/activate`, THE System SHALL
   set the target version to `status = 'active'`, set `activated_at` and `activated_by`,
   and archive all other `active` versions.
3. WHEN Hedra calls `POST /hedrasoul/instructions/{id}/rollback`, THE System SHALL
   activate the previous `active` version and archive the current active version.
4. THE System SHALL expose a `GET /hedrasoul/instructions/{id}` endpoint that returns
   the full instruction content and a `diff` comparison against the current active version.
5. WHEN an instruction activation expands Souly's autonomy permissions compared to the
   current active version, THE System SHALL create an `hedrasoul_approval_requests`
   record before the activation proceeds.
6. WHEN a new instruction is activated, THE `HedraSoulRealtimeBroadcaster` SHALL
   broadcast a `hedrasoul.instruction.changed` event so connected clients update their
   displayed instruction version without reload.
7. THE `POST /hedrasoul/instructions/{id}/test` endpoint SHALL accept a test prompt,
   execute Souly using the target instruction version in sandbox mode, and return the
   response without persisting any side effects.

---

### Requirement 7: Autonomy Mode and Souly Control

**User Story:** As Hedra, I want to control Souly's autonomy level, active model,
and tool permissions from a single control panel, so that I can adjust her behavior
without modifying system instructions.

#### Acceptance Criteria

1. THE `SoulyRuntimeProfileService` SHALL maintain a `souly_runtime_profiles` record
   representing Souly's current operational state; only one record is active at any time.
2. WHEN Hedra calls `PATCH /hedrasoul/souly/autonomy`, THE System SHALL update the
   `autonomy_mode` in `souly_runtime_profiles` and broadcast a
   `hedrasoul.autonomy.changed` event.
3. WHEN Hedra calls `POST /hedrasoul/souly/quarantine`, THE System SHALL set
   `is_quarantined = true` and immediately block all Souly command execution.
4. WHEN Hedra calls `POST /hedrasoul/souly/resume`, THE System SHALL set
   `is_quarantined = false` and restore Souly's previous autonomy mode.
5. WHEN Hedra calls `PATCH /hedrasoul/souly/model`, THE System SHALL update
   `active_model_instance_id` in the runtime profile, validate the model exists in
   AiModelsHub, and record the change in audit logs.
6. THE `SoulyActionPolicyService` SHALL evaluate all autonomy mode checks before any
   `ExecuteSoulyCommandJob` proceeds, consulting `souly_action_policies` for the
   current mode.
7. WHEN `is_quarantined = true` or `autonomy_mode = 'emergency_paused'`, THE
   `SoulyActionPolicyService` SHALL block all outgoing actions and return an explanation.
8. FOR ALL valid combinations of `autonomy_mode` and action `risk_level`, THE
   `SoulyActionPolicyService` SHALL consistently enforce the correct allow/block decision
   (policy invariant).

---

### Requirement 8: Approval Gate System

**User Story:** As Hedra, I want an approval inbox where I can review, approve, reject,
or defer risky actions before they are executed, so that I maintain full control over
consequential operations.

#### Acceptance Criteria

1. WHEN `SoulyCommandRouter` classifies an action as requiring approval, THE
   `ApprovalInboxService` SHALL create an `hedrasoul_approval_requests` record with all
   required fields and `status = 'pending'`.
2. WHEN an approval request is created, THE `HedraSoulRealtimeBroadcaster` SHALL
   broadcast a `hedrasoul.approval.requested` event to the hub Reverb channel.
3. WHEN Hedra calls `POST /hedrasoul/approvals/{id}/approve`, THE `ApprovalInboxService`
   SHALL update `status = 'approved'`, set `decided_by` and `decided_at`, and dispatch
   `ExecuteSoulyCommandJob` with the approved action payload.
4. WHEN Hedra calls `POST /hedrasoul/approvals/{id}/reject`, THE `ApprovalInboxService`
   SHALL update `status = 'rejected'` and NOT execute the action.
5. WHEN Hedra calls `POST /hedrasoul/approvals/{id}/defer`, THE
   `DispatchApprovalReminderJob` SHALL schedule a reminder for the defer duration and
   set `status = 'deferred'`.
6. WHEN an approval request remains `pending` for more than the configured reminder
   interval, THE `DispatchApprovalReminderJob` SHALL broadcast a reminder notification.
7. WHEN an approval is resolved, THE `HedraSoulRealtimeBroadcaster` SHALL broadcast
   `hedrasoul.approval.approved` or `hedrasoul.approval.rejected` to update all
   connected clients.
8. FOR ALL approval requests, the approval state machine SHALL only allow transitions
   `pending → approved`, `pending → rejected`, and `pending → deferred` (state
   machine invariant).

---

### Requirement 9: Mention System

**User Story:** As Hedra, I want to mention contacts, tasks, workflows, agents,
memories, and providers in my messages to Souly, so that the relevant context is
automatically assembled and injected into Souly's prompt.

#### Acceptance Criteria

1. THE `GET /api/v1/hedrasoul/mentions/search` endpoint SHALL accept a `query` parameter
   and return matching objects from at least: contacts (ContactHub), tasks (TasksHub),
   workflows (WorkflowsHub), agents (AgentsHub), and memories (internal).
2. WHEN a message is saved with one or more mentions, THE `HedraSoulMessageService`
   SHALL create `hedrasoul_message_mentions` records for each resolved mention with
   `mention_type`, `object_id`, `object_type`, `display_name`, and `sensitivity`.
3. WHEN `SoulyContextAssembler` builds a context snapshot, THE assembler SHALL include
   the resolved data for all mentions in that message.
4. WHEN a sensitive object (sensitivity level ≥ `medium`) is mentioned and injected into
   context, THE `HedraSoulMessageService` SHALL write an audit entry with the mention
   type and object ID.
5. IF a user lacks permission to access a mentioned object, THEN THE mention resolver
   SHALL omit the object from context and mark the mention as `unresolved`.
6. THE frontend `NxMentionAutocomplete` component SHALL use `apiClient.get` to call
   the mentions search endpoint, support keyboard navigation, and show a preview card
   for each result.

---

### Requirement 10: Hedra Clone Profile and Memory Management

**User Story:** As Hedra, I want to manage the sources, facts, and memories that shape
Souly's understanding of me, so that Souly's responses remain accurate, consistent, and
aligned with my preferences and values.

#### Acceptance Criteria

1. THE `HedraCloneProfileService` SHALL support CRUD operations on `hedra_clone_sources`
   with source type, content, confidence, sensitivity, freshness score, visibility scope,
   and validation status.
2. THE `HedraMemoryService` SHALL create, read, update, and archive `hedra_profile_facts`
   with the required memory type, confidence, evidence, and scope fields.
3. WHEN `CreateHedraMemorySuggestionJob` runs after a HedraSoul message, THE System
   SHALL create a `hedra_memory_suggestions` record with `status = 'pending'`.
4. WHEN Hedra approves a suggestion via `POST /hedrasoul/memories/{id}/approve`, THE
   `HedraMemoryService` SHALL create a new `hedra_profile_facts` record and update
   the suggestion `status = 'approved'`.
5. WHEN Hedra rejects a suggestion via `POST /hedrasoul/memories/{id}/reject`, THE
   `HedraMemoryService` SHALL update the suggestion `status = 'rejected'` without
   creating any profile fact.
6. WHEN `HedraMemoryMaintenanceService` runs, THE System SHALL recompute embeddings,
   prune stale facts, and resolve conflicts, writing a maintenance audit record.
7. WHEN a `hedra_profile_facts` record is updated, THE `HedraMemoryService` SHALL
   write a `hedra_memory_versions` record preserving the previous content.
8. THE `POST /hedrasoul/memory-maintenance` endpoint SHALL accept scope, operation, and
   dry_run parameters and return a preview of affected records when `dry_run = true`.

---

### Requirement 11: Context Assembly and Preview

**User Story:** As Hedra, I want to inspect the context Souly will use before a command
executes, so that I can remove optional context items or verify that no sensitive data
is unexpectedly included.

#### Acceptance Criteria

1. WHEN `SoulyContextAssembler` builds a context, THE assembler SHALL include:
   active instruction version, active persona, session summary, last N messages,
   resolved mention objects, injected Hedra memories, Hedra profile facts, contact
   rules/facts if a contact is mentioned, tool permissions, and token estimate.
2. THE `SoulyContextAssembler` SHALL compute a `token_estimate` and truncate the oldest
   messages first when the estimate exceeds the configured maximum token budget.
3. THE `SoulyContextAssembler` SHALL record each excluded item and its exclusion reason
   in the `hedrasoul_context_snapshots.excluded_items` JSON field.
4. THE `POST /hedrasoul/context/preview` endpoint SHALL accept a session ID and message
   draft, assemble the context, and return the snapshot payload WITHOUT persisting a
   snapshot or dispatching any job.
5. WHEN Hedra removes an optional context item from the preview and confirms send, THE
   `SoulyContextAssembler` SHALL exclude that item from the final assembled context.
6. FOR ALL context snapshots, the context modal viewed from the frontend SHALL display
   data that exactly matches the snapshot payload sent to AgentsHub (round-trip invariant).

---

### Requirement 12: Realtime Broadcasting

**User Story:** As Hedra, I want HedraSoulHub to update in realtime as Souly processes
commands, approvals arrive, and notifications are created, so that I never need to
manually refresh the hub.

#### Acceptance Criteria

1. THE `HedraSoulRealtimeBroadcaster` SHALL broadcast on a private channel named
   `hedrasoul.private` for all hub-level events.
2. THE `HedraSoulRealtimeBroadcaster` SHALL broadcast the following events: 
   `hedrasoul.message.created`, `hedrasoul.message.processed`,
   `hedrasoul.command.detected`, `hedrasoul.command.executed`,
   `hedrasoul.approval.requested`, `hedrasoul.approval.approved`,
   `hedrasoul.approval.rejected`, `hedrasoul.instruction.changed`,
   `hedrasoul.model.changed`, `hedrasoul.memory.suggested`, `hedrasoul.memory.approved`,
   `hedrasoul.autonomy.changed`, and `hedrasoul.notification.created`.
3. THE EventServiceProvider SHALL register all HedraSoulHub events to their listeners.
4. THE Frontend SHALL subscribe to `hedrasoul.private` via Laravel Echo on mount of
   the HedraSoulHub page.
5. WHEN a `hedrasoul.message.processed` event is received, THE frontend SHALL append
   Souly's response to the message panel without re-fetching the full message list.
6. WHEN a `hedrasoul.approval.requested` event is received, THE `NxApprovalInbox`
   SHALL increment its unread count and show the new approval without a full reload.
7. WHEN a `hedrasoul.notification.created` event is received, THE notification bell
   in `NxHedraTopbar` SHALL update its severity count in real time.

---

### Requirement 13: Frontend Standalone Hub at `/hedra-soul`

**User Story:** As Hedra, I want HedraSoulHub at a dedicated `/hedra-soul` route as a
first-class navigation hub with the private operations cockpit layout.

#### Acceptance Criteria

1. THE System SHALL create `app/hedra-soul/page.tsx` rendering the full hub shell with
   the four-pane layout: topbar, left session pane, center conversation pane, right
   context/monitor pane.
2. THE `AppLayout` navigation SHALL include a HedraSoulHub nav item linking to
   `/hedra-soul` with a distinct icon.
3. WHEN the page loads, THE hub SHALL fetch the active Souly runtime profile from
   `GET /api/v1/hedrasoul/souly/status` and display Souly's current autonomy mode and
   model in the topbar.
4. THE page SHALL subscribe to `hedrasoul.private` via Laravel Echo on mount and
   unsubscribe on unmount.
5. IF the initial session fetch fails, THE page SHALL display an error boundary with
   a retry action rather than a blank page.
6. THE hub page SHALL be accessible only to authenticated users; unauthenticated access
   SHALL redirect to the login page.

---

### Requirement 14: NxHedraTopbar Component

**User Story:** As Hedra, I want the HedraSoulHub topbar to show Souly's live status,
my approval inbox count, running tasks, and an emergency pause button, so that I can
monitor and control the system at a glance.

#### Acceptance Criteria

1. THE `NxHedraTopbar` SHALL display Souly's current status: `online` (green), `thinking`
   (amber pulse), `paused` (amber steady), `quarantined` (red), or `offline` (gray).
2. THE `NxHedraTopbar` SHALL display the active model name and routing profile from the
   Souly runtime profile.
3. THE `NxHedraTopbar` SHALL render an autonomy mode segmented control
   (`Chat Only` / `Copilot` / `Operator` / `Autopilot`) wired to
   `PATCH /api/v1/hedrasoul/souly/autonomy`.
4. THE `NxHedraTopbar` SHALL display a notification bell showing the count of unread
   `hedrasoul_notifications` by severity; clicking it opens `NxHedraSoulNotifications`.
5. THE `NxHedraTopbar` SHALL display an approval inbox count button; clicking it opens
   `NxApprovalInbox`.
6. THE `NxHedraTopbar` SHALL include a prominent Emergency Pause button that calls
   `PATCH /hedrasoul/souly/autonomy` with `emergency_paused` mode and shows a visible
   paused state to Hedra.
7. WHEN the active autonomy mode changes via Reverb event, THE `NxHedraTopbar` SHALL
   update its displayed mode without a page reload.

---

### Requirement 15: Private Conversation UI — Sessions, Messages, and Composer

**User Story:** As Hedra, I want to chat privately with Souly with a rich composer
supporting mentions, slash commands, context preview, and streaming responses, so that
every interaction feels fluid and transparent.

#### Acceptance Criteria

1. THE `NxSessionList` component SHALL render a list of `hedrasoul_sessions`, showing
   title, topic, last message preview, status indicator, task count, and approval count.
   Hedra SHALL be able to create, rename, archive, and switch sessions.
2. THE `NxHedraSoulMessagePanel` component SHALL render messages with date separators,
   session separators, and distinct sender-type styling (user: right aligned; Souly/agent:
   left aligned; system: centered/muted).
3. THE `NxHedraSoulMessagePanel` SHALL support streaming response rendering — Souly's
   response body SHALL update incrementally as tokens arrive via Reverb.
4. EACH message in `NxHedraSoulMessagePanel` SHALL have a hover toolbar with: intent,
   topic, tone, model, cost, trace link, create-task, save-memory, copy, and regenerate.
5. THE `NxHedraSoulComposer` component SHALL support: plain text, markdown preview,
   mention autocomplete (`@object` with search results from mentions/search API),
   slash commands (`/task`, `/workflow`, `/memory`, `/model`, `/pause`, `/summarize`,
   `/inspect-context`), model override selector, context preview button, and send button.
6. WHEN the context preview button is clicked, THE `NxSoulyContextPreview` modal SHALL
   open and display the assembled context snapshot from `POST /hedrasoul/context/preview`.
7. WHEN `emergency_paused` autonomy mode is active, THE `NxHedraSoulComposer` SHALL
   disable the send button and display a visible warning banner.

---

### Requirement 16: Souly Control Panel

**User Story:** As Hedra, I want a dedicated control panel to change Souly's model,
instruction version, autonomy mode, persona, and tool permissions without editing
system instructions directly.

#### Acceptance Criteria

1. THE `NxSoulyControlPanel` component SHALL display and allow updating: active
   autonomy mode, active model and routing profile, active instruction version,
   active persona, memory access toggle, contact access toggle, task execution access
   toggle, workflow execution access toggle, and external messaging permission toggle.
2. WHEN a toggle is changed, THE component SHALL call the appropriate PATCH endpoint
   and update the displayed state optimistically, reverting on API error.
3. THE `NxSoulyControlPanel` SHALL include a Quarantine Souly button that calls
   `POST /hedrasoul/souly/quarantine` with a confirmation dialog.
4. THE `NxSoulyControlPanel` SHALL include a Reset Context button that clears the
   active session's context assembly cache.
5. THE `NxSoulyControlPanel` SHALL include a Simulate/Dry-Run button that calls
   `POST /hedrasoul/souly/simulate` and displays the result without committing any
   side effects.

---

### Requirement 17: Instruction Editor and Approval Inbox

**User Story:** As Hedra, I want to safely version and test Souly's system instructions
and review risky action requests from an approval inbox, so that I maintain authorship
over Souly's behavior.

#### Acceptance Criteria

1. THE `NxInstructionEditor` component SHALL display the list of instruction versions
   with status, version number, change reason, and activated_at.
2. THE `NxInstructionEditor` SHALL allow creating a new draft version, editing draft
   content using a rich text or markdown editor, viewing a diff between draft and active
   versions, activating a draft, and rolling back to a previous version.
3. WHEN a draft is activated that expands autonomy, THE `NxInstructionEditor` SHALL
   display an approval gate confirmation dialog before proceeding.
4. THE `NxInstructionEditor` SHALL include a test sandbox where Hedra can enter a test
   prompt and receive Souly's response using the target instruction version.
5. THE `NxApprovalInbox` component SHALL list all `hedrasoul_approval_requests` with
   `status = 'pending'`, showing action description, risk level, cost estimate, source
   type, and agent reasoning summary.
6. FOR EACH approval request, THE `NxApprovalInbox` SHALL provide Approve, Reject,
   Edit-and-Approve, Defer, Open-Source, and View-Logs actions.
7. WHEN Hedra approves via the Edit-and-Approve action, THE `NxApprovalInbox` SHALL
   allow editing the action inputs before submitting the approval.

---

### Requirement 18: Hedra Clone Manager and Memory Manager

**User Story:** As Hedra, I want to manage my clone sources and memory facts from
within HedraSoulHub so that Souly's understanding of me stays accurate and auditable.

#### Acceptance Criteria

1. THE `NxHedraCloneManager` component SHALL list all `hedra_clone_sources` with type,
   content preview, confidence, sensitivity, visibility scope, and validation status.
2. THE `NxHedraCloneManager` SHALL allow adding, editing, archiving, and deleting
   sources via the clone-sources API endpoints.
3. THE `NxHedraMemoryManager` component SHALL display `hedra_profile_facts` grouped by
   memory type, each showing confidence, sensitivity, evidence links, and version history.
4. THE `NxHedraMemoryManager` SHALL show a separate section for `hedra_memory_suggestions`
   with `status = 'pending'`, allowing Hedra to approve, reject, or edit each.
5. THE `NxHedraMemoryManager` SHALL include a Run Maintenance button that calls
   `POST /hedrasoul/memory-maintenance` and shows a dry-run preview before committing.
6. WHEN a `hedrasoul.memory.suggested` event arrives via Reverb, THE
   `NxHedraMemoryManager` SHALL increment the pending suggestions count without reload.

---

### Requirement 19: Notifications, Task Monitor, and Analytics

**User Story:** As Hedra, I want system notifications, live task monitoring, and usage
analytics accessible from within HedraSoulHub, so that the hub is a complete operations
center.

#### Acceptance Criteria

1. THE `NxHedraSoulNotifications` component SHALL display `hedrasoul_notifications`
   ordered by priority, showing type, title, body, related object link, and action buttons.
2. THE `NxHedraSoulNotifications` SHALL support: mark as read, snooze (with duration
   picker), dismiss, convert to task, and open related object actions.
3. THE `NxHedraSoulNotifications` SHALL show a priority-colored header distinguishing
   `critical`, `high`, `medium`, and `low` notifications.
4. THE `NxTaskMonitor` component SHALL show live task state for tasks created from
   HedraSoul commands: status, assigned agent, last log entry, and Retry/Cancel actions.
5. THE analytics page at `/hedra-soul/analytics` SHALL display: total sessions, task
   commands created, approval requests by status, Souly response latency, model usage
   and cost, memory update acceptance rate, and autonomy mode change history.
6. WHEN a `hedrasoul.notification.created` event is received via Reverb, THE
   notification list SHALL prepend the new item without a full reload.

---

### Requirement 20: AgentsHub and AiModelsHub Integration

**User Story:** As a developer, I want all Souly AI calls to route through AgentsHub
and AiModelsHub so that AI usage is tracked, costs are attributed, and Souly can be
swapped without changing HedraSoulHub code.

#### Acceptance Criteria

1. THE `SoulyPromptBuilder` SHALL construct prompts using the active Souly instruction
   version, context snapshot, and user message, then submit to AgentsHub for execution.
2. THE `SoulyModelControlService` SHALL call `PATCH /api/v1/agents/{soulyAgentId}` on
   AgentsHub when a model change is applied, and SHALL validate the model via AiModelsHub
   before committing.
3. WHEN `ExecuteSoulyCommandJob` runs, THE System SHALL record `model_instance_id`,
   `agent_id`, `cost_usd`, and `duration_ms` from the AgentsHub response on the
   `souly_action_traces` record.
4. THE `SoulyModelControlService` SHALL NEVER store AI provider credentials inside
   HedraSoulHub. All credential management goes through SettingsHub / AiModelsHub.
5. WHEN `POST /hedrasoul/souly/simulate` is called, THE System SHALL set a dry-run
   flag on the AgentsHub execution request so no side effects (tasks, workflows,
   messages) are persisted.
