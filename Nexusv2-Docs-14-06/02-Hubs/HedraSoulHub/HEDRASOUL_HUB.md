# HedraSoulHub — Full Documentation

## Hub Overview

HedraSoulHub is the most complex and unique hub in Nexus. It provides a persistent AI assistant ("HedraSoul" / "Souly") with:
- A full conversation interface with session management
- 5 configurable autonomy levels
- Human-in-the-loop approval gates for risky operations
- Cloned user personality model built from documents and history
- Full audit trail of every AI decision made

---

# Part 1: Backend Documentation

## 1.1 API Endpoints

### Sessions
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/hedrasoul/sessions` | `HedraSoulSessionController@index` | List all sessions |
| POST | `/api/hedrasoul/sessions` | `HedraSoulSessionController@store` | Create new session |
| GET | `/api/hedrasoul/sessions/{id}` | `HedraSoulSessionController@show` | Get session details |
| PUT | `/api/hedrasoul/sessions/{id}` | `HedraSoulSessionController@update` | Update session |
| POST | `/api/hedrasoul/sessions/{id}/close` | `HedraSoulSessionController@close` | Close session |
| POST | `/api/hedrasoul/sessions/{id}/archive` | `HedraSoulSessionController@archive` | Archive session |

### Messages
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/hedrasoul/sessions/{id}/messages` | `HedraSoulMessageController@index` | Get session messages |
| POST | `/api/hedrasoul/sessions/{id}/messages` | `HedraSoulMessageController@store` | Send message to HedraSoul |

### Autonomy & Control
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/hedrasoul/runtime-profile` | `SoulyControlController@getRuntimeProfile` | Current autonomy profile |
| PUT | `/api/hedrasoul/runtime-profile` | `SoulyControlController@updateRuntimeProfile` | Update autonomy settings |
| POST | `/api/hedrasoul/runtime-profile/quarantine` | `SoulyControlController@quarantine` | Emergency pause |
| POST | `/api/hedrasoul/runtime-profile/lift-quarantine` | `SoulyControlController@liftQuarantine` | Restore from quarantine |
| GET | `/api/hedrasoul/instructions` | `SoulyInstructionController@index` | List instruction versions |
| POST | `/api/hedrasoul/instructions` | `SoulyInstructionController@store` | Create new instruction version |
| POST | `/api/hedrasoul/instructions/{id}/activate` | `SoulyInstructionController@activate` | Activate instruction version |

### Approvals
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/hedrasoul/approvals` | `HedraSoulApprovalController@index` | List approval requests |
| POST | `/api/hedrasoul/approvals/{id}/approve` | `HedraSoulApprovalController@approve` | Approve action |
| POST | `/api/hedrasoul/approvals/{id}/reject` | `HedraSoulApprovalController@reject` | Reject action |
| POST | `/api/hedrasoul/approvals/{id}/defer` | `HedraSoulApprovalController@defer` | Defer decision |

### Memory & Profile
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/hedrasoul/memory` | `HedraMemoryController@index` | HedraSoul memory |
| POST | `/api/hedrasoul/memory` | `HedraMemoryController@store` | Add memory |
| DELETE | `/api/hedrasoul/memory/{id}` | `HedraMemoryController@destroy` | Delete memory |
| GET | `/api/hedrasoul/profile-facts` | `HedraProfileController@index` | User profile facts |
| GET | `/api/hedrasoul/clone-sources` | `HedraCloneSourceController@index` | Cloning sources |
| POST | `/api/hedrasoul/clone-sources` | `HedraCloneSourceController@store` | Add clone source |

### Notifications & Misc
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/hedrasoul/notifications` | `HedraSoulNotificationController@index` | In-system notifications |
| POST | `/api/hedrasoul/notifications/{id}/read` | mark as read |
| GET | `/api/hedrasoul/action-traces` | `HedraSoulMiscController` | Execution trace log |
| GET | `/api/hedrasoul/context-snapshots` | Context snapshots list |

---

## 1.2 Core Services

### SoulyCommandRouter
Routes incoming user messages to the correct action:
```php
// Parses intent → determines action
// Returns: { intent, selected_action, risk_level }
$route = $router->route($message, $runtimeProfile);
```

### SoulyContextAssembler
Builds the full context package for an AI call:
```php
// Assembles: instruction_version, persona, memories, 
//            conversation history, current session data
// Returns context_snapshot stored in DB
$context = $assembler->assemble($session, $message);
```

### SoulyActionPolicyService
Evaluates whether an action is allowed under current autonomy rules:
```php
// Checks: autonomy_mode, tool_permissions, is_quarantined
// Returns: { allowed: bool, explanation: string }
$policy = $policyService->evaluate($intent, $runtimeProfile);
```

### ApprovalInboxService
Manages the approval gate lifecycle:
```php
$request = $inboxService->createRequest([
  'source_type' => 'task',
  'action_description' => 'Send message to 150 contacts',
  'risk_level' => 'high',
  'cost_estimate' => 25.00,
]);
// Execution is BLOCKED until user approves/rejects
```

### HedraMemoryService
Manages HedraSoul's personal memory about the user:
```php
$memory->addFact($type, $content, $confidence);
$memory->getSuggestions(); // Pending memory suggestions to approve
$memory->approveSuggestion($id);
```

### HedraCloneProfileService
Processes external sources (documents, emails) to build personality clone:
```php
$service->ingestSource($content, $type, $sensitivity);
// → Extracts profile facts
// → Builds HedraProfileFacts
// → Updates memory suggestions
```

### HedraSoulRealtimeBroadcaster
Pushes real-time events to the frontend:
```php
$broadcaster->broadcastMessage($session, $message);
$broadcaster->broadcastApprovalRequest($request);
$broadcaster->broadcastNotification($notification);
```

---

## 1.3 Autonomy Mode Logic

```
chat_only          → policy.allowed = false for ALL actions except reading
copilot            → shows suggestions, requires explicit user trigger
operator           → executes low_risk actions automatically
autopilot_limited  → executes medium_risk and below, blocks high_risk
emergency_paused   → is_quarantined = true, ALL actions blocked
```

**Risk Level Classification:**
| Level | Examples |
|-------|---------|
| `low` | Reading data, generating summaries, fetching memories |
| `medium` | Sending notifications, creating tasks, updating contacts |
| `high` | Bulk operations, external messaging to many contacts, workflow triggers |
| `critical` | Deleting data, billing actions, external payments |

---

# Part 2: Frontend Documentation

## 2.1 Hub Page (`app/hedra-soul/page.tsx`)

Main HedraSoulHub page features:
- **Chat interface**: Message input, streaming response display
- **Session sidebar**: Session list, create new session, archive
- **Autonomy panel**: Current mode, change autonomy level
- **Approval inbox**: Pending approvals with approve/reject
- **Memory panel**: Browse HedraSoul's memory about you
- **Notifications**: In-system alerts from HedraSoul

## 2.2 Key Custom Hook: `useHedraSoulHub`

**File:** `hooks/useHedraSoulHub.ts`

Comprehensive hook managing all HedraSoulHub state and operations:

```typescript
const {
  // Session management
  sessions, activeSession, createSession, closeSession,

  // Messaging
  messages, sendMessage, isStreaming,

  // Autonomy
  runtimeProfile, updateAutonomyMode, quarantine, liftQuarantine,

  // Approvals
  pendingApprovals, approveAction, rejectAction,

  // Memory
  memories, memorySuggestions, approveMemorySuggestion,

  // Instructions
  instructionVersions, activeInstruction, activateInstruction,
} = useHedraSoulHub();
```

## 2.3 Components

| Component | Purpose |
|-----------|---------|
| `NxApprovalGateModal` | Shows pending approval request details + approve/reject |
| `NxChatBubble` / `NxMessageBubble` | Chat message rendering |
| `NxChatInput` | Rich message input with @mentions support |
| `NxThinkingIndicator` | Animated "HedraSoul is thinking" indicator |
| `NxAuditViewer` | Shows SoulyActionTrace records |
| `NxNotificationDrawer` | In-system notification drawer |
| `NxMemoryChip` | Individual memory visualization |
| `NxSourceCitation` | Shows evidence/citations for AI decisions |
| `NxTokenBudget` | Token usage and cost display |

## 2.4 TypeScript Types

All types defined in `app/hedra-soul/types.ts`:
- `HedrasoulSession`
- `HedrasoulMessage`
- `SoulyRuntimeProfile`
- `HedrasoulApprovalRequest`
- `HedraProfileFact`
- `SoulyInstructionVersion`
- `SoulyActionTrace`
- `HedraCloneSource`

---

# Part 3: Frontend ↔ Backend Integration

## 3.1 Message Send Flow

```
User types message + hits send
  → sendMessage({ session_id, body, intent })
  → POST /api/hedrasoul/sessions/{id}/messages
  → HedraSoulMessageController@store
  → SoulyCommandRouter analyzes intent
  → SoulyActionPolicyService evaluates risk
  ┌─ IF allowed:
  │   → UniversalAiGatewayService calls LLM
  │   → SoulyContextAssembler builds context
  │   → AI generates response
  │   → HedraSoulRealtimeBroadcaster pushes via WebSocket
  │   → Frontend receives 'HedraSoulMessageCreated' event
  │   → Message appended to chat
  └─ IF blocked (needs approval):
      → ApprovalInboxService creates request
      → 'ApprovalRequestCreated' WebSocket event
      → NxApprovalGateModal opens on frontend
      → User approves → action executes
      → User rejects → action cancelled
```

## 3.2 Real-Time Channel

```typescript
// Frontend subscribes:
Echo.private(`nexus.hedrasoul.${userId}`)
  .listen('HedraSoulMessageCreated', (msg) => addMessage(msg))
  .listen('ApprovalRequestCreated', (req) => showApprovalModal(req))
  .listen('HedraSoulNotificationCreated', (n) => addNotification(n))
  .listen('AutonomyModeChanged', (e) => updateRuntimeProfile(e.profile));
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
