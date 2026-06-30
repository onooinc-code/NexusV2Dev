# HedraSoulHub — Technical Design

## Overview

This document is the technical design for the `hedra-soul-hub` spec. HedraSoulHub is built
from scratch as a standalone private cockpit for Hedra ↔ Souly communication, command execution,
approval management, instruction versioning, and Hedra identity management.

- **Nexus-backend** — Laravel 11, PHP 8.2 (`Nexus-backend/`)
- **Nexus-Frontend** — Next.js 14, TypeScript (`Nexus-Frontend/`)

### Design Principles

1. **Fix before build** — The two silent-error bugs in the proactive-ai page are patched first.
2. **Private by default** — All HedraSoulHub routes are owner-authenticated. No public access.
3. **Approval gates before risk** — Medium/high-risk commands always create an approval request before executing.
4. **Trace everything** — Every Souly action produces a `souly_action_traces` record.
5. **Autonomy mode is authoritative** — `SoulyActionPolicyService` consults the runtime profile before any execution.
6. **Single API client** — All frontend components use `apiClient` from `@/lib/api/client`. No raw `fetch()`.

---

## Architecture

```mermaid
flowchart TD
    FE[Frontend POST /hedrasoul/sessions/{id}/messages] --> HS_MSG[HedraSoulMessageService]
    HS_MSG --> DB_MSG[(hedrasoul_messages)]
    HS_MSG --> PHJ[ProcessHedraSoulMessageJob]
    PHJ --> CMD[SoulyCommandRouter — classify intent]
    CMD --> POLICY[SoulyActionPolicyService — autonomy check]
    POLICY -- allowed --> CTX[SoulyContextAssembler — build context snapshot]
    POLICY -- blocked --> BCAST[HedraSoulRealtimeBroadcaster]
    CTX --> AGT[AgentsHub / AiModelsHub execution]
    AGT --> TRACE[SoulyTraceService — write souly_action_traces]
    CMD -- requires_approval --> APV[ApprovalInboxService — hedrasoul_approval_requests]
    APV --> BCAST
    APV -- approved --> EXE[ExecuteSoulyCommandJob]
    EXE --> AGT
    AGT --> MEM[CreateHedraMemorySuggestionJob]
    AGT --> BCAST
    SCHED[SchedulerHub 2h] --> CLOSE[CloseInactiveHedraSoulSessionsJob]
```

All new backend classes live in `app/Services/HedraSoul/` and `app/Http/Controllers/HedraSoul/`.

---

## Components and Interfaces

### Backend Services

**`HedraSoulSessionService`** (`app/Services/HedraSoul/`)
- `resolveOrCreate(): HedrasoulSession` — returns the default active session or creates one
- `createNamed(string $title): HedrasoulSession`
- `archive(HedrasoulSession $session): void`
- `restore(HedrasoulSession $session): void`
- Session auto-close enforced by `CloseInactiveHedraSoulSessionsJob`

**`HedraSoulMessageService`** (`app/Services/HedraSoul/`)
- `save(array $data, HedrasoulSession $session): HedrasoulMessage`
- Dispatches `ProcessHedraSoulMessageJob` after save
- Returns 202 immediately

**`SoulyCommandRouter`** (`app/Services/HedraSoul/`)
- `classify(HedrasoulMessage $message): CommandIntent`
- Maps message to intent: `answer`, `draft`, `create_task`, `execute_agent`, `start_workflow`, `schedule_work`, `open_approval`, `update_profile`, `suggest_memory`, `suggest_setting`, `notify`
- Looks up `risk_level` for the detected intent
- Checks `SoulyActionPolicyService` before routing

**`SoulyActionPolicyService`** (`app/Services/HedraSoul/`)
- `canExecute(string $intent, string $riskLevel): PolicyResult`
- Checks `souly_runtime_profiles.autonomy_mode` and `is_quarantined`
- Checks `souly_action_policies` table for mode-specific rules
- Enforces: `chat_only` → only answer/draft; `emergency_paused` → block all; `copilot` → draft+preview; `operator` → low-risk write; `autopilot_limited` → pre-approved workflows only

**`SoulyContextAssembler`** (`app/Services/HedraSoul/`)
- `assemble(HedrasoulSession $session, HedrasoulMessage $trigger): HedrasoulContextSnapshot`
- Collects: active instruction version content, active persona, session summary, last N messages, resolved mentions, injected hedra_profile_facts, contact facts (if @mentioned), rules, tool permissions
- Computes token estimate; truncates oldest messages first if over budget
- Records excluded items + reasons in snapshot `excluded_items` JSON
- Stores frozen `hedrasoul_context_snapshots` record before invoking AgentsHub

**`SoulyTraceService`** (`app/Services/HedraSoul/`)
- `record(array $traceData): SoulyActionTrace`
- Writes `souly_action_traces` for every meaningful Souly action

**`ApprovalInboxService`** (`app/Services/HedraSoul/`)
- `create(array $data): HedrasoulApprovalRequest`
- `approve(HedrasoulApprovalRequest $req, int $userId, ?string $notes): void` — dispatches `ExecuteSoulyCommandJob`
- `reject(HedrasoulApprovalRequest $req, int $userId, ?string $notes): void`
- `defer(HedrasoulApprovalRequest $req, string $duration): void` — schedules `DispatchApprovalReminderJob`

**`SoulyInstructionVersionService`** (`app/Services/HedraSoul/`)
- `createDraft(array $content, string $changeReason): SoulyInstructionVersion`
- `activate(SoulyInstructionVersion $version, int $userId): void` — archives current active, creates approval request if autonomy expands
- `rollback(SoulyInstructionVersion $version): void`
- `diff(int $versionId): array` — returns structured diff against current active
- `testSandbox(SoulyInstructionVersion $version, string $testPrompt): string` — runs Souly without persisting side effects

**`HedraCloneProfileService`** (`app/Services/HedraSoul/`)
- CRUD for `hedra_clone_sources`: `create`, `update`, `archive`, `delete`
- `detectConflicts(): array`

**`HedraMemoryService`** (`app/Services/HedraSoul/`)
- `suggestFromMessage(HedrasoulMessage $msg): HedraMemorySuggestion`
- `approve(HedraMemorySuggestion $sug): HedraProfileFact`
- `reject(HedraMemorySuggestion $sug): void`
- CRUD for `hedra_profile_facts`
- `search(string $query): array`

**`HedraSoulNotificationService`** (`app/Services/HedraSoul/`)
- `create(string $type, string $priority, string $title, string $body, ?int $relatedId, ?string $relatedType): HedrasoulNotification`
- `markRead`, `snooze`, `dismiss`

**`HedraSoulRealtimeBroadcaster`** (`app/Services/HedraSoul/`)
- Broadcasts all 13 events to Reverb channel `hedrasoul.hub.{user_id}` (private)

---

## Data Models

### 14 HedraSoulHub Tables

| Table | Key Columns |
|---|---|
| `hedrasoul_sessions` | id, title, status (active/archived/closed), topic, task_count, approval_count, instruction_version_id, last_autonomy_mode, opened_at, closed_at, summary |
| `hedrasoul_messages` | id, session_id, sender_type (user/agent/system), sender_id, body, body_format, status, intent, topic, tone, sentiment, risk_level, context_snapshot_id, trace_id, model_instance_id, token_count, cost_usd, is_streaming |
| `hedrasoul_message_mentions` | id, message_id, mention_type, object_id, object_type, display_name, sensitivity, resolved_at |
| `hedrasoul_context_snapshots` | id, session_id, message_id, instruction_version_id, persona_id, model_instance_id, payload (JSON), token_estimate, risk_classification, excluded_items (JSON) |
| `souly_instruction_versions` | id, version_number, status (draft/active/archived), content (JSON), change_reason, activated_at, activated_by |
| `souly_runtime_profiles` | id, autonomy_mode, active_model_instance_id, active_instruction_version_id, active_persona_id, tool_permissions (JSON), memory_access, contact_access, task_execution_access, workflow_execution_access, external_messaging_access, is_quarantined |
| `souly_action_policies` | id, policy_type, rule_key, rule_value, applies_to_mode |
| `hedra_clone_sources` | id, source_type, content (text), confidence, sensitivity, freshness_score, visibility_scope, validation_status, provenance, is_archived |
| `hedra_profile_facts` | id, memory_type (working/episodic/semantic/structured/graph/preference/tone_style/decision/boundary/correction), content, confidence, evidence (JSON), sensitivity, visibility_scope, is_approved, approved_at, version |
| `hedra_memory_suggestions` | id, source_message_id, content, memory_type, confidence, status (pending/approved/rejected), reviewed_at |
| `hedra_memory_versions` | id, fact_id, content, version_number, changed_by, change_reason |
| `hedrasoul_approval_requests` | id, source_type, source_id, action_description, inputs (JSON), expected_side_effects, risk_level, cost_estimate, context_snapshot_id, agent_reasoning, status (pending/approved/rejected/deferred), decided_by, decided_at, decision_notes |
| `hedrasoul_notifications` | id, notification_type, priority, title, body, related_type, related_id, action_buttons (JSON), is_read, snoozed_until, is_dismissed |
| `souly_action_traces` | id, message_id, trace_id, parsed_intent, selected_action, model_instance_id, agent_id, instruction_version_id, context_snapshot_id, tools_invoked (JSON), tasks_created (JSON), workflows_triggered (JSON), approval_decision, final_output, cost_usd, duration_ms, errors (JSON) |

---

## API Contract Summary

All routes registered under `Route::prefix('hedrasoul')->middleware(['auth:sanctum'])` in `routes/api.php`.

| Method | Path | Description |
|---|---|---|
| GET | `/hedrasoul/sessions` | List sessions |
| POST | `/hedrasoul/sessions` | Create session |
| GET | `/hedrasoul/sessions/{id}` | Get session |
| PATCH | `/hedrasoul/sessions/{id}` | Rename/update session |
| POST | `/hedrasoul/sessions/{id}/archive` | Archive session |
| GET | `/hedrasoul/sessions/{id}/messages` | List messages |
| POST | `/hedrasoul/sessions/{id}/messages` | Send message (202 async) |
| POST | `/hedrasoul/messages/{id}/regenerate` | Regenerate Souly response |
| GET | `/hedrasoul/messages/{id}/trace` | View trace |
| GET | `/hedrasoul/messages/{id}/context` | View context snapshot |
| GET | `/hedrasoul/souly/status` | Souly runtime profile |
| PATCH | `/hedrasoul/souly/autonomy` | Change autonomy mode |
| PATCH | `/hedrasoul/souly/model` | Change active model |
| POST | `/hedrasoul/souly/quarantine` | Quarantine Souly |
| POST | `/hedrasoul/souly/resume` | Resume from quarantine |
| POST | `/hedrasoul/souly/simulate` | Dry-run a command |
| GET | `/hedrasoul/instructions` | List instruction versions |
| POST | `/hedrasoul/instructions` | Create draft instruction |
| GET | `/hedrasoul/instructions/{id}` | Get instruction + diff |
| PATCH | `/hedrasoul/instructions/{id}` | Update draft |
| POST | `/hedrasoul/instructions/{id}/activate` | Activate version |
| POST | `/hedrasoul/instructions/{id}/rollback` | Rollback to previous |
| POST | `/hedrasoul/instructions/{id}/test` | Test in sandbox |
| GET | `/hedrasoul/profile` | Hedra profile |
| PATCH | `/hedrasoul/profile` | Update profile |
| GET | `/hedrasoul/clone-sources` | List clone sources |
| POST | `/hedrasoul/clone-sources` | Add clone source |
| PATCH | `/hedrasoul/clone-sources/{id}` | Update source |
| DELETE | `/hedrasoul/clone-sources/{id}` | Delete source |
| GET | `/hedrasoul/memories` | List profile facts |
| POST | `/hedrasoul/memories` | Add memory |
| PATCH | `/hedrasoul/memories/{id}` | Edit memory |
| POST | `/hedrasoul/memories/{id}/approve` | Approve suggestion |
| POST | `/hedrasoul/memories/{id}/reject` | Reject suggestion |
| POST | `/hedrasoul/memory-maintenance` | Run maintenance |
| GET | `/hedrasoul/approvals` | List approval requests |
| GET | `/hedrasoul/approvals/{id}` | Get approval detail |
| POST | `/hedrasoul/approvals/{id}/approve` | Approve action |
| POST | `/hedrasoul/approvals/{id}/reject` | Reject action |
| POST | `/hedrasoul/approvals/{id}/defer` | Defer action |
| GET | `/hedrasoul/notifications` | List notifications |
| POST | `/hedrasoul/notifications/{id}/read` | Mark read |
| POST | `/hedrasoul/notifications/{id}/snooze` | Snooze |
| GET | `/hedrasoul/mentions/search` | Resolve mention search |
| POST | `/hedrasoul/context/preview` | Preview context |
| GET | `/hedrasoul/search` | Full-text search |
| GET | `/hedrasoul/analytics` | Analytics |
| GET | `/hedrasoul/usage` | Usage stats |

---

## Realtime Broadcasting

Channel: `hedrasoul.hub.{user_id}` (private, Laravel Reverb)

| Event | Trigger |
|---|---|
| `hedrasoul.message.created` | Message saved |
| `hedrasoul.message.processed` | ProcessHedraSoulMessageJob complete |
| `hedrasoul.command.detected` | Intent classified |
| `hedrasoul.command.executed` | ExecuteSoulyCommandJob complete |
| `hedrasoul.approval.requested` | ApprovalInboxService creates request |
| `hedrasoul.approval.approved` | Approval approved |
| `hedrasoul.approval.rejected` | Approval rejected |
| `hedrasoul.instruction.changed` | Instruction version activated |
| `hedrasoul.model.changed` | Model override set |
| `hedrasoul.memory.suggested` | CreateHedraMemorySuggestionJob complete |
| `hedrasoul.memory.approved` | Memory suggestion approved |
| `hedrasoul.autonomy.changed` | Autonomy mode changed |
| `hedrasoul.notification.created` | HedraSoulNotificationService creates notification |

Channel definition in `routes/channels.php`:
```php
Broadcast::channel('hedrasoul.hub.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});
```

---

## Frontend Architecture

```
app/hedra-soul/
  page.tsx                        ← Hub shell, Echo subscriptions, layout
  components/
    NxHedraTopbar.tsx
    NxSessionList.tsx
    NxHedraSoulComposer.tsx
    NxHedraSoulMessagePanel.tsx
    NxSoulyControlPanel.tsx
    NxInstructionEditor.tsx
    NxApprovalInbox.tsx
    NxHedraCloneManager.tsx
    NxHedraMemoryManager.tsx
    NxHedraSoulNotifications.tsx
    NxSoulyContextPreview.tsx
    NxSoulyTraceViewer.tsx
    NxMentionAutocomplete.tsx
    NxTaskMonitor.tsx
    NxWorkflowApprovalModal.tsx
```

### Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│  NxHedraTopbar (Souly status · model · autonomy mode · bell)    │
├──────────────┬──────────────────────────────┬───────────────────┤
│ NxSessionList│  NxHedraSoulMessagePanel     │ NxSoulyControlPanel│
│              │  (date/session separators,   │ NxSoulyContextPreview│
│ NxApproval   │   sender colors, toolbar)    │ NxTaskMonitor     │
│ Inbox badge  │                              │ NxSoulyTraceViewer │
│              │  NxHedraSoulComposer         │                   │
└──────────────┴──────────────────────────────┴───────────────────┘
```

### Component Interfaces

#### `NxHedraTopbar`
```typescript
interface NxHedraTopbarProps {
  soulyStatus: 'online' | 'offline' | 'thinking' | 'paused';
  activeModel: string;
  autonomyMode: string;
  instructionVersion: number;
  notificationCount: number;
  approvalCount: number;
  runningTaskCount: number;
  failedCount: number;
  onEmergencyPause: () => void;
  onNotificationsClick: () => void;
  onApprovalsClick: () => void;
  onAutonomyChange: (mode: string) => void;
}
```
Emergency pause button → `POST /hedrasoul/souly/quarantine`. Status badge: green=online, amber=thinking, red=paused.

#### `NxSessionList`
```typescript
interface NxSessionListProps {
  sessions: HedrasoulSession[];
  activeSessionId: number | null;
  onSelect: (id: number) => void;
  onCreate: () => void;
  onArchive: (id: number) => void;
}
```
Search input (client-side filter). Session cards show title, topic, message count, approval badge.

#### `NxHedraSoulComposer`
```typescript
interface NxHedraSoulComposerProps {
  sessionId: number;
  soulyStatus: string;
  onMessageSent: () => void;
  onPreviewContext: (snapshot: ContextSnapshot) => void;
}
```
- Text area with markdown support
- `NxMentionAutocomplete` inline (triggered by `@`)
- Slash command support (`/task`, `/workflow`, `/memory`, `/model`, `/pause`, `/summarize`, etc.)
- Model override selector
- Preview Context button → calls `POST /hedrasoul/context/preview`
- Dry-run toggle
- Send → `POST /hedrasoul/sessions/{id}/messages` (shows streaming indicator)

#### `NxHedraSoulMessagePanel`
```typescript
interface NxHedraSoulMessagePanelProps {
  sessionId: number;
  messages: HedrasoulMessage[];
  onCreateTask: (msgId: number) => void;
  onSaveMemory: (msgId: number) => void;
  onViewTrace: (msgId: number) => void;
  onRegenerateMessage: (msgId: number) => void;
}
```
- Date separators + session separators
- `user` messages: right-aligned, primary color
- `agent` (Souly) messages: left-aligned, accent color with Souly avatar
- `system` messages: centered, muted
- Streaming state: animated dots while `is_streaming = true`
- Per-message toolbar on hover: intent, topic, tone, sentiment, model, cost, trace, create task, save memory, copy, retry/regenerate
- Approval inline previews when message includes pending approval

#### `NxSoulyControlPanel`
Props: `{ runtimeProfile: SoulyRuntimeProfile; onUpdate: () => void }`
- Autonomy mode segmented control (chat_only / copilot / operator / autopilot_limited / emergency_paused)
- Active model display + override button
- Instruction version selector
- Toggle switches: memory access, contact access, task execution, workflow execution, external messaging
- Quarantine button → `POST /hedrasoul/souly/quarantine`
- Context Reset button
- Simulate/dry-run button

#### `NxInstructionEditor`
Props: `{ versions: SoulyInstructionVersion[]; activeVersionId: number; }`
- Version list with status badges (draft/active/archived)
- Monaco editor (or `<textarea>` with markdown) for instruction content
- Diff viewer between selected version and active version
- Activate, Rollback, Test Sandbox buttons
- Test sandbox: enter prompt, see response, no side effects persisted

#### `NxApprovalInbox`
Props: `{ approvals: HedrasoulApprovalRequest[]; onDecision: () => void }`
- Grouped by priority (danger, external_send, write_medium)
- Per-approval card: workflow/task name, trigger source, requested action, inputs, side effects, risk, cost estimate, agent reasoning
- Approve / Reject / Defer / Edit+Approve buttons → call respective API endpoints

#### `NxMentionAutocomplete`
Props: `{ onSelect: (mention: ResolvedMention) => void }`
- Triggered by `@` in composer
- Calls `GET /hedrasoul/mentions/search?q={query}&type={type}`
- Types: contact, task, workflow, agent, memory, provider, setting, schedule
- Keyboard navigation (arrow keys + enter)
- Preview card for hovered object
- Selected mention stored in message metadata on send

#### `NxHedraCloneManager`
- Lists `hedra_clone_sources` by type: facts, notes, writing samples, values, work preferences, boundaries, voice examples, decision examples
- Add/edit/archive/delete per source
- Sensitivity badge, freshness indicator, visibility scope selector
- Conflict detection section

#### `NxHedraMemoryManager`
- Tabs: All Memories, Pending Suggestions, Conflicts
- Memory list by type with confidence, evidence references, version history
- Approve/reject/edit per suggestion
- Memory search input
- Rebuild embeddings, prune stale, export/erase actions

#### `NxSoulyContextPreview`
Props: `{ snapshot: HedrasoulContextSnapshot; onRemoveItem: (key: string) => void }`
- Displays all assembled context sections: instruction version, persona, session summary, last messages, mentions, injected memories, profile facts, tool permissions
- Token estimate with budget bar
- Risk classification badge
- Excluded items with reasons
- Remove optional context items before send
- Copy raw JSON button for debugging

#### `NxSoulyTraceViewer`
Props: `{ trace: SoulyActionTrace }`
- Trace ID, parsed intent, selected action, model+provider, agent, instruction version
- Context snapshot ID link
- Tools invoked list, tasks created list, workflows triggered list
- Approval decision status
- Final output preview
- Cost (USD) + duration (ms)
- Error details if present

---

## Correctness Properties

### Property 1: Command Processing is Always Async

*For any* valid message submitted to `POST /hedrasoul/sessions/{id}/messages`, the HTTP
response returns 202 before `ProcessHedraSoulMessageJob` has begun executing.

**Validates: Requirements 5.1**

---

### Property 2: Every Souly Action Has a Trace

*For any* `ProcessHedraSoulMessageJob` execution that reaches the AgentsHub call (i.e., not
blocked by policy), exactly one `souly_action_traces` record is written with a non-null
`trace_id`.

**Validates: Requirements 5.7**

---

### Property 3: Approval Gate Blocks Before Execution

*For any* message whose classified intent has `risk_level` in `{write_medium, external_send, danger}`,
the action is NOT executed and an `hedrasoul_approval_requests` record is created with
`status = 'pending'` before any side effect occurs.

**Validates: Requirements 5.4, 8.1**

---

### Property 4: Autonomy Mode Enforces Command Restrictions

*For any* combination of `autonomy_mode` and action `risk_level`, `SoulyActionPolicyService`
consistently returns the correct allow/block decision as specified in the policy table.

**Validates: Requirements 5.5, 5.6, 7.6, 7.8**

---

### Property 5: Emergency Pause Blocks All Actions

*When* `is_quarantined = true` or `autonomy_mode = 'emergency_paused'`,
`SoulyActionPolicyService` blocks every action type including `answer` and returns an
explanation string.

**Validates: Requirements 7.3, 7.7**

---

### Property 6: Instruction Activation Archives Previous Active

*For any* instruction version activation, exactly one version has `status = 'active'`
afterwards — all other previously active versions are set to `archived`.

**Validates: Requirements 6.2**

---

### Property 7: Instruction Rollback Restores Previous Active

*For any* rollback call, the version immediately prior to the current active version
becomes the new `active`, and the current active version becomes `archived`.

**Validates: Requirements 6.3**

---

### Property 8: Context Round-Trip

*For any* context snapshot, the `payload` JSON stored in `hedrasoul_context_snapshots`
is byte-for-byte identical to the context sent to AgentsHub for that Souly response.

**Validates: Requirements 12.3** (Context preview section)

---

### Property 9: Session Closes After 2-Hour Inactivity

*For any* HedraSoul session that is active and has received no new message for 120 minutes,
`CloseInactiveHedraSoulSessionsJob` closes it within 15 minutes of the threshold.

**Validates: Requirements 4.2**

---

### Property 10: New Session Opens After Closure

*For any* closed HedraSoul session, the next incoming message always results in a new
`hedrasoul_sessions` record being created — never appended to the closed session.

**Validates: Requirements 4.3**

---

### Property 11: Memory Suggestion Requires Approval Before Profile Fact

*For any* `hedra_memory_suggestions` record, the corresponding `hedra_profile_facts`
record is only created when `status` is set to `approved` and `reviewed_at` is set —
never before approval.

**Validates: Requirements 8.3** (memory approval subsection)

---

### Property 12: Mention Audit on Sensitive Object Injection

*For any* message that resolves a mention with `sensitivity != 'public'`, an audit entry
is created in `hedrasoul_message_mentions` with the `sensitivity` value recorded before
the context is assembled.

**Validates: Requirements 3.8** (mentions section)

---

### Property 13: Realtime Approval Notification Without Reload

*For any* `hedrasoul.approval.requested` Reverb event, the `NxApprovalInbox` approval
count in `NxHedraTopbar` increments without a page reload.

**Validates: Requirements 8.2**

---

### Property 14: Streaming Message Completes or Errors

*For any* message with `is_streaming = true`, the frontend eventually transitions to
either showing the full response body or showing an error retry button — it never stays
in streaming state indefinitely.

**Validates: Requirements 5.1** (streaming subsection)

---

### Property 15: Proactive AI Silent Errors Now Visible

*For any* failed `deleteRule` or `toggleRule` API call on the proactive-ai page, an
error notification is displayed and local state remains unchanged from the pre-call value.

**Validates: Requirements 2.1, 2.2, 2.3**

---

## Error Handling

### Backend HTTP Contracts

| Scenario | HTTP | Body |
|---|---|---|
| Unauthenticated request | 401 | `{ "message": "Unauthenticated." }` |
| Action blocked by autonomy policy | 403 | `{ "message": "Action blocked: emergency_paused" }` |
| Risk-level requires approval | 202 | `{ "approval_request_id": 123, "status": "pending_approval" }` |
| Resource not found | 404 | `{ "message": "Not found." }` |
| Instruction activation expands autonomy | 202 | Creates approval request before activating |
| AI provider unavailable | — | Job retried 3x, then trace set to `failed`, error broadcast |

### Job Failed Hooks

All HedraSoulHub jobs implement:
```php
public function failed(Throwable $e): void {
    // Update associated message/trace status to 'failed'
    // Write hedrasoul_notifications with type 'agent_failure'
    // Broadcast hedrasoul.notification.created event
}
```

---

## Testing Strategy

### Backend
- **Unit tests**: `SoulyCommandRouterTest`, `SoulyActionPolicyServiceTest`, `SoulyContextAssemblerTest`, `ApprovalInboxServiceTest`, `SoulyInstructionVersionServiceTest`, `HedraMemoryServiceTest`
- **Feature tests**: `HedraSoulSessionApiTest`, `HedraSoulMessageApiTest`, `HedraSoulApprovalsApiTest`, `HedraSoulInstructionsApiTest`, `HedraSoulMemoriesApiTest`
- **PBT (Pest data-driven)**: Properties 1–12, minimum 100 iterations using Faker

### Frontend
- **Component tests** (React Testing Library): `NxHedraTopbar`, `NxApprovalInbox`, `NxSoulyControlPanel`, `NxHedraSoulComposer`
- **Integration tests** (Playwright): full send → approval flow, instruction activation, memory approval
- **PBT (fast-check)**: Properties 13–15 for realtime and UI state properties, 100 runs each

### Property Test Tag Format
`Feature: hedra-soul-hub, Property {N}: {property_text}`
